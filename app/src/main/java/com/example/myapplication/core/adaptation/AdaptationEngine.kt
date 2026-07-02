package com.example.myapplication.core.adaptation

import com.example.myapplication.core.nutrition.NutritionTargetCalculator
import com.example.myapplication.core.nutrition.CalculationResult
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * Pure, deterministic rules engine that evaluates a [WeeklySnapshot] and produces
 * zero or more [AdaptationDecision] objects.
 *
 * Design invariants:
 * - The engine never reads from or writes to a database.
 * - Program, volume, target-weight, and session-count changes always require confirmation.
 * - Small capped calorie corrections can auto-apply when data quality gates pass.
 * - Recovery suggestions never delete or skip workouts.
 * - At most one calorie decision per 7 days and one workout decision per 7 days.
 * - Insufficient or contradictory data produces an empty list.
 */
class AdaptationEngine(
    private val calculator: NutritionTargetCalculator = NutritionTargetCalculator(),
) {

    fun evaluate(snapshot: WeeklySnapshot): List<AdaptationDecision> {
        // Gate 1: minimum data requirements
        if (!hasMinimumData(snapshot)) return emptyList()

        val decisions = mutableListOf<AdaptationDecision>()

        // Rule group 1: calorie target adjustment
        evaluateCalorieAdjustment(snapshot)?.let { decisions.add(it) }

        // Rule group 2: recovery suggestion
        evaluateRecoverySuggestion(snapshot)?.let { decisions.add(it) }

        // Rule group 3: workout volume / missed sessions
        evaluateWorkoutVolume(snapshot)?.let { decisions.add(it) }

        return decisions
    }

    // ── Data quality gates ──────────────────────────────────────────────

    private fun hasMinimumData(snapshot: WeeklySnapshot): Boolean {
        // Need at least 7 tracked days of nutrition data
        if (snapshot.trackedDays < MINIMUM_TRACKED_DAYS) return false
        // Need at least one check-in
        if (snapshot.latestCheckIn == null) return false
        // Need at least 2 weight measurements for a trend
        if (snapshot.recentWeights.size < MINIMUM_WEIGHT_MEASUREMENTS) return false
        return true
    }

    // ── Calorie adjustment ──────────────────────────────────────────────

    private fun evaluateCalorieAdjustment(snapshot: WeeklySnapshot): AdaptationDecision? {
        // Cooldown: at most one calorie decision per 7 days
        if (snapshot.daysSinceLastCalorieDecision < CALORIE_COOLDOWN_DAYS) return null

        // Adherence must be at least 70% for auto-apply
        val adherenceOk = snapshot.adherencePercent >= MINIMUM_ADHERENCE

        // Determine weight trend from the two most recent measurements
        val weights = snapshot.recentWeights
        if (weights.size < MINIMUM_WEIGHT_MEASUREMENTS) return null
        val recentWeight = weights.last()
        val previousWeight = weights[weights.size - 2]
        val weightDelta = recentWeight - previousWeight

        // Decide direction: if losing weight toward target, check if on track
        val wantToLose = snapshot.targetWeightKg < recentWeight
        val wantToGain = snapshot.targetWeightKg > recentWeight
        val onTarget = !wantToLose && !wantToGain

        // If weight is at target, no adjustment needed
        if (onTarget) return null

        // Determine needed calorie delta
        val requestedDelta: Int = when {
            wantToLose && weightDelta >= 0 -> {
                // Stalled or gaining when should be losing → decrease calories
                -calculateSuggestedDelta(snapshot)
            }
            wantToLose && weightDelta < -MAXIMUM_WEEKLY_WEIGHT_LOSS_KG -> {
                // Losing too fast → increase calories slightly
                calculateSuggestedDelta(snapshot) / 2
            }
            wantToGain && weightDelta <= 0 -> {
                // Stalled or losing when should be gaining → increase calories
                calculateSuggestedDelta(snapshot)
            }
            wantToGain && weightDelta > MAXIMUM_WEEKLY_WEIGHT_GAIN_KG -> {
                // Gaining too fast → decrease slightly
                -calculateSuggestedDelta(snapshot) / 2
            }
            else -> {
                // Trending in the right direction at an acceptable rate
                return null
            }
        }

        if (requestedDelta == 0) return null

        // Apply the cap
        val cappedDelta = calculator.capAutomaticCalorieDelta(
            currentCalories = snapshot.currentCalories,
            requestedDelta = requestedDelta,
        )

        if (cappedDelta == 0) return null

        val newCalories = snapshot.currentCalories + cappedDelta
        val fitsInCap = cappedDelta == requestedDelta
        val mode = if (fitsInCap && adherenceOk) {
            AdaptationMode.AUTO_APPLY
        } else {
            AdaptationMode.REQUIRES_CONFIRMATION
        }

        val reason = buildCalorieReason(cappedDelta, weightDelta, wantToLose, adherenceOk)

        return AdaptationDecision(
            kind = AdaptationKind.CALORIE_TARGET,
            mode = mode,
            reasonVi = reason,
            beforeValue = """{"calories":${snapshot.currentCalories}}""",
            afterValue = """{"calories":$newCalories}""",
            undoPayload = """{"calories":${snapshot.currentCalories}}""",
        )
    }

    private fun calculateSuggestedDelta(snapshot: WeeklySnapshot): Int {
        // Base suggestion: 5% of current or 150, whichever is smaller
        val fivePercent = (snapshot.currentCalories * AUTOMATIC_CHANGE_RATE).roundToInt()
        return minOf(fivePercent, MAXIMUM_AUTOMATIC_CALORIES)
    }

    private fun buildCalorieReason(
        delta: Int,
        weightDelta: Double,
        wantToLose: Boolean,
        adherenceOk: Boolean,
    ): String {
        val direction = if (delta > 0) "tăng" else "giảm"
        val absDelta = abs(delta)
        val weightTrend = when {
            weightDelta > 0.01 -> "tăng %.1f kg".format(weightDelta)
            weightDelta < -0.01 -> "giảm %.1f kg".format(abs(weightDelta))
            else -> "không thay đổi"
        }
        val adherenceNote = if (!adherenceOk) " (lưu ý: mức tuân thủ dưới 70%)" else ""
        return "Cân nặng tuần qua $weightTrend. Đề xuất $direction $absDelta kcal/ngày$adherenceNote."
    }

    // ── Recovery suggestion ─────────────────────────────────────────────

    private fun evaluateRecoverySuggestion(snapshot: WeeklySnapshot): AdaptationDecision? {
        // Need at least 2 consecutive check-ins with low recovery
        if (snapshot.consecutiveLowRecoveryCheckIns < MINIMUM_LOW_RECOVERY_CHECKINS) return null

        return AdaptationDecision(
            kind = AdaptationKind.RECOVERY_DAY,
            mode = AdaptationMode.AUTO_APPLY,
            reasonVi = "Khả năng phục hồi thấp trong ${snapshot.consecutiveLowRecoveryCheckIns} " +
                "check-in liên tiếp. Đề xuất ưu tiên nghỉ ngơi và giảm cường độ tập luyện.",
            beforeValue = """{"recoveryStatus":"normal"}""",
            afterValue = """{"recoveryStatus":"suggested_rest"}""",
            undoPayload = """{"recoveryStatus":"normal"}""",
        )
    }

    // ── Workout volume / missed sessions ────────────────────────────────

    private fun evaluateWorkoutVolume(snapshot: WeeklySnapshot): AdaptationDecision? {
        // Cooldown: at most one workout decision per 7 days
        if (snapshot.daysSinceLastWorkoutDecision < WORKOUT_COOLDOWN_DAYS) return null

        if (snapshot.missedSessions < MINIMUM_MISSED_SESSIONS_FOR_SUGGESTION) return null

        // Workout volume changes always require confirmation
        return AdaptationDecision(
            kind = AdaptationKind.WORKOUT_VOLUME,
            mode = AdaptationMode.REQUIRES_CONFIRMATION,
            reasonVi = "Đã bỏ lỡ ${snapshot.missedSessions} buổi tập liên tiếp. " +
                "Đề xuất điều chỉnh khối lượng tập luyện để phù hợp hơn với lịch trình hiện tại.",
            beforeValue = """{"scheduledSessions":${snapshot.scheduledSessionsThisWeek}}""",
            afterValue = """{"scheduledSessions":${maxOf(1, snapshot.scheduledSessionsThisWeek - 1)}}""",
            undoPayload = """{"scheduledSessions":${snapshot.scheduledSessionsThisWeek}}""",
        )
    }

    companion object {
        /** Minimum tracked nutrition days before the engine evaluates. */
        const val MINIMUM_TRACKED_DAYS = 7
        /** Minimum weight measurements needed to establish a trend. */
        const val MINIMUM_WEIGHT_MEASUREMENTS = 2
        /** Cooldown period (days) between calorie decisions. */
        const val CALORIE_COOLDOWN_DAYS = 7
        /** Cooldown period (days) between workout decisions. */
        const val WORKOUT_COOLDOWN_DAYS = 7
        /** Minimum nutrition adherence for auto-apply calorie changes. */
        const val MINIMUM_ADHERENCE = 0.70
        /** Max fraction of current calories for automatic change. */
        const val AUTOMATIC_CHANGE_RATE = 0.05
        /** Absolute max automatic calorie change. */
        const val MAXIMUM_AUTOMATIC_CALORIES = 150
        /** Number of consecutive low-recovery check-ins to trigger a suggestion. */
        const val MINIMUM_LOW_RECOVERY_CHECKINS = 2
        /** Number of missed sessions to trigger a volume suggestion. */
        const val MINIMUM_MISSED_SESSIONS_FOR_SUGGESTION = 2
        /** Weekly weight loss above this (kg) is considered too fast. */
        const val MAXIMUM_WEEKLY_WEIGHT_LOSS_KG = 0.9
        /** Weekly weight gain above this (kg) is considered too fast. */
        const val MAXIMUM_WEEKLY_WEIGHT_GAIN_KG = 0.5
    }
}
