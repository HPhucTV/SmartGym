package com.example.myapplication.data

import com.example.myapplication.core.nutrition.EntrySource
import com.example.myapplication.core.nutrition.Nutrients
import com.example.myapplication.core.nutrition.NutritionTarget
import com.example.myapplication.core.nutrition.NutritionTargetAudit
import com.example.myapplication.data.local.AdaptationDecisionEntity
import com.example.myapplication.data.local.DailyNutritionEntity
import com.example.myapplication.data.local.PersonalProfileEntity
import com.example.myapplication.data.local.PersonalizationDao
import com.example.myapplication.data.local.WeeklyCheckInEntity
import com.example.myapplication.data.local.WeightMeasurementEntity
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class NutritionRepositoryTest {
    @Test
    fun `adding food changes only selected day`() = runTest {
        val dao = FakePersonalizationDao()
        val repository = RoomNutritionRepository(
            personalizationDao = dao,
            legacyPreferences = FakeLegacyNutritionPreferences(),
            todayEpochDay = { 20636L },
            nowEpochMillis = { 1000L },
        )

        repository.addNutrients(
            epochDay = 20636L,
            nutrients = Nutrients(calories = 500, proteinGrams = 30, carbsGrams = 60, fatGrams = 15),
            source = EntrySource.MANUAL,
        )

        assertEquals(500, repository.observeDay(20636L).first().consumed.calories)
        assertEquals(0, repository.observeDay(20637L).first().consumed.calories)
    }

    @Test
    fun `setting target preserves consumed nutrients for that day`() = runTest {
        val repository = RoomNutritionRepository(
            personalizationDao = FakePersonalizationDao(),
            legacyPreferences = FakeLegacyNutritionPreferences(),
            todayEpochDay = { 20636L },
            nowEpochMillis = { 1000L },
        )
        repository.addNutrients(
            epochDay = 20636L,
            nutrients = Nutrients(calories = 400, proteinGrams = 20, carbsGrams = 45, fatGrams = 12),
            source = EntrySource.MANUAL,
        )

        repository.setTarget(20636L, target())

        val day = repository.observeDay(20636L).first()
        assertEquals(400, day.consumed.calories)
        assertEquals(2400, day.target!!.calories)
    }

    @Test
    fun `legacy daily totals migrate once into today's room row`() = runTest {
        val legacy = FakeLegacyNutritionPreferences(
            migrated = false,
            snapshot = LegacyNutritionSnapshot(
                caloriesEaten = 350,
                proteinEaten = 25,
                carbsEaten = 40,
                fatEaten = 8,
                sweatExerciseId = "push_up",
                sweatExerciseName = "Chong day",
                sweatExtraSets = 2,
                sweatActive = true,
                aiCoachReview = "On dinh",
            ),
        )
        val repository = RoomNutritionRepository(
            personalizationDao = FakePersonalizationDao(),
            legacyPreferences = legacy,
            todayEpochDay = { 20636L },
            nowEpochMillis = { 1000L },
        )

        val today = repository.observeDay(20636L).first()
        repository.observeDay(20636L).first()

        assertEquals(350, today.consumed.calories)
        assertTrue(legacy.migrated)
        assertEquals(1, legacy.markMigrationCalls)
        assertEquals("push_up", repository.nutritionData.first().sweatExerciseId)
    }

    @Test
    fun `range observes stored days in date order`() = runTest {
        val repository = RoomNutritionRepository(
            personalizationDao = FakePersonalizationDao(),
            legacyPreferences = FakeLegacyNutritionPreferences(migrated = true),
            todayEpochDay = { 20636L },
            nowEpochMillis = { 1000L },
        )
        repository.addNutrients(20638L, Nutrients(calories = 300), EntrySource.MANUAL)
        repository.addNutrients(20636L, Nutrients(calories = 100), EntrySource.MANUAL)

        val days = repository.observeRange(20636L, 20638L).first()

        assertEquals(listOf(20636L, 20638L), days.map { it.epochDay })
    }

    @Test
    fun `resetting today leaves stored target intact`() = runTest {
        val repository = RoomNutritionRepository(
            personalizationDao = FakePersonalizationDao(),
            legacyPreferences = FakeLegacyNutritionPreferences(migrated = true),
            todayEpochDay = { 20636L },
            nowEpochMillis = { 1000L },
        )
        repository.setTarget(20636L, target())
        repository.addNutrients(20636L, Nutrients(calories = 250), EntrySource.MANUAL)

        repository.resetDaily()

        val day = repository.observeDay(20636L).first()
        assertEquals(0, day.consumed.calories)
        assertEquals(2400, day.target!!.calories)
    }

    private fun target() = NutritionTarget(
        basalCalories = 1700,
        maintenanceCalories = 2600,
        calories = 2400,
        proteinGrams = 120,
        carbsGrams = 300,
        fatGrams = 67,
        audit = NutritionTargetAudit(
            rawBasalCalories = 1700.0,
            rawMaintenanceCalories = 2600.0,
            rawTargetCalories = 2400.0,
            rawProteinGrams = 120.0,
            rawCarbsGrams = 300.0,
            rawFatGrams = 67.0,
        ),
    )
}

