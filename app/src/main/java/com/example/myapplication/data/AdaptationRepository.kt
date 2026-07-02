package com.example.myapplication.data

import com.example.myapplication.core.adaptation.AdaptationDecision
import com.example.myapplication.core.adaptation.AdaptationKind
import com.example.myapplication.core.adaptation.AdaptationStatus
import com.example.myapplication.data.local.AdaptationDecisionEntity
import kotlinx.coroutines.flow.Flow

/**
 * Repository contract for persisting and managing adaptation decisions.
 *
 * All state-changing operations are atomic: they validate current state,
 * apply changes to nutrition targets when appropriate, and record audit history.
 */
interface AdaptationRepository {
    /** Observe all decisions, newest first. */
    fun observeDecisions(): Flow<List<AdaptationDecisionEntity>>

    /** Record a new decision from the engine. Auto-apply decisions are applied immediately. */
    suspend fun recordDecision(decision: AdaptationDecision): Long

    /** User accepts a PROPOSED / REQUIRES_CONFIRMATION decision. */
    suspend fun acceptDecision(decisionId: Long): DecisionActionResult

    /** User rejects a PROPOSED / REQUIRES_CONFIRMATION decision. */
    suspend fun rejectDecision(decisionId: Long): DecisionActionResult

    /** Undo the latest applied decision of a given kind. */
    suspend fun undoLatestDecision(kind: AdaptationKind): DecisionActionResult
}

sealed interface DecisionActionResult {
    data object Success : DecisionActionResult
    data class NotFound(val id: Long) : DecisionActionResult
    data class InvalidState(val currentStatus: AdaptationStatus, val expectedStatus: AdaptationStatus) : DecisionActionResult
    data class Stale(val reason: String) : DecisionActionResult
}
