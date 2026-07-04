package com.example.myapplication.data

import androidx.room.withTransaction
import com.example.myapplication.core.model.ActiveGoal
import com.example.myapplication.core.model.CompletedWorkout
import com.example.myapplication.core.model.ExercisePrescription
import com.example.myapplication.core.model.GoalConfig
import com.example.myapplication.core.model.ProgramTemplate
import com.example.myapplication.core.model.WorkoutExercise
import com.example.myapplication.core.model.WorkoutSession
import com.example.myapplication.core.model.ExerciseDefinition
import com.example.myapplication.core.catalog.ExerciseSubstitutionEngine
import com.example.myapplication.core.model.trainingDaysFromMask
import com.example.myapplication.core.model.trainingDaysMask
import com.example.myapplication.core.program.AdaptiveProgramPlanner
import com.example.myapplication.core.program.SchedulePlanner
import com.example.myapplication.core.program.TrainingSchedule
import com.example.myapplication.core.program.SessionTimeBudgetPlanner
import com.example.myapplication.data.local.GoalEntity
import com.example.myapplication.data.local.GymDatabase
import com.example.myapplication.data.local.SessionExerciseEntity
import com.example.myapplication.data.local.SessionWithExercises
import com.example.myapplication.data.local.WorkoutSessionEntity
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlin.math.floor

class RoomWorkoutRepository(
    private val database: GymDatabase,
    exercises: List<ExerciseDefinition> = emptyList(),
) : WorkoutRepository {
    private val dao = database.workoutDao()
    private val substitutionEngine = ExerciseSubstitutionEngine(exercises)

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
                    trainingDays = trainingDaysFromMask(it.goal.trainingDaysMask),
                    sessionDurationMinutes = it.goal.sessionDurationMinutes,
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
        TrainingSchedule.validate(config.trainingDays, config.sessionDurationMinutes)
        val orderedWorkouts = AdaptiveProgramPlanner.adapt(program, config)
        require(orderedWorkouts.map { it.sequence } == orderedWorkouts.indices.toList()) {
            "Program workouts must use contiguous sequence values starting at zero"
        }
        val dueEpochDays = SchedulePlanner.dueEpochDays(startEpochDay, config.trainingDays, orderedWorkouts.size)

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
                    trainingDaysMask = trainingDaysMask(config.trainingDays),
                    sessionDurationMinutes = config.sessionDurationMinutes,
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

    override suspend fun substituteExercise(
        sessionId: Long,
        orderIndex: Int,
        replacementExerciseId: String,
    ): ExerciseSubstitutionResult = database.withTransaction {
        if (dao.getCurrentSessionId() != sessionId) {
            return@withTransaction ExerciseSubstitutionResult.StaleSession
        }
        val row = dao.getExercisesForSession(sessionId).firstOrNull { it.orderIndex == orderIndex }
            ?: return@withTransaction ExerciseSubstitutionResult.InvalidCandidate
        if (row.checked) return@withTransaction ExerciseSubstitutionResult.AlreadyChecked

        val session = dao.getSession(sessionId)
            ?: return@withTransaction ExerciseSubstitutionResult.StaleSession
        val profile = dao.getGoal(session.goalId)?.equipmentProfile
            ?: return@withTransaction ExerciseSubstitutionResult.StaleSession
        val originalId = row.originalExerciseId ?: row.exerciseId
        val validIds = substitutionEngine.candidates(originalId, profile).mapTo(mutableSetOf()) { it.id }
        if (row.originalExerciseId != null) validIds += originalId
        if (replacementExerciseId !in validIds) {
            return@withTransaction ExerciseSubstitutionResult.InvalidCandidate
        }

        if (dao.substituteCurrentExercise(sessionId, orderIndex, replacementExerciseId) == 1) {
            ExerciseSubstitutionResult.Applied
        } else {
            ExerciseSubstitutionResult.StaleSession
        }
    }

    override suspend fun applyTimeBudget(
        sessionId: Long,
        minutes: Int?,
    ): TimeBudgetResult = database.withTransaction {
        if (dao.getCurrentSessionId() != sessionId) {
            return@withTransaction TimeBudgetResult.StaleSession
        }
        val session = dao.getSession(sessionId)
            ?: return@withTransaction TimeBudgetResult.StaleSession
        if (dao.countChecked(sessionId) > 0) {
            return@withTransaction TimeBudgetResult.HasCheckedExercises
        }
        if (minutes != null && minutes !in setOf(15, 30, 45) && minutes != session.estimatedMinutes) {
            return@withTransaction TimeBudgetResult.InvalidBudget
        }

        dao.updateSelectedTimeBudget(sessionId, minutes)
        if (minutes == null || minutes >= session.estimatedMinutes) {
            dao.setAllExercisesOmittedByTimeBudget(sessionId, false)
        } else {
            val rows = dao.getExercisesForSession(sessionId).sortedBy { it.orderIndex }
            val selection = SessionTimeBudgetPlanner.select(
                rows.map { row ->
                    ExercisePrescription(
                        exerciseId = row.exerciseId,
                        sets = scaledSets(row.sets, session.volumeScalePercent),
                        repsMin = row.repsMin,
                        repsMax = row.repsMax,
                        durationSeconds = row.durationSeconds,
                        restSeconds = row.restSeconds,
                    )
                },
                minutes,
            )
            dao.setAllExercisesOmittedByTimeBudget(sessionId, true)
            dao.activateExercisesForTimeBudget(
                sessionId,
                selection.activeOrderIndices.map { rows[it].orderIndex },
            )
        }
        TimeBudgetResult.Applied
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
            val laterSessions = dao.getSessionsForGoal(session.goalId)
                .filter { it.sequenceIndex > session.sequenceIndex && it.completedEpochDay == null }
                .sortedBy { it.sequenceIndex }
            val trainingDays = dao.getGoal(session.goalId)?.let { trainingDaysFromMask(it.trainingDaysMask) }.orEmpty()
            if (laterSessions.isNotEmpty() && trainingDays.isNotEmpty()) {
                val newDueDates = SchedulePlanner.dueEpochDays(
                    startEpochDay = Math.addExact(completedEpochDay, 1L),
                    trainingDays = trainingDays,
                    workoutCount = laterSessions.size,
                )
                laterSessions.zip(newDueDates).forEach { (later, dueEpochDay) ->
                    dao.updateSessionDueEpochDay(later.id, dueEpochDay)
                }
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
        require(program.durationWeeks == config.durationWeeks) {
            "Program duration does not match goal configuration"
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
        exercises = exercises.filterNot { it.omittedByTimeBudget }.sortedBy { it.orderIndex }.map { exercise ->
            WorkoutExercise(
                orderIndex = exercise.orderIndex,
                exerciseId = exercise.exerciseId,
                originalExerciseId = exercise.originalExerciseId,
                prescription = ExercisePrescription(
                    exerciseId = exercise.exerciseId,
                    sets = if (session.completedEpochDay == null) {
                        scaledSets(exercise.sets, session.volumeScalePercent)
                    } else {
                        exercise.sets
                    },
                    repsMin = exercise.repsMin,
                    repsMax = exercise.repsMax,
                    durationSeconds = exercise.durationSeconds,
                    restSeconds = exercise.restSeconds,
                ),
                checked = exercise.checked,
            )
        },
        selectedTimeBudgetMinutes = session.selectedTimeBudgetMinutes,
        omittedExerciseCount = exercises.count { it.omittedByTimeBudget },
    )
}

internal fun scaledSets(sets: Int, percent: Int): Int =
    maxOf(1, floor(sets * percent.coerceIn(1, 100) / 100.0).toInt())
