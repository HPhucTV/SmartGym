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
    fun `physical device has no hidden developer host fallback`() {
        assertEquals("http://10.0.2.2:3000", resolveBackendBaseUrl(customUrl = null, emulator = true))
        assertNull(resolveBackendBaseUrl(customUrl = null, emulator = false))
        assertEquals(
            "https://coach.example.com",
            resolveBackendBaseUrl(customUrl = "https://coach.example.com/", emulator = false),
        )
    }
}
