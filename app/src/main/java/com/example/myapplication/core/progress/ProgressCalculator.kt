package com.example.myapplication.core.progress

import java.time.DayOfWeek
import java.time.LocalDate
import java.time.YearMonth
import java.time.temporal.TemporalAdjusters

object ProgressCalculator {
    fun percentage(completed: Int, total: Int): Int {
        if (total <= 0) return 0
        return ((completed.toLong() * 100L) / total)
            .coerceIn(0L, 100L)
            .toInt()
    }

    /**
     * Counts completed sessions by month. Repeated epoch days are retained because
     * they represent separate completed sessions, not duplicate calendar entries.
     */
    fun completedSessionsByMonth(completedEpochDays: List<Long>): Map<YearMonth, Int> =
        completedEpochDays
            .groupingBy { YearMonth.from(LocalDate.ofEpochDay(it)) }
            .eachCount()

    fun weeklyStreak(
        completedEpochDays: List<Long>,
        targetPerWeek: Int,
        currentEpochDay: Long,
    ): Int {
        if (targetPerWeek <= 0) return 0

        val completionsByWeek = completedEpochDays
            .asSequence()
            .map(::mondayOfWeek)
            .groupingBy { it }
            .eachCount()

        val currentWeek = mondayOfWeek(currentEpochDay)
        var week = if ((completionsByWeek[currentWeek] ?: 0) >= targetPerWeek) {
            currentWeek
        } else {
            currentWeek.minusWeeks(1)
        }
        var streak = 0
        while ((completionsByWeek[week] ?: 0) >= targetPerWeek) {
            streak++
            week = week.minusWeeks(1)
        }
        return streak
    }

    private fun mondayOfWeek(epochDay: Long): LocalDate =
        LocalDate.ofEpochDay(epochDay)
            .with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
}
