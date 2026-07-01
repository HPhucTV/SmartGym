package com.example.myapplication.notification

import com.example.myapplication.data.Settings
import java.time.*
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Test

class ReminderRecoveryTest {
    @Test fun `next alarm handles future passed gap overlap and rejects invalid time`() {
        val zone = ZoneId.of("America/New_York")
        val now = ZonedDateTime.of(2026, 1, 2, 10, 0, 0, 0, zone)
        assertEquals(LocalDate.of(2026,1,2), nextReminderOccurrence(now, 11, 0).toLocalDate())
        assertEquals(LocalDate.of(2026,1,3), nextReminderOccurrence(now, 9, 0).toLocalDate())
        val gapNow = ZonedDateTime.of(2026,3,8,1,0,0,0,zone)
        assertTrue(nextReminderOccurrence(gapNow, 2, 30).isAfter(gapNow))
        val overlapNow = ZonedDateTime.of(2026,11,1,0,30,0,0,zone)
        assertTrue(nextReminderOccurrence(overlapNow, 1, 30).isAfter(overlapNow))
        assertThrows(IllegalArgumentException::class.java) { nextReminderOccurrence(now, 24, 0) }
    }

    @Test fun `workout orchestration isolates schedule and notification failures`() = runTest {
        val calls = mutableListOf<String>()
        runWorkoutReminder(
            loadSettings = { Settings(reminderEnabled = true, reminderHour = 7) },
            schedule = { _, _ -> calls += "schedule"; error("alarm") },
            notify = { calls += "notify"; error("notification") },
            log = { calls += "log" },
        )
        assertEquals(listOf("schedule", "log", "notify", "log"), calls)
    }

    @Test fun `workout still notifies when settings load fails and boot catches failures`() = runTest {
        val calls = mutableListOf<String>()
        runWorkoutReminder({ error("data") }, { _, _ -> calls += "schedule" }, { calls += "notify" }, { calls += "log" })
        assertEquals(listOf("log", "notify"), calls)
        calls.clear()
        runBootReschedule({ Settings(reminderEnabled = true) }, { _, _ -> error("alarm") }, { calls += "log" })
        assertEquals(listOf("log"), calls)
    }
}
