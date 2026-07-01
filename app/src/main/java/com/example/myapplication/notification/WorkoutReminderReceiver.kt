package com.example.myapplication.notification

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.example.myapplication.MainActivity
import com.example.myapplication.R
import com.example.myapplication.data.DataStoreSettingsRepository
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.first

class WorkoutReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val pending = goAsync()
        val app = context.applicationContext
        CoroutineScope(SupervisorJob() + Dispatchers.IO).launch {
            try {
                runWorkoutReminder(
                    loadSettings = { DataStoreSettingsRepository(app).settings.first() },
                    schedule = { hour, minute -> AlarmReminderScheduler(app).schedule(hour, minute) },
                    notify = { postNotification(app) },
                    log = { Log.e(TAG, "Reminder operation failed", it) },
                )
            } finally { pending.finish() }
        }
    }

    private fun postNotification(app: Context) {
        if (Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(app, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return
        val manager = app.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(
            NotificationChannel(CHANNEL, app.getString(R.string.reminder_channel), NotificationManager.IMPORTANCE_DEFAULT))
        val contentIntent = PendingIntent.getActivity(
            app, 0, Intent(app, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        NotificationManagerCompat.from(app).notify(1001, NotificationCompat.Builder(app, CHANNEL)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle(app.getString(R.string.reminder_title))
            .setContentText(app.getString(R.string.reminder_body))
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .build())
    }

    companion object { const val CHANNEL = "workout_reminders"; private const val TAG = "WorkoutReminder" }
}
