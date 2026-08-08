import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_app/core/model/achievement_models.dart';
import 'package:gym_app/core/model/goal_models.dart';
import 'package:gym_app/core/model/workout_models.dart';
import 'package:gym_app/core/model/catalog_models.dart';
import 'package:gym_app/core/model/feedback_models.dart';
import 'package:gym_app/core/model/movement_block_models.dart';
import 'package:gym_app/core/program/program_phase_planner.dart';
import 'package:gym_app/core/catalog/asset_catalog_repository.dart';
import 'package:gym_app/data/providers/data_providers.dart';
import 'package:gym_app/data/repositories/workout_repository.dart';
import 'package:gym_app/data/repositories/settings_repository.dart';
import 'package:gym_app/data/repositories/nutrition_repository.dart';
import 'package:gym_app/data/repositories/workout_feedback_repository.dart';
import 'package:gym_app/feature/today/today_ui_state.dart';
import 'package:gym_app/feature/today/today_view_model.dart';

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockNutritionRepository extends Mock implements NutritionRepository {}

class MockAssetCatalogRepository extends Mock
    implements AssetCatalogRepository {}

class MockWorkoutFeedbackRepository extends Mock
    implements WorkoutFeedbackRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockWorkoutRepository mockWorkoutRepo;
  late MockSettingsRepository mockSettingsRepo;
  late MockNutritionRepository mockNutritionRepo;
  late MockAssetCatalogRepository mockCatalogRepo;
  late MockWorkoutFeedbackRepository mockFeedbackRepo;

  final exerciseCatalog = [
    const ExerciseDefinition(
      id: "push_up",
      sourceId: "1",
      nameVi: "Chống đẩy",
      level: ExperienceLevel.beginner,
      equipment: [Equipment.bodyweight],
      movementPattern: MovementPattern.horizontalPush,
      primaryMuscleGroup: MuscleGroup.chest,
      instructionsVi: ["Giữ thân thẳng", "Hạ ngực có kiểm soát"],
      substituteIds: ["knee_push_up"],
    ),
    const ExerciseDefinition(
      id: "knee_push_up",
      sourceId: "2",
      nameVi: "Knee push-up",
      level: ExperienceLevel.beginner,
      equipment: [Equipment.bodyweight],
      movementPattern: MovementPattern.horizontalPush,
      primaryMuscleGroup: MuscleGroup.chest,
      instructionsVi: ["Quỳ gối", "Đẩy người lên"],
      substituteIds: ["push_up"],
    ),
  ];

  final movementBlocks = [
    const MovementBlock(
      id: "push_warmup",
      kind: MovementBlockKind.warmUp,
      movementPatterns: {MovementPattern.horizontalPush},
      titleVi: "Khởi động đẩy",
      stepsVi: ["Xoay vai", "Đẩy tường"],
      estimatedMinutes: 4,
    ),
    const MovementBlock(
      id: "push_cooldown",
      kind: MovementBlockKind.coolDown,
      movementPatterns: {MovementPattern.horizontalPush},
      titleVi: "Thả lỏng đẩy",
      stepsVi: ["Thả lỏng tay", "Hít thở đều"],
      estimatedMinutes: 4,
    ),
  ];

  setUpAll(() {
    registerFallbackValue(WorkoutDifficulty.easy);
    registerFallbackValue(<AchievementType>{});
  });

  setUp(() {
    mockWorkoutRepo = MockWorkoutRepository();
    mockSettingsRepo = MockSettingsRepository();
    mockNutritionRepo = MockNutritionRepository();
    mockCatalogRepo = MockAssetCatalogRepository();
    mockFeedbackRepo = MockWorkoutFeedbackRepository();

    // Default return values
    when(() => mockCatalogRepo.exercises).thenReturn(exerciseCatalog);
    when(() => mockCatalogRepo.movementBlocks).thenReturn([]);

    final defaultGoal = ActiveGoal(
      id: 1,
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

    when(() => mockWorkoutRepo.observeActiveGoal())
        .thenAnswer((_) => Stream.value(defaultGoal));
    when(() => mockWorkoutRepo.observeCurrentWorkout())
        .thenAnswer((_) => Stream.value(null));
    when(() => mockWorkoutRepo.observeCompletedWorkouts())
        .thenAnswer((_) => Stream.value([]));
    when(() => mockWorkoutRepo.unlockedAchievements())
        .thenAnswer((_) => Future.value(<AchievementType>{}));
    when(() => mockWorkoutRepo.recordUnlockedAchievements(any(), any()))
        .thenAnswer((_) => Future.value());

    when(() => mockSettingsRepo.settings)
        .thenAnswer((_) => Stream.value(const Settings()));
    when(() => mockNutritionRepo.nutritionData)
        .thenAnswer((_) => Stream.value(const NutritionData()));
    when(() => mockNutritionRepo.clearSweatPayment())
        .thenAnswer((_) => Future.value());

    when(() => mockFeedbackRepo.save(
          sessionId: any(named: 'sessionId'),
          goalId: any(named: 'goalId'),
          completedEpochDay: any(named: 'completedEpochDay'),
          difficulty: any(named: 'difficulty'),
        )).thenAnswer((_) => Future.value());
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(mockWorkoutRepo),
        settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        nutritionRepositoryProvider.overrideWithValue(mockNutritionRepo),
        assetCatalogRepositoryProvider.overrideWithValue(mockCatalogRepo),
        workoutFeedbackRepositoryProvider.overrideWithValue(mockFeedbackRepo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  WorkoutSession createSession(
      {required int id,
      required int dueEpochDay,
      int sequenceIndex = 0,
      List<bool> checked = const [false]}) {
    return WorkoutSession(
      id: id,
      goalId: 1,
      sequenceIndex: sequenceIndex,
      titleVi: "Toàn thân A",
      focusVi: "Toàn thân",
      estimatedMinutes: 42,
      dueEpochDay: dueEpochDay,
      exercises: checked
          .asMap()
          .entries
          .map((entry) => WorkoutExercise(
                orderIndex: entry.key,
                exerciseId: "push_up",
                prescription: const ExercisePrescription(
                    exerciseId: "push_up",
                    sets: 3,
                    minReps: 8,
                    maxReps: 12,
                    restSeconds: 60),
                isChecked: entry.value,
              ))
          .toList(),
    );
  }

  test('settings rest override controls recovery', () async {
    final today = currentLocalEpochDay();
    // Due day is tomorrow, so it's a recovery day
    final session = createSession(id: 7, dueEpochDay: today + 1);

    when(() => mockWorkoutRepo.observeCurrentWorkout())
        .thenAnswer((_) => Stream.value(session));
    // Settings has restDayMode = lightRecovery
    when(() => mockSettingsRepo.settings).thenAnswer((_) =>
        Stream.value(const Settings(restDayMode: RestDayMode.lightRecovery)));

    final container = createContainer();
    final subscription =
        container.listen(todayNotifierProvider, (prev, next) {});
    await Future.delayed(const Duration(milliseconds: 50));

    final state = container.read(todayNotifierProvider);
    expect(state, isA<TodayUiStateRecovery>());
    expect((state as TodayUiStateRecovery).kind,
        equals(RecoveryKind.lightRecovery));
    subscription.close();
  });

  test('maps due workout and mutations use persisted identity', () async {
    final today = currentLocalEpochDay();
    final session = createSession(id: 7, dueEpochDay: today);

    final workoutController = StreamController<WorkoutSession?>();
    when(() => mockWorkoutRepo.observeCurrentWorkout())
        .thenAnswer((_) => workoutController.stream);
    when(() => mockWorkoutRepo.setExerciseChecked(7, 0, true))
        .thenAnswer((_) => Future.value());

    final container = createContainer();
    final subscription =
        container.listen(todayNotifierProvider, (prev, next) {});

    workoutController.add(session);
    await Future.delayed(const Duration(milliseconds: 50));

    final state1 = container.read(todayNotifierProvider);
    expect(state1, isA<TodayUiStateWorkout>());
    final workoutState = state1 as TodayUiStateWorkout;
    expect(workoutState.rows.single.nameVi, equals("Chống đẩy"));
    expect(workoutState.rows.single.instructionsVi,
        equals(["Giữ thân thẳng", "Hạ ngực có kiểm soát"]));
    expect(workoutState.rows.single.prescriptionText, equals("3 × 8–12"));
    expect(workoutState.canComplete, isFalse);
    expect(workoutState.phase, equals(ProgramPhase.foundation));

    // Perform check mutation
    final notifier = container.read(todayNotifierProvider.notifier);
    await notifier.setChecked(0, true);

    verify(() => mockWorkoutRepo.setExerciseChecked(7, 0, true)).called(1);

    // Update stream to show it is now checked
    workoutController.add(session.copyWith(
      exercises: [session.exercises.single.copyWith(isChecked: true)],
    ));
    await Future.delayed(const Duration(milliseconds: 50));

    final state2 = container.read(todayNotifierProvider);
    expect((state2 as TodayUiStateWorkout).canComplete, isTrue);

    subscription.close();
    workoutController.close();
  });

  test('today infers deload phase from ordered session', () async {
    final today = currentLocalEpochDay();
    // sequenceIndex = 11 for 3 sessions/week means week 4, which is the last week (deload) for 4 durationWeeks goal
    final session = createSession(id: 7, dueEpochDay: today, sequenceIndex: 11);

    when(() => mockWorkoutRepo.observeCurrentWorkout())
        .thenAnswer((_) => Stream.value(session));

    final container = createContainer();
    final subscription =
        container.listen(todayNotifierProvider, (prev, next) {});
    await Future.delayed(const Duration(milliseconds: 50));

    final state = container.read(todayNotifierProvider);
    expect(state, isA<TodayUiStateWorkout>());
    expect((state as TodayUiStateWorkout).phase, equals(ProgramPhase.deload));
    subscription.close();
  });

  test('replacement dialog exposes reviewed candidates and applies selection',
      () async {
    final today = currentLocalEpochDay();
    final session = createSession(id: 7, dueEpochDay: today);

    when(() => mockWorkoutRepo.observeCurrentWorkout())
        .thenAnswer((_) => Stream.value(session));
    when(() => mockWorkoutRepo.substituteExercise(
          sessionId: 7,
          orderIndex: 0,
          replacementExerciseId: "knee_push_up",
        )).thenAnswer((_) => Future.value(ExerciseSubstitutionResult.applied));

    final container = createContainer();
    final subscription =
        container.listen(todayNotifierProvider, (prev, next) {});
    await Future.delayed(const Duration(milliseconds: 50));

    final notifier = container.read(todayNotifierProvider.notifier);
    notifier.requestSubstitution(0);

    final state = container.read(todayNotifierProvider);
    expect(state, isA<TodayUiStateWorkout>());
    final workoutState = state as TodayUiStateWorkout;
    expect(workoutState.substitution, isNotNull);
    expect(workoutState.substitution!.candidates.map((c) => c.nameVi),
        equals(["Knee push-up"]));

    await notifier.applySubstitution("knee_push_up");

    verify(() => mockWorkoutRepo.substituteExercise(
          sessionId: 7,
          orderIndex: 0,
          replacementExerciseId: "knee_push_up",
        )).called(1);

    subscription.close();
  });

  test('replacement reports when no compatible candidate exists', () async {
    final today = currentLocalEpochDay();
    final session = createSession(id: 7, dueEpochDay: today);

    when(() => mockWorkoutRepo.observeCurrentWorkout())
        .thenAnswer((_) => Stream.value(session));
    // Provide empty exercises list so no compatible candidate is found
    when(() => mockCatalogRepo.exercises)
        .thenReturn([exerciseCatalog.first]); // Only push_up, no knee_push_up

    final container = createContainer();
    final subscription =
        container.listen(todayNotifierProvider, (prev, next) {});
    await Future.delayed(const Duration(milliseconds: 50));

    final notifier = container.read(todayNotifierProvider.notifier);
    notifier.requestSubstitution(0);

    final state = container.read(todayNotifierProvider);
    expect(state, isA<TodayUiStateWorkout>());
    final workoutState = state as TodayUiStateWorkout;
    expect(workoutState.substitution, isNull);
    expect(workoutState.interactionError, contains("Không có bài thay thế"));

    subscription.close();
  });

  test('time budget choices apply and lock behavior', () async {
    final today = currentLocalEpochDay();
    // Initially unchecked
    final sessionUnchecked = createSession(id: 7, dueEpochDay: today).copyWith(
      selectedTimeBudgetMinutes: 15,
      omittedExerciseCount: 2,
    );

    final workoutController = StreamController<WorkoutSession?>();
    when(() => mockWorkoutRepo.observeCurrentWorkout())
        .thenAnswer((_) => workoutController.stream);
    when(() => mockWorkoutRepo.applyTimeBudget(7, 30))
        .thenAnswer((_) => Future.value(TimeBudgetResult.applied));

    final container = createContainer();
    final subscription =
        container.listen(todayNotifierProvider, (prev, next) {});

    workoutController.add(sessionUnchecked);
    await Future.delayed(const Duration(milliseconds: 50));

    final state1 = container.read(todayNotifierProvider);
    expect(state1, isA<TodayUiStateWorkout>());
    var workoutState = state1 as TodayUiStateWorkout;
    expect(workoutState.timeBudgetChoices, equals([15, 30, 45, null]));
    expect(workoutState.selectedTimeBudgetMinutes, equals(15));
    expect(workoutState.omittedExerciseCount, equals(2));
    expect(workoutState.canChangeTimeBudget, isTrue);

    final notifier = container.read(todayNotifierProvider.notifier);
    await notifier.applyTimeBudget(30);

    verify(() => mockWorkoutRepo.applyTimeBudget(7, 30)).called(1);

    // Now checked
    final sessionChecked = sessionUnchecked.copyWith(
      exercises: [sessionUnchecked.exercises.single.copyWith(isChecked: true)],
    );
    workoutController.add(sessionChecked);
    await Future.delayed(const Duration(milliseconds: 50));

    final state2 = container.read(todayNotifierProvider);
    workoutState = state2 as TodayUiStateWorkout;
    expect(workoutState.canChangeTimeBudget, isFalse);

    // Calling applyTimeBudget while checked does nothing
    await notifier.applyTimeBudget(15);
    verifyNever(() => mockWorkoutRepo.applyTimeBudget(7, 15));

    subscription.close();
    workoutController.close();
  });

  test('maps advisory warmup and cooldown from active movement patterns',
      () async {
    final today = currentLocalEpochDay();
    final session = createSession(id: 7, dueEpochDay: today);

    when(() => mockWorkoutRepo.observeCurrentWorkout())
        .thenAnswer((_) => Stream.value(session));
    when(() => mockCatalogRepo.movementBlocks).thenReturn(movementBlocks);

    final container = createContainer();
    final subscription =
        container.listen(todayNotifierProvider, (prev, next) {});
    await Future.delayed(const Duration(milliseconds: 50));

    final state = container.read(todayNotifierProvider);
    expect(state, isA<TodayUiStateWorkout>());
    final workoutState = state as TodayUiStateWorkout;
    expect(workoutState.warmUp?.id, equals("push_warmup"));
    expect(workoutState.coolDown?.id, equals("push_cooldown"));
    subscription.close();
  });

  test('shows both recovery modes goal complete and missing catalog error',
      () async {
    final today = currentLocalEpochDay();
    final session = createSession(id: 7, dueEpochDay: today + 1);

    final workoutController = StreamController<WorkoutSession?>();
    final goalController = StreamController<ActiveGoal?>();

    final defaultGoal = ActiveGoal(
      id: 1,
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

    when(() => mockWorkoutRepo.observeCurrentWorkout())
        .thenAnswer((_) => workoutController.stream);
    when(() => mockWorkoutRepo.observeActiveGoal())
        .thenAnswer((_) => goalController.stream);

    final container = createContainer();
    final subscription =
        container.listen(todayNotifierProvider, (prev, next) {});

    workoutController.add(session);
    goalController.add(defaultGoal);
    await Future.delayed(const Duration(milliseconds: 50));

    final state1 = container.read(todayNotifierProvider);
    expect(state1, isA<TodayUiStateRecovery>());
    expect(
        (state1 as TodayUiStateRecovery).kind, equals(RecoveryKind.fullRest));

    // Goal rest mode change
    goalController.add(defaultGoal.copyWith(
      config:
          defaultGoal.config.copyWith(restDayMode: RestDayMode.lightRecovery),
    ));
    await Future.delayed(const Duration(milliseconds: 50));
    final state2 = container.read(todayNotifierProvider);
    expect(state2, isA<TodayUiStateRecovery>());
    expect((state2 as TodayUiStateRecovery).kind,
        equals(RecoveryKind.lightRecovery));

    // Current workout null means goal completed
    workoutController.add(null);
    await Future.delayed(const Duration(milliseconds: 50));
    final state3 = container.read(todayNotifierProvider);
    expect(state3, isA<TodayUiStateGoalComplete>());

    // Missing exercise definition error
    workoutController.add(session.copyWith(
      dueEpochDay: today,
      exercises: [
        WorkoutExercise(
          orderIndex: 0,
          exerciseId: "missing_exercise",
          prescription: const ExercisePrescription(
              exerciseId: "missing_exercise", sets: 3, restSeconds: 60),
          isChecked: false,
        )
      ],
    ));
    await Future.delayed(const Duration(milliseconds: 50));
    final state4 = container.read(todayNotifierProvider);
    expect(state4, isA<TodayUiStateError>());
    expect((state4 as TodayUiStateError).message, contains("missing_exercise"));

    subscription.close();
    workoutController.close();
    goalController.close();
  });

  test('completion is guarded deduplicated recoverable and retryable',
      () async {
    final today = currentLocalEpochDay();
    final sessionUnchecked =
        createSession(id: 7, dueEpochDay: today, checked: [false]);

    final workoutController = StreamController<WorkoutSession?>();
    when(() => mockWorkoutRepo.observeCurrentWorkout())
        .thenAnswer((_) => workoutController.stream);
    when(() => mockWorkoutRepo.completeWorkout(7, today))
        .thenAnswer((_) => Future.value(CompleteWorkoutResult.completed));

    final container = createContainer();
    final subscription =
        container.listen(todayNotifierProvider, (prev, next) {});

    workoutController.add(sessionUnchecked);
    await Future.delayed(const Duration(milliseconds: 50));

    final notifier = container.read(todayNotifierProvider.notifier);

    // Call completeWorkout on unchecked session -> ignored (completions remains 0)
    await notifier.completeWorkout();
    verifyNever(() => mockWorkoutRepo.completeWorkout(any(), any()));

    // Make checked
    final sessionChecked =
        createSession(id: 7, dueEpochDay: today, checked: [true]);
    workoutController.add(sessionChecked);
    await Future.delayed(const Duration(milliseconds: 50));

    // Double invocation deduplication test
    final fut1 = notifier.completeWorkout();
    final fut2 = notifier.completeWorkout();
    await Future.wait([fut1, fut2]);

    // Should only invoke once
    verify(() => mockWorkoutRepo.completeWorkout(7, today)).called(1);

    // Fail completion test
    var failAttempts = 0;
    when(() => mockWorkoutRepo.completeWorkout(7, today)).thenAnswer((_) async {
      failAttempts++;
      if (failAttempts == 1) {
        throw Exception("Network Timeout");
      }
      return CompleteWorkoutResult.completed;
    });

    await notifier.completeWorkout();
    final state1 = container.read(todayNotifierProvider);
    expect(state1, isA<TodayUiStateError>());
    expect((state1 as TodayUiStateError).canRetry, isTrue);

    // Retry succeeds
    await notifier.retry();
    final state2 = container.read(todayNotifierProvider);
    expect(state2, isNot(isA<TodayUiStateError>()));

    subscription.close();
    workoutController.close();
  });

  test('completion exposes feedback request and submitting saves it', () async {
    final today = currentLocalEpochDay();
    final session = createSession(id: 7, dueEpochDay: today, checked: [true]);

    when(() => mockWorkoutRepo.observeCurrentWorkout())
        .thenAnswer((_) => Stream.value(session));
    when(() => mockWorkoutRepo.completeWorkout(7, today))
        .thenAnswer((_) => Future.value(CompleteWorkoutResult.completed));

    final container = createContainer();
    final subscription =
        container.listen(todayNotifierProvider, (prev, next) {});
    await Future.delayed(const Duration(milliseconds: 50));

    final notifier = container.read(todayNotifierProvider.notifier);
    expect(container.read(pendingFeedbackProvider), isNull);

    await notifier.completeWorkout();

    final pending = container.read(pendingFeedbackProvider);
    expect(pending, isNotNull);
    expect(pending!.sessionId, equals(7));
    expect(pending.goalId, equals(1));
    expect(pending.completedEpochDay, equals(today));

    // Submit difficulty
    await notifier.submitDifficulty(WorkoutDifficulty.hard);

    verify(() => mockFeedbackRepo.save(
          sessionId: 7,
          goalId: 1,
          completedEpochDay: today,
          difficulty: WorkoutDifficulty.hard,
        )).called(1);

    expect(container.read(pendingFeedbackProvider), isNull);

    subscription.close();
  });

  test('dismissing feedback records nothing', () async {
    final today = currentLocalEpochDay();
    final session = createSession(id: 7, dueEpochDay: today, checked: [true]);

    when(() => mockWorkoutRepo.observeCurrentWorkout())
        .thenAnswer((_) => Stream.value(session));
    when(() => mockWorkoutRepo.completeWorkout(7, today))
        .thenAnswer((_) => Future.value(CompleteWorkoutResult.completed));

    final container = createContainer();
    final subscription =
        container.listen(todayNotifierProvider, (prev, next) {});
    await Future.delayed(const Duration(milliseconds: 50));

    final notifier = container.read(todayNotifierProvider.notifier);
    await notifier.completeWorkout();

    expect(container.read(pendingFeedbackProvider), isNotNull);

    notifier.dismissFeedback();
    expect(container.read(pendingFeedbackProvider), isNull);
    verifyNever(() => mockFeedbackRepo.save(
          sessionId: any(named: 'sessionId'),
          goalId: any(named: 'goalId'),
          completedEpochDay: any(named: 'completedEpochDay'),
          difficulty: any(named: 'difficulty'),
        ));

    subscription.close();
  });

  test('feedback save failure keeps request open with retry message', () async {
    final today = currentLocalEpochDay();
    final session = createSession(id: 7, dueEpochDay: today, checked: [true]);

    when(() => mockWorkoutRepo.observeCurrentWorkout())
        .thenAnswer((_) => Stream.value(session));
    when(() => mockWorkoutRepo.completeWorkout(7, today))
        .thenAnswer((_) => Future.value(CompleteWorkoutResult.completed));
    when(() => mockFeedbackRepo.save(
          sessionId: any(named: 'sessionId'),
          goalId: any(named: 'goalId'),
          completedEpochDay: any(named: 'completedEpochDay'),
          difficulty: any(named: 'difficulty'),
        )).thenThrow(Exception("Disk write error"));

    final container = createContainer();
    final subscription =
        container.listen(todayNotifierProvider, (prev, next) {});
    await Future.delayed(const Duration(milliseconds: 50));

    final notifier = container.read(todayNotifierProvider.notifier);
    await notifier.completeWorkout();

    await notifier.submitDifficulty(WorkoutDifficulty.right);

    final pending = container.read(pendingFeedbackProvider);
    expect(pending, isNotNull);
    expect(pending!.saving, isFalse);
    expect(pending.error, contains("thử lại"));

    subscription.close();
  });

  test('checkbox error stays inline and retry clears after flow truth',
      () async {
    final today = currentLocalEpochDay();
    final session = createSession(id: 7, dueEpochDay: today, checked: [false]);

    final workoutController = StreamController<WorkoutSession?>();
    when(() => mockWorkoutRepo.observeCurrentWorkout())
        .thenAnswer((_) => workoutController.stream);
    when(() => mockWorkoutRepo.setExerciseChecked(7, 0, true))
        .thenThrow(Exception("Database locked"));

    final container = createContainer();
    final subscription =
        container.listen(todayNotifierProvider, (prev, next) {});

    workoutController.add(session);
    await Future.delayed(const Duration(milliseconds: 50));

    final notifier = container.read(todayNotifierProvider.notifier);
    await notifier.setChecked(0, true);

    final state1 = container.read(todayNotifierProvider);
    expect(state1, isA<TodayUiStateWorkout>());
    var workoutState = state1 as TodayUiStateWorkout;
    expect(workoutState.interactionError, isNotNull);

    // Clear error on next successful check
    when(() => mockWorkoutRepo.setExerciseChecked(7, 0, true))
        .thenAnswer((_) => Future.value());
    await notifier.setChecked(0, true);

    final state2 = container.read(todayNotifierProvider);
    expect(state2, isA<TodayUiStateWorkout>());
    workoutState = state2 as TodayUiStateWorkout;
    expect(workoutState.interactionError, isNull);

    subscription.close();
    workoutController.close();
  });
}
