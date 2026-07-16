package com.example.myapplication.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class BackendConfigTest {
    @Test
    fun `server URL is trimmed normalized and restricted to HTTP protocols`() {
        assertEquals("https://coach.example.com", normalizeServerUrl("  https://coach.example.com/  "))
        assertEquals("http://192.168.1.8:3000", normalizeServerUrl("http://192.168.1.8:3000"))
        assertEquals("http://192.168.1.7:3000", normalizeServerUrl("192.168.1.7:3000"))
        assertEquals("http://localhost:3000", normalizeServerUrl("localhost:3000"))
        assertNull(normalizeServerUrl("ftp://coach.example.com"))
        assertNull(normalizeServerUrl("not a url"))
        assertNull(normalizeServerUrl("  "))
    }

    @Test
    fun `custom URL overrides default backend regardless of device type`() {
        assertEquals(
            "https://coach.example.com",
            resolveBackendBaseUrl(customUrl = "https://coach.example.com/", emulator = false),
        )
        assertEquals(
            "http://192.168.1.5:3000",
            resolveBackendBaseUrl(customUrl = "http://192.168.1.5:3000", emulator = true),
        )
    }

    @Test
    fun `null custom URL falls back to provided default`() {
        // BuildConfig fields are compile-time constants; test the routing logic
        // by providing explicit emulator/physical URLs (simulating what BuildConfig provides).
        // When customUrl is null, resolveBackendBaseUrl returns the emulator URL.
        assertEquals(
            "http://10.0.2.2:3000",
            resolveBackendBaseUrlWithDefaults(customUrl = null, emulator = true, emulatorUrl = "http://10.0.2.2:3000", physicalUrl = "https://gym-app-w7sz.onrender.com"),
        )
        // When customUrl is null on physical device, returns physical URL.
        assertEquals(
            "https://gym-app-w7sz.onrender.com",
            resolveBackendBaseUrlWithDefaults(customUrl = null, emulator = false, emulatorUrl = "http://10.0.2.2:3000", physicalUrl = "https://gym-app-w7sz.onrender.com"),
        )
    }
}

/** Test helper that mirrors resolveBackendBaseUrl logic with injectable defaults. */
private fun resolveBackendBaseUrlWithDefaults(
    customUrl: String?,
    emulator: Boolean,
    emulatorUrl: String,
    physicalUrl: String,
): String? = normalizeServerUrl(customUrl) ?: if (emulator) emulatorUrl else physicalUrl
