package com.example.myapplication.core.program

import com.example.myapplication.core.model.ExercisePrescription
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SessionTimeBudgetPlannerTest {
    private val exercises = listOf(
        prescription("compound", sets = 6, reps = 12, rest = 90),
        prescription("second", sets = 6, reps = 12, rest = 90),
        prescription("third", sets = 6, reps = 12, rest = 90),
        prescription("fourth", sets = 6, reps = 12, rest = 90),
    )

    @Test
    fun `short budget always keeps first compound exercise`() {
        val result = SessionTimeBudgetPlanner.select(exercises, 15)

        assertTrue(result.activeOrderIndices.isNotEmpty())
        assertEquals(0, result.activeOrderIndices.first())
    }

    @Test
    fun `larger budgets monotonically add an ordered prefix`() {
        val short = SessionTimeBudgetPlanner.select(exercises, 15).activeOrderIndices
        val medium = SessionTimeBudgetPlanner.select(exercises, 30).activeOrderIndices
        val long = SessionTimeBudgetPlanner.select(exercises, 45).activeOrderIndices

        assertTrue(short.all { it in medium })
        assertTrue(medium.all { it in long })
        assertEquals(short.indices.toList(), short)
        assertEquals(medium.indices.toList(), medium)
        assertEquals(long.indices.toList(), long)
    }

    @Test
    fun `estimate uses active work plus rest for every set`() {
        val result = SessionTimeBudgetPlanner.select(
            listOf(ExercisePrescription("hold", 3, durationSeconds = 30, restSeconds = 60)),
            15,
        )

        assertEquals(5, result.estimatedMinutes)
    }

    private fun prescription(id: String, sets: Int, reps: Int, rest: Int) =
        ExercisePrescription(id, sets, reps, reps, restSeconds = rest)
}
