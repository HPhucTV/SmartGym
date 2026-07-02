package com.example.myapplication.feature.checkin

sealed interface WeeklyCheckInUiState {
    data object Loading : WeeklyCheckInUiState
    data object NoProfile : WeeklyCheckInUiState
    data class Input(
        val weightKgStr: String,
        val energy: Int,
        val hunger: Int,
        val recovery: Int,
        val sleepQuality: Int,
        val note: String,
        val isSubmitting: Boolean = false,
        val error: String? = null,
        val success: Boolean = false,
        val validationErrors: List<String> = emptyList(),
    ) : WeeklyCheckInUiState
}
