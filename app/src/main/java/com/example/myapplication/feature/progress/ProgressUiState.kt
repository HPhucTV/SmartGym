package com.example.myapplication.feature.progress

import java.time.YearMonth

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
    ) : ProgressUiState

    data class NoActiveGoal(
        val selectedMonth: YearMonth,
        val markedEpochDays: Set<Long>,
        val completedInMonth: Int,
        val canNavigatePrevious: Boolean,
        val canNavigateNext: Boolean,
    ) : ProgressUiState
}
