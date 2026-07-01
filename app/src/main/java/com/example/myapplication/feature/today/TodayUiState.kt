package com.example.myapplication.feature.today

sealed interface TodayUiState {
    data object Loading : TodayUiState

    data class Workout(
        val sessionId: Long,
        val titleVi: String,
        val focusVi: String,
        val estimatedMinutes: Int,
        val rows: List<WorkoutRowUi>,
        val checkedCount: Int,
        val total: Int,
        val canComplete: Boolean,
        val isCompleting: Boolean,
    ) : TodayUiState

    data class Recovery(val kind: RecoveryKind, val nextDueEpochDay: Long) : TodayUiState
    data object GoalComplete : TodayUiState
    data class Error(val message: String, val canRetry: Boolean = false) : TodayUiState
}

enum class RecoveryKind { FULL_REST, LIGHT_RECOVERY }

data class WorkoutRowUi(
    val orderIndex: Int,
    val nameVi: String,
    val prescriptionText: String,
    val restSeconds: Int,
    val instructionsVi: List<String>,
    val checked: Boolean,
)
