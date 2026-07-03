package com.example.myapplication.feature.onboarding

import com.example.myapplication.core.model.*
import com.example.myapplication.data.CompleteWorkoutResult
import com.example.myapplication.data.WorkoutRepository
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Test
import org.junit.Rule
import org.junit.rules.TestWatcher
import org.junit.runner.Description
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.setMain
import java.time.DayOfWeek

@OptIn(ExperimentalCoroutinesApi::class)
class OnboardingViewModelTest {
    private val dispatcher = StandardTestDispatcher()
    @get:Rule val mainRule = MainDispatcherRule(dispatcher)

    @Test fun `user selects one to six weekdays and a duration bucket`() = runTest(dispatcher) {
        val vm = viewModel()
        vm.selectGoal(FitnessGoal.GENERAL_FITNESS)
        vm.selectLevel(ExperienceLevel.BEGINNER)
        vm.selectEquipment(EquipmentProfile.BODYWEIGHT_ONLY)

        DayOfWeek.entries.take(6).forEach(vm::toggleTrainingDay)
        vm.toggleTrainingDay(DayOfWeek.SUNDAY)
        vm.selectSessionDuration(75)

        val draft = (vm.uiState.value as OnboardingUiState.Editing).draft
        assertEquals(6, draft.trainingDays.size)
        assertFalse(DayOfWeek.SUNDAY in draft.trainingDays)
        assertEquals(75, draft.sessionDurationMinutes)
    }

    @Test fun `progresses through one decision at a time and can go back`() = runTest(dispatcher) {
            val vm = viewModel()
            assertStep(vm, OnboardingStep.GOAL)
            vm.selectGoal(FitnessGoal.GENERAL_FITNESS); vm.next(); assertStep(vm, OnboardingStep.LEVEL)
            vm.selectLevel(ExperienceLevel.BEGINNER); vm.next(); assertStep(vm, OnboardingStep.EQUIPMENT)
            vm.selectEquipment(EquipmentProfile.BODYWEIGHT_ONLY); vm.next(); assertStep(vm, OnboardingStep.TRAINING_DAYS)
            listOf(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY).forEach(vm::toggleTrainingDay)
            vm.next(); assertStep(vm, OnboardingStep.SESSION_DURATION)
            vm.selectSessionDuration(45); vm.next(); assertStep(vm, OnboardingStep.REST_BEHAVIOR)
            vm.selectRestDayMode(RestDayMode.FULL_REST); vm.next(); assertStep(vm, OnboardingStep.REVIEW)
            vm.back(); assertStep(vm, OnboardingStep.REST_BEHAVIOR)
    }

    @Test fun `available choices narrow and changing earlier choice clears downstream`() = runTest(dispatcher) {
            val vm = viewModel()
            vm.selectGoal(FitnessGoal.GENERAL_FITNESS)
            var editing = vm.uiState.value as OnboardingUiState.Editing
            assertEquals(setOf(ExperienceLevel.BEGINNER, ExperienceLevel.INTERMEDIATE), editing.options.levels)
            vm.selectLevel(ExperienceLevel.BEGINNER)
            editing = vm.uiState.value as OnboardingUiState.Editing
            assertEquals(setOf(EquipmentProfile.BODYWEIGHT_ONLY), editing.options.equipment)
            assertFalse(editing.options.equipment.contains(EquipmentProfile.FULL_GYM))
            vm.selectEquipment(EquipmentProfile.BODYWEIGHT_ONLY); vm.selectCommitment(3, 4)
            vm.selectGoal(FitnessGoal.MUSCLE_GAIN)
            assertEquals(OnboardingDraft(goal = FitnessGoal.MUSCLE_GAIN), (vm.uiState.value as OnboardingUiState.Editing).draft)
    }

    @Test fun `supported selection creates exact goal once`() = runTest(dispatcher) {
            val repository = FakeWorkoutRepository()
            val vm = viewModel(repository)
            completeGeneral(vm)
            vm.createGoal(); advanceUntilIdle(); vm.createGoal(); advanceUntilIdle()
            assertEquals(1, repository.creations.size)
            val creation = repository.creations.single()
            assertEquals(programs.first().id, creation.program.id)
            assertEquals(1234L, creation.startEpochDay)
            assertEquals(RestDayMode.FULL_REST, creation.config.restDayMode)
            assertTrue(vm.uiState.value is OnboardingUiState.Created)
    }

    @Test fun `duplicate create while saving invokes repository once`() = runTest(dispatcher) {
            val gate = CompletableDeferred<Unit>()
            val repository = FakeWorkoutRepository(gate = gate)
            val vm = viewModel(repository); completeGeneral(vm)
            vm.createGoal(); vm.createGoal(); runCurrent()
            assertEquals(1, repository.createAttempts)
            assertTrue((vm.uiState.value as OnboardingUiState.Editing).isSaving)
            gate.complete(Unit); advanceUntilIdle()
            assertEquals(1, repository.creations.size)
    }

    @Test fun `saving locks step draft and all navigation mutations`() = runTest(dispatcher) {
        val gate = CompletableDeferred<Unit>()
        val repository = FakeWorkoutRepository(gate = gate)
        val vm = viewModel(repository)
        completeGeneral(vm)
        repeat(6) { vm.next() }
        assertStep(vm, OnboardingStep.REVIEW)

        vm.createGoal()
        runCurrent()
        val saving = vm.uiState.value as OnboardingUiState.Editing
        vm.back()
        vm.selectGoal(FitnessGoal.MUSCLE_GAIN)
        vm.selectLevel(ExperienceLevel.INTERMEDIATE)
        vm.selectEquipment(EquipmentProfile.FULL_GYM)
        vm.selectCommitment(4, 8)
        vm.selectRestDayMode(RestDayMode.LIGHT_RECOVERY)
        vm.next()
        repeat(3) { vm.createGoal() }

        assertEquals(saving, vm.uiState.value)
        assertEquals(OnboardingStep.REVIEW, saving.step)
        assertTrue(saving.isSaving)
        assertEquals(1, repository.createAttempts)
        gate.complete(Unit)
        advanceUntilIdle()
    }

