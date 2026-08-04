import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/model/workout_models.dart';
import '../../core/model/catalog_models.dart';
import '../../core/model/feedback_models.dart';
import '../../core/progress/progress_calculator.dart';
import '../../core/progress/weekly_insight_engine.dart';
import '../../core/progress/goal_forecast_calculator.dart';
import '../../core/program/program_selector.dart';
import '../../data/local/database.dart';
import '../../data/providers/data_providers.dart';
import 'progress_ui_state.dart';

final progressEpochDayProvider = Provider<int>((ref) {
  return currentLocalEpochDay();
});

class ProgressSelectedMonthNotifier extends Notifier<YearMonth> {
  @override
  YearMonth build() => YearMonth.fromEpochDay(ref.watch(progressEpochDayProvider));

  void update(YearMonth Function(YearMonth) cb) => state = cb(state);
}

final progressSelectedMonthProvider = NotifierProvider<ProgressSelectedMonthNotifier, YearMonth>(
  ProgressSelectedMonthNotifier.new,
);

class ProgressWeightFilterNotifier extends Notifier<WeightFilter> {
  @override
  WeightFilter build() => WeightFilter.last30Days;

  void set(WeightFilter val) => state = val;
}

final progressWeightFilterProvider = NotifierProvider<ProgressWeightFilterNotifier, WeightFilter>(
  ProgressWeightFilterNotifier.new,
);

// Input streams
final progressActiveGoalProvider = StreamProvider<ActiveGoal?>((ref) {
  return ref.watch(workoutRepositoryProvider).observeActiveGoal();
});

final progressCompletedWorkoutsProvider = StreamProvider<List<CompletedWorkout>>((ref) {
  return ref.watch(workoutRepositoryProvider).observeCompletedWorkouts();
});

final progressWorkoutHistoryProvider = StreamProvider<List<WorkoutHistoryEntry>>((ref) {
  return ref.watch(workoutRepositoryProvider).observeWorkoutHistory();
});

final progressWeightHistoryProvider = StreamProvider<List<WeightMeasurement>>((ref) {
  final db = ref.watch(gymDatabaseProvider);
  return db.personalizationDao.observeWeightHistory();
});

final progressFeedbackProvider = StreamProvider<List<WorkoutFeedback>>((ref) {
  final activeGoalAsync = ref.watch(progressActiveGoalProvider);
  final activeGoal = activeGoalAsync.value;
  if (activeGoal == null) return Stream.value(const []);
  final feedbackRepo = ref.watch(workoutFeedbackRepositoryProvider);
  return feedbackRepo.observeForGoal(activeGoal.id);
});

