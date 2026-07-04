package com.example.myapplication.core.program

import com.example.myapplication.core.model.ExercisePrescription
import kotlin.math.ceil

data class TimeBudgetSelection(
    val activeOrderIndices: List<Int>,
    val estimatedMinutes: Int,
)

object SessionTimeBudgetPlanner {
    fun select(
        exercises: List<ExercisePrescription>,
        budgetMinutes: Int,
    ): TimeBudgetSelection {
        require(exercises.isNotEmpty()) { "A workout must contain at least one exercise" }
        require(budgetMinutes > 0) { "Time budget must be positive" }

        val costs = exercises.map(::estimatedMinutes)
        var usedMinutes = 0
        val active = buildList {
            costs.forEachIndexed { index, cost ->
                if (isEmpty() || usedMinutes + cost <= budgetMinutes) {
                    add(index)
                    usedMinutes += cost
                }
            }
        }
        return TimeBudgetSelection(active, usedMinutes)
    }

    internal fun estimatedMinutes(prescription: ExercisePrescription): Int {
        val activeSecondsPerSet = prescription.durationSeconds
            ?: (((prescription.repsMin ?: 1) +
                (prescription.repsMax ?: prescription.repsMin ?: 1)) / 2 * 4)
        val totalSeconds = prescription.sets * (activeSecondsPerSet + prescription.restSeconds)
        return ceil(totalSeconds / 60.0).toInt().coerceAtLeast(1)
    }
}
