package com.example.myapplication.feature.recommendations

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.myapplication.core.adaptation.AdaptationKind
import com.example.myapplication.core.adaptation.AdaptationStatus
import com.example.myapplication.data.AdaptationRepository
import com.example.myapplication.data.CoachExplanationClient
import com.example.myapplication.data.local.AdaptationDecisionEntity
import com.example.myapplication.data.local.PersonalizationDao
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class RecommendationViewModel(
    private val adaptationRepository: AdaptationRepository,
    private val personalizationDao: PersonalizationDao,
    private val coachExplanationClient: CoachExplanationClient,
) : ViewModel() {

    private val aiExplanations = MutableStateFlow<Map<Long, String>>(emptyMap())
    private val loadingAiExplanations = MutableStateFlow<Set<Long>>(emptySet())

    val uiState: StateFlow<RecommendationUiState> = combine(
        adaptationRepository.observeDecisions(),
        personalizationDao.observeProfile(),
        aiExplanations,
        loadingAiExplanations
    ) { decisions, profile, explanations, loading ->
        if (profile == null) {
            RecommendationUiState.Success(
                decisions = emptyList(),
                cloudAiConsent = false
            )
        } else {
            val cloudConsent = profile.cloudAiConsent
            val uiDecisions = decisions.map { entity ->
                val isUndoEligible = checkIfUndoEligible(entity, decisions)
                val aiExp = explanations[entity.id]

                // Trigger AI explanation fetch asynchronously if cloud AI consent is granted
                if (cloudConsent && aiExp == null && !loading.contains(entity.id) && entity.status == AdaptationStatus.PROPOSED) {
                    fetchAiExplanation(entity)
                }

                UiDecision(
                    entity = entity,
                    explanationText = aiExp ?: entity.reasonVi,
                    isUndoEligible = isUndoEligible,
                    isExplaining = loading.contains(entity.id)
                )
            }
            RecommendationUiState.Success(
                decisions = uiDecisions,
                cloudAiConsent = cloudConsent
            )
        }
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = RecommendationUiState.Loading
    )

    private fun checkIfUndoEligible(
        entity: AdaptationDecisionEntity,
        allDecisions: List<AdaptationDecisionEntity>
    ): Boolean {
        if (entity.status != AdaptationStatus.APPLIED) return false
        val newerApplied = allDecisions.any {
            it.kind == entity.kind &&
                it.id != entity.id &&
                it.createdAtEpochMillis > entity.createdAtEpochMillis &&
                it.status == AdaptationStatus.APPLIED
        }
        return !newerApplied
    }

    private fun fetchAiExplanation(entity: AdaptationDecisionEntity) {
        viewModelScope.launch {
            loadingAiExplanations.value = loadingAiExplanations.value + entity.id
            val explanation = coachExplanationClient.explainDecision(
                kind = entity.kind,
                reasonVi = entity.reasonVi,
                beforeValue = entity.beforeJson,
                afterValue = entity.afterJson
            )
            loadingAiExplanations.value = loadingAiExplanations.value - entity.id
            if (explanation != null) {
                aiExplanations.value = aiExplanations.value + (entity.id to explanation)
            }
        }
    }

    fun acceptDecision(id: Long) {
        viewModelScope.launch {
            adaptationRepository.acceptDecision(id)
        }
    }

    fun rejectDecision(id: Long) {
        viewModelScope.launch {
            adaptationRepository.rejectDecision(id)
        }
    }

    fun undoDecision(kind: AdaptationKind) {
        viewModelScope.launch {
            adaptationRepository.undoLatestDecision(kind)
        }
    }
}
