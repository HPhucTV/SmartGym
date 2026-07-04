package com.example.myapplication.core.progress

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

class GoalForecastCalculatorTest {
    @Test
    fun `no completions and invalid totals are insufficient`() {
        assertEquals(GoalForecast.InsufficientData, calculate(total = 12, completed = 0))
        assertEquals(GoalForecast.InsufficientData, calculate(total = 0, completed = 0))
        assertEquals(GoalForecast.InsufficientData, calculate(total = -1, completed = 2))
    }

    @Test
    fun `less than two elapsed weeks is insufficient`() {
        assertEquals(
            GoalForecast.InsufficientData,
            calculate(total = 12, completed = 3, firstDue = 100, today = 113),
        )
    }

    @Test
    fun `projects on track from capped weekly rate`() {
        val forecast = calculate(
            total = 12,
            completed = 6,
            sessionsPerWeek = 3,
            firstDue = 100,
            finalDue = 160,
            today = 121,
        )

        assertEquals(GoalForecast.OnTrack(projectedEpochDay = 142), forecast)
    }

    @Test
    fun `marks at risk past planned end and reports sessions behind`() {
        val forecast = calculate(
            total = 12,
            completed = 2,
            sessionsPerWeek = 3,
            firstDue = 100,
            finalDue = 130,
            today = 128,
        )

        assertTrue(forecast is GoalForecast.AtRisk)
        assertEquals(10, (forecast as GoalForecast.AtRisk).sessionsBehind)
    }

    @Test
    fun `past planned end still forecasts and full completion is complete`() {
        assertTrue(
            calculate(12, 8, 3, 100, 120, 135) is GoalForecast.AtRisk,
        )
        assertEquals(GoalForecast.Complete, calculate(12, 12, 3, 100, 120, 135))
    }

    @Test
    fun `date overflow is rejected`() {
        assertThrows(ArithmeticException::class.java) {
            calculate(12, 2, 3, Long.MAX_VALUE - 30, Long.MAX_VALUE - 1, Long.MAX_VALUE - 1)
        }
    }

    private fun calculate(
        total: Int,
        completed: Int,
        sessionsPerWeek: Int = 3,
        firstDue: Long = 100,
        finalDue: Long = 160,
        today: Long = 121,
    ) = GoalForecastCalculator.calculate(
        totalSessions = total,
        completedSessions = completed,
        sessionsPerWeek = sessionsPerWeek,
        firstDueEpochDay = firstDue,
        plannedFinalDueEpochDay = finalDue,
        todayEpochDay = today,
    )
}
