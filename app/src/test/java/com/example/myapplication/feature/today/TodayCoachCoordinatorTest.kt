package com.example.myapplication.feature.today

import com.example.myapplication.data.CoachReviewClient
import com.example.myapplication.data.CoachReviewRequest
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test

class TodayCoachCoordinatorTest {
    @Test
    fun `cloud client is not called without consent`() = runTest {
        val client = FakeCoachReviewClient("cloud")
        val coordinator = TodayCoachCoordinator(client)

        val result = coordinator.review(request(), cloudAiConsent = false, localFallback = "local")

        assertEquals("local", result)
        assertEquals(0, client.calls)
    }

    @Test
    fun `blank or failed cloud response falls back to local advice`() = runTest {
        val blank = TodayCoachCoordinator(FakeCoachReviewClient(" "))
        val failed = TodayCoachCoordinator(FakeCoachReviewClient(error = IllegalStateException("offline")))

        assertEquals("local", blank.review(request(), true, "local"))
        assertEquals("local", failed.review(request(), true, "local"))
    }

    @Test
    fun `consented cloud response is returned`() = runTest {
        val coordinator = TodayCoachCoordinator(FakeCoachReviewClient("cloud advice"))

        assertEquals("cloud advice", coordinator.review(request(), true, "local"))
    }

    private fun request() = CoachReviewRequest(
        goalVi = "Khỏe mạnh",
        levelVi = "Mới bắt đầu",
        sessionTitle = "Toàn thân A",
        completedToday = false,
        caloriesEaten = 1200,
        calorieLimit = 2000,
        proteinEaten = 80,
        carbsEaten = 120,
        fatEaten = 40,
        sweatActive = false,
        sweatExerciseName = "",
        sweatExtraSets = 0,
    )
}

private class FakeCoachReviewClient(
    private val response: String? = null,
    private val error: Exception? = null,
) : CoachReviewClient {
    var calls = 0

    override suspend fun reviewToday(request: CoachReviewRequest): String? {
        calls++
        error?.let { throw it }
        return response
    }
}
