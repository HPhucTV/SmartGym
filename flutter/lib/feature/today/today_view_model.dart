import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/model/goal_models.dart';
import '../../core/model/workout_models.dart';
import '../../core/model/catalog_models.dart';
import '../../core/model/feedback_models.dart';
import '../../core/model/movement_block_models.dart';
import '../../core/achievement/achievement_checker.dart';
import '../../core/model/achievement_models.dart';
import '../../core/catalog/exercise_substitution_engine.dart';
import '../../core/catalog/movement_block_planner.dart';
import '../../core/program/program_phase_planner.dart';
import '../../core/motivation/smart_coach_advisor.dart';
import '../../core/motivation/today_coach_coordinator.dart';
import '../../data/providers/data_providers.dart';
import '../../data/providers/remote_providers.dart';
import '../../data/remote/coach_review_client.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/repositories/settings_repository.dart';
import 'today_ui_state.dart';

class CelebrationState {
  final bool showConfetti;
  final List<AchievementType> unlockedAchievements;
  final String workoutTitle;
  final int completedExercises;
  final int totalExercises;

  const CelebrationState({
    this.showConfetti = false,
    this.unlockedAchievements = const [],
    this.workoutTitle = "",
    this.completedExercises = 0,
    this.totalExercises = 0,
  });
}

class CelebrationNotifier extends Notifier<CelebrationState> {
  @override
  CelebrationState build() => const CelebrationState();

  @override
  set state(CelebrationState value) => super.state = value;
}

// Celebration provider
final celebrationProvider =
    NotifierProvider<CelebrationNotifier, CelebrationState>(
      CelebrationNotifier.new,
    );

class PendingFeedbackNotifier extends Notifier<PendingWorkoutFeedback?> {
  @override
  PendingWorkoutFeedback? build() => null;

  @override
  set state(PendingWorkoutFeedback? value) => super.state = value;
}

// Pending feedback provider
final pendingFeedbackProvider =
    NotifierProvider<PendingFeedbackNotifier, PendingWorkoutFeedback?>(
      PendingFeedbackNotifier.new,
    );

// Cloud AI consent stream provider
final cloudAiConsentStreamProvider = StreamProvider<bool>((ref) {
  final db = ref.watch(gymDatabaseProvider);
  return db.personalizationDao.observeProfile().map(
    (p) => p?.cloudAiConsent == true,
  );
});

// Coach coordinator provider
final todayCoachCoordinatorProvider = Provider<TodayCoachCoordinator>((ref) {
  final client = ref.watch(coachReviewClientProvider);
  return TodayCoachCoordinator(client: client);
});

final activeGoalStreamProvider = StreamProvider<ActiveGoal?>((ref) {
  return ref.watch(workoutRepositoryProvider).observeActiveGoal();
});

final currentWorkoutStreamProvider = StreamProvider<WorkoutSession?>((ref) {
  return ref.watch(workoutRepositoryProvider).observeCurrentWorkout();
});

final settingsStreamProvider = StreamProvider<Settings>((ref) {
  return ref.watch(settingsRepositoryProvider).settings;
});

final nutritionDataStreamProvider = StreamProvider<NutritionData>((ref) {
  return ref.watch(nutritionRepositoryProvider).nutritionData;
});

class TodayNotifier extends Notifier<TodayUiState> {
  final Set<int> _pendingOrderIndices = {};
  int? _completingSessionId;
  String? _interactionError;
  String? _completionError;
  bool _isRefreshingCoach = false;

  ActiveGoal? _lastGoal;
  WorkoutSession? _lastSession;
  Settings? _lastSettings;
  NutritionData? _lastNutrition;

