package com.example.myapplication.feature.profile

import com.example.myapplication.core.model.ActiveGoal
import com.example.myapplication.data.CompleteWorkoutResult
import com.example.myapplication.core.model.CompletedWorkout
import com.example.myapplication.core.model.EquipmentProfile
import com.example.myapplication.core.model.ExperienceLevel
import com.example.myapplication.core.model.FitnessGoal
import com.example.myapplication.core.model.GoalConfig
import com.example.myapplication.core.model.ProgramTemplate
import com.example.myapplication.core.model.RestDayMode
import com.example.myapplication.core.model.WorkoutSession
import com.example.myapplication.core.nutrition.EntrySource
import com.example.myapplication.core.nutrition.Nutrients
import com.example.myapplication.core.nutrition.NutritionDay
import com.example.myapplication.core.nutrition.NutritionTarget
import com.example.myapplication.core.profile.ActivityLevel
import com.example.myapplication.core.profile.GoalPace
import com.example.myapplication.core.profile.MetabolicSex
import com.example.myapplication.data.NutritionData
import com.example.myapplication.data.NutritionRepository
import com.example.myapplication.data.WorkoutRepository
import com.example.myapplication.data.local.AdaptationDecisionEntity
import com.example.myapplication.data.local.DailyNutritionEntity
import com.example.myapplication.data.local.PersonalProfileEntity
import com.example.myapplication.data.local.PersonalizationDao
import com.example.myapplication.data.local.WeeklyCheckInEntity
import com.example.myapplication.data.local.WeightMeasurementEntity
import com.example.myapplication.feature.onboarding.MainDispatcherRule
import java.time.LocalDate
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class ProfileViewModelTest {
    private val dispatcher = StandardTestDispatcher()
    @get:Rule val mainRule = MainDispatcherRule(dispatcher)

    @Test
    fun `default profile is set when database profile is empty`() = runTest(dispatcher) {
        val dao = FakePersonalizationDao()
        val viewModel = ProfileViewModel(
            personalizationDao = dao,
            workoutRepository = FakeWorkoutRepository(),
            nutritionRepository = FakeNutritionRepository(),
            currentEpochDay = { 20636L }
        )
        collectUiState(viewModel)
        runCurrent()

        val state = viewModel.uiState.value as ProfileUiState.Content
        assertEquals("170", state.heightCmStr)
        assertEquals("70", state.currentWeightKgStr)
        assertEquals("65", state.targetWeightKgStr)
        assertEquals(MetabolicSex.MALE, state.metabolicSex)
        assertEquals(ActivityLevel.MODERATE, state.activityLevel)
        assertEquals(GoalPace.GRADUAL, state.goalPace)
        assertFalse(state.personalizationConsent)
        assertFalse(state.cloudAiConsent)
    }

    @Test
    fun `saving valid profile updates DB and registers weight measurement`() = runTest(dispatcher) {
        val dao = FakePersonalizationDao()
        val nutritionRepo = FakeNutritionRepository()
        val viewModel = ProfileViewModel(
            personalizationDao = dao,
            workoutRepository = FakeWorkoutRepository(),
            nutritionRepository = nutritionRepo,
            currentEpochDay = { 20636L }
        )
        collectUiState(viewModel)
        runCurrent()

        viewModel.updateHeight("180")
        viewModel.updateCurrentWeight("80")
        viewModel.updateTargetWeight("75")
        viewModel.updatePersonalizationConsent(true)
        viewModel.saveProfile()
        advanceUntilIdle()

        val savedProfile = dao.profile
        assertNotNull(savedProfile)
        assertEquals(180.0, savedProfile!!.heightCm, 0.001)
        assertEquals(80.0, savedProfile.currentWeightKg, 0.001)
        assertEquals(75.0, savedProfile.targetWeightKg, 0.001)
        assertTrue(savedProfile.personalizationConsent)

        // Verify weight logged
        assertEquals(1, dao.weights.size)
        assertEquals(80.0, dao.weights.first().weightKg, 0.001)
        assertEquals(20636L, dao.weights.first().epochDay)

        // Verify nutrition target calculated and set
        assertEquals(1, nutritionRepo.targets.size)
        val target = nutritionRepo.targets.first().second
        assertTrue(target.calories > 0)
    }

    @Test
    fun `saving invalid values fails with validation errors`() = runTest(dispatcher) {
        val dao = FakePersonalizationDao()
        val viewModel = ProfileViewModel(
            personalizationDao = dao,
            workoutRepository = FakeWorkoutRepository(),
            nutritionRepository = FakeNutritionRepository(),
            currentEpochDay = { 20636L }
        )
        collectUiState(viewModel)
        runCurrent()

        viewModel.updateHeight("invalid")
        viewModel.updateCurrentWeight("-10")
        viewModel.saveProfile()
        advanceUntilIdle()

        val state = viewModel.uiState.value as ProfileUiState.Content
        assertTrue(state.validationErrors.isNotEmpty())
    }

    @Test
    fun `checkin is disabled if profile does not exist`() = runTest(dispatcher) {
        val dao = FakePersonalizationDao()
        val viewModel = com.example.myapplication.feature.checkin.WeeklyCheckInViewModel(
            personalizationDao = dao,
            nutritionRepository = FakeNutritionRepository(),
            currentEpochDay = { 20636L }
        )
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { viewModel.uiState.collect() }
        runCurrent()

        assertEquals(com.example.myapplication.feature.checkin.WeeklyCheckInUiState.NoProfile, viewModel.uiState.value)
    }

    @Test
    fun `submitting valid checkin updates checkins history, weight history, profile weight, and targets`() = runTest(dispatcher) {
        val dao = FakePersonalizationDao()
        dao.profile = PersonalProfileEntity(
            birthDateEpochDay = LocalDate.of(1995, 6, 15).toEpochDay(),
            metabolicSex = MetabolicSex.MALE,
            heightCm = 175.0,
            currentWeightKg = 78.0,
            targetWeightKg = 72.0,
            activityLevel = ActivityLevel.MODERATE,
            goalPace = GoalPace.GRADUAL,
            personalizationConsent = true,
            cloudAiConsent = false,
            updatedAtEpochMillis = 1000L
        )
        val nutritionRepo = FakeNutritionRepository()
        val viewModel = com.example.myapplication.feature.checkin.WeeklyCheckInViewModel(
            personalizationDao = dao,
            nutritionRepository = nutritionRepo,
            currentEpochDay = { 20636L }
        )
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { viewModel.uiState.collect() }
        runCurrent()

        val initialState = viewModel.uiState.value as com.example.myapplication.feature.checkin.WeeklyCheckInUiState.Input
        assertEquals("78.0", initialState.weightKgStr)

        viewModel.updateWeight("76.5")
        viewModel.updateEnergy(4)
        viewModel.updateHunger(2)
        viewModel.updateRecovery(5)
        viewModel.updateSleepQuality(4)
        viewModel.updateNote("Feeling good!")
        viewModel.submitCheckIn()
        advanceUntilIdle()

        // 1. Verify checkin saved
        assertEquals(1, dao.checkIns.size)
        val checkIn = dao.checkIns.first()
        assertEquals(20636L, checkIn.weekStartEpochDay)
        assertEquals(76.5, checkIn.weightKg, 0.001)
        assertEquals(4, checkIn.energy)
        assertEquals("Feeling good!", checkIn.note)

        // 2. Verify weight logged
        assertEquals(1, dao.weights.size)
        assertEquals(76.5, dao.weights.first().weightKg, 0.001)

        // 3. Verify profile current weight updated
        assertEquals(76.5, dao.profile!!.currentWeightKg, 0.001)

        // 4. Verify nutrition target recalculated and set
        assertEquals(1, nutritionRepo.targets.size)
        assertTrue(nutritionRepo.targets.first().second.calories > 0)
    }

    private fun TestScope.collectUiState(viewModel: ProfileViewModel) {
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { viewModel.uiState.collect() }
    }
}

