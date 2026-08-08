import 'dart:math';

sealed class GoalForecast {}

class GoalForecastInsufficientData extends GoalForecast {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalForecastInsufficientData && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;
}

class GoalForecastOnTrack extends GoalForecast {
  final int projectedEpochDay;
  GoalForecastOnTrack(this.projectedEpochDay);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalForecastOnTrack &&
          runtimeType == other.runtimeType &&
          projectedEpochDay == other.projectedEpochDay;

  @override
  int get hashCode => projectedEpochDay.hashCode;
}

class GoalForecastAtRisk extends GoalForecast {
  final int projectedEpochDay;
  final int sessionsBehind;
  GoalForecastAtRisk({
    required this.projectedEpochDay,
    required this.sessionsBehind,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalForecastAtRisk &&
          runtimeType == other.runtimeType &&
          projectedEpochDay == other.projectedEpochDay &&
          sessionsBehind == other.sessionsBehind;

  @override
  int get hashCode => projectedEpochDay.hashCode ^ sessionsBehind.hashCode;
}

class GoalForecastComplete extends GoalForecast {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalForecastComplete && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;
}

class GoalForecastCalculator {
  static int _safeAdd(int a, int b) {
    final res = a + b;
    if ((a > 0 && b > 0 && res < 0) || (a < 0 && b < 0 && res > 0)) {
      throw UnsupportedError("Integer overflow");
    }
    return res;
  }

  static int _safeSubtract(int a, int b) {
    final res = a - b;
    if ((b < 0 && a > 0 && res < 0) || (b > 0 && a < 0 && res > 0)) {
      throw UnsupportedError("Integer overflow");
    }
    return res;
  }

  static GoalForecast calculate({
    required int totalSessions,
    required int completedSessions,
    required int sessionsPerWeek,
    required int firstDueEpochDay,
    required int plannedFinalDueEpochDay,
    required int todayEpochDay,
  }) {
    if (totalSessions <= 0 ||
        sessionsPerWeek <= 0 ||
        completedSessions < 0 ||
        completedSessions > totalSessions) {
      return GoalForecastInsufficientData();
    }
    if (completedSessions == totalSessions) return GoalForecastComplete();

    final elapsedDays = _safeSubtract(todayEpochDay, firstDueEpochDay);
    if (elapsedDays < 0) return GoalForecastInsufficientData();
    
    final elapsedWeeks = elapsedDays ~/ 7;
    if (elapsedWeeks < 2 || completedSessions < 2) {
      return GoalForecastInsufficientData();
    }

    // Dùng đúng tốc độ *đo được*, không kẹp xuống tốc độ kế hoạch: kẹp lại sẽ
    // khiến người tập 5 buổi/tuần trên kế hoạch 3 buổi/tuần bị dự báo là 3, nên
    // không bao giờ báo được là đang vượt tiến độ.
    final double weeklyRate = completedSessions.toDouble() / elapsedWeeks;
    if (weeklyRate <= 0.0) return GoalForecastInsufficientData();
    
    final remaining = totalSessions - completedSessions;
    final remainingWeeks = (remaining / weeklyRate).ceil();
    
    final projectedEpochDay = _safeAdd(todayEpochDay, _safeAdd(remainingWeeks * 7, 0)); // dùng _safeAdd để phát hiện tràn số
    final riskBoundary = _safeAdd(plannedFinalDueEpochDay, 7);

    if (projectedEpochDay > riskBoundary) {
      final expectedByNow =
          min(totalSessions, elapsedWeeks * sessionsPerWeek);
      return GoalForecastAtRisk(
        projectedEpochDay: projectedEpochDay,
        sessionsBehind: max(0, expectedByNow - completedSessions),
      );
    }
    
    return GoalForecastOnTrack(projectedEpochDay);
  }
}