  @override
  TodayUiState build() {
    final activeGoalAsync = ref.watch(activeGoalStreamProvider);
    final currentWorkoutAsync = ref.watch(currentWorkoutStreamProvider);
    final settingsAsync = ref.watch(settingsStreamProvider);
    final nutritionDataAsync = ref.watch(nutritionDataStreamProvider);

    if (activeGoalAsync.hasError) {
      return TodayUiStateError(activeGoalAsync.error.toString());
    }
    if (currentWorkoutAsync.hasError) {
      return TodayUiStateError(currentWorkoutAsync.error.toString());
    }
    if (settingsAsync.hasError) {
      return TodayUiStateError(settingsAsync.error.toString());
    }
    if (nutritionDataAsync.hasError) {
      return TodayUiStateError(nutritionDataAsync.error.toString());
    }

    if (activeGoalAsync.isLoading ||
        currentWorkoutAsync.isLoading ||
        settingsAsync.isLoading ||
        nutritionDataAsync.isLoading) {
      return const TodayUiStateLoading();
    }

    _lastGoal = activeGoalAsync.value;
    _lastSession = currentWorkoutAsync.value;
    _lastSettings = settingsAsync.value;
    _lastNutrition = nutritionDataAsync.value;

    return _resolve();
  }

  TodayUiState _resolve() {
    try {
      final goal = _lastGoal;
      final session = _lastSession;
      final settings = _lastSettings;
      final nutrition = _lastNutrition ?? const NutritionData();
      final day = currentLocalEpochDay();

      if (_completionError != null) {
        return TodayUiStateError(_completionError!, canRetry: true);
      }
      if (goal == null) {
        return const TodayUiStateError(
          "Không tìm thấy mục tiêu đang hoạt động.",
        );
      }
      if (session == null) {
        return const TodayUiStateGoalComplete();
      }

      final isRecovery = session.dueEpochDay > day;

      final coachTip = nutrition.aiCoachReview?.isNotEmpty == true
          ? nutrition.aiCoachReview
          : SmartCoachAdvisor.getLocalAdvice(
              goal: goal.config.goal,
              completedToday: isRecovery,
              nutrition: nutrition,
              sessionTitle: session.titleVi,
            );

      if (isRecovery) {
        final restDayMode = settings?.restDayMode ?? goal.config.restDayMode;
        return TodayUiStateRecovery(
          kind: restDayMode == RestDayMode.fullRest
              ? RecoveryKind.fullRest
              : RecoveryKind.lightRecovery,
          nextDueEpochDay: session.dueEpochDay,
          coachTip: coachTip,
          isRefreshingCoach: _isRefreshingCoach,
        );
      }

      final catalog = ref
          .read(assetCatalogRepositoryProvider)
          .exercises
          .associateById();

      final rows = session.exercises.map((exercise) {
        final definition = catalog[exercise.exerciseId];
        if (definition == null) {
          throw StateError(
            "Không tìm thấy bài tập '${exercise.exerciseId}' trong dữ liệu.",
          );
        }

        final isSweatMatch =
            nutrition.sweatActive &&
            nutrition.sweatExerciseId == exercise.exerciseId;
        final finalPrescriptionText =
            (isSweatMatch && nutrition.sweatExtraSets > 0)
            ? "${exercise.prescription.displayText()} (+${nutrition.sweatExtraSets} hiệp bù calo 🔥)"
            : exercise.prescription.displayText();

        return WorkoutRowUi(
          orderIndex: exercise.orderIndex,
          nameVi: definition.nameVi,
          prescriptionText: finalPrescriptionText,
          restSeconds: exercise.prescription.restSeconds,
          instructionsVi: definition.instructionsVi,
          isChecked: exercise.isChecked,
          exerciseId: exercise.exerciseId,
          primaryMuscleGroup: definition.primaryMuscleGroup,
          originalExerciseId: exercise.originalExerciseId,
          isLightWorkout: exercise.isLightWorkout,
          animationId: definition.animationId,
        );
      }).toList();

      rows.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      final checked = rows.where((r) => r.isChecked).length;
      final activePatterns = rows
          .map((r) => catalog[r.exerciseId]!.movementPattern)
          .toSet();

      final movementBlocks = ref
          .read(assetCatalogRepositoryProvider)
          .movementBlocks;
      AdvisoryMovementBlockUi? warmUp;
      AdvisoryMovementBlockUi? coolDown;

      if (movementBlocks.isNotEmpty) {
        final selectedWarmUp = MovementBlockPlanner.select(
          movementBlocks,
          MovementBlockKind.warmUp,
          activePatterns,
        );
        warmUp = AdvisoryMovementBlockUi(
          id: selectedWarmUp.id,
          titleVi: selectedWarmUp.titleVi,
          stepsVi: selectedWarmUp.stepsVi,
          estimatedMinutes: selectedWarmUp.estimatedMinutes,
        );

        final selectedCoolDown = MovementBlockPlanner.select(
          movementBlocks,
          MovementBlockKind.coolDown,
          activePatterns,
        );
        coolDown = AdvisoryMovementBlockUi(
          id: selectedCoolDown.id,
          titleVi: selectedCoolDown.titleVi,
          stepsVi: selectedCoolDown.stepsVi,
          estimatedMinutes: selectedCoolDown.estimatedMinutes,
        );
      }

      final hour = DateTime.now().hour;
      final durationWeeks = goal.config.durationWeeks.clamp(1, 999);
      final week =
          (session.sequenceIndex ~/ goal.config.sessionsPerWeek.clamp(1, 999) +
                  1)
              .clamp(1, durationWeeks);
      final phase = ProgramPhasePlanner.phaseFor(week, durationWeeks);

      return TodayUiStateWorkout(
        sessionId: session.id,
        titleVi: session.titleVi,
        focusVi: session.focusVi,
        estimatedMinutes: session.estimatedMinutes,
        rows: rows,
        checkedCount: checked,
        total: rows.length,
        canComplete:
            rows.isNotEmpty &&
            checked == rows.length &&
            _pendingOrderIndices.isEmpty,
        isCompleting: _completingSessionId == session.id,
        pendingOrderIndices: Set.from(_pendingOrderIndices),
        interactionError: _interactionError,
        greetingHour: hour,
        coachTip: coachTip,
        isRefreshingCoach: _isRefreshingCoach,
        goalId: goal.id,
        phase: phase,
        selectedTimeBudgetMinutes: session.selectedTimeBudgetMinutes,
        omittedExerciseCount: session.omittedExerciseCount,
        canChangeTimeBudget:
            checked == 0 &&
            _pendingOrderIndices.isEmpty &&
            _completingSessionId == null,
        warmUp: warmUp,
        coolDown: coolDown,
        soreMuscles: settings?.soreMuscles ?? const {},
      );
    } catch (e) {
      return TodayUiStateError(e.toString());
    }
  }

