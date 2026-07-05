package com.example.myapplication.data

import com.example.myapplication.core.adaptation.AdaptationEngine
import com.example.myapplication.core.adaptation.CheckInData
import com.example.myapplication.core.adaptation.WorkoutDifficultySample
import com.example.myapplication.core.adaptation.WeeklySnapshot
import com.example.myapplication.core.feedback.WorkoutFeedback
import com.example.myapplication.core.model.ActiveGoal
import com.example.myapplication.core.model.CompletedWorkout
import com.example.myapplication.core.model.WorkoutSession
import com.example.myapplication.core.nutrition.NutritionDay
import com.example.myapplication.core.nutrition.NutritionTarget
import com.example.myapplication.core.profile.PersonalProfile
import com.example.myapplication.core.program.ProgramPhase
import com.example.myapplication.core.program.ProgramPhasePlanner
import com.example.myapplication.data.local.PersonalizationDao
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.Period
import java.time.temporal.TemporalAdjusters
import kotlinx.coroutines.flow.first

fun interface WeeklySnapshotProvider {
    suspend fun snapshotFor(currentEpochDay: Long): WeeklySnapshot?
}

class WeeklyAdaptationCoordinator(
    private val snapshotProvider: WeeklySnapshotProvider,
    private val adaptationRepository: AdaptationRepository,
    private val engine: AdaptationEngine = AdaptationEngine(),
) {
    suspend fun evaluateAfterCheckIn(currentEpochDay: Long): List<Long> {
        val snapshot = snapshotProvider.snapshotFor(currentEpochDay) ?: return emptyList()
        return engine.evaluate(snapshot).map { decision ->
            adaptationRepository.recordDecision(decision)
        }
    }
}

data class WeeklySnapshotInputs(
    val currentEpochDay: Long,
    val goal: ActiveGoal,
    val currentSession: WorkoutSession?,
    val completedWorkouts: List<CompletedWorkout>,
    val feedback: List<WorkoutFeedback>,
    val nutritionDays: List<NutritionDay>,
    val recentWeights: List<Double>,
    val checkInsNewestFirst: List<CheckInData>,
    val currentTarget: NutritionTarget,
    val profile: PersonalProfile,
    val daysSinceLastCalorieDecision: Int,
    val daysSinceLastWorkoutDecision: Int,
    val missedSessions: Int = 0,
)

object WeeklySnapshotAssembler {
    fun build(inputs: WeeklySnapshotInputs): WeeklySnapshot {
        val currentDate = LocalDate.ofEpochDay(inputs.currentEpochDay)
        val weekStart = currentDate.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)).toEpochDay()
        val weekEnd = Math.addExact(weekStart, 6L)
        val completedThisWeek = inputs.completedWorkouts.count { workout ->
            workout.goalId == inputs.goal.id && workout.completedEpochDay in weekStart..weekEnd
        }
        val trackedDays = inputs.nutritionDays.filter { it.consumed.calories > 0 }
        val averageConsumed = trackedDays.map { it.consumed.calories }
            .average()
            .takeUnless(Double::isNaN)
            ?.toInt()
            ?: 0
        val adherence = if (trackedDays.isEmpty()) {
            0.0
        } else {
            trackedDays.count { it.consumed.calories >= inputs.currentTarget.calories * 0.7 }
                .toDouble() / trackedDays.size
        }
        val durationWeeks = inputs.goal.config.durationWeeks.coerceAtLeast(1)
        val currentWeek = inputs.currentSession
            ?.let { it.sequenceIndex / inputs.goal.config.sessionsPerWeek.coerceAtLeast(1) + 1 }
            ?.coerceIn(1, durationWeeks)
            ?: durationWeeks
        val phase = ProgramPhasePlanner.phaseFor(currentWeek, durationWeeks)

        return WeeklySnapshot(
            currentCalories = inputs.currentTarget.calories,
            currentTarget = inputs.currentTarget,
            averageConsumedCalories = averageConsumed,
            adherencePercent = adherence,
            recentWeights = inputs.recentWeights,
            targetWeightKg = inputs.profile.targetWeightKg,
            latestCheckIn = inputs.checkInsNewestFirst.firstOrNull(),
            consecutiveLowRecoveryCheckIns = inputs.checkInsNewestFirst.takeWhile { it.recovery <= 2 }.size,
            daysSinceLastCalorieDecision = inputs.daysSinceLastCalorieDecision,
            daysSinceLastWorkoutDecision = inputs.daysSinceLastWorkoutDecision,
            trackedDays = trackedDays.size,
            completedSessionsThisWeek = completedThisWeek,
            scheduledSessionsThisWeek = inputs.goal.config.sessionsPerWeek,
            missedSessions = inputs.missedSessions,
            profileAgeYears = Period.between(
                LocalDate.ofEpochDay(inputs.profile.birthDateEpochDay),
                currentDate,
            ).years,
            profile = inputs.profile,
            lastDifficulties = inputs.feedback.sortedBy(WorkoutFeedback::completedEpochDay)
                .takeLast(4)
                .map { WorkoutDifficultySample(it.completedEpochDay, it.difficulty) },
            currentProgramPhase = phase,
        )
    }
}

