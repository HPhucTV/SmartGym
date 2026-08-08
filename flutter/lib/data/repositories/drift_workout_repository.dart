import 'dart:async';
import 'dart:math' as math;
import 'package:drift/drift.dart';
import '../local/database.dart' as db;
import '../local/daos/workout_dao.dart';
import 'workout_repository.dart';
import 'settings_repository.dart';
import '../../../core/model/achievement_models.dart';
import '../../../core/model/goal_models.dart';
import '../../../core/model/workout_models.dart';
import '../../../core/model/catalog_models.dart';
import '../../../core/program/training_schedule.dart';
import '../../../core/program/adaptive_program_planner.dart';
import '../../../core/program/schedule_planner.dart';
import '../../../core/program/schedule_rescheduler.dart';
import '../../../core/program/session_time_budget_planner.dart';
import '../../../core/catalog/exercise_substitution_engine.dart';

Stream<R> combineLatest2<A, B, R>(
  Stream<A> streamA,
  Stream<B> streamB,
  R Function(A, B) combiner,
) {
  StreamController<R>? controller;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;

  A? lastA;
  B? lastB;
  bool hasA = false;
  bool hasB = false;
  bool isDoneA = false;
  bool isDoneB = false;

  void update() {
    if (hasA && hasB) {
      controller?.add(combiner(lastA as A, lastB as B));
    }
  }

  void checkDone() {
    if (isDoneA && isDoneB) {
      if (controller != null && !controller.isClosed) {
        controller.close();
      }
    }
  }

  controller = StreamController<R>(
    onListen: () {
      subA = streamA.listen(
        (a) {
          lastA = a;
          hasA = true;
          update();
        },
        onError: controller?.addError,
        onDone: () {
          isDoneA = true;
          checkDone();
        },
      );
      subB = streamB.listen(
        (b) {
          lastB = b;
          hasB = true;
          update();
        },
        onError: controller?.addError,
        onDone: () {
          isDoneB = true;
          checkDone();
        },
      );
    },
    onCancel: () async {
      await subA?.cancel();
      subA = null;
      await subB?.cancel();
      subB = null;
    },
  );

  return controller.stream;
}

class DriftWorkoutRepository implements WorkoutRepository {
  final db.GymDatabase database;
  final List<ExerciseDefinition> Function() exercisesProvider;
  final SettingsRepository? settingsRepository;
  final int Function() currentEpochDay;

  DriftWorkoutRepository({
    required this.database,
    required this.exercisesProvider,
    this.settingsRepository,
    required this.currentEpochDay,
  });

  WorkoutDao get dao => database.workoutDao;

  Map<String, ExerciseDefinition> get _exercisesMap {
    return {for (var ex in exercisesProvider()) ex.id: ex};
  }

  @override
  Stream<ActiveGoal?> observeActiveGoal() {
    return dao.observeActiveGoal().map((row) {
      if (row == null) return null;
      final goalEntity = row.goal;

      final goalsList = goalEntity.goalsCsv.isEmpty
          ? [goalEntity.goal]
          : goalEntity.goalsCsv.split(',').map((name) {
              return FitnessGoal.values.firstWhere(
                (e) =>
                    e.name.toUpperCase() == name.toUpperCase() ||
                    e.toString().split('.').last.toUpperCase() ==
                        name.toUpperCase(),
                orElse: () => FitnessGoal.generalFitness,
              );
            }).toList();

      return ActiveGoal(
        id: goalEntity.id,
        config: GoalConfig(
          goal: goalEntity.goal,
          goals: goalsList,
          gender: goalEntity.gender,
          bodyType: goalEntity.bodyType,
          level: goalEntity.level,
          equipmentProfile: goalEntity.equipmentProfile,
          sessionsPerWeek: goalEntity.sessionsPerWeek,
          durationWeeks: goalEntity.durationWeeks,
          restDayMode: goalEntity.restDayMode,
          trainingDays: trainingDaysFromMask(goalEntity.trainingDaysMask),
          sessionDurationMinutes: goalEntity.sessionDurationMinutes,
        ),
        totalWorkouts: row.totalWorkouts,
      );
    });
  }

