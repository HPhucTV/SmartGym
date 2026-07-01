package com.example.myapplication.feature.today

import com.example.myapplication.core.model.*
import com.example.myapplication.data.*
import com.example.myapplication.feature.onboarding.MainDispatcherRule
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.test.*
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class TodayViewModelTest {
    private val dispatcher = StandardTestDispatcher()
    @get:Rule val mainRule = MainDispatcherRule(dispatcher)

    @Test fun `maps due workout and mutations use persisted identity`() = runTest(dispatcher) {
        val repository = FakeTodayRepository(goal(), workout())
        val vm = TodayViewModel(repository, catalog) { 100 }
        runCurrent()
        val state = vm.uiState.value as TodayUiState.Workout
        assertEquals("Chống đẩy", state.rows.single().nameVi)
        assertEquals(listOf("Giữ thân thẳng", "Hạ ngực có kiểm soát"), state.rows.single().instructionsVi)
        assertEquals("3 × 8–12", state.rows.single().prescriptionText)
        assertFalse(state.canComplete)
        vm.setChecked(0, true); advanceUntilIdle()
        assertEquals(Triple(7L, 0, true), repository.checks.single())
        repository.current.value = workout(checked = true); runCurrent()
        assertTrue((vm.uiState.value as TodayUiState.Workout).canComplete)
    }

    @Test fun `shows both recovery modes goal complete and missing catalog error`() = runTest(dispatcher) {
        val repository = FakeTodayRepository(goal(RestDayMode.FULL_REST), workout(due = 101))
        val vm = TodayViewModel(repository, catalog) { 100 }; runCurrent()
        assertEquals(RecoveryKind.FULL_REST, (vm.uiState.value as TodayUiState.Recovery).kind)
        repository.active.value = goal(RestDayMode.LIGHT_RECOVERY); runCurrent()
        assertEquals(RecoveryKind.LIGHT_RECOVERY, (vm.uiState.value as TodayUiState.Recovery).kind)
        repository.current.value = null; runCurrent()
        assertTrue(vm.uiState.value is TodayUiState.GoalComplete)
        repository.current.value = workout(exerciseId = "missing"); runCurrent()
        assertTrue((vm.uiState.value as TodayUiState.Error).message.contains("missing"))
    }

    @Test fun `completion is guarded deduplicated recoverable and retryable`() = runTest(dispatcher) {
        val repository = FakeTodayRepository(goal(), workout(checked = false))
        val vm = TodayViewModel(repository, catalog) { 100 }; runCurrent()
        vm.completeWorkout(); runCurrent(); assertEquals(0, repository.completions)
        repository.current.value = workout(checked = true); runCurrent()
        val gate = CompletableDeferred<Unit>(); repository.completionGate = gate
        vm.completeWorkout(); vm.completeWorkout(); runCurrent(); assertEquals(1, repository.completions)
        gate.complete(Unit); advanceUntilIdle()
        repository.failCompletion = true
        vm.completeWorkout(); advanceUntilIdle()
        val error = vm.uiState.value as TodayUiState.Error
        assertTrue(error.canRetry); assertEquals(2, repository.completions)
        repository.failCompletion = false; vm.retry(); advanceUntilIdle()
        assertEquals(3, repository.completions)
    }

    @Test fun `checkbox failure is recoverable and flow can restore workout`() = runTest(dispatcher) {
        val repository = FakeTodayRepository(goal(), workout()).apply { failCheck = true }
        val vm = TodayViewModel(repository, catalog) { 100 }; runCurrent()
        vm.setChecked(0, true); advanceUntilIdle()
        assertTrue(vm.uiState.value is TodayUiState.Error)
        repository.failCheck = false; repository.current.value = workout(checked = true); runCurrent()
        assertTrue(vm.uiState.value is TodayUiState.Workout)
    }

    private fun goal(mode: RestDayMode = RestDayMode.FULL_REST) = ActiveGoal(1, GoalConfig(
        FitnessGoal.GENERAL_FITNESS, ExperienceLevel.BEGINNER, EquipmentProfile.BODYWEIGHT_ONLY, 3, 4, mode), 12)
    private fun workout(checked: Boolean = false, due: Long = 100, exerciseId: String = "push_up") = WorkoutSession(
        7, 1, 0, "Toàn thân A", "Ngực và thân giữa", 25, due,
        listOf(WorkoutExercise(0, exerciseId, ExercisePrescription(exerciseId, 3, 8, 12, restSeconds = 60), checked)))

    companion object { val catalog = listOf(ExerciseDefinition("push_up", "project:push_up", "Chống đẩy",
        ExperienceLevel.BEGINNER, listOf(Equipment.BODYWEIGHT), MovementPattern.HORIZONTAL_PUSH,
        MuscleGroup.CHEST, instructionsVi = listOf("Giữ thân thẳng", "Hạ ngực có kiểm soát"))) }
}

private class FakeTodayRepository(goal: ActiveGoal?, workout: WorkoutSession?) : WorkoutRepository {
    val active = MutableStateFlow(goal); val current = MutableStateFlow(workout)
    val checks = mutableListOf<Triple<Long, Int, Boolean>>(); var completions = 0
    var completionGate: CompletableDeferred<Unit>? = null; var failCompletion = false; var failCheck = false
    override fun observeActiveGoal(): Flow<ActiveGoal?> = active
    override fun observeCurrentWorkout(): Flow<WorkoutSession?> = current
    override fun observeCompletedWorkouts(): Flow<List<CompletedWorkout>> = flowOf(emptyList())
    override suspend fun setExerciseChecked(sessionId: Long, orderIndex: Int, checked: Boolean) {
        checks += Triple(sessionId, orderIndex, checked); if (failCheck) error("disk")
    }
    override suspend fun completeWorkout(sessionId: Long, completedEpochDay: Long): CompleteWorkoutResult {
        completions++; completionGate?.await(); if (failCompletion) error("disk"); return CompleteWorkoutResult.Completed
    }
    override suspend fun createGoal(config: GoalConfig, program: ProgramTemplate, startEpochDay: Long) = Unit
    override suspend fun archiveActiveGoal() = Unit
}
