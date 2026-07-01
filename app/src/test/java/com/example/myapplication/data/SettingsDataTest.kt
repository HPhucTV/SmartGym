package com.example.myapplication.data

import androidx.datastore.preferences.core.*
import java.io.IOException
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Test

class SettingsDataTest {
    @Test fun `io failure emits defaults and invalid values map safely`() = runTest {
        val values = settingsFromPreferences(flow { throw IOException("disk") }).toList()
        assertEquals(listOf(Settings()), values)
        val prefs = mutablePreferencesOf(intPreferencesKey("reminder_hour") to 99, intPreferencesKey("reminder_minute") to -1,
            stringPreferencesKey("rest_day_mode") to "UNKNOWN")
        assertEquals(Settings(), preferencesToSettings(prefs))
    }
    @Test fun `unexpected data exception is rethrown`() = runTest {
        try { settingsFromPreferences(flow { throw IllegalStateException("bug") }).first(); fail("expected") }
        catch (error: IllegalStateException) { assertEquals("bug", error.message) }
    }
}
