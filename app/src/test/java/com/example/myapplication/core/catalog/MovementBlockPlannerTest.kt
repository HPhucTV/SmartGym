package com.example.myapplication.core.catalog

import com.example.myapplication.core.model.MovementBlock
import com.example.myapplication.core.model.MovementBlockKind
import com.example.myapplication.core.model.MovementPattern
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class MovementBlockPlannerTest {
    private val blocks = listOf(
        block("general_mobility_warmup", MovementBlockKind.WARM_UP, MovementPattern.MOBILITY),
        block("push_warmup", MovementBlockKind.WARM_UP, MovementPattern.HORIZONTAL_PUSH),
        block("push_pull_warmup", MovementBlockKind.WARM_UP, MovementPattern.HORIZONTAL_PUSH, MovementPattern.HORIZONTAL_PULL),
        block("a_push_cooldown", MovementBlockKind.COOL_DOWN, MovementPattern.HORIZONTAL_PUSH),
        block("z_push_cooldown", MovementBlockKind.COOL_DOWN, MovementPattern.HORIZONTAL_PUSH),
    )

    @Test
    fun `selects greatest distinct pattern overlap`() {
        val selected = MovementBlockPlanner.select(
            blocks,
            MovementBlockKind.WARM_UP,
            setOf(MovementPattern.HORIZONTAL_PUSH, MovementPattern.HORIZONTAL_PULL),
        )

        assertEquals("push_pull_warmup", selected.id)
    }

    @Test
    fun `breaks overlap ties by stable block id`() {
        val selected = MovementBlockPlanner.select(
            blocks,
            MovementBlockKind.COOL_DOWN,
            setOf(MovementPattern.HORIZONTAL_PUSH),
        )

        assertEquals("a_push_cooldown", selected.id)
    }

    @Test
    fun `empty workout returns general mobility block`() {
        val selected = MovementBlockPlanner.select(blocks, MovementBlockKind.WARM_UP, emptySet())

        assertEquals("general_mobility_warmup", selected.id)
    }

    @Test
    fun `validator rejects malformed movement blocks`() {
        val malformed = block("Bad ID", MovementBlockKind.WARM_UP).copy(
            titleVi = "",
            stepsVi = listOf("", "b", "c", "d", "e", "f", "g"),
            estimatedMinutes = 1,
        )
        val duplicate = block("duplicate", MovementBlockKind.COOL_DOWN, MovementPattern.CORE)
        val issues = CatalogValidator.validateMovementBlocks(listOf(malformed, duplicate, duplicate))

        listOf("Duplicate", "id", "titleVi", "movementPatterns", "stepsVi", "blank", "estimatedMinutes")
            .forEach { expected ->
                assertTrue("Missing $expected in $issues", issues.any { expected in it })
            }
    }

    private fun block(
        id: String,
        kind: MovementBlockKind,
        vararg patterns: MovementPattern,
    ) = MovementBlock(
        id = id,
        kind = kind,
        movementPatterns = patterns.toSet(),
        titleVi = "Chuẩn bị vận động",
        stepsVi = listOf("Di chuyển chậm và có kiểm soát", "Hít thở đều"),
        estimatedMinutes = 4,
    )
}
