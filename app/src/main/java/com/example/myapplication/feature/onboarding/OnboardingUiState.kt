package com.example.myapplication.feature.onboarding

import com.example.myapplication.core.model.*
import java.time.DayOfWeek

enum class OnboardingStep { GOAL, LEVEL, EQUIPMENT, TRAINING_DAYS, SESSION_DURATION, REST_BEHAVIOR, REVIEW }

data class WorkoutCommitment(val sessionsPerWeek: Int, val durationWeeks: Int)

data class OnboardingDraft(
    val goal: FitnessGoal? = null,
    val level: ExperienceLevel? = null,
    val equipment: EquipmentProfile? = null,
    val sessionsPerWeek: Int? = null,
    val durationWeeks: Int? = null,
    val restDayMode: RestDayMode? = null,
    val trainingDays: Set<DayOfWeek> = emptySet(),
    val sessionDurationMinutes: Int? = null,
)

data class OnboardingOptions(
    val goals: Set<FitnessGoal>,
    val levels: Set<ExperienceLevel>,
    val equipment: Set<EquipmentProfile>,
    val commitments: Set<WorkoutCommitment>,
    val restDayModes: Set<RestDayMode>,
)

sealed interface OnboardingUiState {
    data class Editing(
        val step: OnboardingStep,
        val draft: OnboardingDraft,
        val options: OnboardingOptions,
        val isSaving: Boolean = false,
        val saveError: String? = null,
    ) : OnboardingUiState

    data class Unsupported(
        val draft: OnboardingDraft,
        val explanation: String,
        val alternatives: List<String>,
    ) : OnboardingUiState

    data object Created : OnboardingUiState
}
