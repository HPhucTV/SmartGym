import '../../core/model/catalog_models.dart';
import '../../core/model/feedback_models.dart';
import '../../core/program/program_phase_planner.dart';

class PendingWorkoutFeedback {
  final int sessionId;
  final int goalId;
  final int completedEpochDay;
  final bool saving;
  final WorkoutDifficulty? selectedDifficulty;
  final String? error;

  const PendingWorkoutFeedback({
    required this.sessionId,
    required this.goalId,
    required this.completedEpochDay,
    this.saving = false,
    this.selectedDifficulty,
    this.error,
  });

  PendingWorkoutFeedback copyWith({
    int? sessionId,
    int? goalId,
    int? completedEpochDay,
    bool? saving,
    WorkoutDifficulty? selectedDifficulty,
    String? error,
  }) {
    return PendingWorkoutFeedback(
      sessionId: sessionId ?? this.sessionId,
      goalId: goalId ?? this.goalId,
      completedEpochDay: completedEpochDay ?? this.completedEpochDay,
      saving: saving ?? this.saving,
      selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
      error: error ?? this.error,
    );
  }
}

sealed class TodayUiState {
  const TodayUiState();
}

class TodayUiStateLoading extends TodayUiState {
  const TodayUiStateLoading();
}

class TodayUiStateWorkout extends TodayUiState {
  final int sessionId;
  final String titleVi;
  final String focusVi;
  final int estimatedMinutes;
  final List<WorkoutRowUi> rows;
  final int checkedCount;
  final int total;
  final bool canComplete;
  final bool isCompleting;
  final Set<int> pendingOrderIndices;
  final String? interactionError;
  final int greetingHour;
  final String? coachTip;
  final bool isRefreshingCoach;
  final int goalId;
  final ProgramPhase phase;
  final ExerciseSubstitutionUi? substitution;
  final List<int?> timeBudgetChoices;
  final int? selectedTimeBudgetMinutes;
  final int omittedExerciseCount;
  final bool canChangeTimeBudget;
  final AdvisoryMovementBlockUi? warmUp;
  final AdvisoryMovementBlockUi? coolDown;
  final Set<String> soreMuscles;

  const TodayUiStateWorkout({
    required this.sessionId,
    required this.titleVi,
    required this.focusVi,
    required this.estimatedMinutes,
    required this.rows,
    required this.checkedCount,
    required this.total,
    required this.canComplete,
    required this.isCompleting,
    this.pendingOrderIndices = const {},
    this.interactionError,
    this.greetingHour = 8,
    this.coachTip,
    this.isRefreshingCoach = false,
    this.goalId = 0,
    this.phase = ProgramPhase.foundation,
    this.substitution,
    this.timeBudgetChoices = const [15, 30, 45, null],
    this.selectedTimeBudgetMinutes,
    this.omittedExerciseCount = 0,
    this.canChangeTimeBudget = true,
    this.warmUp,
    this.coolDown,
    this.soreMuscles = const {},
  });

  TodayUiStateWorkout copyWith({
    int? sessionId,
    String? titleVi,
    String? focusVi,
    int? estimatedMinutes,
    List<WorkoutRowUi>? rows,
    int? checkedCount,
    int? total,
    bool? canComplete,
    bool? isCompleting,
    Set<int>? pendingOrderIndices,
    String? interactionError,
    int? greetingHour,
    String? coachTip,
    bool? isRefreshingCoach,
    int? goalId,
    ProgramPhase? phase,
    ExerciseSubstitutionUi? substitution,
    bool clearSubstitution = false,
    List<int?>? timeBudgetChoices,
    int? selectedTimeBudgetMinutes,
    int? omittedExerciseCount,
    bool? canChangeTimeBudget,
    AdvisoryMovementBlockUi? warmUp,
    AdvisoryMovementBlockUi? coolDown,
    Set<String>? soreMuscles,
  }) {
    return TodayUiStateWorkout(
      sessionId: sessionId ?? this.sessionId,
      titleVi: titleVi ?? this.titleVi,
      focusVi: focusVi ?? this.focusVi,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      rows: rows ?? this.rows,
      checkedCount: checkedCount ?? this.checkedCount,
      total: total ?? this.total,
      canComplete: canComplete ?? this.canComplete,
      isCompleting: isCompleting ?? this.isCompleting,
      pendingOrderIndices: pendingOrderIndices ?? this.pendingOrderIndices,
      interactionError: interactionError ?? this.interactionError,
      greetingHour: greetingHour ?? this.greetingHour,
      coachTip: coachTip ?? this.coachTip,
      isRefreshingCoach: isRefreshingCoach ?? this.isRefreshingCoach,
      goalId: goalId ?? this.goalId,
      phase: phase ?? this.phase,
      substitution: clearSubstitution
          ? null
          : (substitution ?? this.substitution),
      timeBudgetChoices: timeBudgetChoices ?? this.timeBudgetChoices,
      selectedTimeBudgetMinutes:
          selectedTimeBudgetMinutes ?? this.selectedTimeBudgetMinutes,
      omittedExerciseCount: omittedExerciseCount ?? this.omittedExerciseCount,
      canChangeTimeBudget: canChangeTimeBudget ?? this.canChangeTimeBudget,
      warmUp: warmUp ?? this.warmUp,
      coolDown: coolDown ?? this.coolDown,
      soreMuscles: soreMuscles ?? this.soreMuscles,
    );
  }
}