  Future<void> toggleSoreMuscle(String muscleName) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final settings = _lastSettings;
    if (settings == null) return;

    final newSoreMuscles = settings.soreMuscles.contains(muscleName)
        ? settings.soreMuscles.where((m) => m != muscleName).toSet()
        : {...settings.soreMuscles, muscleName};

    await settingsRepo.setSoreMuscles(newSoreMuscles);
  }

  void refreshToday() {
    ref.invalidate(currentWorkoutStreamProvider);
  }

  Future<void> setChecked(int orderIndex, bool checked) async {
    final session = _lastSession;
    if (session == null) return;
    if (_completingSessionId == session.id ||
        _pendingOrderIndices.contains(orderIndex)) {
      return;
    }

    _pendingOrderIndices.add(orderIndex);
    _interactionError = null;
    state = _resolve();

    try {
      final repo = ref.read(workoutRepositoryProvider);
      await repo.setExerciseChecked(session.id, orderIndex, checked);
    } catch (e) {
      if (ref.mounted) {
        _interactionError = e.toString();
        state = _resolve();
      }
    } finally {
      if (ref.mounted) {
        _pendingOrderIndices.remove(orderIndex);
        state = _resolve();
      }
    }
  }

  void requestSubstitution(int orderIndex) {
    final session = _lastSession;
    final goal = _lastGoal;
    if (session == null || goal == null) return;

    final currentState = state;
    if (currentState is! TodayUiStateWorkout) return;

    final row = currentState.rows.firstWhere((r) => r.orderIndex == orderIndex);
    if (row.isChecked || _pendingOrderIndices.contains(orderIndex)) return;

    final exercises = ref.read(assetCatalogRepositoryProvider).exercises;
    final catalog = exercises.associateById();
    final profile = goal.config.equipmentProfile;
    final originalId = row.originalExerciseId ?? row.exerciseId;

    final substitutionEngine = ExerciseSubstitutionEngine(exercises);
    final candidates = <ExerciseDefinition>[];
    if (row.originalExerciseId != null && row.exerciseId != originalId) {
      final orig = catalog[originalId];
      if (orig != null) candidates.add(orig);
    }
    candidates.addAll(
      substitutionEngine
          .findSubstitutionCandidates(originalId, profile)
          .where((e) => e.id != row.exerciseId),
    );

    final distinctCandidates = candidates.distinctById().take(3).toList();

    if (distinctCandidates.isEmpty) {
      const message = "Không có bài thay thế phù hợp với thiết bị hiện tại.";
      _interactionError = message;
      state = currentState.copyWith(
        interactionError: message,
        substitution: null,
      );
      return;
    }

    _interactionError = null;
    state = currentState.copyWith(
      interactionError: null,
      substitution: ExerciseSubstitutionUi(
        orderIndex: orderIndex,
        currentNameVi: row.nameVi,
        candidates: distinctCandidates.map((c) {
          return ExerciseSubstitutionCandidateUi(
            exerciseId: c.id,
            nameVi: c.nameVi,
            equipment: c.equipment,
            instructionsVi: c.instructionsVi,
            restoresOriginal: c.id == row.originalExerciseId,
          );
        }).toList(),
      ),
    );
  }

  void dismissSubstitution() {
    final currentState = state;
    if (currentState is TodayUiStateWorkout) {
      state = currentState.copyWith(clearSubstitution: true);
    }
  }

  Future<void> applySubstitution(String replacementExerciseId) async {
    final currentState = state;
    if (currentState is! TodayUiStateWorkout) return;
    final dialog = currentState.substitution;
    if (dialog == null) return;
    if (dialog.candidates.none((c) => c.exerciseId == replacementExerciseId)) {
      return;
    }

    final orderIndex = dialog.orderIndex;
    final sessionId = currentState.sessionId;

    _pendingOrderIndices.add(orderIndex);
    _interactionError = null;
    state = currentState.copyWith(substitution: null);

    try {
      final repo = ref.read(workoutRepositoryProvider);
      final result = await repo.substituteExercise(
        sessionId: sessionId,
        orderIndex: orderIndex,
        replacementExerciseId: replacementExerciseId,
      );
      if (!ref.mounted) return;
      switch (result) {
        case ExerciseSubstitutionResult.applied:
          break;
        case ExerciseSubstitutionResult.invalidCandidate:
          _interactionError = "Bài thay thế không còn phù hợp.";
          break;
        case ExerciseSubstitutionResult.staleSession:
          _interactionError = "Buổi tập đã thay đổi. Vui lòng thử lại.";
          break;
        case ExerciseSubstitutionResult.alreadyChecked:
          _interactionError = "Bỏ đánh dấu hoàn thành trước khi thay bài.";
          break;
      }
    } catch (_) {
      if (ref.mounted) {
        _interactionError = "Không thể thay bài. Vui lòng thử lại.";
      }
    } finally {
      if (ref.mounted) {
        _pendingOrderIndices.remove(orderIndex);
        state = _resolve();
      }
    }
  }

  Future<void> applyTimeBudget(int? minutes) async {
    final currentState = state;
    if (currentState is! TodayUiStateWorkout) return;
    if (!currentState.canChangeTimeBudget ||
        currentState.selectedTimeBudgetMinutes == minutes) {
      return;
    }

    try {
      final repo = ref.read(workoutRepositoryProvider);
      final result = await repo.applyTimeBudget(
        currentState.sessionId,
        minutes,
      );
      if (!ref.mounted) return;
      switch (result) {
        case TimeBudgetResult.applied:
          break;
        case TimeBudgetResult.invalidBudget:
          _interactionError = "Thời lượng đã chọn không hợp lệ.";
          break;
        case TimeBudgetResult.hasCheckedExercises:
          _interactionError =
              "Không thể đổi thời lượng sau khi đã bắt đầu tập.";
          break;
        case TimeBudgetResult.staleSession:
          _interactionError = "Buổi tập đã thay đổi. Vui lòng thử lại.";
          break;
      }
    } catch (_) {
      if (ref.mounted) {
        _interactionError = "Không thể đổi thời lượng. Vui lòng thử lại.";
      }
    } finally {
      if (ref.mounted) {
        state = _resolve();
      }
    }
  }

  Future<void> completeWorkout() async {
    final currentState = state;
    if (currentState is! TodayUiStateWorkout) return;
    if (!currentState.canComplete ||
        _completingSessionId != null ||
        _pendingOrderIndices.isNotEmpty) {
      return;
    }
    await _complete(currentState.sessionId);
  }

  Future<void> retry() async {
    if (_completingSessionId != null) return;
    final session = _lastSession;
    if (session == null) return;
    await _complete(session.id);
  }

  Future<void> _complete(int sessionId) async {
    final currentState = state;
    final workoutTitle = currentState is TodayUiStateWorkout
        ? currentState.titleVi
        : "";
    final checkedCount = currentState is TodayUiStateWorkout
        ? currentState.checkedCount
        : 0;
    final total = currentState is TodayUiStateWorkout ? currentState.total : 0;

    _completingSessionId = sessionId;
    _completionError = null;
    state = _resolve();

    try {
      final completedEpochDay = currentLocalEpochDay();
      final repo = ref.read(workoutRepositoryProvider);
      final result = await repo.completeWorkout(sessionId, completedEpochDay);

      if (!ref.mounted) return;

      switch (result) {
        case CompleteWorkoutResult.completed:
          final activeGoal = _lastGoal;
          if (activeGoal != null) {
            ref
                .read(pendingFeedbackProvider.notifier)
                .state = PendingWorkoutFeedback(
              sessionId: sessionId,
              goalId: activeGoal.id,
              completedEpochDay: completedEpochDay,
            );
          }

          await ref.read(nutritionRepositoryProvider).clearSweatPayment();
          if (!ref.mounted) return;

          final completed = await repo.observeCompletedWorkouts().first;
          if (!ref.mounted) return;
          final activeGoalForAchievements = await repo
              .observeActiveGoal()
              .first;
          if (!ref.mounted) return;
          final totalSessions = activeGoalForAchievements?.totalWorkouts ?? 0;
          final targetPerWeek =
              activeGoalForAchievements?.config.sessionsPerWeek ?? 0;

          final checker = AchievementChecker();
          final newlyUnlockedBadges = activeGoalForAchievements == null
              ? <AchievementType>[]
              : checker.checkNewUnlocks(
                  completed: completed,
                  activeGoalId: activeGoalForAchievements.id,
                  totalProgramSessions: totalSessions,
                  targetPerWeek: targetPerWeek,
                  existing: {},
                );

          ref.read(celebrationProvider.notifier).state = CelebrationState(
            showConfetti: true,
            unlockedAchievements: newlyUnlockedBadges,
            workoutTitle: workoutTitle,
            completedExercises: checkedCount,
            totalExercises: total,
          );
          break;
        case CompleteWorkoutResult.alreadyCompleted:
          break;
        case CompleteWorkoutResult.blockedByUncheckedExercises:
          _interactionError = "Vẫn còn bài tập chưa được đánh dấu hoàn thành.";
          break;
      }
    } catch (e) {
      if (ref.mounted) {
        _completionError = "Không thể hoàn thành buổi tập. Vui lòng thử lại.";
      }
    } finally {
      if (ref.mounted) {
        if (_completingSessionId == sessionId) {
          _completingSessionId = null;
        }
        state = _resolve();
      }
    }
  }

  Future<void> refreshCoachTip() async {
    final goalConfig = _lastGoal?.config;
    final sessionTitle = _lastSession?.titleVi;
    final completedToday =
        _lastSession != null &&
        _lastSession!.dueEpochDay > currentLocalEpochDay();
    final nutrition = ref.read(nutritionRepositoryProvider);

    if (_isRefreshingCoach || goalConfig == null || sessionTitle == null) {
      return;
    }
    _isRefreshingCoach = true;
    state = _resolve();

    try {
      final nutritionData = await nutrition.nutritionData.first;
      if (!ref.mounted) return;
      final limit = _calorieLimitForGoal(goalConfig.goal);

      final localAdvice = SmartCoachAdvisor.getLocalAdvice(
        goal: goalConfig.goal,
        completedToday: completedToday,
        nutrition: nutritionData,
        sessionTitle: sessionTitle,
      );

      final request = CoachReviewRequest(
        goalVi: _goalTitleVi(goalConfig.goal),
        levelVi: _levelTitleVi(goalConfig.level),
        sessionTitle: sessionTitle,
        completedToday: completedToday,
        caloriesEaten: nutritionData.caloriesEaten,
        calorieLimit: limit,
        proteinEaten: nutritionData.proteinEaten,
        carbsEaten: nutritionData.carbsEaten,
        fatEaten: nutritionData.fatEaten,
        sweatActive: nutritionData.sweatActive,
        sweatExerciseName: nutritionData.sweatExerciseName ?? "",
        sweatExtraSets: nutritionData.sweatExtraSets,
      );

      final cloudConsent =
          ref.read(cloudAiConsentStreamProvider).value ?? false;
      final coordinator = ref.read(todayCoachCoordinatorProvider);

      final review = await coordinator.review(
        request: request,
        cloudAiConsent: cloudConsent,
        localFallback: localAdvice,
      );
      if (!ref.mounted) return;

      await nutrition.updateAiCoachReview(review);
    } catch (_) {
    } finally {
      if (ref.mounted) {
        _isRefreshingCoach = false;
        state = _resolve();
      }
    }
  }

  int _calorieLimitForGoal(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.muscleGain:
        return 2700;
      case FitnessGoal.fatLossConditioning:
        return 1800;
      case FitnessGoal.endurance:
        return 2200;
      case FitnessGoal.generalFitness:
        return 2000;
    }
  }

  String _goalTitleVi(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.muscleGain:
        return "Tăng cơ";
      case FitnessGoal.fatLossConditioning:
        return "Giảm cân";
      case FitnessGoal.endurance:
        return "Sức bền";
      case FitnessGoal.generalFitness:
        return "Khỏe mạnh";
    }
  }

  String _levelTitleVi(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return "Mới bắt đầu";
      case ExperienceLevel.intermediate:
        return "Trung cấp";
    }
  }

  void dismissCelebration() {
    ref.read(celebrationProvider.notifier).state = const CelebrationState();
  }

  void dismissFeedback() {
    final pending = ref.read(pendingFeedbackProvider);
    if (pending != null && !pending.saving) {
      ref.read(pendingFeedbackProvider.notifier).state = null;
    }
  }

  Future<void> submitDifficulty(WorkoutDifficulty difficulty) async {
    final pending = ref.read(pendingFeedbackProvider);
    if (pending == null || pending.saving) return;

    ref.read(pendingFeedbackProvider.notifier).state = pending.copyWith(
      saving: true,
      selectedDifficulty: difficulty,
      error: null,
    );

    try {
      final feedbackRepo = ref.read(workoutFeedbackRepositoryProvider);
      await feedbackRepo.save(
        sessionId: pending.sessionId,
        goalId: pending.goalId,
        completedEpochDay: pending.completedEpochDay,
        difficulty: difficulty,
      );
      ref.read(pendingFeedbackProvider.notifier).state = null;
    } catch (_) {
      ref.read(pendingFeedbackProvider.notifier).state = pending.copyWith(
        saving: false,
        selectedDifficulty: difficulty,
        error: "Không thể lưu đánh giá. Vui lòng thử lại.",
      );
    }
  }
}

final todayNotifierProvider = NotifierProvider<TodayNotifier, TodayUiState>(() {
  return TodayNotifier();
});

extension ExerciseDefinitionListExt on List<ExerciseDefinition> {
  Map<String, ExerciseDefinition> associateById() {
    return {for (final e in this) e.id: e};
  }
}

extension ExerciseDefinitionListDistinctExt on List<ExerciseDefinition> {
  List<ExerciseDefinition> distinctById() {
    final seen = <String>{};
    return where((e) => seen.add(e.id)).toList();
  }
}

extension ExercisePrescriptionExt on ExercisePrescription {
  String displayText() {
    if (durationSeconds != null) {
      return "$durationSeconds giây";
    }
    if (minReps != null && maxReps != null) {
      return minReps == maxReps
          ? "$sets × $minReps"
          : "$sets × $minReps–$maxReps";
    }
    return "$sets hiệp";
  }
}

extension IterableExt<T> on Iterable<T> {
  bool none(bool Function(T) test) {
    return !any(test);
  }
}
