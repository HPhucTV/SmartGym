package com.example.myapplication.feature.today

import com.example.myapplication.core.feedback.WorkoutDifficulty
import com.example.myapplication.core.model.MuscleGroup
import com.example.myapplication.core.model.Equipment
import com.example.myapplication.core.program.ProgramPhase

data class PendingWorkoutFeedback(
    val sessionId: Long,
    val goalId: Long,
    val completedEpochDay: Long,
    val saving: Boolean = false,
    val selectedDifficulty: WorkoutDifficulty? = null,
    val error: String? = null,
)

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
        val goalId: Long = 0L,
        val phase: ProgramPhase = ProgramPhase.FOUNDATION,
        val substitution: ExerciseSubstitutionUi? = null,
        val timeBudgetChoices: List<Int?> = listOf(15, 30, 45, null),
        val selectedTimeBudgetMinutes: Int? = null,
        val omittedExerciseCount: Int = 0,
        val canChangeTimeBudget: Boolean = true,
        val warmUp: AdvisoryMovementBlockUi? = null,
        val coolDown: AdvisoryMovementBlockUi? = null,
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
    val originalExerciseId: String? = null,
)

data class ExerciseSubstitutionUi(
    val orderIndex: Int,
    val currentNameVi: String,
    val candidates: List<ExerciseSubstitutionCandidateUi>,
)

data class ExerciseSubstitutionCandidateUi(
    val exerciseId: String,
    val nameVi: String,
    val equipment: List<Equipment>,
    val instructionsVi: List<String>,
    val restoresOriginal: Boolean,
)

data class AdvisoryMovementBlockUi(
    val id: String,
    val titleVi: String,
    val stepsVi: List<String>,
    val estimatedMinutes: Int,
    val participatesInCompletion: Boolean = false,
)
