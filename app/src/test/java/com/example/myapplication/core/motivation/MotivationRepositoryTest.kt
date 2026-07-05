package com.example.myapplication.core.motivation

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class MotivationRepositoryTest {
    @Test
    fun `loads quotes successfully when asset exists and is valid`() {
        val repository = MotivationRepository(
            assetReader = { path ->
                assertEquals("motivational_quotes.json", path)
                """["Quote A", "Quote B", "Quote C"]"""
            }
        )
        assertEquals("Quote A", repository.getDailyQuote(0))
        assertEquals("Quote B", repository.getDailyQuote(1))
        assertEquals("Quote C", repository.getDailyQuote(2))
        assertEquals("Quote A", repository.getDailyQuote(3))
    }

    @Test
    fun `falls back to default quotes when asset reader fails`() {
        val repository = MotivationRepository(
            assetReader = { error("File not found") }
        )
        // Verify daily quote returns one of the fallback quotes
        val quote = repository.getDailyQuote(0)
        assertTrue(quote.isNotEmpty())
        assertTrue(
            quote == "Hãy tiếp tục cố gắng vì mục tiêu của bạn!" ||
            quote == "Mỗi ngày một chút nỗ lực sẽ tạo nên sự khác biệt lớn." ||
            quote == "Kỷ luật là cầu nối giữa mục tiêu và thành tựu." ||
            quote == "Đừng so sánh bản thân với người khác, hãy so sánh với ngày hôm qua." ||
            quote == "Thành công không phải là ngẫu nhiên, đó là sự lựa chọn."
        )
    }

    @Test
    fun `falls back to default quotes when json serialization fails`() {
        val repository = MotivationRepository(
            assetReader = { "invalid json content" }
        )
        val quote = repository.getDailyQuote(5)
        assertTrue(quote.isNotEmpty())
    }
}
