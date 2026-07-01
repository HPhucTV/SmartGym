package com.example.myapplication.feature.progress

import com.example.myapplication.core.model.*
import com.example.myapplication.data.*
import com.example.myapplication.feature.onboarding.MainDispatcherRule
import java.time.LocalDate
import java.time.YearMonth
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.test.*
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class ProgressViewModelTest {
    private val dispatcher = StandardTestDispatcher()
    @get:Rule val mainRule = MainDispatcherRule(dispatcher)

    @Test fun `active summary and two qualifying weeks are calculated`() = runTest(dispatcher) {
        val current = day("2026-06-14")
        val dates = listOf("2026-06-01", "2026-06-02", "2026-06-03", "2026-06-08", "2026-06-09", "2026-06-10", "2026-06-11")
        val repo = FakeProgressRepository(goal(), dates.map { CompletedWorkout(1, day(it)) })
        val vm = ProgressViewModel(repo) { current }; runCurrent()
        val state = vm.uiState.value as ProgressUiState.Content
        assertEquals(58, state.percentage); assertEquals(7, state.completedActive)
        assertEquals(12, state.totalActive); assertEquals(2, state.weeklyStreak)
        assertEquals(dates.map(::day).toSet(), state.markedEpochDays)
    }

    @Test fun `empty history is meaningful zero state`() = runTest(dispatcher) {
        val vm = ProgressViewModel(FakeProgressRepository(goal(), emptyList())) { day("2026-06-14") }; runCurrent()
        val state = vm.uiState.value as ProgressUiState.Content
        assertEquals(0, state.percentage); assertEquals(0, state.completedActive)
        assertEquals(0, state.weeklyStreak); assertTrue(state.markedEpochDays.isEmpty())
    }

    @Test fun `archived rows appear in calendar but not active summary or streak`() = runTest(dispatcher) {
        val rows = listOf(CompletedWorkout(1, day("2026-06-08")), CompletedWorkout(2, day("2026-06-09")), CompletedWorkout(2, day("2026-06-10")))
        val vm = ProgressViewModel(FakeProgressRepository(goal(sessions = 1), rows)) { day("2026-06-14") }; runCurrent()
        val state = vm.uiState.value as ProgressUiState.Content
        assertEquals(1, state.completedActive); assertEquals(1, state.weeklyStreak)
        assertEquals(3, state.markedEpochDays.size)
    }

    @Test fun `month navigation filters marks and repository emission preserves selection`() = runTest(dispatcher) {
        val repo = FakeProgressRepository(goal(), listOf(CompletedWorkout(1, day("2026-05-20")), CompletedWorkout(1, day("2026-06-01"))))
        val vm = ProgressViewModel(repo) { day("2026-06-14") }; runCurrent()
        vm.previousMonth(); runCurrent()
        var state = vm.uiState.value as ProgressUiState.Content
        assertEquals(YearMonth.of(2026, 5), state.selectedMonth); assertEquals(setOf(day("2026-05-20")), state.markedEpochDays)
        repo.history.value = repo.history.value + CompletedWorkout(1, day("2026-05-21")); runCurrent()
        state = vm.uiState.value as ProgressUiState.Content
        assertEquals(YearMonth.of(2026, 5), state.selectedMonth); assertEquals(2, state.markedEpochDays.size)
        vm.nextMonth(); runCurrent(); assertEquals(YearMonth.of(2026, 6), (vm.uiState.value as ProgressUiState.Content).selectedMonth)
    }

    @Test fun `refresh today recomputes streak without repository emission`() = runTest(dispatcher) {
        var current = day("2026-06-14")
        val rows = listOf("2026-06-08", "2026-06-09", "2026-06-10").map { CompletedWorkout(1, day(it)) }
        val vm = ProgressViewModel(FakeProgressRepository(goal(), rows)) { current }; runCurrent()
        assertEquals(1, (vm.uiState.value as ProgressUiState.Content).weeklyStreak)
        current = day("2026-06-22"); vm.refreshToday(); runCurrent()
        assertEquals(0, (vm.uiState.value as ProgressUiState.Content).weeklyStreak)
    }

    @Test fun `duplicate day counts sessions but draws one calendar mark`() = runTest(dispatcher) {
        val same = day("2026-06-08")
        val vm = ProgressViewModel(FakeProgressRepository(goal(sessions = 1), listOf(CompletedWorkout(1, same), CompletedWorkout(1, same)))) { day("2026-06-14") }; runCurrent()
        val state = vm.uiState.value as ProgressUiState.Content
        assertEquals(2, state.completedActive); assertEquals(1, state.markedEpochDays.size); assertEquals(1, state.weeklyStreak)
    }

    @Test fun `no active goal retains calendar history`() = runTest(dispatcher) {
        val vm = ProgressViewModel(FakeProgressRepository(null, listOf(CompletedWorkout(9, day("2026-06-08"))))) { day("2026-06-14") }; runCurrent()
        val state = vm.uiState.value as ProgressUiState.NoActiveGoal
        assertEquals(setOf(day("2026-06-08")), state.markedEpochDays)
    }

    private fun goal(sessions: Int = 3) = ActiveGoal(1, GoalConfig(FitnessGoal.GENERAL_FITNESS, ExperienceLevel.BEGINNER,
        EquipmentProfile.BODYWEIGHT_ONLY, sessions, 4, RestDayMode.FULL_REST), 12)
    private fun day(value: String) = LocalDate.parse(value).toEpochDay()
}

private class FakeProgressRepository(goal: ActiveGoal?, completed: List<CompletedWorkout>) : WorkoutRepository {
    val active = MutableStateFlow(goal); val history = MutableStateFlow(completed)
    override fun observeActiveGoal(): Flow<ActiveGoal?> = active
    override fun observeCompletedWorkouts(): Flow<List<CompletedWorkout>> = history
    override fun observeCurrentWorkout(): Flow<WorkoutSession?> = flowOf(null)
    override suspend fun createGoal(config: GoalConfig, program: ProgramTemplate, startEpochDay: Long) = Unit
    override suspend fun setExerciseChecked(sessionId: Long, orderIndex: Int, checked: Boolean) = Unit
    override suspend fun completeWorkout(sessionId: Long, completedEpochDay: Long) = CompleteWorkoutResult.Completed
    override suspend fun archiveActiveGoal() = Unit
}
