package com.example.myapplication.core.progress

import kotlin.math.ceil

sealed interface GoalForecast {
    data object InsufficientData : GoalForecast
    data class OnTrack(val projectedEpochDay: Long) : GoalForecast
    data class AtRisk(val projectedEpochDay: Long, val sessionsBehind: Int) : GoalForecast
    data object Complete : GoalForecast
}

object GoalForecastCalculator {
    fun calculate(
        totalSessions: Int,
        completedSessions: Int,
        sessionsPerWeek: Int,
        firstDueEpochDay: Long,
        plannedFinalDueEpochDay: Long,
        todayEpochDay: Long,
    ): GoalForecast {
        if (totalSessions <= 0 || sessionsPerWeek <= 0 || completedSessions < 0 ||
            completedSessions > totalSessions
        ) {
            return GoalForecast.InsufficientData
        }
        if (completedSessions == totalSessions) return GoalForecast.Complete

        val elapsedDays = Math.subtractExact(todayEpochDay, firstDueEpochDay)
        if (elapsedDays < 0) return GoalForecast.InsufficientData
        val elapsedWeeks = elapsedDays / 7L
        if (elapsedWeeks < 2 || completedSessions < 2) return GoalForecast.InsufficientData

        val weeklyRate = minOf(completedSessions.toDouble() / elapsedWeeks, sessionsPerWeek.toDouble())
        if (weeklyRate <= 0.0) return GoalForecast.InsufficientData
        val remaining = totalSessions - completedSessions
        val remainingWeeks = ceil(remaining / weeklyRate).toLong()
        val projectedEpochDay = Math.addExact(todayEpochDay, Math.multiplyExact(remainingWeeks, 7L))
        val riskBoundary = Math.addExact(plannedFinalDueEpochDay, 7L)
        if (projectedEpochDay > riskBoundary) {
            val expectedByNow = minOf(
                totalSessions.toLong(),
                Math.multiplyExact(elapsedWeeks, sessionsPerWeek.toLong()),
            ).toInt()
            return GoalForecast.AtRisk(
                projectedEpochDay = projectedEpochDay,
                sessionsBehind = (expectedByNow - completedSessions).coerceAtLeast(0),
            )
        }
        return GoalForecast.OnTrack(projectedEpochDay)
    }
}
