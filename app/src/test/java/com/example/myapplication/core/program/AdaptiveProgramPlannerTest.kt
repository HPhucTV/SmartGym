package com.example.myapplication.core.program

import com.example.myapplication.core.model.*
import java.time.DayOfWeek
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class AdaptiveProgramPlannerTest {
    @Test
    fun `cycles reviewed workouts for requested weekly frequency`() {
        val plan = AdaptiveProgramPlanner.adapt(program(), config(6, 45))

        assertEquals(12, plan.size)
        assertEquals((0 until 12).toList(), plan.map { it.sequence })
        assertEquals(listOf("A", "B", "A", "B", "A", "B"), plan.take(6).map { it.titleVi })
    }

    @Test
    fun `longer duration monotonically adds reviewed exercises`() {
        val short = AdaptiveProgramPlanner.adapt(program(), config(3, 30)).first().exercises.map { it.exerciseId }
        val long = AdaptiveProgramPlanner.adapt(program(), config(3, 90)).first().exercises.map { it.exerciseId }

        assertTrue(short.isNotEmpty())
        assertTrue(long.size >= short.size)
        assertEquals(short, long.take(short.size))
        assertTrue(long.all { it in setOf("one", "two", "three", "four") })
    }

    @Test
    fun `same inputs always produce identical snapshots`() {
        val first = AdaptiveProgramPlanner.adapt(program(), config(5, 75))
        val second = AdaptiveProgramPlanner.adapt(program(), config(5, 75))

        assertEquals(first, second)
    }

    private fun config(sessions: Int, minutes: Int) = GoalConfig(
        FitnessGoal.GENERAL_FITNESS,
        ExperienceLevel.BEGINNER,
        EquipmentProfile.BODYWEIGHT_ONLY,
        sessions,
        2,
        RestDayMode.FULL_REST,
        DayOfWeek.entries.take(sessions).toSet(),
        minutes,
    )

    private fun program() = ProgramTemplate(
        id = "base",
        goal = FitnessGoal.GENERAL_FITNESS,
        level = ExperienceLevel.BEGINNER,
        equipmentProfile = EquipmentProfile.BODYWEIGHT_ONLY,
        sessionsPerWeek = 2,
        durationWeeks = 2,
        workouts = listOf(
            workout(0, 1, "A", "one", "two"),
            workout(1, 1, "B", "three", "four"),
            workout(2, 2, "A", "one", "two"),
            workout(3, 2, "B", "three", "four"),
        ),
    )

    private fun workout(sequence: Int, week: Int, title: String, vararg ids: String) = WorkoutTemplate(
        sequence = sequence,
        week = week,
        titleVi = title,
        focusVi = title,
        estimatedMinutes = 45,
        restDaysAfter = 0,
        exercises = ids.map { id -> ExercisePrescription(id, 3, 10, 12, null, 60) },
    )
}
