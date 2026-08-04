class SchedulePlanner {
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

  static List<int> dueEpochDaysFromWeekdays({
    required int startEpochDay,
    required Set<int> trainingDays,
    required int workoutCount,
  }) {
    if (trainingDays.isEmpty || trainingDays.length > 6) {
      throw ArgumentError("Training days must contain 1..6 weekdays");
    }
    if (workoutCount < 0) {
      throw ArgumentError("Workout count cannot be negative");
    }
    if (workoutCount == 0) return [];

    final result = <int>[];
    var cursor = startEpochDay;

    while (result.length < workoutCount) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(
        cursor * 24 * 60 * 60 * 1000,
        isUtc: true,
      );
      if (trainingDays.contains(dateTime.weekday)) {
        result.add(cursor);
      }
      if (result.length < workoutCount) {
        cursor = _safeAdd(cursor, 1);
      }
    }

    return result;
  }

  static List<int> dueEpochDaysFromRestDays({
    required int startEpochDay,
    required List<int> restDays,
  }) {
    if (restDays.any((it) => it < 0)) {
      throw ArgumentError("Rest days cannot be negative");
    }
    if (restDays.isEmpty) return [];

    final result = <int>[];
    var dueEpochDay = startEpochDay;
    result.add(dueEpochDay);

    for (var index = 1; index < restDays.length; index++) {
      dueEpochDay = _safeAdd(dueEpochDay, _safeAdd(1, restDays[index - 1]));
      result.add(dueEpochDay);
    }

    return result;
  }

  static List<int> carryForwardAfterCompletion({
    required List<int> dueEpochDays,
    required int completedIndex,
    required int completionEpochDay,
  }) {
    if (completedIndex < 0 || completedIndex >= dueEpochDays.length) {
      throw RangeError(
          "Completed index $completedIndex is outside the schedule");
    }

    final lateness =
        _safeSubtract(completionEpochDay, dueEpochDays[completedIndex]);
    if (lateness <= 0) return List.of(dueEpochDays);

    final result = <int>[];
    for (var index = 0; index < dueEpochDays.length; index++) {
      final dueEpochDay = dueEpochDays[index];
      if (index > completedIndex) {
        result.add(_safeAdd(dueEpochDay, lateness));
      } else {
        result.add(dueEpochDay);
      }
    }
    return result;
  }
}