  @override
  Stream<WorkoutSession?> observeCurrentWorkout() {
    final sessionFlow = dao.observeCurrentSession();
    final settingsFlow = settingsRepository != null
        ? settingsRepository!.settings
        : Stream.value(const Settings());
    return combineLatest2(sessionFlow, settingsFlow, (session, settings) {
      return session != null ? _toDomain(session, settings.soreMuscles) : null;
    });
  }

  @override
  Stream<List<CompletedWorkout>> observeCompletedWorkouts() {
    return dao.observeCompletedSessions().map((rows) {
      return rows
          .map((r) => CompletedWorkout(
              goalId: r.goalId, completedEpochDay: r.completedEpochDay))
          .toList();
    });
  }

  @override
  Stream<List<WorkoutHistoryEntry>> observeWorkoutHistory() {
    return dao.observeWorkoutHistory().map((rows) {
      return rows.map((row) {
        return WorkoutHistoryEntry(
          sessionId: row.id,
          goalId: row.goalId,
          sequenceIndex: row.sequenceIndex,
          dueEpochDay: row.dueEpochDay,
          completedEpochDay: row.completedEpochDay,
          estimatedMinutes: row.estimatedMinutes,
          selectedTimeBudgetMinutes: row.selectedTimeBudgetMinutes,
        );
      }).toList();
    });
  }

  @override
  Future<void> createGoal(
      GoalConfig config, ProgramTemplate program, int startEpochDay) async {
    _validateProgramMatch(config, program);
    TrainingSchedule.validate(
        config.trainingDays, config.sessionDurationMinutes);
    final orderedWorkouts = AdaptiveProgramPlanner.adapt(program, config);

    final expectedSequences = List.generate(orderedWorkouts.length, (i) => i);
    final actualSequences = orderedWorkouts.map((w) => w.sequence).toList();
    if (actualSequences.toString() != expectedSequences.toString()) {
      throw ArgumentError(
          'Program workouts must use contiguous sequence values starting at zero');
    }

    final dueEpochDays = SchedulePlanner.dueEpochDaysFromWeekdays(
      startEpochDay: startEpochDay,
      trainingDays: config.trainingDays.map((d) => d.value).toSet(),
      workoutCount: orderedWorkouts.length,
    );

    await database.transaction(() async {
      await dao.archiveActiveGoals();
      final goalId = await dao.insertGoal(db.GoalsCompanion(
        programId: Value(program.id),
        goal: Value(config.goal),
        goalsCsv: Value(config.goals.map((g) => g.name).join(',')),
        gender: Value(config.gender),
        bodyType: Value(config.bodyType),
        level: Value(config.level),
        equipmentProfile: Value(config.equipmentProfile),
        sessionsPerWeek: Value(config.sessionsPerWeek),
        durationWeeks: Value(config.durationWeeks),
        restDayMode: Value(config.restDayMode),
        trainingDaysMask: Value(trainingDaysMask(config.trainingDays)),
        sessionDurationMinutes: Value(config.sessionDurationMinutes),
        createdEpochDay: Value(startEpochDay),
        archived: const Value(false),
      ));

      final sessionCompanions = orderedWorkouts.asMap().entries.map((entry) {
        final index = entry.key;
        final workout = entry.value;
        return db.WorkoutSessionsCompanion(
          goalId: Value(goalId),
          sequenceIndex: Value(workout.sequence),
          titleVi: Value(workout.titleVi),
          focusVi: Value(workout.focusVi),
          estimatedMinutes: Value(workout.estimatedMinutes),
          dueEpochDay: Value(dueEpochDays[index]),
        );
      }).toList();

      final sessionIds = await dao.insertSessions(sessionCompanions);

      final exerciseCompanions = <db.SessionExercisesCompanion>[];
      for (int i = 0; i < orderedWorkouts.length; i++) {
        final workout = orderedWorkouts[i];
        final sessionId = sessionIds[i];
        for (int exerciseIndex = 0;
            exerciseIndex < workout.exercises.length;
            exerciseIndex++) {
          final prescription = workout.exercises[exerciseIndex];
          exerciseCompanions.add(db.SessionExercisesCompanion(
            sessionId: Value(sessionId),
            orderIndex: Value(exerciseIndex),
            exerciseId: Value(prescription.exerciseId),
            sets: Value(prescription.sets),
            minReps: Value(prescription.minReps),
            maxReps: Value(prescription.maxReps),
            durationSeconds: Value(prescription.durationSeconds),
            restSeconds: Value(prescription.restSeconds),
          ));
        }
      }

      if (exerciseCompanions.isNotEmpty) {
        await dao.insertExercises(exerciseCompanions);
      }
    });
  }

