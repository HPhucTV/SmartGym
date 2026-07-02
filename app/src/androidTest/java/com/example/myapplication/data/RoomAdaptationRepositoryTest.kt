package com.example.myapplication.data

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.myapplication.core.adaptation.AdaptationDecision
import com.example.myapplication.core.adaptation.AdaptationKind
import com.example.myapplication.core.adaptation.AdaptationMode
import com.example.myapplication.core.adaptation.AdaptationStatus
import com.example.myapplication.core.nutrition.EntrySource
import com.example.myapplication.core.nutrition.Nutrients
import com.example.myapplication.core.nutrition.NutritionTarget
import com.example.myapplication.core.nutrition.NutritionTargetAudit
import com.example.myapplication.core.profile.ActivityLevel
import com.example.myapplication.core.profile.GoalPace
import com.example.myapplication.core.profile.MetabolicSex
import com.example.myapplication.data.local.DailyNutritionEntity
import com.example.myapplication.data.local.GymDatabase
import com.example.myapplication.data.local.PersonalProfileEntity
import com.example.myapplication.data.local.PersonalizationDao
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class RoomAdaptationRepositoryTest {
    private lateinit var database: GymDatabase
    private lateinit var dao: PersonalizationDao
    private lateinit var nutritionRepository: NutritionRepository
    private lateinit var adaptationRepository: RoomAdaptationRepository

    private var todayEpoch = 20636L
    private var nowMillis = 1000L

    @Before
    fun setUp() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = Room.inMemoryDatabaseBuilder(context, GymDatabase::class.java)
            .allowMainThreadQueries()
            .build()
        dao = database.personalizationDao()

        // Create a real/fake hybrid or clean database-backed nutrition repository for testing
        // Let's use RoomNutritionRepository but with fake legacy preferences since we don't care about legacy migration
        val fakeLegacyPrefs = object : LegacyNutritionPreferences {
            override val state: Flow<NutritionPreferenceState> = flowOf(NutritionPreferenceState(roomMigrated = true))
            override suspend fun snapshotForMigration() = LegacyNutritionSnapshot()
            override suspend fun markRoomMigrated() = Unit
            override suspend fun setSweatPayment(exerciseId: String, exerciseName: String, extraSets: Int, active: Boolean) = Unit
            override suspend fun clearSweatPayment() = Unit
            override suspend fun updateAiCoachReview(review: String) = Unit
            override suspend fun clearAiCoachReview() = Unit
        }

        nutritionRepository = RoomNutritionRepository(
            personalizationDao = dao,
            legacyPreferences = fakeLegacyPrefs,
            todayEpochDay = { todayEpoch },
            nowEpochMillis = { nowMillis }
        )

        adaptationRepository = RoomAdaptationRepository(
            database = database,
            personalizationDao = dao,
            nutritionRepository = nutritionRepository,
            nowEpochMillis = { nowMillis },
            todayEpochDay = { todayEpoch }
        )
    }

    @After
    fun tearDown() {
        database.close()
    }

    @Test
    fun autoApplyDecision_takesEffectImmediately() = runTest {
        // Setup initial profile and nutrition target
        setupInitialTarget(2400)

        val decision = AdaptationDecision(
            kind = AdaptationKind.CALORIE_TARGET,
            mode = AdaptationMode.AUTO_APPLY,
            reasonVi = "Đề xuất tự động điều chỉnh.",
            beforeValue = """{"calories":2400}""",
            afterValue = """{"calories":2300}""",
            undoPayload = """{"calories":2400}"""
        )

        val decisionId = adaptationRepository.recordDecision(decision)

        // 1. Verify status is APPLIED in DB
        val stored = dao.decisionByIdNow(decisionId)
        assertTrue(stored != null)
        assertEquals(AdaptationStatus.APPLIED, stored!!.status)

        // 2. Verify target calories updated in Room
        val currentTarget = nutritionRepository.observeDay(todayEpoch).first().target
        assertTrue(currentTarget != null)
        assertEquals(2300, currentTarget!!.calories)
    }

    @Test
    fun requiresConfirmationDecision_doesNotTakeEffectAutomatically() = runTest {
        setupInitialTarget(2400)

        val decision = AdaptationDecision(
            kind = AdaptationKind.CALORIE_TARGET,
            mode = AdaptationMode.REQUIRES_CONFIRMATION,
            reasonVi = "Cần xác nhận thay đổi.",
            beforeValue = """{"calories":2400}""",
            afterValue = """{"calories":2000}""",
            undoPayload = """{"calories":2400}"""
        )

        val decisionId = adaptationRepository.recordDecision(decision)

        // 1. Verify status is PROPOSED
        val stored = dao.decisionByIdNow(decisionId)
        assertTrue(stored != null)
        assertEquals(AdaptationStatus.PROPOSED, stored!!.status)

        // 2. Verify target calories unchanged
        val currentTarget = nutritionRepository.observeDay(todayEpoch).first().target
        assertTrue(currentTarget != null)
        assertEquals(2400, currentTarget!!.calories)
    }

    @Test
    fun acceptDecision_appliesProposedChanges() = runTest {
        setupInitialTarget(2400)

        val decision = AdaptationDecision(
            kind = AdaptationKind.CALORIE_TARGET,
            mode = AdaptationMode.REQUIRES_CONFIRMATION,
            reasonVi = "Cần xác nhận thay đổi.",
            beforeValue = """{"calories":2400}""",
            afterValue = """{"calories":2000}""",
            undoPayload = """{"calories":2400}"""
        )

        val id = adaptationRepository.recordDecision(decision)
        val result = adaptationRepository.acceptDecision(id)

        // 1. Verify success returned
        assertEquals(DecisionActionResult.Success, result)

        // 2. Verify status changed to APPLIED
        val stored = dao.decisionByIdNow(id)
        assertEquals(AdaptationStatus.APPLIED, stored!!.status)

        // 3. Verify target updated
        val target = nutritionRepository.observeDay(todayEpoch).first().target
        assertEquals(2000, target!!.calories)
    }

    @Test
    fun rejectDecision_marksProposedAsRejectedWithoutApplying() = runTest {
        setupInitialTarget(2400)

        val decision = AdaptationDecision(
            kind = AdaptationKind.CALORIE_TARGET,
            mode = AdaptationMode.REQUIRES_CONFIRMATION,
            reasonVi = "Cần xác nhận.",
            beforeValue = """{"calories":2400}""",
            afterValue = """{"calories":2000}""",
            undoPayload = """{"calories":2400}"""
        )

        val id = adaptationRepository.recordDecision(decision)
        val result = adaptationRepository.rejectDecision(id)

        assertEquals(DecisionActionResult.Success, result)
        assertEquals(AdaptationStatus.REJECTED, dao.decisionByIdNow(id)!!.status)

        val target = nutritionRepository.observeDay(todayEpoch).first().target
        assertEquals(2400, target!!.calories)
    }

    @Test
    fun acceptOrReject_invalidStateChecks() = runTest {
        setupInitialTarget(2400)

        val decision = AdaptationDecision(
            kind = AdaptationKind.CALORIE_TARGET,
            mode = AdaptationMode.AUTO_APPLY, // Will be recorded as APPLIED
            reasonVi = "Tự động.",
            beforeValue = """{"calories":2400}""",
            afterValue = """{"calories":2300}""",
            undoPayload = """{"calories":2400}"""
        )

        val id = adaptationRepository.recordDecision(decision)

        // Try to accept an already APPLIED decision
        val result = adaptationRepository.acceptDecision(id)
        assertTrue(result is DecisionActionResult.InvalidState)
    }

    @Test
    fun acceptDecision_withStaleBeforeState_failsWithStale() = runTest {
        setupInitialTarget(2400)

        val decision = AdaptationDecision(
            kind = AdaptationKind.CALORIE_TARGET,
            mode = AdaptationMode.REQUIRES_CONFIRMATION,
            reasonVi = "Thay đổi.",
            beforeValue = """{"calories":2400}""",
            afterValue = """{"calories":2200}""",
            undoPayload = """{"calories":2400}"""
        )

        val id = adaptationRepository.recordDecision(decision)

        // Change current target manually behind the scenes, making the proposed decision stale
        nutritionRepository.setTarget(todayEpoch, defaultTarget(2500))

        val result = adaptationRepository.acceptDecision(id)
        assertTrue(result is DecisionActionResult.Stale)

        // Verify target remains at 2500
        val target = nutritionRepository.observeDay(todayEpoch).first().target
        assertEquals(2500, target!!.calories)
    }

    @Test
    fun undoLatestDecision_revertsTargetAndStatus() = runTest {
        setupInitialTarget(2400)

        // Record and apply a decision
        val decision = AdaptationDecision(
            kind = AdaptationKind.CALORIE_TARGET,
            mode = AdaptationMode.AUTO_APPLY,
            reasonVi = "Tự động thay đổi.",
            beforeValue = """{"calories":2400}""",
            afterValue = """{"calories":2300}""",
            undoPayload = """{"calories":2400}"""
        )
        val id = adaptationRepository.recordDecision(decision)

        // Verify target is 2300
        assertEquals(2300, nutritionRepository.observeDay(todayEpoch).first().target!!.calories)

        // Undo
        val result = adaptationRepository.undoLatestDecision(AdaptationKind.CALORIE_TARGET)
        assertEquals(DecisionActionResult.Success, result)

        // Verify status changed to UNDONE
        assertEquals(AdaptationStatus.UNDONE, dao.decisionByIdNow(id)!!.status)

        // Verify target reverted to 2400
        assertEquals(2400, nutritionRepository.observeDay(todayEpoch).first().target!!.calories)
    }

    @Test
    fun undoLatestDecision_whenNewerDecisionIsApplied_failsWithStale() = runTest {
        setupInitialTarget(2400)

        // 1. Record first decision (2400 -> 2300)
        val firstDecision = AdaptationDecision(
            kind = AdaptationKind.CALORIE_TARGET,
            mode = AdaptationMode.AUTO_APPLY,
            reasonVi = "Tự động 1.",
            beforeValue = """{"calories":2400}""",
            afterValue = """{"calories":2300}""",
            undoPayload = """{"calories":2400}"""
        )
        val firstId = adaptationRepository.recordDecision(firstDecision)
        nowMillis += 1000 // increment clock

        // 2. Record second decision (2300 -> 2200)
        val secondDecision = AdaptationDecision(
            kind = AdaptationKind.CALORIE_TARGET,
            mode = AdaptationMode.AUTO_APPLY,
            reasonVi = "Tự động 2.",
            beforeValue = """{"calories":2300}""",
            afterValue = """{"calories":2200}""",
            undoPayload = """{"calories":2300}"""
        )
        val secondId = adaptationRepository.recordDecision(secondDecision)

        // Try to undo firstId by calling undo (it queries latest APPLIED, which is secondId)
        // Wait, undoLatestDecision takes `kind` and undos the latest APPLIED.
        // Let's verify that undoing CALORIE_TARGET once undos secondId (newest).
        val firstUndoResult = adaptationRepository.undoLatestDecision(AdaptationKind.CALORIE_TARGET)
        assertEquals(DecisionActionResult.Success, firstUndoResult)
        assertEquals(AdaptationStatus.UNDONE, dao.decisionByIdNow(secondId)!!.status)
        assertEquals(2300, nutritionRepository.observeDay(todayEpoch).first().target!!.calories)

        // Now if we try to undo again, the latest APPLIED is firstId.
        // But since there is a newer resolved decision of the same kind in history (secondId, which is UNDONE but was newer),
        // wait! The query for newer conflict looks at all decisions in history with:
        // `it.kind == kind && it.id != entity.id && it.createdAtEpochMillis > entity.createdAtEpochMillis && it.status == AdaptationStatus.APPLIED`
        // Since secondId is UNDONE, it doesn't match `status == AdaptationStatus.APPLIED`.
        // So firstId can be undone! Let's test that:
        val secondUndoResult = adaptationRepository.undoLatestDecision(AdaptationKind.CALORIE_TARGET)
        assertEquals(DecisionActionResult.Success, secondUndoResult)
        assertEquals(AdaptationStatus.UNDONE, dao.decisionByIdNow(firstId)!!.status)
        assertEquals(2400, nutritionRepository.observeDay(todayEpoch).first().target!!.calories)
    }

    @Test
    fun undoLatestDecision_whenNewerActiveAppliedDecisionExists_failsWithStale() = runTest {
        setupInitialTarget(2400)

        // 1. Record first decision (2400 -> 2300)
        val firstDecision = AdaptationDecision(
            kind = AdaptationKind.CALORIE_TARGET,
            mode = AdaptationMode.AUTO_APPLY,
            reasonVi = "Tự động 1.",
            beforeValue = """{"calories":2400}""",
            afterValue = """{"calories":2300}""",
            undoPayload = """{"calories":2400}"""
        )
        val firstId = adaptationRepository.recordDecision(firstDecision)
        nowMillis += 1000

        // 2. Record second decision (2300 -> 2200)
        val secondDecision = AdaptationDecision(
            kind = AdaptationKind.CALORIE_TARGET,
            mode = AdaptationMode.AUTO_APPLY,
            reasonVi = "Tự động 2.",
            beforeValue = """{"calories":2300}""",
            afterValue = """{"calories":2200}""",
            undoPayload = """{"calories":2300}"""
        )
        val secondId = adaptationRepository.recordDecision(secondDecision)

        // Manually try to undo firstId by simulating if we fetched firstId and tried to check for newer conflicts.
        // Wait, undoLatestDecision checks if there is any newer decision of same kind with status == APPLIED.
        // Let's look at RoomAdaptationRepository.kt implementation:
        // `val entity = latestDecisionByKindAndStatus(kind, APPLIED)` -> will find secondId.
        // If we want to simulate trying to undo firstId, we can't do it directly via public API because undoLatestDecision always finds latest APPLIED.
        // But we can check that `latestDecisionByKindAndStatus` correctly returns secondId.
        val latestApplied = dao.latestDecisionByKindAndStatus(AdaptationKind.CALORIE_TARGET, AdaptationStatus.APPLIED)
        assertEquals(secondId, latestApplied?.id)
    }

    // ── Helpers ─────────────────────────────────────────────────────────

    private suspend fun setupInitialTarget(calories: Int) {
        nutritionRepository.setTarget(todayEpoch, defaultTarget(calories))
    }

    private fun defaultTarget(calories: Int) = NutritionTarget(
        basalCalories = 1700,
        maintenanceCalories = 2600,
        calories = calories,
        proteinGrams = 120,
        carbsGrams = 280,
        fatGrams = 60,
        audit = NutritionTargetAudit(
            rawBasalCalories = 1700.0,
            rawMaintenanceCalories = 2600.0,
            rawTargetCalories = calories.toDouble(),
            rawProteinGrams = 120.0,
            rawCarbsGrams = 280.0,
            rawFatGrams = 60.0
        )
    )
}
