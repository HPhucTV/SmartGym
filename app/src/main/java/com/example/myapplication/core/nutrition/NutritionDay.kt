package com.example.myapplication.core.nutrition

data class Nutrients(
    val calories: Int = 0,
    val proteinGrams: Int = 0,
    val carbsGrams: Int = 0,
    val fatGrams: Int = 0,
)

enum class EntrySource {
    MANUAL,
    CAMERA_ANALYSIS,
}

data class NutritionDay(
    val epochDay: Long,
    val consumed: Nutrients,
    val target: NutritionTarget?,
)
