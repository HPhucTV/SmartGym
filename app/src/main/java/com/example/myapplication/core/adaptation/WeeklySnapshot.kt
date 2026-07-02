package com.example.myapplication.core.adaptation

import com.example.myapplication.core.nutrition.NutritionTarget
import com.example.myapplication.core.profile.PersonalProfile

/**
 * Immutable snapshot of a user's weekly data, used as the sole input to [AdaptationEngine.evaluate].
 * Assembled by the caller from Room queries; the engine never touches the database directly.
 */
data class WeeklySnapshot(
    /** Current daily calorie target. */
    val currentCalories: Int,
    /** Full current nutrition target (for macro recalculation). */
    val currentTarget: NutritionTarget,
    /** Seven-day average of actually consumed calories. */
    val averageConsumedCalories: Int,
    /** Fraction of tracked days where consumed ≥ 70% of target (0.0–1.0). */
    val adherencePercent: Double,
    /** Most recent weight measurements in chronological order (oldest first). */
    val recentWeights: List<Double>,
    /** The user's goal weight. */
    val targetWeightKg: Double,
    /** Most recent weekly check-in data, or null if none exists. */
    val latestCheckIn: CheckInData?,
    /** Number of consecutive check-ins with recovery ≤ 2 (for recovery rule). */
    val consecutiveLowRecoveryCheckIns: Int,
    /** Days elapsed since the engine last produced a calorie decision. */
    val daysSinceLastCalorieDecision: Int,
    /** Days elapsed since the engine last produced a workout decision. */
    val daysSinceLastWorkoutDecision: Int,
    /** Total tracked days with nutrition data in this evaluation window. */
    val trackedDays: Int,
    /** Completed workout sessions this program week. */
    val completedSessionsThisWeek: Int,
    /** Scheduled workout sessions this program week. */
    val scheduledSessionsThisWeek: Int,
    /** Number of consecutively missed workout sessions. */
    val missedSessions: Int,
    /** User's age in years (for recalculation). */
    val profileAgeYears: Int,
    /** Full profile (for recalculation when needed). */
    val profile: PersonalProfile,
)

/**
 * Subset of a weekly check-in relevant for adaptation evaluation.
 */
data class CheckInData(
    val energy: Int,
    val hunger: Int,
    val recovery: Int,
    val sleepQuality: Int,
)
