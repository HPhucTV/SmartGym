package com.example.myapplication.feature.today

import com.example.myapplication.core.model.MuscleGroup

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
        val pendingOrderIndices: Set<Int> = emptySet(),
        val interactionError: String? = null,
        val greetingHour: Int = 8,
        val coachTip: String? = null,
        val isRefreshingCoach: Boolean = false,
    ) : TodayUiState

    data class Recovery(
        val kind: RecoveryKind,
        val nextDueEpochDay: Long,
        val coachTip: String? = null,
        val isRefreshingCoach: Boolean = false,
    ) : TodayUiState
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
    val exerciseId: String = nameVi,
    val primaryMuscle: MuscleGroup = MuscleGroup.FULL_BODY,
)