class RoomWeeklySnapshotProvider(
    private val personalizationDao: PersonalizationDao,
    private val workoutRepository: WorkoutRepository,
    private val feedbackRepository: WorkoutFeedbackRepository,
    private val nutritionRepository: NutritionRepository,
    private val nowEpochMillis: () -> Long = { System.currentTimeMillis() },
) : WeeklySnapshotProvider {
    override suspend fun snapshotFor(currentEpochDay: Long): WeeklySnapshot? {
        val goal = workoutRepository.observeActiveGoal().first() ?: return null
        val profileEntity = personalizationDao.profileNow() ?: return null
        val currentTarget = nutritionRepository.observeDay(currentEpochDay).first().target ?: return null
        val rangeStart = Math.subtractExact(currentEpochDay, 6L)
        val decisions = personalizationDao.decisionHistoryNow()
        val allSessions = workoutRepository.observeWorkoutHistory().first().filter { it.goalId == goal.id }
        val missedCount = allSessions.count { it.completedEpochDay == null && it.dueEpochDay < currentEpochDay }

        return WeeklySnapshotAssembler.build(
            WeeklySnapshotInputs(
                currentEpochDay = currentEpochDay,
                goal = goal,
                currentSession = workoutRepository.observeCurrentWorkout().first(),
                completedWorkouts = workoutRepository.observeCompletedWorkouts().first(),
                feedback = feedbackRepository.observeForGoal(goal.id).first(),
                nutritionDays = nutritionRepository.observeRange(rangeStart, currentEpochDay).first(),
                recentWeights = personalizationDao.weightHistoryNow().takeLast(4).map { it.weightKg },
                checkInsNewestFirst = personalizationDao.observeAllCheckIns().first().map { row ->
                    CheckInData(row.energy, row.hunger, row.recovery, row.sleepQuality)
                },
                currentTarget = currentTarget,
                profile = PersonalProfile(
                    birthDateEpochDay = profileEntity.birthDateEpochDay,
                    metabolicSex = profileEntity.metabolicSex,
                    heightCm = profileEntity.heightCm,
                    currentWeightKg = profileEntity.currentWeightKg,
                    targetWeightKg = profileEntity.targetWeightKg,
                    activityLevel = profileEntity.activityLevel,
                    goalPace = profileEntity.goalPace,
                    personalizationConsent = profileEntity.personalizationConsent,
                    cloudAiConsent = profileEntity.cloudAiConsent,
                ),
                daysSinceLastCalorieDecision = daysSinceLastDecision(
                    decisions.filter { it.kind == com.example.myapplication.core.adaptation.AdaptationKind.CALORIE_TARGET }
                        .maxOfOrNull { it.createdAtEpochMillis },
                ),
                daysSinceLastWorkoutDecision = daysSinceLastDecision(
                    decisions.filter {
                        it.kind == com.example.myapplication.core.adaptation.AdaptationKind.WORKOUT_VOLUME ||
                            it.kind == com.example.myapplication.core.adaptation.AdaptationKind.DELOAD_WEEK
                    }.maxOfOrNull { it.createdAtEpochMillis },
                ),
                missedSessions = missedCount,
            ),
        )
    }

    private fun daysSinceLastDecision(createdAtEpochMillis: Long?): Int {
        if (createdAtEpochMillis == null) return Int.MAX_VALUE
        val elapsed = (nowEpochMillis() - createdAtEpochMillis).coerceAtLeast(0L)
        return (elapsed / MILLIS_PER_DAY).coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
    }

    private companion object {
        const val MILLIS_PER_DAY = 86_400_000L
    }
}