private class FakePersonalizationDao : PersonalizationDao {
    private val nutritionRows = MutableStateFlow<Map<Long, DailyNutritionEntity>>(emptyMap())

    override suspend fun upsertProfile(profile: PersonalProfileEntity) = Unit
    override fun observeProfile(): Flow<PersonalProfileEntity?> = MutableStateFlow(null)
    override suspend fun profileNow(): PersonalProfileEntity? = null
    override suspend fun upsertWeight(measurement: WeightMeasurementEntity) = Unit
    override suspend fun latestWeightNow(): WeightMeasurementEntity? = null
    override fun observeWeightHistory(): Flow<List<WeightMeasurementEntity>> = MutableStateFlow(emptyList())
    override suspend fun weightHistoryNow(): List<WeightMeasurementEntity> = emptyList()

    override suspend fun upsertDailyNutrition(day: DailyNutritionEntity) {
        nutritionRows.value = nutritionRows.value + (day.epochDay to day)
    }

    override fun observeNutritionDay(epochDay: Long): Flow<DailyNutritionEntity?> =
        nutritionRows.map { rows -> rows[epochDay] }

    override fun observeNutritionRange(startEpochDay: Long, endEpochDay: Long): Flow<List<DailyNutritionEntity>> =
        nutritionRows.map { rows ->
            rows.values
                .filter { it.epochDay in startEpochDay..endEpochDay }
                .sortedBy { it.epochDay }
        }

    override suspend fun nutritionRangeNow(startEpochDay: Long, endEpochDay: Long): List<DailyNutritionEntity> =
        nutritionRows.value.values
            .filter { it.epochDay in startEpochDay..endEpochDay }
            .sortedBy { it.epochDay }

    override suspend fun upsertWeeklyCheckIn(checkIn: WeeklyCheckInEntity) = Unit
    override fun observeLatestCheckIn(): Flow<WeeklyCheckInEntity?> = MutableStateFlow(null)
    override suspend fun latestCheckInNow(): WeeklyCheckInEntity? = null
    override suspend fun insertDecision(decision: AdaptationDecisionEntity): Long = 1L
    override suspend fun updateDecisionStatus(id: Long, status: com.example.myapplication.core.adaptation.AdaptationStatus, resolvedAt: Long) = Unit
    override suspend fun decisionByIdNow(id: Long): AdaptationDecisionEntity? = null
    override suspend fun latestDecisionByKindAndStatus(kind: com.example.myapplication.core.adaptation.AdaptationKind, status: com.example.myapplication.core.adaptation.AdaptationStatus): AdaptationDecisionEntity? = null
    override fun observeDecisionHistory(): Flow<List<AdaptationDecisionEntity>> = MutableStateFlow(emptyList())
    override suspend fun decisionHistoryNow(): List<AdaptationDecisionEntity> = emptyList()
}

private class FakeLegacyNutritionPreferences(
    migrated: Boolean = true,
    private val snapshot: LegacyNutritionSnapshot = LegacyNutritionSnapshot(),
) : LegacyNutritionPreferences {
    private val companionState = MutableStateFlow(snapshot.toCompanionState(migrated))
    var migrated = migrated
        private set
    var markMigrationCalls = 0
        private set

    override val state: Flow<NutritionPreferenceState> = companionState

    override suspend fun snapshotForMigration(): LegacyNutritionSnapshot = snapshot

    override suspend fun markRoomMigrated() {
        markMigrationCalls += 1
        migrated = true
        companionState.value = companionState.value.copy(roomMigrated = true)
    }

    override suspend fun setSweatPayment(
        exerciseId: String,
        exerciseName: String,
        extraSets: Int,
        active: Boolean,
    ) {
        companionState.value = companionState.value.copy(
            sweatExerciseId = exerciseId,
            sweatExerciseName = exerciseName,
            sweatExtraSets = extraSets,
            sweatActive = active,
        )
    }

    override suspend fun clearSweatPayment() {
        companionState.value = companionState.value.copy(sweatActive = false)
    }

    override suspend fun updateAiCoachReview(review: String) {
        companionState.value = companionState.value.copy(aiCoachReview = review)
    }

    override suspend fun clearAiCoachReview() {
        companionState.value = companionState.value.copy(aiCoachReview = "")
    }

    private fun LegacyNutritionSnapshot.toCompanionState(migrated: Boolean) = NutritionPreferenceState(
        roomMigrated = migrated,
        sweatExerciseId = sweatExerciseId,
        sweatExerciseName = sweatExerciseName,
        sweatExtraSets = sweatExtraSets,
        sweatActive = sweatActive,
        aiCoachReview = aiCoachReview,
    )
}
