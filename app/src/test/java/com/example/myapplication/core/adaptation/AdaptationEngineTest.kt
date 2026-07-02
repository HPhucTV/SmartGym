package com.example.myapplication.core.adaptation

import com.example.myapplication.core.nutrition.NutritionTarget
import com.example.myapplication.core.nutrition.NutritionTargetAudit
import com.example.myapplication.core.profile.ActivityLevel
import com.example.myapplication.core.profile.GoalPace
import com.example.myapplication.core.profile.MetabolicSex
import com.example.myapplication.core.profile.PersonalProfile
import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class AdaptationEngineTest {
    private val engine = AdaptationEngine()

    // ── Helper builders ─────────────────────────────────────────────────

    private fun defaultProfile() = PersonalProfile(
        birthDateEpochDay = LocalDate.of(1995, 6, 15).toEpochDay(),
        metabolicSex = MetabolicSex.MALE,
        heightCm = 175.0,
        currentWeightKg = 78.0,
        targetWeightKg = 72.0,
        activityLevel = ActivityLevel.MODERATE,
        goalPace = GoalPace.GRADUAL,
        personalizationConsent = true,
        cloudAiConsent = false,
    )

    private fun defaultTarget() = NutritionTarget(
        basalCalories = 1724,
        maintenanceCalories = 2672,
        calories = 2400,
        proteinGrams = 125,
        carbsGrams = 280,
        fatGrams = 67,
        audit = NutritionTargetAudit(
            rawBasalCalories = 1724.0,
            rawMaintenanceCalories = 2672.0,
            rawTargetCalories = 2400.0,
            rawProteinGrams = 125.0,
            rawCarbsGrams = 280.0,
            rawFatGrams = 67.0,
        ),
    )

    private fun defaultCheckIn() = CheckInData(
        energy = 3,
        hunger = 3,
        recovery = 3,
        sleepQuality = 3,
    )

    private fun baseSnapshot(
        currentCalories: Int = 2400,
        averageConsumedCalories: Int = 2300,
        adherencePercent: Double = 0.85,
        recentWeights: List<Double> = listOf(78.0, 78.2),
        targetWeightKg: Double = 72.0,
        latestCheckIn: CheckInData? = defaultCheckIn(),
        consecutiveLowRecoveryCheckIns: Int = 0,
        daysSinceLastCalorieDecision: Int = 10,
        daysSinceLastWorkoutDecision: Int = 10,
        trackedDays: Int = 7,
        completedSessionsThisWeek: Int = 3,
        scheduledSessionsThisWeek: Int = 3,
        missedSessions: Int = 0,
        profileAgeYears: Int = 31,
        profile: PersonalProfile = defaultProfile(),
    ) = WeeklySnapshot(
        currentCalories = currentCalories,
        currentTarget = defaultTarget().copy(calories = currentCalories),
        averageConsumedCalories = averageConsumedCalories,
        adherencePercent = adherencePercent,
        recentWeights = recentWeights,
        targetWeightKg = targetWeightKg,
        latestCheckIn = latestCheckIn,
        consecutiveLowRecoveryCheckIns = consecutiveLowRecoveryCheckIns,
        daysSinceLastCalorieDecision = daysSinceLastCalorieDecision,
        daysSinceLastWorkoutDecision = daysSinceLastWorkoutDecision,
        trackedDays = trackedDays,
        completedSessionsThisWeek = completedSessionsThisWeek,
        scheduledSessionsThisWeek = scheduledSessionsThisWeek,
        missedSessions = missedSessions,
        profileAgeYears = profileAgeYears,
        profile = profile,
    )

    // ── Minimum data requirements ───────────────────────────────────────

    @Test
    fun `returns empty when tracked days below minimum`() {
        val snapshot = baseSnapshot(trackedDays = 5)
        assertEquals(emptyList<AdaptationDecision>(), engine.evaluate(snapshot))
    }

    @Test
    fun `returns empty when no check-in exists`() {
        val snapshot = baseSnapshot(latestCheckIn = null)
        assertEquals(emptyList<AdaptationDecision>(), engine.evaluate(snapshot))
    }

    @Test
    fun `returns empty when fewer than two weight measurements`() {
        val snapshot = baseSnapshot(recentWeights = listOf(78.0))
        assertEquals(emptyList<AdaptationDecision>(), engine.evaluate(snapshot))
    }

    @Test
    fun `returns empty when zero weight measurements`() {
        val snapshot = baseSnapshot(recentWeights = emptyList())
        assertEquals(emptyList<AdaptationDecision>(), engine.evaluate(snapshot))
    }

    // ── Calorie correction: auto-apply ──────────────────────────────────

    @Test
    fun `small calorie decrease auto-applies when losing weight is stalled`() {
        // Want to lose (target 72 < current 78), weight not going down (78 → 78.2)
        val snapshot = baseSnapshot(
            recentWeights = listOf(78.0, 78.2),
            targetWeightKg = 72.0,
            adherencePercent = 0.85,
        )
        val decisions = engine.evaluate(snapshot)
        val calorie = decisions.singleOrNull { it.kind == AdaptationKind.CALORIE_TARGET }
        assertTrue("Expected a calorie decision", calorie != null)
        assertEquals(AdaptationMode.AUTO_APPLY, calorie!!.mode)
        assertTrue("Should decrease calories", calorie.afterValue.contains(Regex("\"calories\":\\d+")))

        // Parse the after calories value and verify it's less than current
        val afterCalories = Regex("\"calories\":(\\d+)").find(calorie.afterValue)?.groupValues?.get(1)?.toInt()
        assertTrue("After calories ($afterCalories) should be less than current (2400)", afterCalories != null && afterCalories < 2400)
    }

    @Test
    fun `small calorie increase auto-applies when gaining too slowly`() {
        // Want to gain (target 85 > current 78), weight stalled (78 → 78.0)
        val profile = defaultProfile().copy(targetWeightKg = 85.0)
        val snapshot = baseSnapshot(
            targetWeightKg = 85.0,
            recentWeights = listOf(78.0, 78.0),
            adherencePercent = 0.80,
            profile = profile,
        )
        val decisions = engine.evaluate(snapshot)
        val calorie = decisions.singleOrNull { it.kind == AdaptationKind.CALORIE_TARGET }
        assertTrue("Expected a calorie decision", calorie != null)
        assertEquals(AdaptationMode.AUTO_APPLY, calorie!!.mode)

        val afterCalories = Regex("\"calories\":(\\d+)").find(calorie.afterValue)?.groupValues?.get(1)?.toInt()
        assertTrue("After calories ($afterCalories) should be more than current (2400)", afterCalories != null && afterCalories > 2400)
    }

    // ── Calorie correction: requires confirmation ───────────────────────

    @Test
    fun `calorie correction requires confirmation when adherence below threshold`() {
        // Weight stalled but adherence is low → can't trust the data for auto-apply
        val snapshot = baseSnapshot(
            recentWeights = listOf(78.0, 78.5),
            targetWeightKg = 72.0,
            adherencePercent = 0.50,
        )
        val decisions = engine.evaluate(snapshot)
        val calorie = decisions.singleOrNull { it.kind == AdaptationKind.CALORIE_TARGET }
        assertTrue("Expected a calorie decision", calorie != null)
        assertEquals(AdaptationMode.REQUIRES_CONFIRMATION, calorie!!.mode)
    }

    // ── Calorie correction: no action needed ────────────────────────────

    @Test
    fun `no calorie decision when weight is trending correctly at acceptable rate`() {
        // Want to lose (target 72), weight going down at reasonable rate (78 → 77.5)
        val snapshot = baseSnapshot(
            recentWeights = listOf(78.0, 77.5),
            targetWeightKg = 72.0,
        )
        val decisions = engine.evaluate(snapshot)
        val calorie = decisions.singleOrNull { it.kind == AdaptationKind.CALORIE_TARGET }
        assertEquals("No calorie adjustment when trending correctly", null, calorie)
    }

    @Test
    fun `no calorie decision when weight already at target`() {
        val snapshot = baseSnapshot(
            recentWeights = listOf(72.0, 72.0),
            targetWeightKg = 72.0,
            profile = defaultProfile().copy(currentWeightKg = 72.0, targetWeightKg = 72.0),
        )
        val decisions = engine.evaluate(snapshot)
        val calorie = decisions.singleOrNull { it.kind == AdaptationKind.CALORIE_TARGET }
        assertEquals(null, calorie)
    }

    // ── Calorie cooldown ────────────────────────────────────────────────

    @Test
    fun `no calorie decision during cooldown period`() {
        val snapshot = baseSnapshot(
            daysSinceLastCalorieDecision = 3, // only 3 days, need 7
            recentWeights = listOf(78.0, 78.5),
            targetWeightKg = 72.0,
        )
        val decisions = engine.evaluate(snapshot)
        val calorie = decisions.singleOrNull { it.kind == AdaptationKind.CALORIE_TARGET }
        assertEquals(null, calorie)
    }

    // ── Calorie cap enforcement ─────────────────────────────────────────

    @Test
    fun `calorie change is capped at 5 percent or 150 kcal`() {
        // With 2400 cal, 5% = 120; should be capped at 120 (less than 150)
        val snapshot = baseSnapshot(
            currentCalories = 2400,
            recentWeights = listOf(78.0, 78.5),
            targetWeightKg = 72.0,
        )
        val decisions = engine.evaluate(snapshot)
        val calorie = decisions.singleOrNull { it.kind == AdaptationKind.CALORIE_TARGET }
        assertTrue("Expected a calorie decision", calorie != null)

        val beforeCalories = Regex("\"calories\":(\\d+)").find(calorie!!.beforeValue)?.groupValues?.get(1)?.toInt()!!
        val afterCalories = Regex("\"calories\":(\\d+)").find(calorie.afterValue)?.groupValues?.get(1)?.toInt()!!
        val actualDelta = kotlin.math.abs(afterCalories - beforeCalories)
        assertTrue("Delta ($actualDelta) should be ≤ 150", actualDelta <= 150)
        assertTrue("Delta ($actualDelta) should be ≤ 5% of current ($beforeCalories)", actualDelta <= (beforeCalories * 0.05 + 1).toInt())
    }

    // ── Losing too fast → small increase ────────────────────────────────

    @Test
    fun `suggests calorie increase when losing weight too fast`() {
        // Losing > 0.9 kg/week
        val snapshot = baseSnapshot(
            recentWeights = listOf(78.0, 76.5), // lost 1.5 kg
            targetWeightKg = 72.0,
        )
        val decisions = engine.evaluate(snapshot)
        val calorie = decisions.singleOrNull { it.kind == AdaptationKind.CALORIE_TARGET }
        assertTrue("Expected a calorie decision", calorie != null)

        val afterCalories = Regex("\"calories\":(\\d+)").find(calorie!!.afterValue)?.groupValues?.get(1)?.toInt()!!
        assertTrue("After calories ($afterCalories) should be more than current (2400)", afterCalories > 2400)
    }

    // ── Recovery suggestion ─────────────────────────────────────────────

    @Test
    fun `suggests recovery when consecutive low recovery check-ins reach threshold`() {
        val snapshot = baseSnapshot(
            consecutiveLowRecoveryCheckIns = 2,
        )
        val decisions = engine.evaluate(snapshot)
        val recovery = decisions.singleOrNull { it.kind == AdaptationKind.RECOVERY_DAY }
        assertTrue("Expected a recovery decision", recovery != null)
        assertEquals(AdaptationMode.AUTO_APPLY, recovery!!.mode)
    }

    @Test
    fun `no recovery suggestion when low recovery count is below threshold`() {
        val snapshot = baseSnapshot(
            consecutiveLowRecoveryCheckIns = 1,
        )
        val decisions = engine.evaluate(snapshot)
        val recovery = decisions.singleOrNull { it.kind == AdaptationKind.RECOVERY_DAY }
        assertEquals(null, recovery)
    }

    @Test
    fun `no recovery suggestion with zero low recovery check-ins`() {
        val snapshot = baseSnapshot(consecutiveLowRecoveryCheckIns = 0)
        val decisions = engine.evaluate(snapshot)
        val recovery = decisions.singleOrNull { it.kind == AdaptationKind.RECOVERY_DAY }
        assertEquals(null, recovery)
    }

    // ── Workout volume ──────────────────────────────────────────────────

    @Test
    fun `missed sessions produce volume decision requiring confirmation`() {
        val snapshot = baseSnapshot(
            missedSessions = 2,
            scheduledSessionsThisWeek = 4,
        )
        val decisions = engine.evaluate(snapshot)
        val volume = decisions.singleOrNull { it.kind == AdaptationKind.WORKOUT_VOLUME }
        assertTrue("Expected a workout volume decision", volume != null)
        assertEquals(AdaptationMode.REQUIRES_CONFIRMATION, volume!!.mode)
    }

    @Test
    fun `one missed session does not trigger volume suggestion`() {
        val snapshot = baseSnapshot(missedSessions = 1)
        val decisions = engine.evaluate(snapshot)
        val volume = decisions.singleOrNull { it.kind == AdaptationKind.WORKOUT_VOLUME }
        assertEquals(null, volume)
    }

    @Test
    fun `workout volume decision respects cooldown`() {
        val snapshot = baseSnapshot(
            missedSessions = 3,
            daysSinceLastWorkoutDecision = 3, // only 3 days, need 7
        )
        val decisions = engine.evaluate(snapshot)
        val volume = decisions.singleOrNull { it.kind == AdaptationKind.WORKOUT_VOLUME }
        assertEquals(null, volume)
    }

    @Test
    fun `volume suggestion does not reduce below 1 session`() {
        val snapshot = baseSnapshot(
            missedSessions = 3,
            scheduledSessionsThisWeek = 1,
        )
        val decisions = engine.evaluate(snapshot)
        val volume = decisions.singleOrNull { it.kind == AdaptationKind.WORKOUT_VOLUME }
        assertTrue("Expected a workout volume decision", volume != null)
        // After value should suggest at least 1 session
        val afterSessions = Regex("\"scheduledSessions\":(\\d+)").find(volume!!.afterValue)?.groupValues?.get(1)?.toInt()
        assertTrue("Scheduled sessions ($afterSessions) should be at least 1", afterSessions != null && afterSessions >= 1)
    }

    // ── Multiple decisions can coexist ───────────────────────────────────

    @Test
    fun `calorie and recovery decisions can be produced simultaneously`() {
        val snapshot = baseSnapshot(
            recentWeights = listOf(78.0, 78.5),
            targetWeightKg = 72.0,
            consecutiveLowRecoveryCheckIns = 3,
        )
        val decisions = engine.evaluate(snapshot)
        val calorie = decisions.singleOrNull { it.kind == AdaptationKind.CALORIE_TARGET }
        val recovery = decisions.singleOrNull { it.kind == AdaptationKind.RECOVERY_DAY }
        assertTrue("Expected both calorie and recovery decisions", calorie != null && recovery != null)
    }

    @Test
    fun `all three decision types can coexist in one evaluation`() {
        val snapshot = baseSnapshot(
            recentWeights = listOf(78.0, 78.5),
            targetWeightKg = 72.0,
            consecutiveLowRecoveryCheckIns = 2,
            missedSessions = 2,
            scheduledSessionsThisWeek = 3,
        )
        val decisions = engine.evaluate(snapshot)
        assertTrue("Expected calorie decision", decisions.any { it.kind == AdaptationKind.CALORIE_TARGET })
        assertTrue("Expected recovery decision", decisions.any { it.kind == AdaptationKind.RECOVERY_DAY })
        assertTrue("Expected volume decision", decisions.any { it.kind == AdaptationKind.WORKOUT_VOLUME })
    }

    // ── Undo payload correctness ────────────────────────────────────────

    @Test
    fun `calorie decision undo payload contains the original calories`() {
        val snapshot = baseSnapshot(
            currentCalories = 2400,
            recentWeights = listOf(78.0, 78.5),
            targetWeightKg = 72.0,
        )
        val decisions = engine.evaluate(snapshot)
        val calorie = decisions.single { it.kind == AdaptationKind.CALORIE_TARGET }
        assertEquals("""{"calories":2400}""", calorie.undoPayload)
        assertEquals("""{"calories":2400}""", calorie.beforeValue)
    }

    // ── Reason text is non-empty Vietnamese ─────────────────────────────

    @Test
    fun `all decisions have non-empty Vietnamese reason text`() {
        val snapshot = baseSnapshot(
            recentWeights = listOf(78.0, 78.5),
            targetWeightKg = 72.0,
            consecutiveLowRecoveryCheckIns = 2,
            missedSessions = 2,
        )
        val decisions = engine.evaluate(snapshot)
        assertTrue("Should have decisions", decisions.isNotEmpty())
        decisions.forEach { decision ->
            assertTrue("Reason should not be blank: ${decision.kind}", decision.reasonVi.isNotBlank())
        }
    }
}
