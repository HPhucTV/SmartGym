package com.example.myapplication.core.achievement

import com.example.myapplication.core.model.CompletedWorkout
import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AchievementRulesTest {
    private val today = LocalDate.of(2026, 7, 3).toEpochDay()

    @Test
    fun `half program rounds up for an odd number of sessions`() {
        val oneOfThree = snapshot(completedEpochDays = listOf(today), totalProgramSessions = 3)
        val twoOfThree = snapshot(completedEpochDays = listOf(today - 1, today), totalProgramSessions = 3)

        assertFalse(AchievementType.HALF_PROGRAM in AchievementRules.evaluate(oneOfThree))
        assertTrue(AchievementType.HALF_PROGRAM in AchievementRules.evaluate(twoOfThree))
    }

    @Test
    fun `streak is calculated from the supplied day instead of the device clock`() {
        val result = AchievementRules.evaluate(
            snapshot(completedEpochDays = (0L..6L).map { today - it }),
        )

        assertTrue(AchievementType.STREAK_7 in result)
        assertFalse(AchievementType.STREAK_14 in result)
    }

    @Test
    fun `time badges require a completion on the supplied day`() {
        val previousWorkout = AchievementRules.evaluate(
            snapshot(completedEpochDays = listOf(today - 1), currentHour = 6),
        )
        val completedThisMorning = AchievementRules.evaluate(
            snapshot(completedEpochDays = listOf(today), currentHour = 6),
        )

        assertFalse(AchievementType.EARLY_BIRD in previousWorkout)
        assertTrue(AchievementType.EARLY_BIRD in completedThisMorning)
    }

    @Test
    fun `program progress excludes completed workouts from replaced goals`() {
        val history = listOf(
            CompletedWorkout(goalId = 1, completedEpochDay = today - 1),
            CompletedWorkout(goalId = 2, completedEpochDay = today),
        )

        assertEquals(listOf(today), completedEpochDaysForGoal(history, activeGoalId = 2))
    }

    private fun snapshot(
        completedEpochDays: List<Long>,
        totalProgramSessions: Int = 20,
        targetPerWeek: Int = 3,
        currentHour: Int = 12,
    ) = AchievementSnapshot(
        completedEpochDays = completedEpochDays,
        totalProgramSessions = totalProgramSessions,
        targetPerWeek = targetPerWeek,
        todayEpochDay = today,
        currentHour = currentHour,
    )
}