    @Test fun `cancellation is not converted into persistence error`() = runTest(dispatcher) {
        val repository = FakeWorkoutRepository(cancelOnCreate = true)
        val vm = viewModel(repository)
        completeGeneral(vm)
        vm.createGoal()
        advanceUntilIdle()

        val state = vm.uiState.value as OnboardingUiState.Editing
        assertTrue(state.isSaving)
        assertNull(state.saveError)
        assertEquals(1, repository.createAttempts)
    }
    @Test fun `unsupported exact combination never substitutes and shows alternatives`() = runTest(dispatcher) {
            val repository = FakeWorkoutRepository()
            val vm = viewModel(repository)
            vm.selectGoal(FitnessGoal.MUSCLE_GAIN); vm.selectLevel(ExperienceLevel.BEGINNER)
            vm.selectEquipment(EquipmentProfile.BODYWEIGHT_ONLY); vm.selectCommitment(3, 4)
            vm.selectRestDayMode(RestDayMode.FULL_REST); vm.createGoal(); advanceUntilIdle()
            assertEquals(0, repository.createAttempts)
            val unsupported = vm.uiState.value as OnboardingUiState.Unsupported
            assertTrue(unsupported.explanation.lowercase().contains("chưa có chương trình"))
            assertTrue(unsupported.alternatives.any { it.lowercase().contains("tạ đơn") })
    }

    @Test fun `persistence failure is recoverable and retry succeeds`() = runTest(dispatcher) {
            val repository = FakeWorkoutRepository(failuresRemaining = 1)
            val vm = viewModel(repository); completeGeneral(vm)
            vm.createGoal(); advanceUntilIdle()
            val failed = vm.uiState.value as OnboardingUiState.Editing
            assertFalse(failed.isSaving); assertNotNull(failed.saveError)
            vm.createGoal(); advanceUntilIdle()
            assertEquals(2, repository.createAttempts)
            assertTrue(vm.uiState.value is OnboardingUiState.Created)
    }

    private fun viewModel(repository: FakeWorkoutRepository = FakeWorkoutRepository()) =
        OnboardingViewModel(programs, repository) { 1234L }

    private fun completeGeneral(vm: OnboardingViewModel) {
        vm.selectGoal(FitnessGoal.GENERAL_FITNESS); vm.selectLevel(ExperienceLevel.BEGINNER)
        vm.selectEquipment(EquipmentProfile.BODYWEIGHT_ONLY)
        listOf(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY).forEach(vm::toggleTrainingDay)
        vm.selectSessionDuration(45)
        vm.selectRestDayMode(RestDayMode.FULL_REST)
    }

    private fun assertStep(vm: OnboardingViewModel, step: OnboardingStep) =
        assertEquals(step, (vm.uiState.value as OnboardingUiState.Editing).step)

    companion object {
        private val programs = listOf(
            program("general-body", FitnessGoal.GENERAL_FITNESS, ExperienceLevel.BEGINNER, EquipmentProfile.BODYWEIGHT_ONLY, 3, 4),
            program("general-gym", FitnessGoal.GENERAL_FITNESS, ExperienceLevel.INTERMEDIATE, EquipmentProfile.FULL_GYM, 4, 8),
            program("muscle-dumbbell", FitnessGoal.MUSCLE_GAIN, ExperienceLevel.BEGINNER, EquipmentProfile.DUMBBELLS, 3, 4),
        )
        private fun program(id: String, goal: FitnessGoal, level: ExperienceLevel, equipment: EquipmentProfile, sessions: Int, weeks: Int) =
            ProgramTemplate(id, goal, level, equipment, sessions, weeks, emptyList())
    }
}

private data class Creation(val config: GoalConfig, val program: ProgramTemplate, val startEpochDay: Long)
private class FakeWorkoutRepository(
    private val gate: CompletableDeferred<Unit>? = null,
    var failuresRemaining: Int = 0,
    private val cancelOnCreate: Boolean = false,
) : WorkoutRepository {
    val creations = mutableListOf<Creation>()
    var createAttempts = 0
    override fun observeActiveGoal(): Flow<ActiveGoal?> = flowOf(null)
    override fun observeCurrentWorkout(): Flow<WorkoutSession?> = flowOf(null)
    override fun observeCompletedWorkouts(): Flow<List<CompletedWorkout>> = flowOf(emptyList())
    override suspend fun createGoal(config: GoalConfig, program: ProgramTemplate, startEpochDay: Long) {
        createAttempts++; gate?.await()
        if (cancelOnCreate) throw CancellationException("cancelled")
        if (failuresRemaining-- > 0) error("disk full")
        creations += Creation(config, program, startEpochDay)
    }
    override suspend fun setExerciseChecked(sessionId: Long, orderIndex: Int, checked: Boolean) = Unit
    override suspend fun completeWorkout(sessionId: Long, completedEpochDay: Long) = CompleteWorkoutResult.Completed
    override suspend fun archiveActiveGoal() = Unit
}

@OptIn(ExperimentalCoroutinesApi::class)
class MainDispatcherRule(private val dispatcher: kotlinx.coroutines.test.TestDispatcher) : TestWatcher() {
    override fun starting(description: Description) { Dispatchers.setMain(dispatcher) }
    override fun finished(description: Description) { Dispatchers.resetMain() }
}
