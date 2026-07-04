package com.example.myapplication.core.catalog

import com.example.myapplication.core.model.*
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class ExerciseSubstitutionEngineTest {
    @Test
    fun `candidates respect explicit review equipment and stable ranking`() {
        val source = exercise(
            id = "push_up",
            name = "Chống đẩy",
            equipment = listOf(Equipment.BODYWEIGHT),
            substituteIds = listOf("machine_press", "knee_push_up", "barbell_press"),
        )
        val engine = ExerciseSubstitutionEngine(
            listOf(
                source,
                exercise("barbell_press", "Đẩy đòn", listOf(Equipment.BARBELL), ExperienceLevel.INTERMEDIATE),
                exercise("knee_push_up", "Chống đẩy gối", listOf(Equipment.BODYWEIGHT)),
                exercise("machine_press", "Đẩy máy", listOf(Equipment.MACHINE)),
            ),
        )

        assertEquals(
            listOf("knee_push_up"),
            engine.candidates("push_up", EquipmentProfile.BODYWEIGHT_ONLY).map { it.id },
        )
        assertEquals(
            listOf("knee_push_up", "machine_press", "barbell_press"),
            engine.candidates("push_up", EquipmentProfile.FULL_GYM).map { it.id },
        )
        assertEquals(emptyList<ExerciseDefinition>(), engine.candidates("missing", EquipmentProfile.FULL_GYM))
    }

    @Test
    fun `validator rejects unsafe substitution references`() {
        val source = exercise(
            id = "push_up",
            name = "Chống đẩy",
            equipment = listOf(Equipment.BODYWEIGHT),
            substituteIds = listOf("push_up", "missing", "wrong_muscle", "wrong_pattern", "missing"),
        )
        val issues = CatalogValidator.validateExercises(
            listOf(
                source,
                exercise("wrong_muscle", "Kéo lưng", listOf(Equipment.BODYWEIGHT), muscle = MuscleGroup.BACK),
                exercise(
                    "wrong_pattern",
                    "Đẩy vai",
                    listOf(Equipment.BODYWEIGHT),
                    movementPattern = MovementPattern.VERTICAL_PUSH,
                ),
            ),
        )

        assertTrue(issues.any { "itself" in it })
        assertTrue(issues.any { "Unknown substitute 'missing'" in it })
        assertTrue(issues.any { "duplicate substitute 'missing'" in it })
        assertTrue(issues.any { "primary muscle" in it })
        assertTrue(issues.any { "movement pattern" in it })
    }

    @Test
    fun `bundled substitutions are reviewed reciprocal and useful`() {
        val exercises = CatalogParser.parseExercises(
            File("src/main/assets/catalog/exercises_vi.json").readText(),
        )
        val byId = exercises.associateBy(ExerciseDefinition::id)

        assertTrue(CatalogValidator.validateExercises(exercises).isEmpty())
        assertTrue(exercises.sumOf { it.substituteIds.size } >= 30)
        assertTrue("knee_push_up" in byId.getValue("push_up").substituteIds)
        assertTrue("reverse_lunge" in byId.getValue("split_squat").substituteIds)
        exercises.forEach { exercise ->
            exercise.substituteIds.forEach { substituteId ->
                assertTrue(exercise.id in byId.getValue(substituteId).substituteIds)
            }
        }
    }

    private fun exercise(
        id: String,
        name: String,
        equipment: List<Equipment>,
        level: ExperienceLevel = ExperienceLevel.BEGINNER,
        muscle: MuscleGroup = MuscleGroup.CHEST,
        movementPattern: MovementPattern = MovementPattern.HORIZONTAL_PUSH,
        substituteIds: List<String> = emptyList(),
    ) = ExerciseDefinition(
        id = id,
        sourceId = "project:$id",
        nameVi = name,
        level = level,
        equipment = equipment,
        movementPattern = movementPattern,
        primaryMuscle = muscle,
        instructionsVi = listOf("Bước một.", "Bước hai."),
        substituteIds = substituteIds,
    )
}
