package com.example.myapplication.core.catalog

import com.example.myapplication.core.model.MovementBlock
import com.example.myapplication.core.model.MovementBlockKind
import com.example.myapplication.core.model.MovementPattern

object MovementBlockPlanner {
    fun select(
        blocks: List<MovementBlock>,
        kind: MovementBlockKind,
        activePatterns: Set<MovementPattern>,
    ): MovementBlock {
        val candidates = blocks.filter { it.kind == kind }
        require(candidates.isNotEmpty()) { "No movement blocks available for $kind" }

        if (activePatterns.isEmpty()) {
            return candidates
                .filter { MovementPattern.MOBILITY in it.movementPatterns }
                .minByOrNull { it.id }
                ?: candidates.minBy { it.id }
        }
        return candidates.sortedWith(
            compareByDescending<MovementBlock> { block ->
                block.movementPatterns.intersect(activePatterns).size
            }.thenBy { it.id },
        ).first()
    }
}
