package com.example.myapplication.data

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.myapplication.core.model.CompletedWorkout
import com.example.myapplication.core.model.EquipmentProfile
import com.example.myapplication.core.model.ExercisePrescription
import com.example.myapplication.core.model.ExerciseDefinition
import com.example.myapplication.core.model.Equipment
import com.example.myapplication.core.model.ExperienceLevel
import com.example.myapplication.core.model.FitnessGoal
import com.example.myapplication.core.model.GoalConfig
import com.example.myapplication.core.model.MovementPattern
import com.example.myapplication.core.model.MuscleGroup
import com.example.myapplication.core.model.ProgramTemplate
import com.example.myapplication.core.model.RestDayMode
import com.example.myapplication.core.model.WorkoutTemplate
import com.example.myapplication.data.local.GymDatabase
import kotlinx.coroutines.flow.first
import java.time.DayOfWeek
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class RoomWorkoutRepositoryTest {
    private lateinit var database: GymDatabase
    private lateinit var repository: RoomWorkoutRepository

    @Before
    fun setUp() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = Room.inMemoryDatabaseBuilder(context, GymDatabase::class.java)
            .allowMainThreadQueries()
            .build()
        repository = RoomWorkoutRepository(database, exercises())
    }

    @After
    fun tearDown() = database.close()

    @Test
    fun createGoalSnapshotsSessionsExercisesAndSchedule() = runTest {
        repository.createGoal(config(), program(), startEpochDay = 100)

        val activeGoal = repository.observeActiveGoal().first()
        val current = repository.observeCurrentWorkout().first()

        requireNotNull(activeGoal)
        requireNotNull(current)
        assertEquals(config(), activeGoal.config)
        assertEquals(2, activeGoal.totalWorkouts)
        assertEquals(0, current.sequenceIndex)
        assertEquals(100, current.dueEpochDay)
        assertEquals(listOf("squat", "plank"), current.exercises.map { it.exerciseId })
        assertEquals(listOf(false, false), current.exercises.map { it.checked })

        current.exercises.forEach {
            repository.setExerciseChecked(current.id, it.orderIndex, true)
        }
        assertEquals(CompleteWorkoutResult.Completed, repository.completeWorkout(current.id, 101))

        val next = repository.observeCurrentWorkout().first()
        requireNotNull(next)
        assertEquals(1, next.sequenceIndex)
        assertEquals(102, next.dueEpochDay)
        assertEquals(listOf(CompletedWorkout(activeGoal.id, 101)), repository.observeCompletedWorkouts().first())
        assertEquals(CompleteWorkoutResult.AlreadyCompleted, repository.completeWorkout(current.id, 102))
    }

    @Test
    fun uncheckedExerciseBlocksCompletionAndCanBeUncheckedAgain() = runTest {
        repository.createGoal(config(), program(), 100)
        val current = requireNotNull(repository.observeCurrentWorkout().first())

        repository.setExerciseChecked(current.id, 0, true)
        assertEquals(CompleteWorkoutResult.BlockedByUncheckedExercises, repository.completeWorkout(current.id, 100))
        repository.setExerciseChecked(current.id, 0, false)

        val refreshed = requireNotNull(repository.observeCurrentWorkout().first())
        assertFalse(refreshed.exercises.first().checked)
        assertTrue(repository.observeCompletedWorkouts().first().isEmpty())
    }

    @Test
    fun replacementArchivesOldGoalAndPreservesCompletedHistory() = runTest {
        repository.createGoal(config(), program(), 100)
        val oldGoal = requireNotNull(repository.observeActiveGoal().first())
        val oldWorkout = requireNotNull(repository.observeCurrentWorkout().first())
        oldWorkout.exercises.forEach { repository.setExerciseChecked(oldWorkout.id, it.orderIndex, true) }
        repository.completeWorkout(oldWorkout.id, 100)

        repository.createGoal(config(), program(id = "program_b"), 200)

        val newGoal = requireNotNull(repository.observeActiveGoal().first())
        assertTrue(newGoal.id != oldGoal.id)
        assertEquals(listOf(CompletedWorkout(oldGoal.id, 100)), repository.observeCompletedWorkouts().first())
        assertEquals(200L, repository.observeCurrentWorkout().first()?.dueEpochDay)
    }

    @Test
    fun earlyCompletionDoesNotShiftAndOnlyLaterIncompleteSessionsMove() = runTest {
        repository.createGoal(config(sessionsPerWeek = 3), program(threeSessions = true), 100)
        val first = requireNotNull(repository.observeCurrentWorkout().first())
        first.exercises.forEach { repository.setExerciseChecked(first.id, it.orderIndex, true) }
        repository.completeWorkout(first.id, 99)
        assertEquals(102L, repository.observeCurrentWorkout().first()?.dueEpochDay)

        val second = requireNotNull(repository.observeCurrentWorkout().first())
        second.exercises.forEach { repository.setExerciseChecked(second.id, it.orderIndex, true) }
        repository.completeWorkout(second.id, 104)
        assertEquals(107L, repository.observeCurrentWorkout().first()?.dueEpochDay)

        repository.archiveActiveGoal()
        assertNull(repository.observeActiveGoal().first())
        assertNull(repository.observeCurrentWorkout().first())
        assertEquals(2, repository.observeCompletedWorkouts().first().size)
    }

    @Test
    fun substitution_preservesPrescription_storesFirstOriginal_andCanRestore() = runTest {
        repository.createGoal(config(), program(), 100)
        val current = requireNotNull(repository.observeCurrentWorkout().first())
        val before = current.exercises.first()

        assertEquals(
            ExerciseSubstitutionResult.Applied,
            repository.substituteExercise(current.id, 0, "reverse_lunge"),
        )
        val substituted = requireNotNull(repository.observeCurrentWorkout().first()).exercises.first()
        assertEquals("reverse_lunge", substituted.exerciseId)
        assertEquals("squat", substituted.originalExerciseId)
        assertEquals(before.prescription.copy(exerciseId = "reverse_lunge"), substituted.prescription)

        assertEquals(
            ExerciseSubstitutionResult.Applied,
            repository.substituteExercise(current.id, 0, "squat"),
        )
        val restored = requireNotNull(repository.observeCurrentWorkout().first()).exercises.first()
        assertEquals("squat", restored.exerciseId)
        assertEquals("squat", restored.originalExerciseId)
    }

    @Test
    fun substitution_rejectsInvalidCheckedAndStaleRows() = runTest {
        repository.createGoal(config(), program(), 100)
        val first = requireNotNull(repository.observeCurrentWorkout().first())

        assertEquals(
            ExerciseSubstitutionResult.InvalidCandidate,
            repository.substituteExercise(first.id, 0, "plank"),
        )
        repository.setExerciseChecked(first.id, 0, true)
        assertEquals(
            ExerciseSubstitutionResult.AlreadyChecked,
            repository.substituteExercise(first.id, 0, "reverse_lunge"),
        )
        repository.setExerciseChecked(first.id, 0, false)
        first.exercises.forEach { repository.setExerciseChecked(first.id, it.orderIndex, true) }
        repository.completeWorkout(first.id, 100)
        assertEquals(
            ExerciseSubstitutionResult.StaleSession,
            repository.substituteExercise(first.id, 0, "reverse_lunge"),
        )
    }

    @Test
    fun timeBudget_omitsOrderedSuffix_andNullRestoresFullWorkout() = runTest {
        val longExercises = List(4) { index ->
            ExercisePrescription(if (index % 2 == 0) "squat" else "plank", 6, 12, 12, null, 90)
        }
        val longProgram = program().copy(
            workouts = program().workouts.map { it.copy(exercises = longExercises) },
        )
        repository.createGoal(config(), longProgram, 100)
        val current = requireNotNull(repository.observeCurrentWorkout().first())

        assertEquals(TimeBudgetResult.Applied, repository.applyTimeBudget(current.id, 15))
        val shortened = requireNotNull(repository.observeCurrentWorkout().first())
        assertEquals(15, shortened.selectedTimeBudgetMinutes)
        assertEquals(listOf(0), shortened.exercises.map { it.orderIndex })
        assertEquals(3, shortened.omittedExerciseCount)
        repository.setExerciseChecked(current.id, 3, true)
        assertFalse(database.workoutDao().getExercisesForSession(current.id)[3].checked)

        assertEquals(TimeBudgetResult.Applied, repository.applyTimeBudget(current.id, null))
        val restored = requireNotNull(repository.observeCurrentWorkout().first())
        assertNull(restored.selectedTimeBudgetMinutes)
        assertEquals(listOf(0, 1, 2, 3), restored.exercises.map { it.orderIndex })
        assertEquals(0, restored.omittedExerciseCount)
    }

    @Test
    fun timeBudget_rejectsCheckedAndStaleSessions() = runTest {
        repository.createGoal(config(), program(), 100)
        val first = requireNotNull(repository.observeCurrentWorkout().first())
        repository.setExerciseChecked(first.id, 0, true)

        assertEquals(TimeBudgetResult.HasCheckedExercises, repository.applyTimeBudget(first.id, 15))
        repository.setExerciseChecked(first.id, 0, false)
        first.exercises.forEach { repository.setExerciseChecked(first.id, it.orderIndex, true) }
        repository.completeWorkout(first.id, 100)

        assertEquals(TimeBudgetResult.StaleSession, repository.applyTimeBudget(first.id, 15))
    }

    private fun program(id: String = "program_a", threeSessions: Boolean = false): ProgramTemplate {
        val workouts = buildList {
            add(workout(0, 1, "A"))
            add(workout(1, 1, "B"))
            if (threeSessions) add(workout(2, 0, "C"))
        }
        return ProgramTemplate(
            id = id,
            goal = config().goal,
            level = config().level,
            equipmentProfile = config().equipmentProfile,
            sessionsPerWeek = workouts.size,
            durationWeeks = 1,
            workouts = workouts,
        )
    }

    private fun workout(sequence: Int, restDaysAfter: Int, title: String) = WorkoutTemplate(
        sequence = sequence,
        week = 1,
        titleVi = title,
        focusVi = "Toan than",
        estimatedMinutes = 30,
        restDaysAfter = restDaysAfter,
        exercises = listOf(
            ExercisePrescription("squat", 3, 8, 12, null, 60),
            ExercisePrescription("plank", 2, null, null, 30, 45),
        ),
    )

    private companion object {
        fun exercises() = listOf(
            ExerciseDefinition(
                id = "squat",
                sourceId = "squat",
                nameVi = "Squat",
                level = ExperienceLevel.BEGINNER,
                equipment = listOf(Equipment.BODYWEIGHT),
                movementPattern = MovementPattern.SQUAT,
                primaryMuscle = MuscleGroup.QUADS,
                instructionsVi = listOf("Hạ hông có kiểm soát"),
                substituteIds = listOf("reverse_lunge"),
            ),
            ExerciseDefinition(
                id = "reverse_lunge",
                sourceId = "reverse_lunge",
                nameVi = "Chùng chân lùi",
                level = ExperienceLevel.BEGINNER,
                equipment = listOf(Equipment.BODYWEIGHT),
                movementPattern = MovementPattern.SQUAT,
                primaryMuscle = MuscleGroup.QUADS,
                instructionsVi = listOf("Bước một chân ra sau"),
                substituteIds = listOf("squat"),
            ),
            ExerciseDefinition(
                id = "plank",
                sourceId = "plank",
                nameVi = "Plank",
                level = ExperienceLevel.BEGINNER,
                equipment = listOf(Equipment.BODYWEIGHT),
                movementPattern = MovementPattern.CORE,
                primaryMuscle = MuscleGroup.CORE,
                instructionsVi = listOf("Giữ thân người thẳng"),
            ),
        )

        fun config(sessionsPerWeek: Int = 2) = GoalConfig(
            goal = FitnessGoal.GENERAL_FITNESS,
            level = ExperienceLevel.BEGINNER,
            equipmentProfile = EquipmentProfile.BODYWEIGHT_ONLY,
            sessionsPerWeek = sessionsPerWeek,
            durationWeeks = 1,
            restDayMode = RestDayMode.FULL_REST,
            trainingDays = if (sessionsPerWeek == 2) {
                setOf(DayOfWeek.SATURDAY, DayOfWeek.MONDAY)
            } else {
                setOf(DayOfWeek.SATURDAY, DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY)
            },
            sessionDurationMinutes = 45,
        )
    }
}
