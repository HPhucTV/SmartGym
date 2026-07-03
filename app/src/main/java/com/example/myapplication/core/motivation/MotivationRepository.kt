package com.example.myapplication.core.motivation

import android.content.Context
import kotlinx.serialization.json.Json
import java.time.LocalDate

class MotivationRepository(private val context: Context) {
    private val quotes: List<String> by lazy {
        val json = context.assets.open("motivational_quotes.json").bufferedReader().readText()
        Json.decodeFromString<List<String>>(json)
    }

    fun getDailyQuote(epochDay: Long = LocalDate.now().toEpochDay()): String {
        if (quotes.isEmpty()) return "Hãy tiếp tục cố gắng!"
        val index = (epochDay % quotes.size).toInt().let { if (it < 0) it + quotes.size else it }
        return quotes[index]
    }
}
