package com.example.myapplication.feature.progress

import com.example.myapplication.core.model.MuscleGroup
import java.time.YearMonth
import com.example.myapplication.core.progress.WeeklyInsight
import com.example.myapplication.core.progress.GoalForecast

data class WeeklyCompletedStats(
    val weekLabel: String,
    val count: Int,
)

data class MuscleCompletedStats(
    val muscleGroup: MuscleGroup,
    val count: Int,
)

sealed interface ProgressUiState {
    data object Loading : ProgressUiState

    data class Content(
        val percentage: Int,
        val completedActive: Int,
        val totalActive: Int,
        val weeklyStreak: Int,
        val targetPerWeek: Int,
        val selectedMonth: YearMonth,
        val markedEpochDays: Set<Long>,
        val completedInMonth: Int,
        val canNavigatePrevious: Boolean,
        val canNavigateNext: Boolean,
        val weeklyStats: List<WeeklyCompletedStats> = emptyList(),
        val muscleStats: List<MuscleCompletedStats> = emptyList(),
        val weeklyInsights: List<WeeklyInsight> = emptyList(),
        val goalForecast: GoalForecast = GoalForecast.InsufficientData,
        val forecastCompletedSessions: Int = 0,
        val forecastElapsedWeeks: Long = 0,
    ) : ProgressUiState

    data class NoActiveGoal(
        val selectedMonth: YearMonth,
        val markedEpochDays: Set<Long>,
        val completedInMonth: Int,
        val canNavigatePrevious: Boolean,
        val canNavigateNext: Boolean,
        val weeklyStats: List<WeeklyCompletedStats> = emptyList(),
        val muscleStats: List<MuscleCompletedStats> = emptyList(),
    ) : ProgressUiState
}
