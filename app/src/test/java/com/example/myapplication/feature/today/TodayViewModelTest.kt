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

    @Test fun `settings rest override controls recovery`() = runTest(dispatcher) {
        val repository = FakeTodayRepository(goal(RestDayMode.FULL_REST), workout(due = 101))
        val override = MutableStateFlow<RestDayMode?>(RestDayMode.LIGHT_RECOVERY)
        val vm = TodayViewModel(repository, catalog, override) { 100 }; runCurrent()
        assertEquals(RecoveryKind.LIGHT_RECOVERY, (vm.uiState.value as TodayUiState.Recovery).kind)
    }
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

    @Test fun `completion uses current session and injected day then restores while flow catches up`() = runTest(dispatcher) {
        val repository = FakeTodayRepository(goal(), workout(checked = true))
        val vm = TodayViewModel(repository, catalog) { 4321 }; runCurrent()
        vm.completeWorkout(); advanceUntilIdle()
        assertEquals(7L to 4321L, repository.completionArguments.single())
        val state = vm.uiState.value as TodayUiState.Workout
        assertFalse(state.isCompleting)
        assertTrue(state.canComplete)
    }

    @Test fun `blocked and already completed results never leave workout stuck`() = runTest(dispatcher) {
        val repository = FakeTodayRepository(goal(), workout(checked = true))
        val vm = TodayViewModel(repository, catalog) { 100 }; runCurrent()
        repository.completionResult = CompleteWorkoutResult.BlockedByUncheckedExercises
        vm.completeWorkout(); advanceUntilIdle()
        assertTrue(vm.uiState.value is TodayUiState.Error || vm.uiState.value is TodayUiState.Workout)
        repository.current.value = workout(checked = true, due = 99); runCurrent()
        repository.completionResult = CompleteWorkoutResult.AlreadyCompleted
        vm.completeWorkout(); advanceUntilIdle()
        assertFalse((vm.uiState.value as TodayUiState.Workout).isCompleting)
        assertFalse(vm.celebration.value.showConfetti)
    }

    @Test fun `completion cancellation runs cleanup and leaves surviving workout interactive`() = runTest(dispatcher) {
        val repository = FakeTodayRepository(goal(), workout(checked = true)).apply { cancelCompletion = true }
        val vm = TodayViewModel(repository, catalog) { 100 }; runCurrent()
        vm.completeWorkout(); advanceUntilIdle()
        assertFalse((vm.uiState.value as TodayUiState.Workout).isCompleting)
    }
    @Test fun `pending uncheck prevents completion race`() = runTest(dispatcher) {
        val gate = CompletableDeferred<Unit>()
        val repository = FakeTodayRepository(goal(), workout(checked = true)).apply { checkGate = gate }
        val vm = TodayViewModel(repository, catalog) { 100 }; runCurrent()
        vm.setChecked(0, false); vm.completeWorkout(); runCurrent()
        assertEquals(0, repository.completions)
        assertFalse((vm.uiState.value as TodayUiState.Workout).canComplete)
        gate.complete(Unit); advanceUntilIdle()
        assertFalse((vm.uiState.value as TodayUiState.Workout).canComplete)
    }

    @Test fun `new session is interactive while old completion is gated`() = runTest(dispatcher) {
        val gate = CompletableDeferred<Unit>()
        val repository = FakeTodayRepository(goal(), workout(checked = true)).apply { completionGate = gate }
        val vm = TodayViewModel(repository, catalog) { 100 }; runCurrent()
        vm.completeWorkout(); runCurrent()
        repository.current.value = workout(checked = true).copy(id = 8, titleVi = "Buổi mới"); runCurrent()
        val newer = vm.uiState.value as TodayUiState.Workout
        assertEquals(8L, newer.sessionId); assertFalse(newer.isCompleting)
        gate.complete(Unit); advanceUntilIdle()
    }

    @Test fun `checkbox error stays inline and retry clears after flow truth`() = runTest(dispatcher) {
        val repository = FakeTodayRepository(goal(), workout()).apply { failCheck = true }
        val vm = TodayViewModel(repository, catalog) { 100 }; runCurrent()
        vm.setChecked(0, true); advanceUntilIdle()
        val failed = vm.uiState.value as TodayUiState.Workout
        assertNotNull(failed.interactionError); assertTrue(failed.pendingOrderIndices.isEmpty())
        repository.failCheck = false; vm.setChecked(0, true); advanceUntilIdle()
        assertTrue((vm.uiState.value as TodayUiState.Workout).interactionError == null)
    }

    @Test fun `refresh today resolves recovery without repository emission`() = runTest(dispatcher) {
        var today = 100L
        val repository = FakeTodayRepository(goal(), workout(due = 101))
        val vm = TodayViewModel(repository, catalog) { today }; runCurrent()
        assertTrue(vm.uiState.value is TodayUiState.Recovery)
        today = 101; vm.refreshToday(); runCurrent()
        assertTrue(vm.uiState.value is TodayUiState.Workout)
    }
    @Test fun `checkbox failure is recoverable and flow can restore workout`() = runTest(dispatcher) {
        val repository = FakeTodayRepository(goal(), workout()).apply { failCheck = true }
        val vm = TodayViewModel(repository, catalog) { 100 }; runCurrent()
        vm.setChecked(0, true); advanceUntilIdle()
        val failed = vm.uiState.value as TodayUiState.Workout
        assertNotNull(failed.interactionError)
        assertTrue(failed.pendingOrderIndices.isEmpty())
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
    var completionResult: CompleteWorkoutResult = CompleteWorkoutResult.Completed
    var checkGate: CompletableDeferred<Unit>? = null
    var cancelCompletion = false
    val completionArguments = mutableListOf<Pair<Long, Long>>()
    override fun observeActiveGoal(): Flow<ActiveGoal?> = active
    override fun observeCurrentWorkout(): Flow<WorkoutSession?> = current
    override fun observeCompletedWorkouts(): Flow<List<CompletedWorkout>> = flowOf(emptyList())
    override suspend fun setExerciseChecked(sessionId: Long, orderIndex: Int, checked: Boolean) {
        checks += Triple(sessionId, orderIndex, checked); checkGate?.await(); if (failCheck) error("disk")
        current.value = current.value?.copy(exercises = current.value!!.exercises.map { if (it.orderIndex == orderIndex) it.copy(checked = checked) else it })
    }
    override suspend fun completeWorkout(sessionId: Long, completedEpochDay: Long): CompleteWorkoutResult {
        completions++; completionArguments += sessionId to completedEpochDay; completionGate?.await()
        if (cancelCompletion) throw kotlinx.coroutines.CancellationException("cancelled")
        if (failCompletion) error("disk"); return completionResult
    }
    override suspend fun createGoal(config: GoalConfig, program: ProgramTemplate, startEpochDay: Long) = Unit
    override suspend fun archiveActiveGoal() = Unit
}
