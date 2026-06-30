package com.example.myapplication.core.model

import kotlinx.serialization.Serializable

@Serializable
enum class FitnessGoal {
    MUSCLE_GAIN,
    FAT_LOSS_CONDITIONING,
    ENDURANCE,
    GENERAL_FITNESS,
}

@Serializable
enum class ExperienceLevel {
    BEGINNER,
    INTERMEDIATE,
}

@Serializable
enum class EquipmentProfile {
    BODYWEIGHT_ONLY,
    DUMBBELLS,
    RESISTANCE_BANDS,
    FULL_GYM,
}

@Serializable
enum class RestDayMode {
    FULL_REST,
    LIGHT_RECOVERY,
}

data class GoalConfig(
    val goal: FitnessGoal,
    val level: ExperienceLevel,
    val equipmentProfile: EquipmentProfile,
    val sessionsPerWeek: Int,
    val durationWeeks: Int,
    val restDayMode: RestDayMode,
)
