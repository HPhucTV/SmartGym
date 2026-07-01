package com.example.myapplication.notification

import android.content.*
import android.util.Log
import com.example.myapplication.data.DataStoreSettingsRepository
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.first

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action !in SUPPORTED_ACTIONS) return
        val pending = goAsync()
        val app = context.applicationContext
        CoroutineScope(SupervisorJob() + Dispatchers.IO).launch {
            try {
                runBootReschedule(
                    loadSettings = { DataStoreSettingsRepository(app).settings.first() },
                    schedule = { hour, minute -> AlarmReminderScheduler(app).schedule(hour, minute) },
                    log = { Log.e(TAG, "Unable to restore reminder", it) },
                )
            } finally { pending.finish() }
        }
    }
    companion object {
        private const val TAG = "BootReminder"
        private val SUPPORTED_ACTIONS = setOf(Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED)
    }
}
