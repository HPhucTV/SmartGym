package com.example.myapplication.feature.today

import com.example.myapplication.core.model.ActiveGoal
import com.example.myapplication.core.model.CompletedWorkout
import com.example.myapplication.core.model.EquipmentProfile
import com.example.myapplication.core.model.ExerciseDefinition
import com.example.myapplication.core.model.ExercisePrescription
import com.example.myapplication.core.model.ExperienceLevel
import com.example.myapplication.core.model.FitnessGoal
import com.example.myapplication.core.model.GoalConfig
import com.example.myapplication.core.model.MovementPattern
import com.example.myapplication.core.model.MuscleGroup
import com.example.myapplication.core.model.ProgramTemplate
import com.example.myapplication.core.model.RestDayMode
import com.example.myapplication.core.model.WorkoutExercise
import com.example.myapplication.core.model.WorkoutSession
import com.example.myapplication.data.CoachReviewClient
import com.example.myapplication.data.CoachReviewRequest
import com.example.myapplication.data.CompleteWorkoutResult
import com.example.myapplication.data.NutritionData
import com.example.myapplication.data.NutritionRepository
import com.example.myapplication.data.WorkoutRepository
import com.example.myapplication.feature.onboarding.MainDispatcherRule
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class TodayViewModelCoachTest {
    private val dispatcher = StandardTestDispatcher()

    @get:Rule
    val mainRule = MainDispatcherRule(dispatcher)

    @Test
    fun `coach refresh exposes loading and stores consented cloud response`() = runTest(dispatcher) {
        val reply = CompletableDeferred<String?>()
        val nutrition = CoachNutritionRepository()
        val viewModel = TodayViewModel(
            repository = CoachWorkoutRepository(),
            exercises = catalog,
            nutritionRepository = nutrition,
            coachCoordinator = TodayCoachCoordinator(GatedCoachClient(reply)),
            cloudAiConsent = flowOf(true),
            currentEpochDay = { 100L },
        )
        runCurrent()

        viewModel.refreshCoachTip()
        runCurrent()
        assertTrue((viewModel.uiState.value as TodayUiState.Workout).isRefreshingCoach)

        reply.complete("Lời khuyên cloud")
        advanceUntilIdle()

        assertFalse((viewModel.uiState.value as TodayUiState.Workout).isRefreshingCoach)
        assertEquals("Lời khuyên cloud", nutrition.savedReview)
    }

    private companion object {
        val catalog = listOf(
            ExerciseDefinition(
                id = "push_up",
                sourceId = "project:push_up",
                nameVi = "Chống đẩy",
                level = ExperienceLevel.BEGINNER,
                equipment = emptyList(),
                movementPattern = MovementPattern.HORIZONTAL_PUSH,
                primaryMuscle = MuscleGroup.CHEST,
                instructionsVi = listOf("Giữ thân thẳng"),
            ),
        )
    }
}

private class GatedCoachClient(
    private val reply: CompletableDeferred<String?>,
) : CoachReviewClient {
    override suspend fun reviewToday(request: CoachReviewRequest): String? = reply.await()
}

private class CoachWorkoutRepository : WorkoutRepository {
    private val goal = ActiveGoal(
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
    )
    private val workout = WorkoutSession(
        id = 7,
        goalId = 1,
        sequenceIndex = 0,
        titleVi = "Toàn thân A",
        focusVi = "Ngực",
        estimatedMinutes = 25,
        dueEpochDay = 100,
        exercises = listOf(
            WorkoutExercise(
                orderIndex = 0,
                exerciseId = "push_up",
                prescription = ExercisePrescription("push_up", 3, 8, 12, restSeconds = 60),
                checked = false,
            ),
        ),
    )

    override fun observeActiveGoal(): Flow<ActiveGoal?> = flowOf(goal)
    override fun observeCurrentWorkout(): Flow<WorkoutSession?> = flowOf(workout)
    override fun observeCompletedWorkouts(): Flow<List<CompletedWorkout>> = flowOf(emptyList())
    override suspend fun createGoal(config: GoalConfig, program: ProgramTemplate, startEpochDay: Long) = Unit
    override suspend fun setExerciseChecked(sessionId: Long, orderIndex: Int, checked: Boolean) = Unit
    override suspend fun completeWorkout(sessionId: Long, completedEpochDay: Long) = CompleteWorkoutResult.Completed
    override suspend fun archiveActiveGoal() = Unit
}

private class CoachNutritionRepository : NutritionRepository {
    override val nutritionData = MutableStateFlow(NutritionData())
    var savedReview: String? = null

    override fun observeDay(epochDay: Long) = flowOf(
        com.example.myapplication.core.nutrition.NutritionDay(
            epochDay,
            com.example.myapplication.core.nutrition.Nutrients(),
            null,
        ),
    )
    override fun observeRange(startEpochDay: Long, endEpochDay: Long) = flowOf(emptyList<com.example.myapplication.core.nutrition.NutritionDay>())
    override suspend fun addNutrients(epochDay: Long, nutrients: com.example.myapplication.core.nutrition.Nutrients, source: com.example.myapplication.core.nutrition.EntrySource) = Unit
    override suspend fun setTarget(epochDay: Long, target: com.example.myapplication.core.nutrition.NutritionTarget) = Unit
    override suspend fun setSweatPayment(exerciseId: String, exerciseName: String, extraSets: Int, active: Boolean) = Unit
    override suspend fun clearSweatPayment() = Unit
    override suspend fun updateAiCoachReview(review: String) {
        savedReview = review
        nutritionData.value = nutritionData.value.copy(aiCoachReview = review)
    }
    override suspend fun resetDaily() = Unit
}
