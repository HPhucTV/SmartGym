package com.example.myapplication.core.progress

import java.time.LocalDate
import java.time.YearMonth
import org.junit.Assert.assertEquals
import org.junit.Test

class ProgressCalculatorTest {
    @Test
    fun percentageHandlesEmptyNegativeOverCompleteAndLargeValues() {
        assertEquals(0, ProgressCalculator.percentage(4, 0))
        assertEquals(0, ProgressCalculator.percentage(-1, 10))
        assertEquals(100, ProgressCalculator.percentage(11, 10))
        assertEquals(75, ProgressCalculator.percentage(1_500_000_000, 2_000_000_000))
    }

    @Test
    fun completedSessionsAreGroupedByMonthAndDuplicateDaysRemainSeparateSessions() {
        val may31 = LocalDate.of(2026, 5, 31).toEpochDay()
        val june1 = LocalDate.of(2026, 6, 1).toEpochDay()

        assertEquals(
            mapOf(YearMonth.of(2026, 5) to 1, YearMonth.of(2026, 6) to 2),
            ProgressCalculator.completedSessionsByMonth(listOf(june1, may31, june1)),
        )
    }

    @Test
    fun weeklyStreakCountsTwoConsecutiveQualifiedIsoWeeks() {
        val monday = LocalDate.of(2026, 6, 8).toEpochDay()
        val completed = listOf(0L, 2L, 4L, 7L, 9L, 11L).map(monday::plus)

        assertEquals(2, ProgressCalculator.weeklyStreak(completed, 3, monday + 13))
    }

    @Test
    fun incompleteCurrentWeekPreservesStreakThroughPreviousWeek() {
        val monday = LocalDate.of(2026, 6, 8).toEpochDay()
        val completed = listOf(0L, 2L, 4L).map(monday::plus)

        assertEquals(1, ProgressCalculator.weeklyStreak(completed, 3, monday + 8))
    }

    @Test
    fun weeklyStreakUsesIsoWeeksAcrossYearBoundaryAndRetainsMultipleSessions() {
        val dec29 = LocalDate.of(2025, 12, 29).toEpochDay()
        val completions = listOf(dec29, dec29, dec29 + 2, dec29 + 7, dec29 + 9)

        assertEquals(2, ProgressCalculator.weeklyStreak(completions, 2, dec29 + 13))
    }

    @Test
    fun weeklyStreakCountsMultipleSessionsOnSameDay() {
        val monday = LocalDate.of(2026, 6, 8).toEpochDay()
        // 2 sessions on Monday, 1 session on Wednesday -> 3 sessions total
        val completions = listOf(monday, monday, monday + 2)

        // Target is 3 sessions per week. If duplicates were ignored, count would be 2 (not qualified).
        // Since they count, count is 3 (qualified).
        assertEquals(1, ProgressCalculator.weeklyStreak(completions, 3, monday + 6))
    }

    @Test
    fun gapBreaksWeeklyStreakAndNonPositiveTargetHasNoStreak() {
        val monday = LocalDate.of(2026, 6, 1).toEpochDay()
        val completions = listOf(monday, monday + 14)

        assertEquals(1, ProgressCalculator.weeklyStreak(completions, 1, monday + 20))
        assertEquals(0, ProgressCalculator.weeklyStreak(completions, 0, monday + 20))
    }
}
