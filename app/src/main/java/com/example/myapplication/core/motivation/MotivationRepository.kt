package com.example.myapplication.core.motivation

import android.content.Context
import kotlinx.serialization.json.Json
import java.time.LocalDate

class MotivationRepository(
    private val assetReader: (String) -> String,
) {
    constructor(context: Context) : this(
        assetReader = { path ->
            context.assets.open(path).bufferedReader().use { it.readText() }
        }
    )

    private val quotes: List<String> by lazy {
        runCatching {
            val json = assetReader("motivational_quotes.json")
            Json.decodeFromString<List<String>>(json)
        }.getOrElse {
            listOf(
                "Hãy tiếp tục cố gắng vì mục tiêu của bạn!",
                "Mỗi ngày một chút nỗ lực sẽ tạo nên sự khác biệt lớn.",
                "Kỷ luật là cầu nối giữa mục tiêu và thành tựu.",
                "Đừng so sánh bản thân với người khác, hãy so sánh với ngày hôm qua.",
                "Thành công không phải là ngẫu nhiên, đó là sự lựa chọn."
            )
        }
    }

    fun getDailyQuote(epochDay: Long = LocalDate.now().toEpochDay()): String {
        if (quotes.isEmpty()) return "Hãy tiếp tục cố gắng!"
        val index = (epochDay % quotes.size).toInt().let { if (it < 0) it + quotes.size else it }
        return quotes[index]
    }
}
