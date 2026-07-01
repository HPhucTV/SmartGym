package com.example.myapplication.notification

import com.example.myapplication.data.Settings

internal suspend fun runWorkoutReminder(
    loadSettings: suspend () -> Settings,
    schedule: (Int, Int) -> Unit,
    notify: () -> Unit,
    log: (Throwable) -> Unit,
) {
    val settings = try { loadSettings() } catch (error: Throwable) { log(error); null }
    if (settings?.reminderEnabled == true) try { schedule(settings.reminderHour, settings.reminderMinute) } catch (error: Throwable) { log(error) }
    try { notify() } catch (error: Throwable) { log(error) }
}

internal suspend fun runBootReschedule(
    loadSettings: suspend () -> Settings,
    schedule: (Int, Int) -> Unit,
    log: (Throwable) -> Unit,
) {
    try {
        val settings = loadSettings()
        if (settings.reminderEnabled) schedule(settings.reminderHour, settings.reminderMinute)
    } catch (error: Throwable) { log(error) }
}
