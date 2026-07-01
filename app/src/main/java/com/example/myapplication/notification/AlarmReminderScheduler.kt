package com.example.myapplication.notification

import android.app.*
import android.content.*
import java.time.*

internal fun nextReminderOccurrence(now: ZonedDateTime, hour: Int, minute: Int): ZonedDateTime {
    require(hour in 0..23 && minute in 0..59)
    var date = now.toLocalDate()
    while (true) {
        val local = date.atTime(hour, minute)
        val offsets = now.zone.rules.getValidOffsets(local)
        val candidates = if (offsets.isEmpty()) {
            listOf(local.atZone(now.zone))
        } else {
            offsets.map { offset -> ZonedDateTime.ofLocal(local, now.zone, offset) }
        }
        candidates.sortedBy { it.toInstant() }.firstOrNull { it.toInstant().isAfter(now.toInstant()) }?.let { return it }
        date = date.plusDays(1)
    }
}

class AlarmReminderScheduler(context: Context) : ReminderScheduler {
    private val app = context.applicationContext
    private val alarm = app.getSystemService(AlarmManager::class.java)
    override fun schedule(hour: Int, minute: Int) {
        val next = nextReminderOccurrence(ZonedDateTime.now(), hour, minute)
        alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.toInstant().toEpochMilli(), intent())
    }
    override fun cancel() = alarm.cancel(intent())
    private fun intent() = PendingIntent.getBroadcast(app, 0, Intent(app, WorkoutReminderReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
}
