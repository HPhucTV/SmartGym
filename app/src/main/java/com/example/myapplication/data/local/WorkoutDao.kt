package com.example.myapplication.data.local

import androidx.room.Dao
import androidx.room.Embedded
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Relation
import androidx.room.Transaction
import kotlinx.coroutines.flow.Flow

data class GoalWithWorkoutCount(
    @Embedded val goal: GoalEntity,
    val totalWorkouts: Int,
)

data class SessionWithExercises(
    @Embedded val session: WorkoutSessionEntity,
    @Relation(parentColumn = "id", entityColumn = "sessionId")
    val exercises: List<SessionExerciseEntity>,
)

data class CompletedSessionRow(
    val goalId: Long,
    val completedEpochDay: Long,
)

@Dao
interface WorkoutDao {
    @Query(
        """
        SELECT goals.*,
            (SELECT COUNT(*) FROM workout_sessions WHERE workout_sessions.goalId = goals.id) AS totalWorkouts
        FROM goals
        WHERE archived = 0
        ORDER BY id DESC
        LIMIT 1
        """,
    )
    fun observeActiveGoal(): Flow<GoalWithWorkoutCount?>

    @Transaction
    @Query(
        """
        SELECT workout_sessions.* FROM workout_sessions
        INNER JOIN goals ON goals.id = workout_sessions.goalId
        WHERE goals.archived = 0 AND workout_sessions.completedEpochDay IS NULL
        ORDER BY workout_sessions.sequenceIndex ASC, workout_sessions.id ASC
        LIMIT 1
        """,
    )
    fun observeCurrentSession(): Flow<SessionWithExercises?>

    @Query(
        """
        SELECT goalId, completedEpochDay FROM workout_sessions
        WHERE completedEpochDay IS NOT NULL
        ORDER BY completedEpochDay ASC, goalId ASC, sequenceIndex ASC, id ASC
        """,
    )
    fun observeCompletedSessions(): Flow<List<CompletedSessionRow>>

    @Insert
    suspend fun insertGoal(goal: GoalEntity): Long

    @Insert
    suspend fun insertSessions(sessions: List<WorkoutSessionEntity>): List<Long>

    @Insert
    suspend fun insertExercises(exercises: List<SessionExerciseEntity>)

    @Query("SELECT * FROM workout_sessions WHERE goalId = :goalId ORDER BY sequenceIndex ASC, id ASC")
    suspend fun getSessionsForGoal(goalId: Long): List<WorkoutSessionEntity>

    @Query("SELECT * FROM session_exercises WHERE sessionId = :sessionId ORDER BY orderIndex ASC")
    suspend fun getExercisesForSession(sessionId: Long): List<SessionExerciseEntity>

    @Query(
        """
        UPDATE session_exercises SET checked = :checked
        WHERE sessionId = :sessionId AND orderIndex = :orderIndex
          AND EXISTS (
            SELECT 1 FROM workout_sessions target
            INNER JOIN goals target_goal ON target_goal.id = target.goalId
            WHERE target.id = session_exercises.sessionId
              AND target.completedEpochDay IS NULL
              AND target_goal.archived = 0
              AND target.id = (
                SELECT candidate.id FROM workout_sessions candidate
                INNER JOIN goals active_goal ON active_goal.id = candidate.goalId
                WHERE active_goal.archived = 0 AND candidate.completedEpochDay IS NULL
                ORDER BY candidate.sequenceIndex ASC, candidate.id ASC
                LIMIT 1
              )
          )
        """,
    )
    suspend fun setCurrentExerciseChecked(sessionId: Long, orderIndex: Int, checked: Boolean): Int

    @Query("SELECT COUNT(*) FROM session_exercises WHERE sessionId = :sessionId AND checked = 0")
    suspend fun countUnchecked(sessionId: Long): Int

    @Query("SELECT * FROM workout_sessions WHERE id = :sessionId LIMIT 1")
    suspend fun getSession(sessionId: Long): WorkoutSessionEntity?

    @Query(
        """
        SELECT workout_sessions.id FROM workout_sessions
        INNER JOIN goals ON goals.id = workout_sessions.goalId
        WHERE goals.archived = 0 AND workout_sessions.completedEpochDay IS NULL
        ORDER BY workout_sessions.sequenceIndex ASC, workout_sessions.id ASC
        LIMIT 1
        """,
    )
    suspend fun getCurrentSessionId(): Long?

    @Query(
        """
        UPDATE workout_sessions SET completedEpochDay = :completedEpochDay
        WHERE id = :sessionId AND completedEpochDay IS NULL
          AND goalId IN (SELECT id FROM goals WHERE archived = 0)
          AND id = (
            SELECT candidate.id FROM workout_sessions candidate
            INNER JOIN goals active_goal ON active_goal.id = candidate.goalId
            WHERE active_goal.archived = 0 AND candidate.completedEpochDay IS NULL
            ORDER BY candidate.sequenceIndex ASC, candidate.id ASC
            LIMIT 1
          )
        """,
    )
    suspend fun completeSessionIfIncomplete(sessionId: Long, completedEpochDay: Long): Int

    @Query("UPDATE goals SET archived = 1 WHERE archived = 0")
    suspend fun archiveActiveGoals(): Int

    @Query(
        """
        SELECT MAX(dueEpochDay) FROM workout_sessions
        WHERE goalId = :goalId AND sequenceIndex > :sequenceIndex AND completedEpochDay IS NULL
        """,
    )
    suspend fun maxLaterIncompleteDueEpochDay(goalId: Long, sequenceIndex: Int): Long?

    @Query(
        """
        UPDATE workout_sessions SET dueEpochDay = dueEpochDay + :delayDays
        WHERE goalId = :goalId AND sequenceIndex > :sequenceIndex AND completedEpochDay IS NULL
        """,
    )
    suspend fun shiftLaterIncompleteSessions(goalId: Long, sequenceIndex: Int, delayDays: Long): Int
}
