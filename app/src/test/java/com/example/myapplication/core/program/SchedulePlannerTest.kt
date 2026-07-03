package com.example.myapplication.core.program

import java.time.DayOfWeek
import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class SchedulePlannerTest {
    @Test
    fun selectedWeekdaysDriveDueDatesAcrossWeekBoundaries() {
        val monday = LocalDate.parse("2026-07-06").toEpochDay()

        val dates = SchedulePlanner.dueEpochDays(
            startEpochDay = monday,
            trainingDays = setOf(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY),
            workoutCount = 5,
        )

        assertEquals(
            listOf("2026-07-06", "2026-07-08", "2026-07-10", "2026-07-13", "2026-07-15")
                .map { LocalDate.parse(it).toEpochDay() },
            dates,
        )
    }

    @Test
    fun dueDatesStartOnStartDayAndUsePreviousSessionRestDays() {
        assertEquals(listOf(100L, 102L, 104L), SchedulePlanner.dueEpochDays(100L, listOf(1, 1, 2)))
    }

    @Test
    fun emptyScheduleHasNoDueDates() {
        assertEquals(emptyList<Long>(), SchedulePlanner.dueEpochDays(100L, emptyList()))
    }

    @Test
    fun negativeRestDaysAreRejected() {
        assertThrows(IllegalArgumentException::class.java) {
            SchedulePlanner.dueEpochDays(100L, listOf(1, -1))
        }
    }

    @Test
    fun lateCompletionShiftsOnlyLaterWorkoutsByLateness() {
        val shifted = SchedulePlanner.carryForwardAfterCompletion(
            dueEpochDays = listOf(10L, 12L, 14L, 16L),
            completedIndex = 1,
            completionEpochDay = 15L,
        )

        assertEquals(listOf(10L, 12L, 17L, 19L), shifted)
    }

    @Test
    fun lateCompletionOfFirstWorkoutShiftsAllRemainingWorkouts() {
        assertEquals(
            listOf(10L, 14L, 16L),
            SchedulePlanner.carryForwardAfterCompletion(listOf(10L, 12L, 14L), 0, 12L),
        )
    }

    @Test
    fun onTimeOrEarlyCompletionDoesNotMoveScheduleEarlier() {
        val dueDates = listOf(10L, 12L, 14L)

        assertEquals(dueDates, SchedulePlanner.carryForwardAfterCompletion(dueDates, 1, 12L))
        assertEquals(dueDates, SchedulePlanner.carryForwardAfterCompletion(dueDates, 1, 11L))
    }

    @Test
    fun invalidCompletedIndexIsRejected() {
        assertThrows(IndexOutOfBoundsException::class.java) {
            SchedulePlanner.carryForwardAfterCompletion(listOf(10L), 1, 12L)
        }
    }
}
