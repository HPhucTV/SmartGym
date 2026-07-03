package com.example.myapplication.feature.today

import com.example.myapplication.data.CoachReviewClient
import com.example.myapplication.data.CoachReviewRequest
import kotlinx.coroutines.CancellationException

class TodayCoachCoordinator(
    private val client: CoachReviewClient,
) {
    suspend fun review(
        request: CoachReviewRequest,
        cloudAiConsent: Boolean,
        localFallback: String,
    ): String {
        if (!cloudAiConsent) return localFallback
        return try {
            client.reviewToday(request)?.takeIf { it.isNotBlank() } ?: localFallback
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (_: Exception) {
            localFallback
        }
    }
}
