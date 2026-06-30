package com.example.myapplication.core.catalog

import com.example.myapplication.core.model.*
import org.junit.Assert.assertTrue
import org.junit.Test

class ProgramValidatorBoundaryTest {
    private val exercise = ExerciseDefinition(
        "push_up", "Pushups", "Chống đẩy", ExperienceLevel.BEGINNER,
        listOf(Equipment.BODYWEIGHT), MovementPattern.HORIZONTAL_PUSH, MuscleGroup.CHEST,
        instructionsVi = listOf("Giữ thân thẳng.", "Hạ xuống và đẩy lên."),
    )
    private val prescription = ExercisePrescription("push_up", 2, 8, 12, null, 60)
    private val validWorkouts = listOf(
        WorkoutTemplate(0, 1, "Buổi A", "Ngực", 20, 2, listOf(prescription)),
        WorkoutTemplate(1, 1, "Buổi B", "Toàn thân", 20, 3, listOf(prescription)),
    )
    private val validProgram = ProgramTemplate(
        "valid", FitnessGoal.GENERAL_FITNESS, ExperienceLevel.BEGINNER,
        EquipmentProfile.BODYWEIGHT_ONLY, 2, 1, validWorkouts,
    )

    @Test
    fun `validator rejects blank identity and workout text`() {
        val program = validProgram.copy(
            id = " ",
            workouts = validWorkouts.mapIndexed { index, workout ->
                if (index == 0) workout.copy(titleVi = " ") else workout.copy(focusVi = "")
            },
        )
        val issues = CatalogValidator.validatePrograms(listOf(program), mapOf(exercise.id to exercise))
        assertTrue(issues.any { "blank id" in it })
        assertTrue(issues.any { "blank titleVi" in it })
        assertTrue(issues.any { "blank focusVi" in it })
    }

    @Test
    fun `validator rejects frequency duration and empty workout bounds`() {
        val invalidFrequency = validProgram.copy(id = "frequency", sessionsPerWeek = 8)
        val invalidDuration = validProgram.copy(id = "duration", durationWeeks = 53)
        val emptyWorkout = validProgram.copy(
            id = "empty",
            workouts = validWorkouts.mapIndexed { index, workout ->
                if (index == 0) workout.copy(exercises = emptyList()) else workout
            },
        )
        val issues = CatalogValidator.validatePrograms(
            listOf(invalidFrequency, invalidDuration, emptyWorkout),
            mapOf(exercise.id to exercise),
        )
        assertTrue(issues.any { "sessionsPerWeek must be in 1..7" in it })
        assertTrue(issues.any { "durationWeeks must be in 1..52" in it })
        assertTrue(issues.any { "must contain exercises" in it })
    }
}
