package com.example.myapplication.feature.recommendations

import com.example.myapplication.data.local.AdaptationDecisionEntity

sealed interface RecommendationUiState {
    data object Loading : RecommendationUiState

    data class Success(
        val decisions: List<UiDecision>,
        val cloudAiConsent: Boolean,
    ) : RecommendationUiState
}

data class UiDecision(
    val entity: AdaptationDecisionEntity,
    val explanationText: String, // Will contain either the local reason or AI explanation
    val isUndoEligible: Boolean,
    val isExplaining: Boolean = false, // Loading state for AI explanation request
)
