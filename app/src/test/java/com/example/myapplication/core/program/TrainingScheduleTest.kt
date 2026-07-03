package com.example.myapplication.core.program

import java.time.DayOfWeek
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class TrainingScheduleTest {
    @Test
    fun `accepts one through six unique training days`() {
        (1..6).forEach { count ->
            val days = DayOfWeek.entries.take(count).toSet()
            TrainingSchedule.validate(days, 60)
        }
    }

    @Test
    fun `rejects zero and seven training days`() {
        assertThrows(IllegalArgumentException::class.java) { TrainingSchedule.validate(emptySet(), 60) }
        assertThrows(IllegalArgumentException::class.java) { TrainingSchedule.validate(DayOfWeek.entries.toSet(), 60) }
    }

    @Test
    fun `accepts only reviewed duration buckets`() {
        val day = setOf(DayOfWeek.MONDAY)
        listOf(30, 45, 60, 75, 90).forEach { TrainingSchedule.validate(day, it) }
        listOf(29, 35, 120).forEach { minutes ->
            assertThrows(IllegalArgumentException::class.java) { TrainingSchedule.validate(day, minutes) }
        }
    }

    @Test
    fun `legacy defaults are deterministic and evenly distributed`() {
        assertEquals(setOf(DayOfWeek.MONDAY), TrainingSchedule.defaultDays(1))
        assertEquals(setOf(DayOfWeek.MONDAY, DayOfWeek.THURSDAY), TrainingSchedule.defaultDays(2))
        assertEquals(setOf(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY), TrainingSchedule.defaultDays(3))
        assertEquals(6, TrainingSchedule.defaultDays(6).size)
    }
}