  @override
  Future<void> setExerciseChecked(
      int sessionId, int orderIndex, bool checked) async {
    await dao.setCurrentExerciseChecked(sessionId, orderIndex, checked);
  }

  @override
  Future<ExerciseSubstitutionResult> substituteExercise({
    required int sessionId,
    required int orderIndex,
    required String replacementExerciseId,
  }) async {
    return database.transaction(() async {
      final currentSessionId = await dao.getCurrentSessionId();
      if (currentSessionId != sessionId) {
        return ExerciseSubstitutionResult.staleSession;
      }

      final exercises = await dao.getExercisesForSession(sessionId);
      final row = exercises.firstWhere(
        (e) => e.orderIndex == orderIndex,
        orElse: () => throw StateError('Exercise not found'),
      );

      if (row.isChecked) return ExerciseSubstitutionResult.alreadyChecked;

      final session = await dao.getSession(sessionId);
      if (session == null) return ExerciseSubstitutionResult.staleSession;

      final goal = await dao.getGoal(session.goalId);
      if (goal == null) return ExerciseSubstitutionResult.staleSession;

      final profile = goal.equipmentProfile;
      final originalId = row.originalExerciseId ?? row.exerciseId;

      final substitutionEngine =
          ExerciseSubstitutionEngine(exercisesProvider());
      final validCandidates =
          substitutionEngine.findSubstitutionCandidates(originalId, profile);
      final validIds = validCandidates.map((ex) => ex.id).toSet();

      if (row.originalExerciseId != null) {
        validIds.add(originalId);
      }

      if (!validIds.contains(replacementExerciseId)) {
        return ExerciseSubstitutionResult.invalidCandidate;
      }

      final updated = await dao.substituteCurrentExercise(
        sessionId: sessionId,
        orderIndex: orderIndex,
        replacementExerciseId: replacementExerciseId,
      );

      return updated == 1
          ? ExerciseSubstitutionResult.applied
          : ExerciseSubstitutionResult.staleSession;
    });
  }

  @override
  Future<TimeBudgetResult> applyTimeBudget(int sessionId, int? minutes) async {
    return database.transaction(() async {
      final currentSessionId = await dao.getCurrentSessionId();
      if (currentSessionId != sessionId) {
        return TimeBudgetResult.staleSession;
      }
      final session = await dao.getSession(sessionId);
      if (session == null) {
        return TimeBudgetResult.staleSession;
      }
      final checkedCount = await dao.countChecked(sessionId);
      if (checkedCount > 0) {
        return TimeBudgetResult.hasCheckedExercises;
      }
      if (minutes != null &&
          minutes != 15 &&
          minutes != 30 &&
          minutes != 45 &&
          minutes != session.estimatedMinutes) {
        return TimeBudgetResult.invalidBudget;
      }

      await dao.updateSelectedTimeBudget(sessionId, minutes);
      if (minutes == null || minutes >= session.estimatedMinutes) {
        await dao.setAllExercisesOmittedByTimeBudget(sessionId, false);
      } else {
        final rows = await dao.getExercisesForSession(sessionId);
        rows.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

        final selection = SessionTimeBudgetPlanner.select(
          rows.map((row) {
            return ExercisePrescription(
              exerciseId: row.exerciseId,
              sets: scaledSets(row.sets, session.volumeScalePercent),
              minReps: row.minReps,
              maxReps: row.maxReps,
              durationSeconds: row.durationSeconds,
              restSeconds: row.restSeconds,
            );
          }).toList(),
          minutes,
        );

        await dao.setAllExercisesOmittedByTimeBudget(sessionId, true);
        await dao.activateExercisesForTimeBudget(
          sessionId,
          selection.activeOrderIndices.map((i) => rows[i].orderIndex).toList(),
        );
      }
      return TimeBudgetResult.applied;
    });
  }

