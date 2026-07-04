package com.example.myapplication.core.catalog

import com.example.myapplication.core.model.ExerciseDefinition
import com.example.myapplication.core.model.ProgramTemplate

object CatalogValidator {
    private val validId = Regex("[a-z0-9_]+")

    fun validateExercises(exercises: List<ExerciseDefinition>): List<String> {
        val issues = mutableListOf<String>()
        val exercisesById = exercises.associateBy(ExerciseDefinition::id)

        exercises.groupingBy { it.id }
            .eachCount()
            .filterValues { it > 1 }
            .keys
            .sorted()
            .forEach { issues += "Duplicate exercise id: $it" }

        exercises.forEach { exercise ->
            if (!validId.matches(exercise.id)) {
                issues += "Exercise id '${exercise.id}' must match [a-z0-9_]+"
            }
            if (exercise.sourceId.isBlank()) {
                issues += "Exercise '${exercise.id}' has blank sourceId"
            }
            if (exercise.nameVi.isBlank()) {
                issues += "Exercise '${exercise.id}' has blank nameVi"
            }
            if (exercise.instructionsVi.size !in 2..5) {
                issues += "Exercise '${exercise.id}' instructionsVi must contain 2..5 items"
            }
            if (exercise.instructionsVi.any { it.isBlank() }) {
                issues += "Exercise '${exercise.id}' has a blank instruction"
            }
            if (exercise.equipment.isEmpty()) {
                issues += "Exercise '${exercise.id}' must declare equipment"
            }
            exercise.substituteIds.groupingBy { it }.eachCount()
                .filterValues { it > 1 }
                .keys
                .sorted()
                .forEach { duplicate ->
                    issues += "Exercise '${exercise.id}' has duplicate substitute '$duplicate'"
                }
            exercise.substituteIds.distinct().forEach { substituteId ->
                when {
                    substituteId == exercise.id -> {
                        issues += "Exercise '${exercise.id}' cannot substitute itself"
                    }
                    substituteId !in exercisesById -> {
                        issues += "Exercise '${exercise.id}': Unknown substitute '$substituteId'"
                    }
                    exercisesById.getValue(substituteId).primaryMuscle != exercise.primaryMuscle -> {
                        issues += "Exercise '${exercise.id}' substitute '$substituteId' must use the same primary muscle"
                    }
                    exercisesById.getValue(substituteId).movementPattern != exercise.movementPattern -> {
                        issues += "Exercise '${exercise.id}' substitute '$substituteId' must use the same movement pattern"
                    }
                }
            }
        }

        return issues
    }

    fun validatePrograms(
        programs: List<ProgramTemplate>,
        exercisesById: Map<String, ExerciseDefinition>,
    ): List<String> {
        val issues = mutableListOf<String>()
        programs.groupingBy { it.id }.eachCount().filterValues { it > 1 }.keys.sorted().forEach {
            issues += "Duplicate program id: $it"
        }
        programs.groupingBy {
            listOf(it.goal, it.level, it.equipmentProfile, it.sessionsPerWeek, it.durationWeeks)
        }.eachCount().filterValues { it > 1 }.keys.forEach {
            issues += "Duplicate program match key: ${it.joinToString()}"
        }
        programs.forEach { program ->
            if (program.id.isBlank()) issues += "Program has blank id"
            if (program.sessionsPerWeek !in 1..7) {
                issues += "Program '${program.id}' sessionsPerWeek must be in 1..7"
            }
            if (program.durationWeeks !in 1..52) {
                issues += "Program '${program.id}' durationWeeks must be in 1..52"
            }
            val expectedWorkoutCount = program.sessionsPerWeek * program.durationWeeks
            if (program.workouts.size != expectedWorkoutCount) issues += "Program '${program.id}' workouts.size must be $expectedWorkoutCount"
            if (program.workouts.map { it.sequence }.sorted() != (0 until program.workouts.size).toList()) {
                issues += "Program '${program.id}' sequences must be contiguous starting at 0"
            }
            program.workouts.forEach { workout ->
                val workoutLabel = "Program '${program.id}' workout ${workout.sequence}"
                if (workout.titleVi.isBlank()) issues += "$workoutLabel has blank titleVi"
                if (workout.focusVi.isBlank()) issues += "$workoutLabel has blank focusVi"
                if (workout.exercises.isEmpty()) issues += "$workoutLabel must contain exercises"
                if (workout.week !in 1..program.durationWeeks) issues += "$workoutLabel week must be in 1..${program.durationWeeks}"
                if (workout.estimatedMinutes !in 10..90) issues += "$workoutLabel estimatedMinutes must be in 10..90"
                if (workout.restDaysAfter !in 0..3) issues += "$workoutLabel restDaysAfter must be in 0..3"
                workout.exercises.forEachIndexed { index, prescription ->
                    val exerciseLabel = "$workoutLabel exercise $index"
                    if (prescription.exerciseId !in exercisesById) issues += "$exerciseLabel: Unknown exercise '${prescription.exerciseId}'"
                    if (prescription.sets !in 1..6) issues += "$exerciseLabel sets must be in 1..6"
                    if (prescription.restSeconds !in 15..300) issues += "$exerciseLabel restSeconds must be in 15..300"
                    val validReps = prescription.repsMin != null && prescription.repsMax != null &&
                        prescription.repsMin in 1..50 && prescription.repsMax in prescription.repsMin..100 &&
                        prescription.durationSeconds == null
                    val validDuration = prescription.durationSeconds != null && prescription.durationSeconds in 10..3600 &&
                        prescription.repsMin == null && prescription.repsMax == null
                    if (validReps == validDuration) issues += "$exerciseLabel prescription must use exactly one valid reps or duration mode"
                }
            }
            (1..program.durationWeeks).forEach { week ->
                val weeklyWorkouts = program.workouts.filter { it.week == week }
                if (weeklyWorkouts.size != program.sessionsPerWeek) issues += "Program '${program.id}' week $week must contain ${program.sessionsPerWeek} workouts"
                if (weeklyWorkouts.size + weeklyWorkouts.sumOf { it.restDaysAfter } != 7) {
                    issues += "Program '${program.id}' week $week weekly schedule must total 7 days"
                }
            }
        }
        return issues
    }
}
