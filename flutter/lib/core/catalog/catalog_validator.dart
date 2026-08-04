import '../model/catalog_models.dart';
import '../model/movement_block_models.dart';

class CatalogValidator {
  static final _validId = RegExp(r'^[a-z0-9_]+$');

  static List<String> validateMovementBlocks(List<MovementBlock> blocks) {
    final issues = <String>[];

    final idCounts = <String, int>{};
    for (var b in blocks) {
      idCounts[b.id] = (idCounts[b.id] ?? 0) + 1;
    }
    final duplicateIds =
        idCounts.entries.where((e) => e.value > 1).map((e) => e.key).toList()
          ..sort();

    for (var id in duplicateIds) {
      issues.add("Duplicate movement block id: $id");
    }

    for (var block in blocks) {
      if (!_validId.hasMatch(block.id)) {
        issues.add("Movement block id '${block.id}' must match [a-z0-9_]+");
      }
      if (block.titleVi.trim().isEmpty) {
        issues.add("Movement block '${block.id}' has blank titleVi");
      }
      if (block.movementPatterns.isEmpty) {
        issues.add(
          "Movement block '${block.id}' movementPatterns must not be empty",
        );
      }
      if (block.stepsVi.length < 2 || block.stepsVi.length > 6) {
        issues.add(
          "Movement block '${block.id}' stepsVi must contain 2..6 items",
        );
      }
      if (block.stepsVi.any((s) => s.trim().isEmpty)) {
        issues.add("Movement block '${block.id}' has a blank step");
      }
      if (block.estimatedMinutes < 2 || block.estimatedMinutes > 10) {
        issues.add(
          "Movement block '${block.id}' estimatedMinutes must be in 2..10",
        );
      }
    }
    return issues;
  }

  static List<String> validateExercises(List<ExerciseDefinition> exercises) {
    final issues = <String>[];
    final exercisesById = {for (var e in exercises) e.id: e};

    final idCounts = <String, int>{};
    for (var e in exercises) {
      idCounts[e.id] = (idCounts[e.id] ?? 0) + 1;
    }
    final duplicateIds =
        idCounts.entries.where((e) => e.value > 1).map((e) => e.key).toList()
          ..sort();

    for (var id in duplicateIds) {
      issues.add("Duplicate exercise id: $id");
    }

    for (var exercise in exercises) {
      if (!_validId.hasMatch(exercise.id)) {
        issues.add("Exercise id '${exercise.id}' must match [a-z0-9_]+");
      }
      final animationId = exercise.animationId;
      if (animationId != null && !_validId.hasMatch(animationId)) {
        issues.add(
          "Exercise '${exercise.id}' animationId must match [a-z0-9_]+",
        );
      }
      if (exercise.sourceId.trim().isEmpty) {
        issues.add("Exercise '${exercise.id}' has blank sourceId");
      }
      if (exercise.nameVi.trim().isEmpty) {
        issues.add("Exercise '${exercise.id}' has blank nameVi");
      }
      if (exercise.instructionsVi.length < 2 ||
          exercise.instructionsVi.length > 5) {
        issues.add(
          "Exercise '${exercise.id}' instructionsVi must contain 2..5 items",
        );
      }
      if (exercise.instructionsVi.any((s) => s.trim().isEmpty)) {
        issues.add("Exercise '${exercise.id}' has a blank instruction");
      }
      if (exercise.equipment.isEmpty) {
        issues.add("Exercise '${exercise.id}' must declare equipment");
      }

      final subCounts = <String, int>{};
      for (var sub in exercise.substituteIds) {
        subCounts[sub] = (subCounts[sub] ?? 0) + 1;
      }
      final duplicateSubs =
          subCounts.entries.where((e) => e.value > 1).map((e) => e.key).toList()
            ..sort();

      for (var duplicate in duplicateSubs) {
        issues.add(
          "Exercise '${exercise.id}' has duplicate substitute '$duplicate'",
        );
      }

      final uniqueSubs = exercise.substituteIds.toSet();
      for (var substituteId in uniqueSubs) {
        if (substituteId == exercise.id) {
          issues.add("Exercise '${exercise.id}' cannot substitute itself");
        } else if (!exercisesById.containsKey(substituteId)) {
          issues.add(
            "Exercise '${exercise.id}': Unknown substitute '$substituteId'",
          );
        } else {
          final subDefinition = exercisesById[substituteId]!;
          if (subDefinition.primaryMuscleGroup != exercise.primaryMuscleGroup) {
            issues.add(
              "Exercise '${exercise.id}' substitute '$substituteId' must use the same primary muscle",
            );
          }
          if (subDefinition.movementPattern != exercise.movementPattern) {
            issues.add(
              "Exercise '${exercise.id}' substitute '$substituteId' must use the same movement pattern",
            );
          }
        }
      }
    }

    return issues;
  }

