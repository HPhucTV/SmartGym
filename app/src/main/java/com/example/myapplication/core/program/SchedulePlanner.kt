package com.example.myapplication.core.program

import java.time.DayOfWeek
import java.time.LocalDate

object SchedulePlanner {
    fun dueEpochDays(
        startEpochDay: Long,
        trainingDays: Set<DayOfWeek>,
        workoutCount: Int,
    ): List<Long> {
        require(trainingDays.size in 1..6) { "Training days must contain 1..6 weekdays" }
        require(workoutCount >= 0) { "Workout count cannot be negative" }
        if (workoutCount == 0) return emptyList()

        return buildList(workoutCount) {
            var cursor = startEpochDay
            while (size < workoutCount) {
                if (LocalDate.ofEpochDay(cursor).dayOfWeek in trainingDays) add(cursor)
                if (size < workoutCount) cursor = Math.addExact(cursor, 1L)
            }
        }
    }

    fun dueEpochDays(startEpochDay: Long, restDaysAfter: List<Int>): List<Long> {
        require(restDaysAfter.all { it >= 0 }) { "Rest days cannot be negative" }
        if (restDaysAfter.isEmpty()) return emptyList()

        return buildList(restDaysAfter.size) {
            var dueEpochDay = startEpochDay
            add(dueEpochDay)
            for (index in 1 until restDaysAfter.size) {
                dueEpochDay = Math.addExact(
                    dueEpochDay,
                    Math.addExact(1L, restDaysAfter[index - 1].toLong()),
                )
                add(dueEpochDay)
            }
        }
    }

    fun carryForwardAfterCompletion(
        dueEpochDays: List<Long>,
        completedIndex: Int,
        completionEpochDay: Long,
    ): List<Long> {
        if (completedIndex !in dueEpochDays.indices) {
            throw IndexOutOfBoundsException("Completed index $completedIndex is outside the schedule")
        }
        val lateness = Math.subtractExact(completionEpochDay, dueEpochDays[completedIndex])
            .coerceAtLeast(0L)
        if (lateness == 0L) return dueEpochDays.toList()

        return dueEpochDays.mapIndexed { index, dueEpochDay ->
            if (index > completedIndex) Math.addExact(dueEpochDay, lateness) else dueEpochDay
        }
    }
}
