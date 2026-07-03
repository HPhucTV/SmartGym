package com.example.myapplication.core.achievement

import com.example.myapplication.core.model.CompletedWorkout
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.TemporalAdjusters

data class AchievementSnapshot(
    val completedEpochDays: List<Long>,
    val totalProgramSessions: Int,
    val targetPerWeek: Int,
    val todayEpochDay: Long,
    val currentHour: Int,
    val scanCount: Int = 0,
    val checkInCount: Int = 0,
    val allMuscleGroupsCount: Int = 0,
    val muscleGroupsThisWeek: Int = 0,
)

internal fun completedEpochDaysForGoal(
    history: List<CompletedWorkout>,
    activeGoalId: Long,
): List<Long> = history
    .asSequence()
    .filter { it.goalId == activeGoalId }
    .map { it.completedEpochDay }
    .toList()

object AchievementRules {
    fun evaluate(snapshot: AchievementSnapshot): Set<AchievementType> {
        val completedDays = snapshot.completedEpochDays.toSortedSet()
        val totalCompleted = snapshot.completedEpochDays.size
        val result = mutableSetOf<AchievementType>()
        val streak = currentStreak(completedDays, snapshot.todayEpochDay)
        val weekStart = LocalDate.ofEpochDay(snapshot.todayEpochDay)
            .with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
            .toEpochDay()
        val completedThisWeek = snapshot.completedEpochDays.count { it in weekStart..(weekStart + 6) }
        val completedToday = snapshot.todayEpochDay in completedDays

        result.addIf(AchievementType.FIRST_WORKOUT, totalCompleted >= 1)
        result.addIf(AchievementType.STREAK_7, streak >= 7)
        result.addIf(AchievementType.STREAK_14, streak >= 14)
        result.addIf(AchievementType.STREAK_30, streak >= 30)
        result.addIf(AchievementType.PERFECT_WEEK, snapshot.targetPerWeek > 0 && completedThisWeek >= snapshot.targetPerWeek)
        result.addIf(
            AchievementType.HALF_PROGRAM,
            snapshot.totalProgramSessions > 0 && totalCompleted >= (snapshot.totalProgramSessions + 1) / 2,
        )
        result.addIf(AchievementType.FULL_PROGRAM, snapshot.totalProgramSessions > 0 && totalCompleted >= snapshot.totalProgramSessions)
        result.addIf(AchievementType.SCAN_10, snapshot.scanCount >= 10)
        result.addIf(AchievementType.CHECKIN_4, snapshot.checkInCount >= 4)
        result.addIf(
            AchievementType.ALL_MUSCLES,
            snapshot.allMuscleGroupsCount > 0 && snapshot.muscleGroupsThisWeek >= snapshot.allMuscleGroupsCount,
        )
        result.addIf(AchievementType.EARLY_BIRD, completedToday && snapshot.currentHour < 7)
        result.addIf(AchievementType.NIGHT_OWL, completedToday && snapshot.currentHour >= 21)
        result.addIf(AchievementType.WORKOUTS_10, totalCompleted >= 10)
        result.addIf(AchievementType.WORKOUTS_50, totalCompleted >= 50)
        result.addIf(AchievementType.WORKOUTS_100, totalCompleted >= 100)
        return result
    }

    private fun currentStreak(completedDays: Set<Long>, todayEpochDay: Long): Int {
        var cursor = if (todayEpochDay in completedDays) todayEpochDay else todayEpochDay - 1
        var streak = 0
        while (cursor in completedDays) {
            streak++
            cursor--
        }
        return streak
    }

    private fun MutableSet<AchievementType>.addIf(type: AchievementType, condition: Boolean) {
        if (condition) add(type)
    }
}
