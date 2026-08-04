import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/native.dart';

import 'package:gym_app/core/model/goal_models.dart';
import 'package:gym_app/core/model/workout_models.dart';
import 'package:gym_app/core/model/catalog_models.dart';
import 'package:gym_app/core/model/feedback_models.dart';
import 'package:gym_app/core/progress/progress_calculator.dart';
import 'package:gym_app/core/progress/goal_forecast_calculator.dart';
import 'package:gym_app/data/local/database.dart';
import 'package:gym_app/data/providers/data_providers.dart';
import 'package:gym_app/data/repositories/workout_repository.dart';
import 'package:gym_app/data/repositories/workout_feedback_repository.dart';
import 'package:gym_app/feature/progress/progress_ui_state.dart';
import 'package:gym_app/feature/progress/progress_view_model.dart';
import 'package:gym_app/core/catalog/asset_catalog_repository.dart';

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

class MockWorkoutFeedbackRepository extends Mock
    implements WorkoutFeedbackRepository {}

class MockAssetCatalogRepository extends Mock
    implements AssetCatalogRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixedToday = DateTime.utc(2026, 8, 9).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  late GymDatabase database;
  late MockWorkoutRepository mockWorkoutRepo;
  late MockWorkoutFeedbackRepository mockFeedbackRepo;
  late MockAssetCatalogRepository mockCatalogRepo;

  final exerciseCatalog = [
    const ExerciseDefinition(
      id: "push_up",
      sourceId: "1",
      nameVi: "Chống đẩy",
      level: ExperienceLevel.beginner,
      equipment: [Equipment.bodyweight],
      movementPattern: MovementPattern.horizontalPush,
      primaryMuscleGroup: MuscleGroup.chest,
      instructionsVi: [],
      substituteIds: [],
    ),
    const ExerciseDefinition(
      id: "squat",
      sourceId: "2",
      nameVi: "Squat",
      level: ExperienceLevel.beginner,
      equipment: [Equipment.bodyweight],
      movementPattern: MovementPattern.squat,
      primaryMuscleGroup: MuscleGroup.quads,
      instructionsVi: [],
      substituteIds: [],
    ),
  ];

  final programCatalog = [
    ProgramTemplate(
      id: "program_A",
      goal: FitnessGoal.generalFitness,
      level: ExperienceLevel.beginner,
      equipmentProfile: EquipmentProfile.bodyweightOnly,
      sessionsPerWeek: 3,
      durationWeeks: 4,
      workouts: [
        const WorkoutTemplate(
          sequence: 0,
          week: 1,
          titleVi: "Buổi 1",
          focusVi: "Đẩy",
          estimatedMinutes: 30,
          restDaysAfter: 1,
          exercises: [
            ExercisePrescription(
                exerciseId: "push_up", sets: 3, restSeconds: 60),
          ],
        ),
        const WorkoutTemplate(
          sequence: 1,
          week: 1,
          titleVi: "Buổi 2",
          focusVi: "Chân",
          estimatedMinutes: 30,
          restDaysAfter: 2,
          exercises: [
            ExercisePrescription(exerciseId: "squat", sets: 3, restSeconds: 60),
          ],
        ),
      ],
    ),
  ];

  setUp(() {
    database = GymDatabase(NativeDatabase.memory());
    mockWorkoutRepo = MockWorkoutRepository();
    mockFeedbackRepo = MockWorkoutFeedbackRepository();
    mockCatalogRepo = MockAssetCatalogRepository();

    when(() => mockCatalogRepo.exercises).thenReturn(exerciseCatalog);
    when(() => mockCatalogRepo.programs).thenReturn(programCatalog);

    // Repos default return streams
    when(() => mockWorkoutRepo.observeActiveGoal())
        .thenAnswer((_) => Stream.value(null));
    when(() => mockWorkoutRepo.observeCompletedWorkouts())
        .thenAnswer((_) => Stream.value(<CompletedWorkout>[]));
    when(() => mockWorkoutRepo.observeWorkoutHistory())
        .thenAnswer((_) => Stream.value(<WorkoutHistoryEntry>[]));
    when(() => mockFeedbackRepo.observeForGoal(any()))
        .thenAnswer((_) => Stream.value(<WorkoutFeedback>[]));
  });

  tearDown(() async {
    await database.close();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        gymDatabaseProvider.overrideWithValue(database),
        workoutRepositoryProvider.overrideWithValue(mockWorkoutRepo),
        workoutFeedbackRepositoryProvider.overrideWithValue(mockFeedbackRepo),
        assetCatalogRepositoryProvider.overrideWithValue(mockCatalogRepo),
        progressEpochDayProvider.overrideWithValue(fixedToday),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<ProgressUiState> waitForResolvedState(
    ProviderContainer container,
  ) async {
    final completer = Completer<ProgressUiState>();
    late final ProviderSubscription<ProgressUiState> subscription;
    subscription = container.listen(
      progressUiStateProvider,
      (_, next) {
        if (next is! ProgressUiStateLoading && !completer.isCompleted) {
          completer.complete(next);
        }
      },
      fireImmediately: true,
    );
    try {
      return await completer.future.timeout(const Duration(seconds: 2));
    } finally {
      subscription.close();
    }
  }

  test('selected month and weight filter notifiers track states', () {
    final container = createContainer();

    final currentMonth = YearMonth.fromEpochDay(fixedToday);
    expect(container.read(progressSelectedMonthProvider), equals(currentMonth));

    container
        .read(progressSelectedMonthProvider.notifier)
        .update((m) => m.plusMonths(1));
    expect(container.read(progressSelectedMonthProvider),
        equals(currentMonth.plusMonths(1)));

    expect(container.read(progressWeightFilterProvider),
        equals(WeightFilter.last30Days));
    container
        .read(progressWeightFilterProvider.notifier)
        .set(WeightFilter.last90Days);
    expect(container.read(progressWeightFilterProvider),
        equals(WeightFilter.last90Days));
  });

  test('ui state matches loading when streams have not resolved', () async {
    final completedController = StreamController<List<CompletedWorkout>>();
    when(() => mockWorkoutRepo.observeCompletedWorkouts())
        .thenAnswer((_) => completedController.stream);

    final container = createContainer();

    // State is Loading initially
    expect(
        container.read(progressUiStateProvider), isA<ProgressUiStateLoading>());

    completedController.add(<CompletedWorkout>[]);
    await waitForResolvedState(container);

    completedController.close();
  });

  test('combines inputs correctly when no active goal exists', () async {
    final today = fixedToday;
    final completed = <CompletedWorkout>[
      CompletedWorkout(goalId: 2, completedEpochDay: today),
      CompletedWorkout(goalId: 2, completedEpochDay: today - 5),
    ];

    when(() => mockWorkoutRepo.observeActiveGoal())
        .thenAnswer((_) => Stream.value(null));
    when(() => mockWorkoutRepo.observeCompletedWorkouts())
        .thenAnswer((_) => Stream.value(completed));
    when(() => mockWorkoutRepo.observeWorkoutHistory())
        .thenAnswer((_) => Stream.value(<WorkoutHistoryEntry>[]));

    // Save some weight measurements
    await database.personalizationDao.upsertWeight(WeightMeasurement(
        epochDay: today, weightKg: 70.5, recordedAtEpochMillis: 1234567));
    await database.personalizationDao.upsertWeight(WeightMeasurement(
        epochDay: today - 45, weightKg: 72.0, recordedAtEpochMillis: 1234567));

    final container = createContainer();
    final state = await waitForResolvedState(container);
    expect(state, isA<ProgressUiStateNoActiveGoal>());
    final noGoalState = state as ProgressUiStateNoActiveGoal;

    expect(noGoalState.completedInMonth, equals(2));
    expect(noGoalState.allCompletedDates, equals({today, today - 5}));

    // Weight filter last30Days limits weights count to 1 (only today, not today - 45)
    expect(noGoalState.weightHistory.length, equals(1));
    expect(noGoalState.weightHistory.first.weightKg, equals(70.5));

  });

  test(
      'calculates correct insights forecast streaks and muscle stats under active goal',
      () async {
    final today = fixedToday;
    final todayDate = DateTime.fromMillisecondsSinceEpoch(
        today * 24 * 60 * 60 * 1000,
        isUtc: true);
    final currentMonday = today - (todayDate.weekday - 1);

    final activeGoal = ActiveGoal(
      id: 5,
      config: GoalConfig(
        goal: FitnessGoal.generalFitness,
        level: ExperienceLevel.beginner,
        equipmentProfile: EquipmentProfile.bodyweightOnly,
        sessionsPerWeek: 3,
        durationWeeks: 4,
        restDayMode: RestDayMode.fullRest,
        trainingDays: const {WeekDay.monday, WeekDay.wednesday, WeekDay.friday},
        goals: const [FitnessGoal.generalFitness],
      ),
      totalWorkouts: 12,
    );

    // Completed 2 workouts
    final completed = <CompletedWorkout>[
      CompletedWorkout(goalId: 5, completedEpochDay: currentMonday - 3),
      CompletedWorkout(goalId: 5, completedEpochDay: today),
    ];

    // History:
    // Session 1: due 10 days before currentMonday (Week 1, not completed)
    // Session 2: due 3 days before currentMonday (Week 2, completed)
    // Session 3: due today (current week, completed)
    final history = <WorkoutHistoryEntry>[
      WorkoutHistoryEntry(
        sessionId: 1,
        goalId: 5,
        sequenceIndex: 0,
        dueEpochDay: currentMonday - 10,
        estimatedMinutes: 30,
      ),
      WorkoutHistoryEntry(
        sessionId: 2,
        goalId: 5,
        sequenceIndex: 1,
        dueEpochDay: currentMonday - 3,
        completedEpochDay: currentMonday - 3,
        estimatedMinutes: 30,
      ),
      WorkoutHistoryEntry(
        sessionId: 3,
        goalId: 5,
        sequenceIndex: 2,
        dueEpochDay: today,
        completedEpochDay: today,
        estimatedMinutes: 30,
      ),
    ];

    final feedback = <WorkoutFeedback>[
      WorkoutFeedback(
        sessionId: 2,
        goalId: 5,
        completedEpochDay: currentMonday - 3,
        difficulty: WorkoutDifficulty.hard,
        recordedAtEpochMillis: 1234567,
      ),
    ];

    when(() => mockWorkoutRepo.observeActiveGoal())
        .thenAnswer((_) => Stream.value(activeGoal));
    when(() => mockWorkoutRepo.observeCompletedWorkouts())
        .thenAnswer((_) => Stream.value(completed));
    when(() => mockWorkoutRepo.observeWorkoutHistory())
        .thenAnswer((_) => Stream.value(history));
    when(() => mockFeedbackRepo.observeForGoal(5))
        .thenAnswer((_) => Stream.value(feedback));

    final container = createContainer();
    final state = await waitForResolvedState(container);
    expect(state, isA<ProgressUiStateContent>());
    final contentState = state as ProgressUiStateContent;

    // Completed 2 out of 12 workouts -> 16%
    expect(contentState.percentage, equals(16));
    expect(contentState.completedActive, equals(2));
    expect(contentState.totalActive, equals(12));

    // Weekly stats
    expect(contentState.weeklyStats.length, equals(4));

    // MuscleStats: mapping exercises completed
    // Since index 0 is push_up (chest) and index 1 is squat (quads), completedCount=2 means both were completed
    final muscleGroups =
        contentState.muscleStats.map((s) => s.muscleGroup).toList();
    expect(muscleGroups, contains(MuscleGroup.chest));
    expect(muscleGroups, contains(MuscleGroup.quads));
    expect(
        contentState.muscleStats
            .firstWhere((s) => s.muscleGroup == MuscleGroup.chest)
            .count,
        equals(1));
    expect(
        contentState.muscleStats
            .firstWhere((s) => s.muscleGroup == MuscleGroup.quads)
            .count,
        equals(1));

    // Forecast check: now elapsedDays is today - (currentMonday - 10) >= 15 (>=14) and completed = 2 (>=2), so forecast should be valid
    expect(
        contentState.goalForecast, isNot(isA<GoalForecastInsufficientData>()));

    // Weekly Insights count: adherence difference is 100% (Week 2) - 0% (Week 1) = 100% >= 15%, so adherence trend insight should be present
    expect(contentState.weeklyInsights, isNotEmpty);

  });
}
