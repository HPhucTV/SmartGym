package com.example.myapplication

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.myapplication.core.adaptation.*
import com.example.myapplication.core.nutrition.*
import com.example.myapplication.core.profile.*
import com.example.myapplication.data.*
import com.example.myapplication.data.local.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.time.LocalDate

@RunWith(AndroidJUnit4::class)
class AdaptiveJourneyEndToEndTest {
    private lateinit var database: GymDatabase
    private lateinit var dao: PersonalizationDao
    private lateinit var nutritionRepository: NutritionRepository
    private lateinit var adaptationRepository: AdaptationRepository
    private lateinit var engine: AdaptationEngine

    private var todayEpoch = LocalDate.of(2026, 7, 2).toEpochDay()
    private var nowMillis = 1000L

    @Before
    fun setUp() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = Room.inMemoryDatabaseBuilder(context, GymDatabase::class.java)
            .allowMainThreadQueries()
            .build()
        dao = database.personalizationDao()

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

        engine = AdaptationEngine()
    }

    @After
    fun tearDown() {
        database.close()
    }

    @Test
    fun completeAdaptiveNutritionJourney_flowAndUndo() = runTest {
        // 1. Profile Setup
        val profile = PersonalProfile(
            birthDateEpochDay = LocalDate.of(1995, 6, 15).toEpochDay(),
            metabolicSex = MetabolicSex.MALE,
            heightCm = 175.0,
            currentWeightKg = 78.0,
            targetWeightKg = 72.0,
            activityLevel = ActivityLevel.MODERATE,
            goalPace = GoalPace.GRADUAL,
            personalizationConsent = true,
            cloudAiConsent = false
        )
        dao.upsertProfile(PersonalProfileEntity(
            birthDateEpochDay = profile.birthDateEpochDay,
            metabolicSex = profile.metabolicSex,
            heightCm = profile.heightCm,
            currentWeightKg = profile.currentWeightKg,
            targetWeightKg = profile.targetWeightKg,
            activityLevel = profile.activityLevel,
            goalPace = profile.goalPace,
            personalizationConsent = profile.personalizationConsent,
            cloudAiConsent = profile.cloudAiConsent,
            updatedAtEpochMillis = nowMillis
        ))

        // 2. Initial Nutrition Target
        val calculator = NutritionTargetCalculator()
        val calcResult = calculator.calculate(profile, 31)
        assertTrue(calcResult is CalculationResult.Target)
        val initialTarget = (calcResult as CalculationResult.Target).value
        nutritionRepository.setTarget(todayEpoch, initialTarget)

        // 3. Food Entry
        nutritionRepository.addNutrients(
            todayEpoch,
            Nutrients(calories = 600, proteinGrams = 40, carbsGrams = 70, fatGrams = 15),
            EntrySource.MANUAL
        )
        val dailyNutrition = nutritionRepository.observeDay(todayEpoch).first()
        assertEquals(600, dailyNutrition.consumed.calories)
        assertEquals(initialTarget.calories, dailyNutrition.target?.calories)

        // 4. Weekly Check-In
        dao.upsertWeeklyCheckIn(WeeklyCheckInEntity(
            weekStartEpochDay = todayEpoch - 7,
            weightKg = 78.2,
            energy = 4,
            hunger = 3,
            recovery = 5,
            sleepQuality = 4,
            note = "Feeling great",
            createdAtEpochMillis = nowMillis
        ))

        // 5. Evaluate Adaptation Engine (Capped nutrition correction auto-applies)
        val snapshot = WeeklySnapshot(
            currentCalories = initialTarget.calories,
            currentTarget = initialTarget,
            averageConsumedCalories = 2300,
            adherencePercent = 0.85,
            recentWeights = listOf(78.2, 78.0), // weight trend slightly down, but target is 72, so decrease needed
            targetWeightKg = 72.0,
            latestCheckIn = CheckInData(4, 3, 5, 4),
            consecutiveLowRecoveryCheckIns = 0,
            daysSinceLastCalorieDecision = 10,
            daysSinceLastWorkoutDecision = 10,
            trackedDays = 7,
            completedSessionsThisWeek = 3,
            scheduledSessionsThisWeek = 3,
            missedSessions = 0,
            profileAgeYears = 31,
            profile = profile
        )

        val decisions = engine.evaluate(snapshot)
        val calorieDecision = decisions.firstOrNull { it.kind == AdaptationKind.CALORIE_TARGET }
        assertNotNull(calorieDecision)
        assertEquals(AdaptationMode.AUTO_APPLY, calorieDecision!!.mode)

        // Record the decision (applies the effect automatically since AUTO_APPLY)
        val decisionId = adaptationRepository.recordDecision(calorieDecision)
        
        // 6. Verify status and applied target
        val recorded = dao.decisionByIdNow(decisionId)
        assertNotNull(recorded)
        assertEquals(AdaptationStatus.APPLIED, recorded!!.status)

        val newTarget = nutritionRepository.observeDay(todayEpoch).first().target
        assertNotNull(newTarget)
        assertTrue(newTarget!!.calories < initialTarget.calories)

        // 7. Undo applied decision
        val undoResult = adaptationRepository.undoLatestDecision(AdaptationKind.CALORIE_TARGET)
        assertEquals(DecisionActionResult.Success, undoResult)

        // Verify state is UNDONE and target is reverted
        val revertedTarget = nutritionRepository.observeDay(todayEpoch).first().target
        assertEquals(initialTarget.calories, revertedTarget!!.calories)
        assertEquals(AdaptationStatus.UNDONE, dao.decisionByIdNow(decisionId)!!.status)
    }
}