private class FakePersonalizationDao : PersonalizationDao {
    var profile: PersonalProfileEntity? = null
    val weights = mutableListOf<WeightMeasurementEntity>()
    val checkIns = mutableListOf<WeeklyCheckInEntity>()

    override suspend fun upsertProfile(profile: PersonalProfileEntity) {
        this.profile = profile
    }
    override fun observeProfile(): Flow<PersonalProfileEntity?> = flowOf(profile)
    override suspend fun profileNow(): PersonalProfileEntity? = profile

    override suspend fun upsertWeight(measurement: WeightMeasurementEntity) {
        weights.add(measurement)
    }
    override suspend fun latestWeightNow(): WeightMeasurementEntity? = weights.lastOrNull()
    override fun observeWeightHistory(): Flow<List<WeightMeasurementEntity>> = flowOf(weights)
    override suspend fun weightHistoryNow(): List<WeightMeasurementEntity> = weights

    override suspend fun upsertDailyNutrition(day: DailyNutritionEntity) = Unit
    override fun observeNutritionDay(epochDay: Long): Flow<DailyNutritionEntity?> = flowOf(null)
    override fun observeNutritionRange(startEpochDay: Long, endEpochDay: Long): Flow<List<DailyNutritionEntity>> = flowOf(emptyList())
    override fun observeAllNutrition(): Flow<List<DailyNutritionEntity>> = flowOf(emptyList())
    override suspend fun nutritionRangeNow(startEpochDay: Long, endEpochDay: Long): List<DailyNutritionEntity> = emptyList()