  static List<String> validatePrograms(
    List<ProgramTemplate> programs,
    Map<String, ExerciseDefinition> exercisesById,
  ) {
    final issues = <String>[];

    final idCounts = <String, int>{};
    for (var p in programs) {
      idCounts[p.id] = (idCounts[p.id] ?? 0) + 1;
    }
    final duplicateIds =
        idCounts.entries.where((e) => e.value > 1).map((e) => e.key).toList()
          ..sort();

    for (var id in duplicateIds) {
      issues.add("Duplicate program id: $id");
    }

    final keyCounts = <String, int>{};
    for (var p in programs) {
      final key =
          "${p.goal.name}_${p.level.name}_${p.equipmentProfile.name}_${p.sessionsPerWeek}_${p.durationWeeks}";
      keyCounts[key] = (keyCounts[key] ?? 0) + 1;
    }
    final duplicateKeys = keyCounts.entries
        .where((e) => e.value > 1)
        .map((e) => e.key)
        .toList();
    for (var key in duplicateKeys) {
      issues.add("Duplicate program match key: ${key.split('_').join(', ')}");
    }

    for (var program in programs) {
      if (program.id.trim().isEmpty) {
        issues.add("Program has blank id");
      }
      if (program.sessionsPerWeek < 1 || program.sessionsPerWeek > 7) {
        issues.add("Program '${program.id}' sessionsPerWeek must be in 1..7");
      }
      if (program.durationWeeks < 1 || program.durationWeeks > 52) {
        issues.add("Program '${program.id}' durationWeeks must be in 1..52");
      }

      final expectedWorkoutCount =
          program.sessionsPerWeek * program.durationWeeks;
      if (program.workouts.length != expectedWorkoutCount) {
        issues.add(
          "Program '${program.id}' workouts.size must be $expectedWorkoutCount",
        );
      }

      final sequences = program.workouts.map((w) => w.sequence).toList()
        ..sort();
      final expectedSequences = List.generate(
        program.workouts.length,
        (i) => i,
      );

      bool contiguous = true;
      if (sequences.length != expectedSequences.length) {
        contiguous = false;
      } else {
        for (var i = 0; i < sequences.length; i++) {
          if (sequences[i] != expectedSequences[i]) {
            contiguous = false;
            break;
          }
        }
      }
      if (!contiguous) {
        issues.add(
          "Program '${program.id}' sequences must be contiguous starting at 0",
        );
      }

      for (var workout in program.workouts) {
        final workoutLabel =
            "Program '${program.id}' workout ${workout.sequence}";
        if (workout.titleVi.trim().isEmpty) {
          issues.add("$workoutLabel has blank titleVi");
        }
        if (workout.focusVi.trim().isEmpty) {
          issues.add("$workoutLabel has blank focusVi");
        }
        if (workout.exercises.isEmpty) {
          issues.add("$workoutLabel must contain exercises");
        }
        if (workout.week < 1 || workout.week > program.durationWeeks) {
          issues.add(
            "$workoutLabel week must be in 1..${program.durationWeeks}",
          );
        }
        if (workout.estimatedMinutes < 10 || workout.estimatedMinutes > 90) {
          issues.add("$workoutLabel estimatedMinutes must be in 10..90");
        }
        if (workout.restDaysAfter < 0 || workout.restDaysAfter > 3) {
          issues.add("$workoutLabel restDaysAfter must be in 0..3");
        }

        for (var i = 0; i < workout.exercises.length; i++) {
          final prescription = workout.exercises[i];
          final exerciseLabel = "$workoutLabel exercise $i";

          if (!exercisesById.containsKey(prescription.exerciseId)) {
            issues.add(
              "$exerciseLabel: Unknown exercise '${prescription.exerciseId}'",
            );
          }
          if (prescription.sets < 1 || prescription.sets > 6) {
            issues.add("$exerciseLabel sets must be in 1..6");
          }
          if (prescription.restSeconds < 15 || prescription.restSeconds > 300) {
            issues.add("$exerciseLabel restSeconds must be in 15..300");
          }

          final validReps =
              prescription.minReps != null &&
              prescription.maxReps != null &&
              prescription.minReps! >= 1 &&
              prescription.minReps! <= 50 &&
              prescription.maxReps! >= prescription.minReps! &&
              prescription.maxReps! <= 100 &&
              prescription.durationSeconds == null;

          final validDuration =
              prescription.durationSeconds != null &&
              prescription.durationSeconds! >= 10 &&
              prescription.durationSeconds! <= 3600 &&
              prescription.minReps == null &&
              prescription.maxReps == null;

          if (validReps == validDuration) {
            issues.add(
              "$exerciseLabel prescription must use exactly one valid reps or duration mode",
            );
          }
        }
      }

      for (var week = 1; week <= program.durationWeeks; week++) {
        final weeklyWorkouts = program.workouts
            .where((w) => w.week == week)
            .toList();
        if (weeklyWorkouts.length != program.sessionsPerWeek) {
          issues.add(
            "Program '${program.id}' week $week must contain ${program.sessionsPerWeek} workouts",
          );
        }

        final totalDays =
            weeklyWorkouts.length +
            weeklyWorkouts.fold<int>(0, (sum, w) => sum + w.restDaysAfter);
        if (totalDays != 7) {
          issues.add(
            "Program '${program.id}' week $week weekly schedule must total 7 days",
          );
        }
      }
    }
    return issues;
  }
}
