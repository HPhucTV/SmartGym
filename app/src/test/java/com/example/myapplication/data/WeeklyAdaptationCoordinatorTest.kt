package com.example.myapplication.data

import com.example.myapplication.core.adaptation.*
import com.example.myapplication.core.feedback.WorkoutDifficulty
import com.example.myapplication.core.feedback.WorkoutFeedback
import com.example.myapplication.core.model.*
import com.example.myapplication.core.nutrition.Nutrients
import com.example.myapplication.core.nutrition.NutritionDay
import com.example.myapplication.core.nutrition.NutritionTarget
import com.example.myapplication.core.nutrition.NutritionTargetAudit
import com.example.myapplication.core.profile.*
import com.example.myapplication.core.program.ProgramPhase
import com.example.myapplication.data.local.AdaptationDecisionEntity
import java.time.LocalDate
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test

class WeeklyAdaptationCoordinatorTest {
    @Test
    fun `assembler derives chronological feedback and weekly completion counts`() {
        val goal = ActiveGoal(
            id = 1L,
            config = GoalConfig(
                FitnessGoal.GENERAL_FITNESS,
                ExperienceLevel.BEGINNER,
                EquipmentProfile.BODYWEIGHT_ONLY,
                3,
                4,
                RestDayMode.FULL_REST,
            ),
            totalWorkouts = 12,
        )
        val inputs = WeeklySnapshotInputs(
            currentEpochDay = LocalDate.of(2026, 7, 3).toEpochDay(),
            goal = goal,
            currentSession = WorkoutSession(7L, 1L, 3, "B", "Toàn thân", 45, 0L, emptyList()),
            completedWorkouts = listOf(
                CompletedWorkout(1L, LocalDate.of(2026, 6, 30).toEpochDay()),
                CompletedWorkout(1L, LocalDate.of(2026, 7, 2).toEpochDay()),
            ),
            feedback = listOf(
                WorkoutFeedback(2L, 1L, 20L, WorkoutDifficulty.HARD, 2L),
                WorkoutFeedback(1L, 1L, 10L, WorkoutDifficulty.RIGHT, 1L),
            ),
            nutritionDays = (0L..6L).map { offset ->
                NutritionDay(offset, Nutrients(calories = 2000), target())
            },
            recentWeights = listOf(78.0, 77.8),
            checkInsNewestFirst = listOf(CheckInData(3, 3, 2, 3), CheckInData(3, 3, 2, 3)),
            currentTarget = target(),
            profile = profile(),
            daysSinceLastCalorieDecision = 8,
            daysSinceLastWorkoutDecision = 8,
            missedSessions = 2,
        )

        val result = WeeklySnapshotAssembler.build(inputs)

        assertEquals(2, result.completedSessionsThisWeek)
        assertEquals(2, result.missedSessions)
        assertEquals(
            listOf(WorkoutDifficulty.RIGHT, WorkoutDifficulty.HARD),
            result.lastDifficulties.map { it.difficulty },
        )
        assertEquals(2, result.consecutiveLowRecoveryCheckIns)
        assertEquals(ProgramPhase.BUILD, result.currentProgramPhase)
    }

    @Test
    fun `records every decision produced from loaded snapshot`() = runTest {
        val repository = FakeAdaptationRepository()
        val coordinator = WeeklyAdaptationCoordinator(
            snapshotProvider = WeeklySnapshotProvider { snapshot() },
            adaptationRepository = repository,
        )

        val ids = coordinator.evaluateAfterCheckIn(20640L)

        assertEquals(listOf(1L), ids)
        assertEquals(AdaptationKind.DELOAD_WEEK, repository.recorded.single().kind)
    }

    @Test
    fun `missing snapshot records nothing`() = runTest {
        val repository = FakeAdaptationRepository()
        val coordinator = WeeklyAdaptationCoordinator(
            snapshotProvider = WeeklySnapshotProvider { null },
            adaptationRepository = repository,
        )

        assertEquals(emptyList<Long>(), coordinator.evaluateAfterCheckIn(20640L))
        assertEquals(emptyList<AdaptationDecision>(), repository.recorded)
    }

    private fun snapshot() = WeeklySnapshot(
        currentCalories = 2400,
        currentTarget = target(),
        averageConsumedCalories = 2300,
        adherencePercent = 0.8,
        recentWeights = listOf(78.0, 78.1),
        targetWeightKg = 72.0,
        latestCheckIn = CheckInData(3, 3, 3, 3),
        consecutiveLowRecoveryCheckIns = 0,
        daysSinceLastCalorieDecision = 0,
        daysSinceLastWorkoutDecision = 10,
        trackedDays = 7,
        completedSessionsThisWeek = 3,
        scheduledSessionsThisWeek = 3,
        missedSessions = 0,
        profileAgeYears = 31,
        profile = profile(),
        lastDifficulties = listOf(
            WorkoutDifficultySample(20637L, WorkoutDifficulty.HARD),
            WorkoutDifficultySample(20638L, WorkoutDifficulty.HARD),
            WorkoutDifficultySample(20639L, WorkoutDifficulty.HARD),
        ),
        currentProgramPhase = ProgramPhase.BUILD,
    )

    private fun target() = NutritionTarget(
        basalCalories = 1700,
        maintenanceCalories = 2600,
        calories = 2400,
        proteinGrams = 120,
        carbsGrams = 280,
        fatGrams = 60,
        audit = NutritionTargetAudit(1700.0, 2600.0, 2400.0, 120.0, 280.0, 60.0),
    )

    private fun profile() = PersonalProfile(
        birthDateEpochDay = LocalDate.of(1995, 1, 1).toEpochDay(),
        metabolicSex = MetabolicSex.MALE,
        heightCm = 175.0,
        currentWeightKg = 78.0,
        targetWeightKg = 72.0,
        activityLevel = ActivityLevel.MODERATE,
        goalPace = GoalPace.GRADUAL,
        personalizationConsent = true,
        cloudAiConsent = false,
    )
}

private class FakeAdaptationRepository : AdaptationRepository {
    val recorded = mutableListOf<AdaptationDecision>()

    override fun observeDecisions(): Flow<List<AdaptationDecisionEntity>> = flowOf(emptyList())

    override suspend fun recordDecision(decision: AdaptationDecision): Long {
        recorded += decision
        return recorded.size.toLong()
    }

    override suspend fun acceptDecision(decisionId: Long): DecisionActionResult = DecisionActionResult.Success
    override suspend fun rejectDecision(decisionId: Long): DecisionActionResult = DecisionActionResult.Success
    override suspend fun undoLatestDecision(kind: AdaptationKind): DecisionActionResult = DecisionActionResult.Success
}