  @override
  Future<ScheduleChangePreview> previewScheduleChange(
      int sessionId, int newEpochDay) async {
    return database.transaction(() async {
      final currentSessionId = await dao.getCurrentSessionId();
      if (currentSessionId != sessionId) {
        throw ArgumentError(
            'Only the current pending session can be rescheduled');
      }
      final session = await dao.getSession(sessionId);
      if (session == null) {
        throw ArgumentError('Unknown session $sessionId');
      }
      final goal = await dao.getGoal(session.goalId);
      if (goal == null) {
        throw ArgumentError('Unknown goal ${session.goalId}');
      }

      final sessions = await dao.getSessionsForGoal(session.goalId);
      final reschedulableList = sessions.map((row) {
        return ReschedulableSession(
          sessionId: row.id,
          sequenceIndex: row.sequenceIndex,
          dueEpochDay: row.dueEpochDay,
          completedEpochDay: row.completedEpochDay,
          demanding: row.estimatedMinutes >= 30,
        );
      }).toList();

      return ScheduleRescheduler.preview(
        sessions: reschedulableList,
        selectedSessionId: sessionId,
        newEpochDay: newEpochDay,
        todayEpochDay: currentEpochDay(),
        trainingDays: trainingDaysFromMask(goal.trainingDaysMask),
      );
    });
  }

  @override
  Future<ScheduleChangeResult> applyScheduleChange(
      ScheduleChangePreview preview) async {
    return database.transaction(() async {
      if (preview.changes.isEmpty) return ScheduleChangeResult.stale;
      final first = preview.changes.first;
      final currentSessionId = await dao.getCurrentSessionId();
      if (currentSessionId != first.sessionId) {
        return ScheduleChangeResult.stale;
      }

      bool unchanged = true;
      for (final change in preview.changes) {
        final row = await dao.getSession(change.sessionId);
        if (row == null ||
            row.completedEpochDay != null ||
            row.dueEpochDay != change.oldEpochDay) {
          unchanged = false;
          break;
        }
      }
      if (!unchanged) return ScheduleChangeResult.stale;

      for (final change in preview.changes) {
        await dao.updateSessionDueEpochDay(
            change.sessionId, change.newEpochDay);
      }
      return ScheduleChangeResult.applied;
    });
  }

