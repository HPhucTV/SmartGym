package com.example.myapplication.feature.profile

import com.example.myapplication.core.profile.ActivityLevel
import com.example.myapplication.core.profile.GoalPace
import com.example.myapplication.core.profile.MetabolicSex

sealed interface ProfileUiState {
    data object Loading : ProfileUiState
    data class Content(
        val birthDateEpochDay: Long,
        val metabolicSex: MetabolicSex,
        val heightCmStr: String,
        val currentWeightKgStr: String,
        val targetWeightKgStr: String,
        val activityLevel: ActivityLevel,
        val goalPace: GoalPace,
        val personalizationConsent: Boolean,
        val cloudAiConsent: Boolean,
        val isSaving: Boolean = false,
        val saveError: String? = null,
        val success: Boolean = false,
        val validationErrors: List<String> = emptyList(),
    ) : ProfileUiState
}
