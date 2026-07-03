package com.example.myapplication.core.program

import com.example.myapplication.core.model.EquipmentProfile
import com.example.myapplication.core.model.ExperienceLevel
import com.example.myapplication.core.model.FitnessGoal
import com.example.myapplication.core.model.GoalConfig
import com.example.myapplication.core.model.ProgramTemplate
import com.example.myapplication.core.model.RestDayMode
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class ProgramSelectorTest {
    private val config = GoalConfig(
        goal = FitnessGoal.GENERAL_FITNESS,
        level = ExperienceLevel.BEGINNER,
        equipmentProfile = EquipmentProfile.BODYWEIGHT_ONLY,
        sessionsPerWeek = 3,
        durationWeeks = 4,
        restDayMode = RestDayMode.FULL_REST,
    )

    @Test
    fun exactMatchReturnsFoundProgram() {
        val expected = program("general-beginner-bodyweight")

        val result = ProgramSelector.select(config, listOf(expected))

        assertEquals(ProgramSelectionResult.Found(expected), result)
    }

    @Test
    fun emptyCatalogReturnsUnsupported() {
        val result = ProgramSelector.select(config, emptyList())

        assertEquals(ProgramSelectionResult.Unsupported, result)
    }

    @Test
    fun reviewedBaseProgramCanAdaptToDifferentWeeklyFrequency() {
        val differentProgram = program("different").copy(sessionsPerWeek = 4)

        val result = ProgramSelector.select(config, listOf(differentProgram))

        assertEquals(ProgramSelectionResult.Found(differentProgram), result)
    }

    @Test
    fun duplicateExactConfigurationsThrowIllegalArgumentException() {
        assertThrows(IllegalArgumentException::class.java) {
            ProgramSelector.select(config, listOf(program("first"), program("second")))
        }
    }

    private fun program(id: String) = ProgramTemplate(
        id = id,
        goal = config.goal,
        level = config.level,
        equipmentProfile = config.equipmentProfile,
        sessionsPerWeek = config.sessionsPerWeek,
        durationWeeks = config.durationWeeks,
        workouts = emptyList(),
    )
}