enum RecoveryKind { fullRest, lightRecovery }

class TodayUiStateRecovery extends TodayUiState {
  final RecoveryKind kind;
  final int nextDueEpochDay;
  final String? coachTip;
  final bool isRefreshingCoach;

  const TodayUiStateRecovery({
    required this.kind,
    required this.nextDueEpochDay,
    this.coachTip,
    this.isRefreshingCoach = false,
  });

  TodayUiStateRecovery copyWith({
    RecoveryKind? kind,
    int? nextDueEpochDay,
    String? coachTip,
    bool? isRefreshingCoach,
  }) {
    return TodayUiStateRecovery(
      kind: kind ?? this.kind,
      nextDueEpochDay: nextDueEpochDay ?? this.nextDueEpochDay,
      coachTip: coachTip ?? this.coachTip,
      isRefreshingCoach: isRefreshingCoach ?? this.isRefreshingCoach,
    );
  }
}

class TodayUiStateGoalComplete extends TodayUiState {
  const TodayUiStateGoalComplete();
}

class TodayUiStateError extends TodayUiState {
  final String message;
  final bool canRetry;

  const TodayUiStateError(this.message, {this.canRetry = false});
}

class WorkoutRowUi {
  final int orderIndex;
  final String nameVi;
  final String prescriptionText;
  final int restSeconds;
  final List<String> instructionsVi;
  final bool isChecked;
  final String exerciseId;
  final MuscleGroup primaryMuscleGroup;
  final String? originalExerciseId;
  final bool isLightWorkout;
  final String? animationId;

  const WorkoutRowUi({
    required this.orderIndex,
    required this.nameVi,
    required this.prescriptionText,
    required this.restSeconds,
    required this.instructionsVi,
    required this.isChecked,
    required this.exerciseId,
    required this.primaryMuscleGroup,
    this.originalExerciseId,
    this.isLightWorkout = false,
    this.animationId,
  });
}

class ExerciseSubstitutionUi {
  final int orderIndex;
  final String currentNameVi;
  final List<ExerciseSubstitutionCandidateUi> candidates;

  const ExerciseSubstitutionUi({
    required this.orderIndex,
    required this.currentNameVi,
    required this.candidates,
  });
}

class ExerciseSubstitutionCandidateUi {
  final String exerciseId;
  final String nameVi;
  final List<Equipment> equipment;
  final List<String> instructionsVi;
  final bool restoresOriginal;

  const ExerciseSubstitutionCandidateUi({
    required this.exerciseId,
    required this.nameVi,
    required this.equipment,
    required this.instructionsVi,
    required this.restoresOriginal,
  });
}

class AdvisoryMovementBlockUi {
  final String id;
  final String titleVi;
  final List<String> stepsVi;
  final int estimatedMinutes;
  final bool participatesInCompletion;

  const AdvisoryMovementBlockUi({
    required this.id,
    required this.titleVi,
    required this.stepsVi,
    required this.estimatedMinutes,
    this.participatesInCompletion = false,
  });
}
