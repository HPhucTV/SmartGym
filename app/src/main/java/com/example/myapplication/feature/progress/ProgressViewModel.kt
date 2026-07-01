package com.example.myapplication.feature.progress

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.myapplication.core.model.ActiveGoal
import com.example.myapplication.core.model.CompletedWorkout
import com.example.myapplication.core.progress.ProgressCalculator
import com.example.myapplication.data.WorkoutRepository
import java.time.LocalDate
import java.time.YearMonth
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch

class ProgressViewModel(
    repository: WorkoutRepository,
    private val currentEpochDay: () -> Long,
) : ViewModel() {
    private val today = MutableStateFlow(currentEpochDay())
    private val selectedMonth = MutableStateFlow(YearMonth.from(LocalDate.ofEpochDay(today.value)))
    private val _uiState = MutableStateFlow<ProgressUiState>(ProgressUiState.Loading)
    val uiState: StateFlow<ProgressUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            combine(
                repository.observeActiveGoal(),
                repository.observeCompletedWorkouts(),
                today,
                selectedMonth,
            ) { goal, history, currentDay, month -> resolve(goal, history, currentDay, month) }
                .collect { _uiState.value = it }
        }
    }

    fun refreshToday() {
        today.value = currentEpochDay()
    }

    fun previousMonth() = moveMonth(-1)
    fun nextMonth() = moveMonth(1)

    private fun moveMonth(delta: Long) {
        selectedMonth.value = runCatching { selectedMonth.value.plusMonths(delta) }
            .getOrElse { selectedMonth.value }
    }

    private fun resolve(
        goal: ActiveGoal?,
        history: List<CompletedWorkout>,
        currentDay: Long,
        month: YearMonth,
    ): ProgressUiState {
        val allDates = history.map { it.completedEpochDay }
        val marked = allDates.asSequence()
            .filter { YearMonth.from(LocalDate.ofEpochDay(it)) == month }
            .toSet()
        val monthCount = ProgressCalculator.completedSessionsByMonth(allDates)[month] ?: 0
        val canPrevious = month != YearMonth.of(-999_999_999, 1)
        val canNext = month != YearMonth.of(999_999_999, 12)
        if (goal == null) return ProgressUiState.NoActiveGoal(month, marked, monthCount, canPrevious, canNext)

        val activeDates = history.asSequence()
            .filter { it.goalId == goal.id }
            .map { it.completedEpochDay }
            .toList()
        return ProgressUiState.Content(
            percentage = ProgressCalculator.percentage(activeDates.size, goal.totalWorkouts),
            completedActive = activeDates.size,
            totalActive = goal.totalWorkouts,
            weeklyStreak = ProgressCalculator.weeklyStreak(activeDates, goal.config.sessionsPerWeek, currentDay),
            targetPerWeek = goal.config.sessionsPerWeek,
            selectedMonth = month,
            markedEpochDays = marked,
            completedInMonth = monthCount,
            canNavigatePrevious = canPrevious,
            canNavigateNext = canNext,
        )
    }
}