// UI State provider combining all inputs
final progressUiStateProvider = Provider<ProgressUiState>((ref) {
  final activeGoalAsync = ref.watch(progressActiveGoalProvider);
  final completedAsync = ref.watch(progressCompletedWorkoutsProvider);
  final historyAsync = ref.watch(progressWorkoutHistoryProvider);
  final weightsAsync = ref.watch(progressWeightHistoryProvider);
  final feedbackAsync = ref.watch(progressFeedbackProvider);

  final selectedMonth = ref.watch(progressSelectedMonthProvider);
  final weightFilter = ref.watch(progressWeightFilterProvider);

  final activeGoal = activeGoalAsync.value;
  final completed = completedAsync.value;
  final history = historyAsync.value;
  final weights = weightsAsync.value;
  final feedback = feedbackAsync.value;

  if (completed == null || history == null || weights == null) {
    return const ProgressUiStateLoading();
  }

  final allDates = completed.map((w) => w.completedEpochDay).toList();
  final allDatesSet = allDates.toSet();

  final marked = allDates
      .where((d) => YearMonth.fromEpochDay(d) == selectedMonth)
      .toSet();

  final monthCount = ProgressCalculator.completedSessionsByMonth(allDates)[selectedMonth] ?? 0;

  // 1. Calculate Weekly Stats (last 4 weeks)
  final todayDay = ref.watch(progressEpochDayProvider);
  final todayDate = DateTime.fromMillisecondsSinceEpoch(todayDay * 24 * 60 * 60 * 1000, isUtc: true);
  
  // Find Monday of current week
  final currentMonday = todayDate.subtract(Duration(days: todayDate.weekday - 1));
  final currentMondayEpoch = currentMonday.millisecondsSinceEpoch ~/ (24 * 60 * 60 * 1000);

  final weeklyStats = List.generate(4, (index) {
    final weeksAgo = 3 - index;
    final monday = currentMondayEpoch - (weeksAgo * 7);
    final sunday = monday + 6;
    final count = allDates.where((d) => d >= monday && d <= sunday).length;
    final label = weeksAgo == 0
        ? "Tuần này"
        : weeksAgo == 1
            ? "Tuần trước"
            : "$weeksAgo tuần trước";
    return WeeklyCompletedStats(weekLabel: label, count: count);
  });

  // Filter weights
  final filteredWeights = weights
      .where((w) => w.epochDay >= todayDay - weightFilter.days)
      .toList()
    ..sort((a, b) => a.epochDay.compareTo(b.epochDay));

  if (activeGoal == null) {
    return ProgressUiStateNoActiveGoal(
      selectedMonth: selectedMonth,
      markedEpochDays: marked,
      completedInMonth: monthCount,
      canNavigatePrevious: true,
      canNavigateNext: true,
      weeklyStats: weeklyStats,
      muscleStats: const [],
      weightHistory: filteredWeights,
      weightFilter: weightFilter,
      allCompletedDates: allDatesSet,
    );
  }

  final activeDates = completed
      .where((w) => w.goalId == activeGoal.id)
      .map((w) => w.completedEpochDay)
      .toList();

  // 2. Calculate Muscle Stats (based on active goal program sequence)
  final catalog = ref.watch(assetCatalogRepositoryProvider);
  final programs = catalog.programs;
  final exercisesMap = {for (var e in catalog.exercises) e.id: e};

  final muscleStatsMap = <MuscleGroup, int>{};
  final selection = ProgramSelector.select(activeGoal.config, programs);
  if (selection is ProgramSelectionFound) {
    final program = selection.program;
    final completedCount = activeDates.length;
    final completedSessions = (List<WorkoutTemplate>.from(program.workouts)
          ..sort((a, b) => a.sequence.compareTo(b.sequence)))
        .take(completedCount);

    for (var session in completedSessions) {
      for (var presc in session.exercises) {
        final definition = exercisesMap[presc.exerciseId];
        if (definition != null) {
          muscleStatsMap[definition.primaryMuscleGroup] =
              (muscleStatsMap[definition.primaryMuscleGroup] ?? 0) + 1;
        }
      }
    }
  }

  final muscleStats = muscleStatsMap.entries
      .map((entry) => MuscleCompletedStats(muscleGroup: entry.key, count: entry.value))
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));

  final weeklyInsights = WeeklyInsightEngine.generate(
    history: history.where((h) => h.goalId == activeGoal.id).toList(),
    feedback: feedback ?? const [],
    todayEpochDay: todayDay,
  );

  final activeHistory = history.where((h) => h.goalId == activeGoal.id).toList();
  final firstDue = activeHistory.isEmpty
      ? null
      : activeHistory.map((h) => h.dueEpochDay).reduce((a, b) => a < b ? a : b);
  final finalDue = activeHistory.isEmpty
      ? null
      : activeHistory.map((h) => h.dueEpochDay).reduce((a, b) => a > b ? a : b);

  final elapsedWeeks = firstDue == null ? 0 : ((todayDay - firstDue).clamp(0, double.infinity).toInt() ~/ 7);

  final forecast = (firstDue == null || finalDue == null)
      ? GoalForecastInsufficientData()
      : GoalForecastCalculator.calculate(
          totalSessions: activeGoal.totalWorkouts,
          completedSessions: activeDates.length,
          sessionsPerWeek: activeGoal.config.sessionsPerWeek,
          firstDueEpochDay: firstDue,
          plannedFinalDueEpochDay: finalDue,
          todayEpochDay: todayDay,
        );

  return ProgressUiStateContent(
    percentage: ProgressCalculator.percentage(activeDates.length, activeGoal.totalWorkouts),
    completedActive: activeDates.length,
    totalActive: activeGoal.totalWorkouts,
    weeklyStreak: ProgressCalculator.weeklyStreak(
      completedEpochDays: activeDates,
      targetPerWeek: activeGoal.config.sessionsPerWeek,
      currentEpochDay: todayDay,
    ),
    targetPerWeek: activeGoal.config.sessionsPerWeek,
    selectedMonth: selectedMonth,
    markedEpochDays: marked,
    completedInMonth: monthCount,
    canNavigatePrevious: true,
    canNavigateNext: true,
    weeklyStats: weeklyStats,
    muscleStats: muscleStats,
    weeklyInsights: weeklyInsights,
    goalForecast: forecast,
    forecastCompletedSessions: activeDates.length,
    forecastElapsedWeeks: elapsedWeeks,
    weightHistory: filteredWeights,
    weightFilter: weightFilter,
    allCompletedDates: allDatesSet,
  );
});
