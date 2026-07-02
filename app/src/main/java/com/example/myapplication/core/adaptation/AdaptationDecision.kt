package com.example.myapplication.core.adaptation

/**
 * A domain-level adaptation decision produced by [AdaptationEngine].
 *
 * This is a pure data object. Persistence (mapping to [AdaptationDecisionEntity])
 * and application logic belong to the repository layer (Task 7).
 */
data class AdaptationDecision(
    /** What category of change this decision represents. */
    val kind: AdaptationKind,
    /** Whether this can be applied automatically or needs user confirmation. */
    val mode: AdaptationMode,
    /** Human-readable explanation in Vietnamese. */
    val reasonVi: String,
    /** JSON-serialized previous state (for audit trail). */
    val beforeValue: String,
    /** JSON-serialized proposed new state. */
    val afterValue: String,
    /** JSON-serialized payload to restore the previous state on undo. */
    val undoPayload: String,
)
