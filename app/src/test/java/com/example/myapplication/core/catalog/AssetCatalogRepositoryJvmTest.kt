package com.example.myapplication.core.catalog

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

class AssetCatalogRepositoryJvmTest {
    @Test
    fun `constructor is lazy and valid programs load on first access`() {
        var reads = 0
        val repository = AssetCatalogRepository { path ->
            reads++
            when (path) {
                "catalog/exercises_vi.json" -> validExerciseJson
                "catalog/programs.json" -> validProgramJson
                else -> error("Unexpected asset $path")
            }
        }
        assertEquals(0, reads)
        assertEquals(1, repository.programs.size)
        assertEquals(2, reads)
    }

    @Test
    fun `invalid bundled programs fail fast with clear argument error`() {
        val repository = AssetCatalogRepository { path ->
            if (path.endsWith("exercises_vi.json")) validExerciseJson else invalidProgramJson
        }
        val error = assertThrows(IllegalArgumentException::class.java) { repository.programs }
        assertTrue(error.message.orEmpty().contains("Invalid bundled program catalog"))
        assertTrue(error.message.orEmpty().contains("blank titleVi"))
    }

    private companion object {
        val validExerciseJson =
            """[{"id":"push_up","sourceId":"Pushups","nameVi":"Chống đẩy","level":"BEGINNER","equipment":["BODYWEIGHT"],"movementPattern":"HORIZONTAL_PUSH","primaryMuscle":"CHEST","instructionsVi":["Giữ thân thẳng.","Hạ xuống và đẩy lên."]}]"""
        val validProgramJson =
            """[{"id":"valid","goal":"GENERAL_FITNESS","level":"BEGINNER","equipmentProfile":"BODYWEIGHT_ONLY","sessionsPerWeek":2,"durationWeeks":1,"workouts":[{"sequence":0,"week":1,"titleVi":"A","focusVi":"Ngực","estimatedMinutes":20,"restDaysAfter":2,"exercises":[{"exerciseId":"push_up","sets":2,"repsMin":8,"repsMax":12,"restSeconds":60}]},{"sequence":1,"week":1,"titleVi":"B","focusVi":"Ngực","estimatedMinutes":20,"restDaysAfter":3,"exercises":[{"exerciseId":"push_up","sets":2,"repsMin":8,"repsMax":12,"restSeconds":60}]}]}]"""
        val invalidProgramJson = validProgramJson.replace("\"titleVi\":\"A\"", "\"titleVi\":\" \"")
    }
}