  @override
  Future<CompleteWorkoutResult> completeWorkout(
      int sessionId, int completedEpochDay) async {
    return database.transaction(() async {
      final session = await dao.getSession(sessionId);
      if (session == null || session.completedEpochDay != null) {
        return CompleteWorkoutResult.alreadyCompleted;
      }
      final currentSessionId = await dao.getCurrentSessionId();
      if (currentSessionId != sessionId) {
        return CompleteWorkoutResult.alreadyCompleted;
      }
      final uncheckedCount = await dao.countUnchecked(sessionId);
      if (uncheckedCount > 0) {
        return CompleteWorkoutResult.blockedByUncheckedExercises;
      }
      final completed =
          await dao.completeSessionIfIncomplete(sessionId, completedEpochDay);
      if (completed == 0) {
        return CompleteWorkoutResult.alreadyCompleted;
      }

      final delayDays = completedEpochDay - session.dueEpochDay;
      if (delayDays != 0) {
        final laterSessions = await dao.getSessionsForGoal(session.goalId);
        final filteredLater = laterSessions
            .where((s) =>
                s.sequenceIndex > session.sequenceIndex &&
                s.completedEpochDay == null)
            .toList();
        filteredLater
            .sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex));

        final activeGoal = await dao.getGoal(session.goalId);
        final trainingDays = activeGoal != null
            ? trainingDaysFromMask(activeGoal.trainingDaysMask)
            : <WeekDay>{};

        if (filteredLater.isNotEmpty && trainingDays.isNotEmpty) {
          final newDueDates = SchedulePlanner.dueEpochDaysFromWeekdays(
            startEpochDay: completedEpochDay + 1,
            trainingDays: trainingDays.map((d) => d.value).toSet(),
            workoutCount: filteredLater.length,
          );

          final updatedSessions = <db.WorkoutSession>[];
          for (int i = 0; i < filteredLater.length; i++) {
            updatedSessions
                .add(filteredLater[i].copyWith(dueEpochDay: newDueDates[i]));
          }
          await dao.updateSessions(updatedSessions);
        }
      }

      return CompleteWorkoutResult.completed;
    });
  }

  @override
  Future<void> archiveActiveGoal() async {
    await database.transaction(() async {
      await dao.archiveActiveGoals();
    });
  }

  @override
  Future<Set<AchievementType>> unlockedAchievements() async {
    final rows = await database.achievementDao.getAll();
    final storedNames = rows.map((row) => row.type).toSet();
    return AchievementType.values
        .where((type) => storedNames.contains(type.name))
        .toSet();
  }

  @override
  Future<void> recordUnlockedAchievements(
      Set<AchievementType> types, int unlockedAtEpochMillis) async {
    if (types.isEmpty) return;
    await database.transaction(() async {
      for (final type in types) {
        await database.achievementDao.insert(
          db.AchievementsCompanion.insert(
            type: type.name,
            unlockedAtEpochMillis: unlockedAtEpochMillis,
          ),
        );
      }
    });
  }

  void _validateProgramMatch(GoalConfig config, ProgramTemplate program) {
    if (program.goal != config.goal) {
      throw ArgumentError('Program goal does not match goal configuration');
    }
    if (program.level != config.level) {
      throw ArgumentError('Program level does not match goal configuration');
    }
    if (program.equipmentProfile != config.equipmentProfile) {
      throw ArgumentError(
          'Program equipment does not match goal configuration');
    }
    if (program.durationWeeks != config.durationWeeks) {
      throw ArgumentError('Program duration does not match goal configuration');
    }
  }

  WorkoutSession _toDomain(SessionWithExercises data, Set<String> soreMuscles) {
    final session = data.session;
    final exercises = data.exercises;

    final workoutExercises =
        exercises.where((e) => !e.omittedByTimeBudget).toList();
    workoutExercises.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final exercisesMap = _exercisesMap;

    return WorkoutSession(
      id: session.id,
      goalId: session.goalId,
      sequenceIndex: session.sequenceIndex,
      titleVi: session.titleVi,
      focusVi: session.focusVi,
      estimatedMinutes: session.estimatedMinutes,
      dueEpochDay: session.dueEpochDay,
      exercises: workoutExercises.map((exercise) {
        final definition = exercisesMap[exercise.exerciseId];
        final isSore = definition != null &&
            soreMuscles.contains(definition.primaryMuscleGroup.name);

        final int baseSets = session.completedEpochDay == null
            ? scaledSets(exercise.sets, session.volumeScalePercent)
            : exercise.sets;

        final int finalSets = (session.completedEpochDay == null && isSore)
            ? math.max<int>(1, (baseSets * 0.5).round())
            : baseSets;

        return WorkoutExercise(
          orderIndex: exercise.orderIndex,
          exerciseId: exercise.exerciseId,
          originalExerciseId: exercise.originalExerciseId,
          prescription: ExercisePrescription(
            exerciseId: exercise.exerciseId,
            sets: finalSets,
            minReps: exercise.minReps,
            maxReps: exercise.maxReps,
            durationSeconds: exercise.durationSeconds,
            restSeconds: exercise.restSeconds,
          ),
          isChecked: exercise.isChecked,
          isLightWorkout: isSore && session.completedEpochDay == null,
        );
      }).toList(),
      selectedTimeBudgetMinutes: session.selectedTimeBudgetMinutes,
      omittedExerciseCount:
          exercises.where((e) => e.omittedByTimeBudget).length,
    );
  }
}

int scaledSets(int sets, int percent) {
  final clampedPercent = percent.clamp(1, 100);
  final scaled = (sets * clampedPercent / 100.0).floor();
  return scaled > 1 ? scaled : 1;
}
