package com.example.myapplication.core.model

import kotlinx.serialization.Serializable

@Serializable
enum class MovementBlockKind { WARM_UP, COOL_DOWN }

@Serializable
data class MovementBlock(
    val id: String,
    val kind: MovementBlockKind,
    val movementPatterns: Set<MovementPattern>,
    val titleVi: String,
    val stepsVi: List<String>,
    val estimatedMinutes: Int,
)
