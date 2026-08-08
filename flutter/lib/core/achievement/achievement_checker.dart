import '../model/achievement_models.dart';
import '../model/workout_models.dart';
import 'achievement_rules.dart';

class AchievementChecker {
  final int Function() todayEpochDay;
  final int Function() currentHour;

  /// [todayEpochDay] bắt buộc phải truyền vào: trước đây nó có giá trị mặc định
  /// tính bằng `floor()` trên thời điểm UTC thô, lệch với `currentLocalEpochDay`
  /// suốt 7 tiếng mỗi ngày ở UTC+7 và khiến badge `nightOwl` không bao giờ mở
  /// được sau 17:00 giờ địa phương. Giữ nó bắt buộc để chỉ còn một định nghĩa
  /// "hôm nay" trong toàn app.
  AchievementChecker({
    required this.todayEpochDay,
    int Function()? currentHour,
  }) : currentHour = currentHour ?? (() => DateTime.now().hour);

  /// Đánh giá xem có thành tựu mới nào được mở khóa hay không.
  /// Trả về danh sách các [AchievementType] mới được mở khóa so với danh sách [existing].
  List<AchievementType> checkNewUnlocks({
    required List<CompletedWorkout> completed,
    required int activeGoalId,
    required int totalProgramSessions,
    required int targetPerWeek,
    required Set<AchievementType> existing,
    int scanCount = 0,
    int checkInCount = 0,
    int allMuscleGroupsCount = 0,
    int muscleGroupsThisWeek = 0,
  }) {
    final eligible = AchievementRules.evaluate(
      AchievementSnapshot(
        completedEpochDays: completedEpochDaysForGoal(completed, activeGoalId),
        totalProgramSessions: totalProgramSessions,
        targetPerWeek: targetPerWeek,
        todayEpochDay: todayEpochDay(),
        currentHour: currentHour(),
        scanCount: scanCount,
        checkInCount: checkInCount,
        allMuscleGroupsCount: allMuscleGroupsCount,
        muscleGroupsThisWeek: muscleGroupsThisWeek,
      ),
    );

    return eligible.where((type) => !existing.contains(type)).toList();
  }
}