    override suspend fun upsertWeeklyCheckIn(checkIn: WeeklyCheckInEntity) {
        checkIns.add(checkIn)
    }
    override fun observeLatestCheckIn(): Flow<WeeklyCheckInEntity?> = flowOf(checkIns.lastOrNull())
    override fun observeAllCheckIns(): Flow<List<WeeklyCheckInEntity>> = flowOf(checkIns)
    override suspend fun latestCheckInNow(): WeeklyCheckInEntity? = checkIns.lastOrNull()

    override suspend fun insertDecision(decision: AdaptationDecisionEntity): Long = 0
    override suspend fun updateDecisionStatus(id: Long, status: com.example.myapplication.core.adaptation.AdaptationStatus, resolvedAt: Long) = Unit
    override suspend fun decisionByIdNow(id: Long): AdaptationDecisionEntity? = null
    override suspend fun latestDecisionByKindAndStatus(kind: com.example.myapplication.core.adaptation.AdaptationKind, status: com.example.myapplication.core.adaptation.AdaptationStatus): AdaptationDecisionEntity? = null
    override fun observeDecisionHistory(): Flow<List<AdaptationDecisionEntity>> = flowOf(emptyList())
    override suspend fun decisionHistoryNow(): List<AdaptationDecisionEntity> = emptyList()
}

private class FakeNutritionRepository : NutritionRepository {
    val targets = mutableListOf<Pair<Long, NutritionTarget>>()

    override val nutritionData: Flow<NutritionData> = flowOf(NutritionData())
    override fun observeDay(epochDay: Long): Flow<NutritionDay> = flowOf(NutritionDay(epochDay, Nutrients(), null))
    override fun observeRange(startEpochDay: Long, endEpochDay: Long): Flow<List<NutritionDay>> = flowOf(emptyList())
    override fun observeAllNutrition(): Flow<List<NutritionDay>> = flowOf(emptyList())
    override suspend fun addNutrients(epochDay: Long, nutrients: Nutrients, source: EntrySource) = Unit
    
    override suspend fun setTarget(epochDay: Long, target: NutritionTarget) {
        targets.add(epochDay to target)
    }
    override suspend fun setSweatPayment(exerciseId: String, exerciseName: String, extraSets: Int, active: Boolean) = Unit
    override suspend fun clearSweatPayment() = Unit
    override suspend fun updateAiCoachReview(review: String) = Unit
    override suspend fun resetDaily() = Unit
}

private class FakeWorkoutRepository : WorkoutRepository {
    override fun observeActiveGoal(): Flow<ActiveGoal?> = flowOf(
        ActiveGoal(
            id = 1,
            config = GoalConfig(
                goal = FitnessGoal.GENERAL_FITNESS,
                level = ExperienceLevel.BEGINNER,
                equipmentProfile = EquipmentProfile.BODYWEIGHT_ONLY,
                sessionsPerWeek = 3,
                durationWeeks = 4,
                restDayMode = RestDayMode.FULL_REST,
            ),
            totalWorkouts = 12,
        ),
    )
    override fun observeCurrentWorkout(): Flow<WorkoutSession?> = flowOf(null)
    override fun observeCompletedWorkouts(): Flow<List<CompletedWorkout>> = flowOf(emptyList())
    override suspend fun createGoal(config: GoalConfig, program: ProgramTemplate, startEpochDay: Long) = Unit
    override suspend fun setExerciseChecked(sessionId: Long, orderIndex: Int, checked: Boolean) = Unit
    override suspend fun completeWorkout(sessionId: Long, completedEpochDay: Long): CompleteWorkoutResult = CompleteWorkoutResult.Completed
    override suspend fun archiveActiveGoal() = Unit
}
