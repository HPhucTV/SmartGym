package com.example.myapplication.core.model

import java.time.DayOfWeek
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
    val trainingDays: Set<DayOfWeek> = legacyTrainingDays(sessionsPerWeek),
    val sessionDurationMinutes: Int = 45,
)

fun legacyTrainingDays(sessionsPerWeek: Int): Set<DayOfWeek> = when (sessionsPerWeek) {
    1 -> setOf(DayOfWeek.MONDAY)
    2 -> setOf(DayOfWeek.MONDAY, DayOfWeek.THURSDAY)
    3 -> setOf(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY)
    4 -> setOf(DayOfWeek.MONDAY, DayOfWeek.TUESDAY, DayOfWeek.THURSDAY, DayOfWeek.FRIDAY)
    5 -> setOf(DayOfWeek.MONDAY, DayOfWeek.TUESDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY, DayOfWeek.SATURDAY)
    6 -> setOf(DayOfWeek.MONDAY, DayOfWeek.TUESDAY, DayOfWeek.WEDNESDAY, DayOfWeek.THURSDAY, DayOfWeek.FRIDAY, DayOfWeek.SATURDAY)
    else -> emptySet()
}

fun trainingDaysMask(days: Set<DayOfWeek>): Int = days.fold(0) { mask, day ->
    mask or (1 shl (day.value - 1))
}

fun trainingDaysFromMask(mask: Int): Set<DayOfWeek> = DayOfWeek.entries
    .filterTo(linkedSetOf()) { day -> mask and (1 shl (day.value - 1)) != 0 }
