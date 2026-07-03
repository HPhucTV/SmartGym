package com.example.myapplication.core.achievement

import com.example.myapplication.core.model.CompletedWorkout
import com.example.myapplication.data.local.AchievementDao
import com.example.myapplication.data.local.AchievementEntity
import java.time.LocalDate
import java.time.LocalTime

/**
 * Evaluates completed workouts and other signals against achievement rules
 * and persists any newly unlocked achievements.
 *
 * Returns the list of achievements that were newly unlocked in this check
 * so the UI can show a celebration popup.
 */
class AchievementChecker(
    private val achievementDao: AchievementDao,
    private val todayEpochDay: () -> Long = { LocalDate.now().toEpochDay() },
    private val currentHour: () -> Int = { LocalTime.now().hour },
) {
    /**
     * Run a full check after a workout completion.
     * [completed] is the full list of completed workouts.
     * [totalProgramSessions] is the total number of sessions in the active program.
     * [targetPerWeek] is the sessions-per-week goal.
     * [scanCount] is the total number of AI food scans.
     * [checkInCount] is the total number of weekly check-ins.
     * [allMuscleGroupsCount] is the number of distinct muscle groups in the program catalog.
     * [muscleGroupsThisWeek] is the number of distinct muscle groups trained this week.
     */
    suspend fun checkAll(
        completed: List<CompletedWorkout>,
        activeGoalId: Long,
        totalProgramSessions: Int,
        targetPerWeek: Int,
        scanCount: Int = 0,
        checkInCount: Int = 0,
        allMuscleGroupsCount: Int = 0,
        muscleGroupsThisWeek: Int = 0,
    ): List<AchievementType> {
        val existing = achievementDao.getAll().map { it.type }.toSet()
        val now = System.currentTimeMillis()
        val eligible = AchievementRules.evaluate(
            AchievementSnapshot(
                completedEpochDays = completedEpochDaysForGoal(completed, activeGoalId),
                totalProgramSessions = totalProgramSessions,
                targetPerWeek = targetPerWeek,
                todayEpochDay = todayEpochDay(),
                currentHour = currentHour(),
                scanCount = scanCount,
                checkInCount = checkInCount,
                allMuscleGroupsCount = allMuscleGroupsCount,
                muscleGroupsThisWeek = muscleGroupsThisWeek,
            ),
        ).filterNot { it.name in existing }

        return eligible.filter { type ->
            achievementDao.insert(
                AchievementEntity(type = type.name, unlockedAtEpochMillis = now),
            ) != INSERT_IGNORED
        }
    }

    private companion object {
        const val INSERT_IGNORED = -1L
    }
}
