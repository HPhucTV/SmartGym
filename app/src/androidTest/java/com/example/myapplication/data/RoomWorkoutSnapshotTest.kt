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
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class RoomWorkoutSnapshotTest {
    @Test
    fun createGoalStoresEveryDueDayAndPrescriptionField() = runTest {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val database = Room.inMemoryDatabaseBuilder(context, GymDatabase::class.java)
            .allowMainThreadQueries()
            .build()
        try {
            val repository = RoomWorkoutRepository(database)
            repository.createGoal(config, program, 100)
            val goalId = requireNotNull(repository.observeActiveGoal().first()).id

            val sessions = database.workoutDao().getSessionsForGoal(goalId)
            assertEquals(listOf(102L, 105L), sessions.map { it.dueEpochDay })
            assertEquals(listOf(0, 1), sessions.map { it.sequenceIndex })
            val exercises = database.workoutDao().getExercisesForSession(sessions.first().id)
            assertEquals(listOf("squat", "plank"), exercises.map { it.exerciseId })
            assertEquals(listOf(0, 1), exercises.map { it.orderIndex })
            assertEquals(3, exercises.first().sets)
            assertEquals(8, exercises.first().repsMin)
            assertEquals(12, exercises.first().repsMax)
            assertEquals(60, exercises.first().restSeconds)
            assertEquals(30, exercises.last().durationSeconds)
        } finally {
            database.close()
        }
    }

    @Test
    fun mismatchedProgramIsRejectedBeforeReplacingActiveGoal() = runTest {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val database = Room.inMemoryDatabaseBuilder(context, GymDatabase::class.java)
            .allowMainThreadQueries()
            .build()
        try {
            val repository = RoomWorkoutRepository(database)
            repository.createGoal(config, program, 100)
            val originalGoalId = requireNotNull(repository.observeActiveGoal().first()).id

            var rejected = false
            try {
                repository.createGoal(config.copy(sessionsPerWeek = 3), program, 200)
            } catch (_: IllegalArgumentException) {
                rejected = true
            }

            assertTrue(rejected)
            assertEquals(originalGoalId, repository.observeActiveGoal().first()?.id)
        } finally {
            database.close()
        }
    }

    private companion object {
        val config = GoalConfig(
            goal = FitnessGoal.GENERAL_FITNESS,
            level = ExperienceLevel.BEGINNER,
            equipmentProfile = EquipmentProfile.BODYWEIGHT_ONLY,
            sessionsPerWeek = 2,
            durationWeeks = 1,
            restDayMode = RestDayMode.FULL_REST,
        )
        val prescriptions = listOf(
            ExercisePrescription("squat", 3, 8, 12, null, 60),
            ExercisePrescription("plank", 2, null, null, 30, 45),
        )
        val program = ProgramTemplate(
            id = "program_a",
            goal = config.goal,
            level = config.level,
            equipmentProfile = config.equipmentProfile,
            sessionsPerWeek = config.sessionsPerWeek,
            durationWeeks = config.durationWeeks,
            workouts = listOf(
                WorkoutTemplate(0, 1, "A", "Toan than", 30, 1, prescriptions),
                WorkoutTemplate(1, 1, "B", "Toan than", 30, 0, prescriptions),
            ),
        )
    }
}
