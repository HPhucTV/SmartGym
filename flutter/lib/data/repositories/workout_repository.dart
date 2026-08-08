import '../../../core/model/achievement_models.dart';
import '../../../core/model/goal_models.dart';
import '../../../core/model/workout_models.dart';
import '../../../core/model/catalog_models.dart';
import '../../../core/program/schedule_rescheduler.dart';

enum CompleteWorkoutResult {
  completed,
  blockedByUncheckedExercises,
  alreadyCompleted,
}

enum ExerciseSubstitutionResult {
  applied,
  invalidCandidate,
  staleSession,
  alreadyChecked,
}

enum TimeBudgetResult {
  applied,
  invalidBudget,
  hasCheckedExercises,
  staleSession,
}

enum ScheduleChangeResult {
  applied,
  stale,
}

abstract class WorkoutRepository {
  Stream<ActiveGoal?> observeActiveGoal();
  Stream<WorkoutSession?> observeCurrentWorkout();
  Stream<List<CompletedWorkout>> observeCompletedWorkouts();
  Stream<List<WorkoutHistoryEntry>> observeWorkoutHistory();
  Future<void> createGoal(
      GoalConfig config, ProgramTemplate program, int startEpochDay);
  Future<void> setExerciseChecked(int sessionId, int orderIndex, bool checked);
  Future<CompleteWorkoutResult> completeWorkout(
      int sessionId, int completedEpochDay);
  Future<ExerciseSubstitutionResult> substituteExercise({
    required int sessionId,
    required int orderIndex,
    required String replacementExerciseId,
  });
  Future<TimeBudgetResult> applyTimeBudget(int sessionId, int? minutes);
  Future<ScheduleChangePreview> previewScheduleChange(
      int sessionId, int newEpochDay);
  Future<ScheduleChangeResult> applyScheduleChange(
      ScheduleChangePreview preview);
  Future<void> archiveActiveGoal();

  /// Các badge đã mở khoá và được lưu lại từ trước.
  Future<Set<AchievementType>> unlockedAchievements();

  /// Lưu các badge vừa mở khoá. Ghi trùng là vô hại (insertOrIgnore).
  Future<void> recordUnlockedAchievements(
      Set<AchievementType> types, int unlockedAtEpochMillis);
}
