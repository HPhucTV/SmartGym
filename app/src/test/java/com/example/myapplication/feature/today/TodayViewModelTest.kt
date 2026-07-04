package com.example.myapplication.feature.today

import com.example.myapplication.core.feedback.WorkoutDifficulty
import com.example.myapplication.core.feedback.WorkoutFeedback
import com.example.myapplication.core.model.*
import com.example.myapplication.core.program.ProgramPhase
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
        assertEquals(ProgramPhase.FOUNDATION, state.phase)
        vm.setChecked(0, true); advanceUntilIdle()
        assertEquals(Triple(7L, 0, true), repository.checks.single())
        repository.current.value = workout(checked = true); runCurrent()
        assertTrue((vm.uiState.value as TodayUiState.Workout).canComplete)
    }

    @Test fun `today infers deload phase from ordered session`() = runTest(dispatcher) {
        val repository = FakeTodayRepository(goal(), workout().copy(sequenceIndex = 11))
        val vm = TodayViewModel(repository, catalog) { 100L }
        runCurrent()

        assertEquals(ProgramPhase.DELOAD, (vm.uiState.value as TodayUiState.Workout).phase)
    }

    @Test fun `replacement dialog exposes reviewed candidates and applies selection`() = runTest(dispatcher) {
        val repository = FakeTodayRepository(goal(), workout())
        val vm = TodayViewModel(repository, substitutionCatalog) { 100L }
        runCurrent()

        vm.requestSubstitution(0)
        val dialog = (vm.uiState.value as TodayUiState.Workout).substitution!!
        assertEquals(listOf("Knee push-up"), dialog.candidates.map { it.nameVi })
        assertTrue(dialog.candidates.single().instructionsVi.isNotEmpty())

        vm.applySubstitution("knee_push_up")
        advanceUntilIdle()

        assertEquals(Triple(7L, 0, "knee_push_up"), repository.substitutions.single())
    }

    @Test fun `replacement reports when no compatible candidate exists`() = runTest(dispatcher) {
        val vm = TodayViewModel(FakeTodayRepository(goal(), workout()), catalog) { 100L }
        runCurrent()

        vm.requestSubstitution(0)

        assertEquals(
            "Không có bài thay thế phù hợp với thiết bị hiện tại.",
            (vm.uiState.value as TodayUiState.Workout).interactionError,
        )
    }

    @Test fun `time budget choices apply before first check and expose omission summary`() = runTest(dispatcher) {
        val repository = FakeTodayRepository(
            goal(),
            workout().copy(selectedTimeBudgetMinutes = 15, omittedExerciseCount = 2),
        )
        val vm = TodayViewModel(repository, catalog) { 100L }
        runCurrent()

        val state = vm.uiState.value as TodayUiState.Workout
        assertEquals(listOf(15, 30, 45, null), state.timeBudgetChoices)
        assertEquals(15, state.selectedTimeBudgetMinutes)
        assertEquals(2, state.omittedExerciseCount)
        assertTrue(state.canChangeTimeBudget)

        vm.applyTimeBudget(30)
        advanceUntilIdle()
        assertEquals(7L to 30, repository.timeBudgets.single())
    }

    @Test fun `time budget is locked after any exercise is checked`() = runTest(dispatcher) {
        val repository = FakeTodayRepository(goal(), workout(checked = true))
        val vm = TodayViewModel(repository, catalog) { 100L }
        runCurrent()

        assertFalse((vm.uiState.value as TodayUiState.Workout).canChangeTimeBudget)
        vm.applyTimeBudget(15)
        advanceUntilIdle()
        assertTrue(repository.timeBudgets.isEmpty())
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

    @Test fun `completion exposes feedback request and submitting saves it once`() = runTest(dispatcher) {
        val repository = FakeTodayRepository(goal(), workout(checked = true))
        val feedback = FakeWorkoutFeedbackRepository()
        val vm = TodayViewModel(
            repository = repository,
            exercises = catalog,
            feedbackRepository = feedback,
            currentEpochDay = { 4321L },
        )
        runCurrent()

        vm.completeWorkout()
        advanceUntilIdle()

        val pending = vm.pendingFeedback.value!!
        assertEquals(7L, pending.sessionId)
        assertEquals(1L, pending.goalId)
        assertEquals(4321L, pending.completedEpochDay)

        vm.submitDifficulty(WorkoutDifficulty.HARD)
        vm.submitDifficulty(WorkoutDifficulty.EASY)
        advanceUntilIdle()

        assertEquals(1, feedback.saved.size)
        assertEquals(WorkoutDifficulty.HARD, feedback.saved.single().difficulty)
        assertNull(vm.pendingFeedback.value)
    }

    @Test fun `dismissing feedback records nothing`() = runTest(dispatcher) {
        val repository = FakeTodayRepository(goal(), workout(checked = true))
        val feedback = FakeWorkoutFeedbackRepository()
        val vm = TodayViewModel(repository, catalog, feedbackRepository = feedback) { 100L }
        runCurrent()
        vm.completeWorkout()
        advanceUntilIdle()

        vm.dismissFeedback()

        assertTrue(feedback.saved.isEmpty())
        assertNull(vm.pendingFeedback.value)
    }

    @Test fun `feedback save failure keeps request open with retry message`() = runTest(dispatcher) {
        val repository = FakeTodayRepository(goal(), workout(checked = true))
        val feedback = FakeWorkoutFeedbackRepository().apply { failSave = true }
        val vm = TodayViewModel(repository, catalog, feedbackRepository = feedback) { 100L }
        runCurrent()
        vm.completeWorkout()
        advanceUntilIdle()

        vm.submitDifficulty(WorkoutDifficulty.RIGHT)
        advanceUntilIdle()

        val pending = vm.pendingFeedback.value!!
        assertFalse(pending.saving)
        assertTrue(pending.error!!.contains("thử lại", ignoreCase = true))
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

    companion object {
        val catalog = listOf(ExerciseDefinition("push_up", "project:push_up", "Chống đẩy",
            ExperienceLevel.BEGINNER, listOf(Equipment.BODYWEIGHT), MovementPattern.HORIZONTAL_PUSH,
            MuscleGroup.CHEST, instructionsVi = listOf("Giữ thân thẳng", "Hạ ngực có kiểm soát")))
        val substitutionCatalog = listOf(
            catalog.single().copy(substituteIds = listOf("knee_push_up")),
            catalog.single().copy(
                id = "knee_push_up",
                sourceId = "project:knee_push_up",
                nameVi = "Knee push-up",
                instructionsVi = listOf("Chống gối trên sàn"),
                substituteIds = listOf("push_up"),
            ),
        )
    }
}

private class FakeTodayRepository(goal: ActiveGoal?, workout: WorkoutSession?) : WorkoutRepository {
    val active = MutableStateFlow(goal); val current = MutableStateFlow(workout)
    val checks = mutableListOf<Triple<Long, Int, Boolean>>(); var completions = 0
    var completionGate: CompletableDeferred<Unit>? = null; var failCompletion = false; var failCheck = false
    var completionResult: CompleteWorkoutResult = CompleteWorkoutResult.Completed
    var checkGate: CompletableDeferred<Unit>? = null
    var cancelCompletion = false
    val completionArguments = mutableListOf<Pair<Long, Long>>()
    val substitutions = mutableListOf<Triple<Long, Int, String>>()
    val timeBudgets = mutableListOf<Pair<Long, Int?>>()
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
    override suspend fun substituteExercise(
        sessionId: Long,
        orderIndex: Int,
        replacementExerciseId: String,
    ): ExerciseSubstitutionResult {
        substitutions += Triple(sessionId, orderIndex, replacementExerciseId)
        return ExerciseSubstitutionResult.Applied
    }
    override suspend fun applyTimeBudget(sessionId: Long, minutes: Int?): TimeBudgetResult {
        timeBudgets += sessionId to minutes
        return TimeBudgetResult.Applied
    }
    override suspend fun createGoal(config: GoalConfig, program: ProgramTemplate, startEpochDay: Long) = Unit
    override suspend fun archiveActiveGoal() = Unit
}

private class FakeWorkoutFeedbackRepository : WorkoutFeedbackRepository {
    val saved = mutableListOf<WorkoutFeedback>()
    var failSave = false

    override fun observeForGoal(goalId: Long): Flow<List<WorkoutFeedback>> = flowOf(emptyList())

    override suspend fun save(
        sessionId: Long,
        goalId: Long,
        completedEpochDay: Long,
        difficulty: WorkoutDifficulty,
    ) {
        if (failSave) error("disk")
        saved += WorkoutFeedback(sessionId, goalId, completedEpochDay, difficulty, 0L)
    }
}
