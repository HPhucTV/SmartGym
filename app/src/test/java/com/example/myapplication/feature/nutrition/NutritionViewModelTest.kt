package com.example.myapplication.feature.nutrition

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
import com.example.myapplication.data.NutritionData
import com.example.myapplication.data.NutritionRepository
import com.example.myapplication.data.WorkoutRepository
import com.example.myapplication.feature.onboarding.MainDispatcherRule
import kotlinx.coroutines.CancellationException
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
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class NutritionViewModelTest {
    private val dispatcher = StandardTestDispatcher()
    @get:Rule val mainRule = MainDispatcherRule(dispatcher)

    @org.junit.Before
    fun setUp() {
        com.example.myapplication.app.BackendConfig.customServerUrl = "http://localhost:3000"
    }

    @org.junit.After
    fun tearDown() {
        com.example.myapplication.app.BackendConfig.customServerUrl = null
    }

    @Test
    fun `accepted scan result is stored on the selected day`() = runTest(dispatcher) {
        val nutritionRepository = FakeNutritionRepository()
        val viewModel = NutritionViewModel(
            workoutRepository = FakeWorkoutRepository(),
            nutritionRepository = nutritionRepository,
            foodAnalysisClient = FakeFoodAnalysisClient(scanResult()),
            cloudAiConsent = flowOf(true),
            currentEpochDay = { 20636L },
        )
        collectUiState(viewModel)
        runCurrent()

        viewModel.scanFood(null)
        advanceUntilIdle()
        viewModel.acceptScanResult()
        advanceUntilIdle()

        assertEquals(20636L, nutritionRepository.additions.single().epochDay)
        assertEquals(Nutrients(calories = 510, proteinGrams = 31, carbsGrams = 62, fatGrams = 16), nutritionRepository.additions.single().nutrients)
        assertEquals(EntrySource.CAMERA_ANALYSIS, nutritionRepository.additions.single().source)
    }

    @Test
    fun `http analysis failure is recoverable`() = runTest(dispatcher) {
        val viewModel = NutritionViewModel(
            workoutRepository = FakeWorkoutRepository(),
            nutritionRepository = FakeNutritionRepository(),
            foodAnalysisClient = FakeFoodAnalysisClient(null),
            cloudAiConsent = flowOf(true),
            currentEpochDay = { 20636L },
        )
        collectUiState(viewModel)
        runCurrent()

        viewModel.scanFood(null)
        advanceUntilIdle()

        val state = viewModel.uiState.value as NutritionUiState.Content
        assertFalse(state.scanning)
        assertNotNull(state.scanError)
    }

    @Test
    fun `scan cancellation is not converted to a user error`() = runTest(dispatcher) {
        val viewModel = NutritionViewModel(
            workoutRepository = FakeWorkoutRepository(),
            nutritionRepository = FakeNutritionRepository(),
            foodAnalysisClient = FakeFoodAnalysisClient(failure = CancellationException("stop")),
            cloudAiConsent = flowOf(true),
            currentEpochDay = { 20636L },
        )
        collectUiState(viewModel)
        runCurrent()

        viewModel.scanFood(null)
        advanceUntilIdle()

        val state = viewModel.uiState.value as NutritionUiState.Content
        assertFalse(state.scanning)
        assertNull(state.scanError)
    }

    @Test
    fun `food image is never uploaded without cloud AI consent`() = runTest(dispatcher) {
        val client = FakeFoodAnalysisClient(scanResult())
        val viewModel = NutritionViewModel(
            workoutRepository = FakeWorkoutRepository(),
            nutritionRepository = FakeNutritionRepository(),
            foodAnalysisClient = client,
            cloudAiConsent = flowOf(false),
            currentEpochDay = { 20636L },
        )
        collectUiState(viewModel)
        runCurrent()

        viewModel.scanFood(null)
        advanceUntilIdle()

        assertEquals(0, client.calls)
        val state = viewModel.uiState.value as NutritionUiState.Content
        assertNotNull(state.scanError)
        assertFalse(state.scanning)
    }

    @Test
    fun `history lists past entries with logged calories`() = runTest(dispatcher) {
        val repo = FakeNutritionRepository()
        val today = 20636L
        
        repo.historyData.value = listOf(
            NutritionDay(today, Nutrients(calories = 500), null),
            NutritionDay(today - 1, Nutrients(calories = 1200), null),
            NutritionDay(today - 2, Nutrients(calories = 0), null),
            NutritionDay(today - 3, Nutrients(calories = 1500), null),
        )
        
        val viewModel = NutritionViewModel(
            workoutRepository = FakeWorkoutRepository(),
            nutritionRepository = repo,
            foodAnalysisClient = FakeFoodAnalysisClient(),
            cloudAiConsent = flowOf(true),
            currentEpochDay = { today },
        )
        collectUiState(viewModel)
        runCurrent()
        
        val state = viewModel.uiState.value as NutritionUiState.Content
        assertEquals(2, state.history.size)
        assertEquals(today - 1, state.history[0].epochDay)
        assertEquals(1200, state.history[0].consumed.calories)
        assertEquals(today - 3, state.history[1].epochDay)
        assertEquals(1500, state.history[1].consumed.calories)
    }

    private fun TestScope.collectUiState(viewModel: NutritionViewModel) {
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { viewModel.uiState.collect() }
    }

    private fun scanResult() = ScanResult(
        dishName = "Com ga",
        totalCalories = 510,
        proteinGrams = 31,
        carbsGrams = 62,
        fatGrams = 16,
        fitnessScore = 7,
        advice = "On voi muc tieu hom nay.",
        constituents = emptyList(),
        sweatPayment = SweatPaymentProposal(
            exerciseId = "bodyweight_squat",
            exerciseName = "Squat khong ta",
            extraSets = 1,
        ),
    )
}

private class FakeFoodAnalysisClient(
    private val result: ScanResult? = null,
    private val failure: Throwable? = null,
) : FoodAnalysisClient {
    var calls = 0

    override suspend fun analyze(bitmap: android.graphics.Bitmap?): ScanResult? {
        calls++
        failure?.let { throw it }
        return result
    }
}

private data class AddedNutrition(
    val epochDay: Long,
    val nutrients: Nutrients,
    val source: EntrySource,
)

private class FakeNutritionRepository : NutritionRepository {
    private val data = MutableStateFlow(NutritionData())
    val additions = mutableListOf<AddedNutrition>()

    override val nutritionData: Flow<NutritionData> = data

    override fun observeDay(epochDay: Long): Flow<NutritionDay> =
        flowOf(NutritionDay(epochDay = epochDay, consumed = Nutrients(), target = null))

    override fun observeRange(startEpochDay: Long, endEpochDay: Long): Flow<List<NutritionDay>> = flowOf(emptyList())

    val historyData = MutableStateFlow<List<NutritionDay>>(emptyList())
    override fun observeAllNutrition(): Flow<List<NutritionDay>> = historyData

    override suspend fun addNutrients(epochDay: Long, nutrients: Nutrients, source: EntrySource) {
        additions += AddedNutrition(epochDay, nutrients, source)
        data.value = data.value.copy(
            caloriesEaten = data.value.caloriesEaten + nutrients.calories,
            proteinEaten = data.value.proteinEaten + nutrients.proteinGrams,
            carbsEaten = data.value.carbsEaten + nutrients.carbsGrams,
            fatEaten = data.value.fatEaten + nutrients.fatGrams,
        )
    }

    override suspend fun setTarget(epochDay: Long, target: com.example.myapplication.core.nutrition.NutritionTarget) = Unit
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



