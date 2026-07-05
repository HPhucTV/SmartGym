package com.example.myapplication.notification

import com.example.myapplication.data.Settings
import java.time.*
import kotlinx.coroutines.CancellationException
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

    @Test fun `workout does not notify when settings load succeeds and reminder is disabled`() = runTest {
        val calls = mutableListOf<String>()
        runWorkoutReminder(
            loadSettings = { Settings(reminderEnabled = false) },
            schedule = { _, _ -> calls += "schedule" },
            notify = { calls += "notify" },
            log = { calls += "log" }
        )
        assertEquals(emptyList<String>(), calls)
    }
    @Test fun `cancellation from settings load is rethrown and never logged`() = runTest {
        val calls = mutableListOf<String>()
        try {
            runWorkoutReminder({ throw CancellationException("settings") }, { _, _ -> }, {}, { calls += "log" })
            fail("expected cancellation from settings load")
        } catch (e: CancellationException) {
            assertEquals("settings", e.message)
            assertFalse("should not log cancellation", calls.contains("log"))
        }
    }

    @Test fun `cancellation from schedule is rethrown and never logged`() = runTest {
        val calls = mutableListOf<String>()
        try {
            runWorkoutReminder({ Settings(reminderEnabled = true) }, { _, _ -> throw CancellationException("schedule") }, {}, { calls += "log" })
            fail("expected cancellation from schedule")
        } catch (e: CancellationException) {
            assertEquals("schedule", e.message)
            assertFalse("should not log cancellation", calls.contains("log"))
        }
    }

    @Test fun `cancellation from notify is rethrown and never logged`() = runTest {
        val calls = mutableListOf<String>()
        try {
            runWorkoutReminder({ Settings(reminderEnabled = true) }, { _, _ -> }, { throw CancellationException("notify") }, { calls += "log" })
            fail("expected cancellation from notify")
        } catch (e: CancellationException) {
            assertEquals("notify", e.message)
            assertFalse("should not log cancellation", calls.contains("log"))
        }
    }

    @Test fun `cancellation from boot reschedule is rethrown and never logged`() = runTest {
        val calls = mutableListOf<String>()
        try {
            runBootReschedule({ throw CancellationException("boot") }, { _, _ -> }, { calls += "log" })
            fail("expected cancellation from boot reschedule")
        } catch (e: CancellationException) {
            assertEquals("boot", e.message)
            assertFalse("should not log cancellation", calls.contains("log"))
        }
    }

    @Test fun `DST gap resolves exactly and overlap chooses next valid instant`() {
        val zone = ZoneId.of("America/New_York")
        val gapNow = ZonedDateTime.of(2026, 3, 8, 1, 0, 0, 0, zone)
        val gap = nextReminderOccurrence(gapNow, 2, 30)
        assertEquals(LocalDateTime.of(2026, 3, 8, 3, 30), gap.toLocalDateTime())
        assertEquals(ZoneOffset.ofHours(-4), gap.offset)

        val beforeOverlap = ZonedDateTime.ofLocal(LocalDateTime.of(2026, 11, 1, 0, 30), zone, ZoneOffset.ofHours(-4))
        val first = nextReminderOccurrence(beforeOverlap, 1, 30)
        assertEquals(ZoneOffset.ofHours(-4), first.offset)
        val betweenOccurrences = ZonedDateTime.ofLocal(LocalDateTime.of(2026, 11, 1, 1, 45), zone, ZoneOffset.ofHours(-4))
        val second = nextReminderOccurrence(betweenOccurrences, 1, 30)
        assertEquals(LocalDateTime.of(2026, 11, 1, 1, 30), second.toLocalDateTime())
        assertEquals(ZoneOffset.ofHours(-5), second.offset)
        assertTrue(second.toInstant().isAfter(betweenOccurrences.toInstant()))
    }

    @Test fun `notification permission matrix and pending intent flags are explicit`() {
        assertTrue(shouldPostNotification(apiLevel = 32, permissionGranted = false))
        assertTrue(shouldPostNotification(apiLevel = 33, permissionGranted = true))
        assertFalse(shouldPostNotification(apiLevel = 33, permissionGranted = false))
        val flags = notificationContentIntentFlags()
        assertTrue(flags and android.app.PendingIntent.FLAG_UPDATE_CURRENT != 0)
        assertTrue(flags and android.app.PendingIntent.FLAG_IMMUTABLE != 0)
    }

    @Test fun `permission denial skips post but orchestration still schedules`() = runTest {
        val calls = mutableListOf<String>()
        runWorkoutReminder(
            loadSettings = { Settings(reminderEnabled = true) },
            schedule = { _, _ -> calls += "schedule" },
            notify = { if (shouldPostNotification(33, false)) calls += "notify" },
            log = { calls += "log" },
        )
        assertEquals(listOf("schedule"), calls)
    }
}
