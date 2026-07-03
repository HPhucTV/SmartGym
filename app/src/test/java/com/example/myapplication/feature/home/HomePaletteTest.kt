package com.example.myapplication.feature.home

import androidx.compose.ui.graphics.Color
import org.junit.Assert.assertEquals
import org.junit.Test

class HomePaletteTest {
    @Test
    fun `home palette matches approved light design system`() {
        assertEquals(Color(0xFFFFFFFF), HomePalette.background)
        assertEquals(Color(0xFF14213D), HomePalette.navy)
        assertEquals(Color(0xFFF97316), HomePalette.orange)
        assertEquals(Color(0xFF22C55E), HomePalette.green)
        assertEquals(Color(0xFFF3F4F6), HomePalette.supportingSurface)
        assertEquals(Color(0xFFE5E7EB), HomePalette.border)
        assertEquals(Color(0xFF64748B), HomePalette.mutedText)
    }
}
