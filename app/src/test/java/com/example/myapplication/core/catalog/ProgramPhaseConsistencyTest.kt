package com.example.myapplication.core.catalog

import com.example.myapplication.core.model.MovementPattern
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class ProgramPhaseConsistencyTest {
    @Test
    fun `general intermediate keeps compounds across phases and changes at most two accessories`() {
        val exercises = CatalogParser.parseExercises(File("src/main/assets/catalog/exercises_vi.json").readText())
            .associateBy { it.id }
        val program = CatalogParser.parsePrograms(File("src/main/assets/catalog/programs.json").readText())
            .single { it.id == "general-intermediate-gym-4x-8w" }
        val accessoryIds = setOf(
            "standing_calf_raise", "leg_curl", "leg_extension", "dumbbell_lateral_raise",
            "triceps_pushdown", "overhead_triceps_extension", "prone_y_raise",
            "reverse_snow_angel", "face_pull", "reverse_fly", "back_extension",
            "dumbbell_biceps_curl", "hammer_curl",
        )
        fun compounds(sequence: Int) = program.workouts.single { it.sequence == sequence }.exercises
            .map { exercises.getValue(it.exerciseId) }
            .filter { it.id !in accessoryIds && it.movementPattern != MovementPattern.CORE }
            .map { it.id }
        fun accessories(sequence: Int) = program.workouts.single { it.sequence == sequence }.exercises
            .map { exercises.getValue(it.exerciseId) }
            .filter { it.id in accessoryIds || it.movementPattern == MovementPattern.CORE }
            .map { it.id }

        (0 until program.sessionsPerWeek).forEach { slot ->
            (5..8).forEach { phaseTwoWeek ->
                val phaseTwoSequence = (phaseTwoWeek - 1) * program.sessionsPerWeek + slot
                assertEquals(
                    "Compound change in week $phaseTwoWeek slot $slot",
                    compounds(slot),
                    compounds(phaseTwoSequence),
                )
                val accessoryDifference =
                    accessories(slot).toSet() xor accessories(phaseTwoSequence).toSet()
                assertTrue(
                    "Too many accessory changes in week $phaseTwoWeek slot $slot: $accessoryDifference",
                    accessoryDifference.size / 2 <= 2,
                )
            }
        }
        val lowerA = program.workouts.filter { it.sequence % 4 == 1 }.flatMap { it.exercises }
        val lowerB = program.workouts.filter { it.sequence % 4 == 3 }.flatMap { it.exercises }
        assertFalse(lowerA.any { it.exerciseId == "conventional_deadlift" })
        assertTrue(lowerB.any { it.exerciseId == "conventional_deadlift" })
    }

    private infix fun <T> Set<T>.xor(other: Set<T>): Set<T> = (this - other) + (other - this)
}
