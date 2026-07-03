package com.example.myapplication.data

import android.content.Context
import androidx.datastore.core.handlers.ReplaceFileCorruptionHandler
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import com.example.myapplication.core.model.RestDayMode
import java.io.IOException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map

private val ENABLED = booleanPreferencesKey("reminder_enabled")
private val HOUR = intPreferencesKey("reminder_hour")
private val MINUTE = intPreferencesKey("reminder_minute")
private val REST = stringPreferencesKey("rest_day_mode")
private val CUSTOM_SERVER_URL = stringPreferencesKey("custom_server_url")
private val DARK_MODE_ENABLED = booleanPreferencesKey("dark_mode_enabled")

val Context.dataStore by preferencesDataStore(
    name = "gym_settings",
    corruptionHandler = ReplaceFileCorruptionHandler { emptyPreferences() },
)

data class Settings(
    val reminderEnabled: Boolean = false,
    val reminderHour: Int = 20,
    val reminderMinute: Int = 0,
    val restDayMode: RestDayMode? = null,
    val customServerUrl: String? = null,
    val darkModeEnabled: Boolean? = null,
)

internal fun preferencesToSettings(preferences: Preferences) = Settings(
    reminderEnabled = preferences[ENABLED] ?: false,
    reminderHour = (preferences[HOUR] ?: 20).takeIf { it in 0..23 } ?: 20,
    reminderMinute = (preferences[MINUTE] ?: 0).takeIf { it in 0..59 } ?: 0,
    restDayMode = preferences[REST]?.let { stored -> RestDayMode.entries.firstOrNull { it.name == stored } },
    customServerUrl = preferences[CUSTOM_SERVER_URL],
    darkModeEnabled = preferences[DARK_MODE_ENABLED],
)

internal fun settingsFromPreferences(data: Flow<Preferences>): Flow<Settings> = data
    .catch { error -> if (error is IOException) emit(emptyPreferences()) else throw error }
    .map(::preferencesToSettings)

interface SettingsRepository {
    val settings: Flow<Settings>
    suspend fun setReminderEnabled(enabled: Boolean)
    suspend fun setReminderTime(hour: Int, minute: Int)
    suspend fun setRestDayMode(mode: RestDayMode?)
    suspend fun setCustomServerUrl(url: String?)
    suspend fun setDarkModeEnabled(enabled: Boolean?)
}

class DataStoreSettingsRepository(context: Context) : SettingsRepository {
    private val store = context.applicationContext.dataStore
    override val settings: Flow<Settings> = settingsFromPreferences(store.data)
    override suspend fun setReminderEnabled(enabled: Boolean) { store.edit { it[ENABLED] = enabled } }
    override suspend fun setReminderTime(hour: Int, minute: Int) {
        require(hour in 0..23 && minute in 0..59)
        store.edit { it[HOUR] = hour; it[MINUTE] = minute }
    }
    override suspend fun setRestDayMode(mode: RestDayMode?) {
        store.edit { if (mode == null) it.remove(REST) else it[REST] = mode.name }
    }
    override suspend fun setCustomServerUrl(url: String?) {
        store.edit { if (url == null) it.remove(CUSTOM_SERVER_URL) else it[CUSTOM_SERVER_URL] = url }
    }
    override suspend fun setDarkModeEnabled(enabled: Boolean?) {
        store.edit { if (enabled == null) it.remove(DARK_MODE_ENABLED) else it[DARK_MODE_ENABLED] = enabled }
    }
}
