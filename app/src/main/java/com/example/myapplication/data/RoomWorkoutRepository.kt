package com.example.myapplication.data

import androidx.room.withTransaction
import com.example.myapplication.core.model.ActiveGoal
import com.example.myapplication.core.model.CompletedWorkout
import com.example.myapplication.core.model.ExercisePrescription
import com.example.myapplication.core.model.GoalConfig
import com.example.myapplication.core.model.ProgramTemplate
import com.example.myapplication.core.model.WorkoutExercise
import com.example.myapplication.core.model.WorkoutSession
import com.example.myapplication.core.program.SchedulePlanner
import com.example.myapplication.data.local.GoalEntity
import com.example.myapplication.data.local.GymDatabase
import com.example.myapplication.data.local.SessionExerciseEntity
import com.example.myapplication.data.local.SessionWithExercises
import com.example.myapplication.data.local.WorkoutSessionEntity
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class RoomWorkoutRepository(
    private val database: GymDatabase,
) : WorkoutRepository {
    private val dao = database.workoutDao()

    override fun observeActiveGoal(): Flow<ActiveGoal?> = dao.observeActiveGoal().map { row ->
        row?.let {
            ActiveGoal(
                id = it.goal.id,
                config = GoalConfig(
                    goal = it.goal.goal,
                    level = it.goal.level,
                    equipmentProfile = it.goal.equipmentProfile,
                    sessionsPerWeek = it.goal.sessionsPerWeek,
                    durationWeeks = it.goal.durationWeeks,
                    restDayMode = it.goal.restDayMode,
                ),
                totalWorkouts = it.totalWorkouts,
            )
        }
    }

    override fun observeCurrentWorkout(): Flow<WorkoutSession?> = dao.observeCurrentSession().map { row ->
        row?.toDomain()
    }

    override fun observeCompletedWorkouts(): Flow<List<CompletedWorkout>> =
        dao.observeCompletedSessions().map { rows ->
            rows.map { CompletedWorkout(it.goalId, it.completedEpochDay) }
        }

    override suspend fun createGoal(
        config: GoalConfig,
        program: ProgramTemplate,
        startEpochDay: Long,
    ) {
        validateProgramMatch(config, program)
        val orderedWorkouts = program.workouts.sortedBy { it.sequence }
        require(orderedWorkouts.map { it.sequence } == orderedWorkouts.indices.toList()) {
            "Program workouts must use contiguous sequence values starting at zero"
        }
        val dueEpochDays = SchedulePlanner.dueEpochDays(
            startEpochDay,
            orderedWorkouts.map { it.restDaysAfter },
        )

        database.withTransaction {
            dao.archiveActiveGoals()
            val goalId = dao.insertGoal(
                GoalEntity(
                    programId = program.id,
                    goal = config.goal,
                    level = config.level,
                    equipmentProfile = config.equipmentProfile,
                    sessionsPerWeek = config.sessionsPerWeek,
                    durationWeeks = config.durationWeeks,
                    restDayMode = config.restDayMode,
                    createdEpochDay = startEpochDay,
                ),
            )
            val sessionIds = dao.insertSessions(
                orderedWorkouts.mapIndexed { index, workout ->
                    WorkoutSessionEntity(
                        goalId = goalId,
                        sequenceIndex = workout.sequence,
                        titleVi = workout.titleVi,
                        focusVi = workout.focusVi,
                        estimatedMinutes = workout.estimatedMinutes,
                        dueEpochDay = dueEpochDays[index],
                    )
                },
            )
            val exerciseSnapshots = orderedWorkouts.flatMapIndexed { workoutIndex, workout ->
                workout.exercises.mapIndexed { exerciseIndex, prescription ->
                    SessionExerciseEntity(
                        sessionId = sessionIds[workoutIndex],
                        orderIndex = exerciseIndex,
                        exerciseId = prescription.exerciseId,
                        sets = prescription.sets,
                        repsMin = prescription.repsMin,
                        repsMax = prescription.repsMax,
                        durationSeconds = prescription.durationSeconds,
                        restSeconds = prescription.restSeconds,
                    )
                }
            }
            if (exerciseSnapshots.isNotEmpty()) dao.insertExercises(exerciseSnapshots)
        }
    }

    override suspend fun setExerciseChecked(sessionId: Long, orderIndex: Int, checked: Boolean) {
        dao.setCurrentExerciseChecked(sessionId, orderIndex, checked)
    }

    override suspend fun completeWorkout(
        sessionId: Long,
        completedEpochDay: Long,
    ): CompleteWorkoutResult = database.withTransaction {
        val session = dao.getSession(sessionId) ?: return@withTransaction CompleteWorkoutResult.AlreadyCompleted
        if (session.completedEpochDay != null) return@withTransaction CompleteWorkoutResult.AlreadyCompleted
        // The public result contract has no stale-state variant. Treat inactive or out-of-order
        // requests as idempotent no-ops, matching repeated completion behavior.
        if (dao.getCurrentSessionId() != sessionId) {
            return@withTransaction CompleteWorkoutResult.AlreadyCompleted
        }
        if (dao.countUnchecked(sessionId) > 0) {
            return@withTransaction CompleteWorkoutResult.BlockedByUncheckedExercises
        }
        if (dao.completeSessionIfIncomplete(sessionId, completedEpochDay) == 0) {
            return@withTransaction CompleteWorkoutResult.AlreadyCompleted
        }

        val delayDays = Math.subtractExact(completedEpochDay, session.dueEpochDay).coerceAtLeast(0L)
        if (delayDays > 0) {
            dao.maxLaterIncompleteDueEpochDay(session.goalId, session.sequenceIndex)?.let { latestDue ->
                Math.addExact(latestDue, delayDays)
                dao.shiftLaterIncompleteSessions(session.goalId, session.sequenceIndex, delayDays)
            }
        }
        CompleteWorkoutResult.Completed
    }

    override suspend fun archiveActiveGoal() {
        database.withTransaction { dao.archiveActiveGoals() }
    }

    private fun validateProgramMatch(config: GoalConfig, program: ProgramTemplate) {
        require(program.goal == config.goal) { "Program goal does not match goal configuration" }
        require(program.level == config.level) { "Program level does not match goal configuration" }
        require(program.equipmentProfile == config.equipmentProfile) {
            "Program equipment does not match goal configuration"
        }
        require(program.sessionsPerWeek == config.sessionsPerWeek) {
            "Program weekly frequency does not match goal configuration"
        }
        require(program.durationWeeks == config.durationWeeks) {
            "Program duration does not match goal configuration"
        }
        val expectedWorkoutCount = Math.multiplyExact(config.sessionsPerWeek, config.durationWeeks)
        require(program.workouts.size == expectedWorkoutCount) {
            "Program workout count does not match frequency and duration"
        }
    }

    private fun SessionWithExercises.toDomain(): WorkoutSession = WorkoutSession(
        id = session.id,
        goalId = session.goalId,
        sequenceIndex = session.sequenceIndex,
        titleVi = session.titleVi,
        focusVi = session.focusVi,
        estimatedMinutes = session.estimatedMinutes,
        dueEpochDay = session.dueEpochDay,
        exercises = exercises.sortedBy { it.orderIndex }.map { exercise ->
            WorkoutExercise(
                orderIndex = exercise.orderIndex,
                exerciseId = exercise.exerciseId,
                prescription = ExercisePrescription(
                    exerciseId = exercise.exerciseId,
                    sets = exercise.sets,
                    repsMin = exercise.repsMin,
                    repsMax = exercise.repsMax,
                    durationSeconds = exercise.durationSeconds,
                    restSeconds = exercise.restSeconds,
                ),
                checked = exercise.checked,
            )
        },
    )
}
