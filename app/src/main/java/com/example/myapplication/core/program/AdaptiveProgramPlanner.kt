package com.example.myapplication.core.program

import com.example.myapplication.core.model.ExercisePrescription
import com.example.myapplication.core.model.GoalConfig
import com.example.myapplication.core.model.ProgramTemplate
import com.example.myapplication.core.model.WorkoutTemplate
import kotlin.math.ceil

object AdaptiveProgramPlanner {
    fun adapt(program: ProgramTemplate, config: GoalConfig): List<WorkoutTemplate> {
        TrainingSchedule.validate(config.trainingDays, config.sessionDurationMinutes)
        require(config.sessionsPerWeek == config.trainingDays.size) {
            "Weekly frequency must equal selected training days"
        }

        val blueprints = program.workouts
            .filter { it.week == program.workouts.minOfOrNull(WorkoutTemplate::week) }
            .sortedBy { it.sequence }
            .ifEmpty { program.workouts.sortedBy { it.sequence } }
        require(blueprints.isNotEmpty()) { "Program must contain reviewed workout blueprints" }

        val workoutCount = Math.multiplyExact(config.sessionsPerWeek, config.durationWeeks)
        return List(workoutCount) { sequence ->
            val blueprintIndex = sequence % blueprints.size
            val blueprint = blueprints[blueprintIndex]
            val candidates = rotatedBlueprints(blueprints, blueprintIndex)
                .flatMap { it.exercises }
                .distinctBy(ExercisePrescription::exerciseId)
            val selected = fitOrdered(candidates, config.sessionDurationMinutes)
            val estimated = selected.sumOf(::estimatedMinutes).coerceAtMost(config.sessionDurationMinutes)
            blueprint.copy(
                sequence = sequence,
                week = sequence / config.sessionsPerWeek + 1,
                estimatedMinutes = estimated,
                restDaysAfter = 0,
                exercises = selected,
            )
        }
    }

    private fun rotatedBlueprints(
        blueprints: List<WorkoutTemplate>,
        startIndex: Int,
    ): List<WorkoutTemplate> = List(blueprints.size) { offset ->
        blueprints[(startIndex + offset) % blueprints.size]
    }

    private fun fitOrdered(
        candidates: List<ExercisePrescription>,
        budgetMinutes: Int,
    ): List<ExercisePrescription> {
        require(candidates.isNotEmpty()) { "Workout blueprint must contain exercises" }
        val selected = mutableListOf<ExercisePrescription>()
        var used = 0
        candidates.forEach { prescription ->
            val cost = estimatedMinutes(prescription)
            if (selected.isEmpty() || used + cost <= budgetMinutes) {
                selected += prescription
                used += cost
            }
        }
        return selected
    }

    internal fun estimatedMinutes(prescription: ExercisePrescription): Int {
        val activeSecondsPerSet = prescription.durationSeconds
            ?: (((prescription.repsMin ?: 1) + (prescription.repsMax ?: prescription.repsMin ?: 1)) / 2 * 4)
        val totalSeconds = prescription.sets * (activeSecondsPerSet + prescription.restSeconds)
        return ceil(totalSeconds / 60.0).toInt().coerceAtLeast(1)
    }
}
