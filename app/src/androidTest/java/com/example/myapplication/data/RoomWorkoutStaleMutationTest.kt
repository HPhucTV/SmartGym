package com.example.myapplication.data

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.myapplication.core.model.EquipmentProfile
import com.example.myapplication.core.model.ExercisePrescription
import com.example.myapplication.core.model.ExperienceLevel
import com.example.myapplication.core.model.FitnessGoal
import com.example.myapplication.core.model.GoalConfig
import com.example.myapplication.core.model.ProgramTemplate
import com.example.myapplication.core.model.RestDayMode
import com.example.myapplication.core.model.WorkoutTemplate
import com.example.myapplication.data.local.GymDatabase
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class RoomWorkoutStaleMutationTest {
    private lateinit var database: GymDatabase
    private lateinit var repository: RoomWorkoutRepository

    @Before
    fun setUp() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = Room.inMemoryDatabaseBuilder(context, GymDatabase::class.java)
            .allowMainThreadQueries()
            .build()
        repository = RoomWorkoutRepository(database)
    }

    @After
    fun tearDown() = database.close()

    @Test
    fun delayedUncheckAfterCompletionIsIgnored() = runTest {
        repository.createGoal(config, program(), 100)
        val current = requireNotNull(repository.observeCurrentWorkout().first())
        current.exercises.forEach { repository.setExerciseChecked(current.id, it.orderIndex, true) }
        assertEquals(CompleteWorkoutResult.Completed, repository.completeWorkout(current.id, 100))

        repository.setExerciseChecked(current.id, 0, false)

        val stored = database.workoutDao().getExercisesForSession(current.id)
        assertTrue(stored.first().checked)
        assertEquals(0, database.workoutDao().setCurrentExerciseChecked(current.id, 0, false))
    }

    @Test
    fun delayedCheckboxAgainstArchivedSessionIsIgnored() = runTest {
        repository.createGoal(config, program(), 100)
        val oldCurrent = requireNotNull(repository.observeCurrentWorkout().first())
        repository.setExerciseChecked(oldCurrent.id, 0, true)
        repository.createGoal(config, program("replacement"), 200)

        repository.setExerciseChecked(oldCurrent.id, 0, false)

        assertTrue(database.workoutDao().getExercisesForSession(oldCurrent.id).first().checked)
        assertEquals(0, database.workoutDao().setCurrentExerciseChecked(oldCurrent.id, 0, false))
    }

    @Test
    fun delayedCompletionAgainstArchivedSessionsCannotMutateNewGoalOrHistory() = runTest {
        repository.createGoal(config, program(), 100)
        val oldGoal = requireNotNull(repository.observeActiveGoal().first())
        val oldFirst = requireNotNull(repository.observeCurrentWorkout().first())
        val oldSessions = database.workoutDao().getSessionsForGoal(oldGoal.id)
        oldFirst.exercises.forEach { repository.setExerciseChecked(oldFirst.id, it.orderIndex, true) }
        assertEquals(CompleteWorkoutResult.Completed, repository.completeWorkout(oldFirst.id, 100))

        repository.createGoal(config, program("replacement"), 200)
        val newGoal = requireNotNull(repository.observeActiveGoal().first())
        val newDueBefore = repository.observeCurrentWorkout().first()?.dueEpochDay

        assertEquals(CompleteWorkoutResult.AlreadyCompleted, repository.completeWorkout(oldFirst.id, 105))
        assertEquals(CompleteWorkoutResult.AlreadyCompleted, repository.completeWorkout(oldSessions.last().id, 105))

        assertEquals(newGoal.id, repository.observeActiveGoal().first()?.id)
        assertEquals(newDueBefore, repository.observeCurrentWorkout().first()?.dueEpochDay)
        assertEquals(listOf(oldGoal.id), repository.observeCompletedWorkouts().first().map { it.goalId })
    }

    @Test
    fun laterActiveSessionCannotCompleteOrShiftOutOfOrder() = runTest {
        repository.createGoal(config, program(), 100)
        val goal = requireNotNull(repository.observeActiveGoal().first())
        val sessions = database.workoutDao().getSessionsForGoal(goal.id)
        val later = sessions.last()
        database.openHelper.writableDatabase.execSQL(
            "UPDATE session_exercises SET checked = 1 WHERE sessionId = ?",
            arrayOf(later.id),
        )

        assertEquals(CompleteWorkoutResult.AlreadyCompleted, repository.completeWorkout(later.id, 105))

        assertEquals(sessions.first().id, repository.observeCurrentWorkout().first()?.id)
        assertEquals(listOf(102L, 105L), database.workoutDao().getSessionsForGoal(goal.id).map { it.dueEpochDay })
        assertTrue(repository.observeCompletedWorkouts().first().isEmpty())
    }

    private fun program(id: String = "program") = ProgramTemplate(
        id = id,
        goal = config.goal,
        level = config.level,
        equipmentProfile = config.equipmentProfile,
        sessionsPerWeek = config.sessionsPerWeek,
        durationWeeks = config.durationWeeks,
        workouts = listOf(workout(0, 1), workout(1, 0)),
    )

    private fun workout(sequence: Int, restDaysAfter: Int) = WorkoutTemplate(
        sequence = sequence,
        week = 1,
        titleVi = "Buoi ${sequence + 1}",
        focusVi = "Toan than",
        estimatedMinutes = 30,
        restDaysAfter = restDaysAfter,
        exercises = listOf(
            ExercisePrescription("squat", 3, 8, 12, null, 60),
            ExercisePrescription("plank", 2, null, null, 30, 45),
        ),
    )

    private companion object {
        val config = GoalConfig(
            goal = FitnessGoal.GENERAL_FITNESS,
            level = ExperienceLevel.BEGINNER,
            equipmentProfile = EquipmentProfile.BODYWEIGHT_ONLY,
            sessionsPerWeek = 2,
            durationWeeks = 1,
            restDayMode = RestDayMode.FULL_REST,
        )
    }
}
