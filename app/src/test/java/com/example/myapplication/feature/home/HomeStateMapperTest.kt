package com.example.myapplication.feature.home

import com.example.myapplication.core.model.CompletedWorkout
import com.example.myapplication.core.model.ExercisePrescription
import com.example.myapplication.core.model.WorkoutExercise
import com.example.myapplication.core.model.WorkoutSession
import com.example.myapplication.core.nutrition.Nutrients
import com.example.myapplication.core.nutrition.NutritionDay
import com.example.myapplication.core.nutrition.NutritionTarget
import com.example.myapplication.core.nutrition.NutritionTargetAudit
import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class HomeStateMapperTest {
    @Test
    fun `maps current workout and nutrition without fabricated values`() {
        val today = day("2026-07-02")

        val state = mapHomeUiState(
            epochDay = today,
            workout = workout(checked = listOf(true, false, true)),
            completed = emptyList(),
            nutrition = NutritionDay(today, Nutrients(calories = 1_240), target = target(2_100)),
        )

        assertEquals("Toàn thân A", state.workoutTitle)
        assertEquals("Toàn thân", state.workoutFocus)
        assertEquals(42, state.durationMinutes)
        assertEquals(2, state.completedExercises)
        assertEquals(3, state.totalExercises)
        assertEquals(1_240, state.caloriesConsumed)
        assertEquals(2_100, state.caloriesTarget)
    }

    @Test
    fun `maps missing workout and nutrition target as empty data`() {
        val today = day("2026-07-02")

        val state = mapHomeUiState(
            epochDay = today,
            workout = null,
            completed = emptyList(),
            nutrition = NutritionDay(today, Nutrients(), target = null),
        )

        assertNull(state.workoutTitle)
        assertNull(state.workoutFocus)
        assertNull(state.durationMinutes)
        assertNull(state.caloriesTarget)
        assertEquals(0, state.completedExercises)
        assertEquals(0, state.totalExercises)
        assertEquals(0, state.completedThisWeek)
        assertEquals(0, state.streakDays)
    }

    @Test
    fun `counts only completions in the current monday to sunday week`() {
        val today = day("2026-07-02")
        val history = listOf("2026-06-28", "2026-06-29", "2026-07-01", "2026-07-05", "2026-07-06")
            .map { CompletedWorkout(goalId = 1, completedEpochDay = day(it)) }

        val state = mapHomeUiState(
            epochDay = today,
            workout = null,
            completed = history,
            nutrition = NutritionDay(today, Nutrients(), null),
        )

        assertEquals(3, state.completedThisWeek)
    }

    @Test
    fun `daily streak continues from yesterday and ignores duplicate sessions`() {
        val today = day("2026-07-02")
        val history = listOf("2026-06-28", "2026-06-29", "2026-06-30", "2026-07-01", "2026-07-01")
            .map { CompletedWorkout(goalId = 1, completedEpochDay = day(it)) }

        val state = mapHomeUiState(
            epochDay = today,
            workout = null,
            completed = history,
            nutrition = NutritionDay(today, Nutrients(), null),
        )

        assertEquals(4, state.streakDays)
    }

    private fun workout(checked: List<Boolean>) = WorkoutSession(
        id = 10,
        goalId = 1,
        sequenceIndex = 0,
        titleVi = "Toàn thân A",
        focusVi = "Toàn thân",
        estimatedMinutes = 42,
        dueEpochDay = day("2026-07-02"),
        exercises = checked.mapIndexed { index, isChecked ->
            WorkoutExercise(
                orderIndex = index,
                exerciseId = "exercise-$index",
                prescription = ExercisePrescription(
                    exerciseId = "exercise-$index",
                    sets = 3,
                    repsMin = 8,
                    repsMax = 12,
                    restSeconds = 60,
                ),
                checked = isChecked,
            )
        },
    )

    private fun target(calories: Int) = NutritionTarget(
        basalCalories = 1_600,
        maintenanceCalories = 2_200,
        calories = calories,
        proteinGrams = 130,
        carbsGrams = 240,
        fatGrams = 65,
        audit = NutritionTargetAudit(
            rawBasalCalories = 1_600.0,
            rawMaintenanceCalories = 2_200.0,
            rawTargetCalories = calories.toDouble(),
            rawProteinGrams = 130.0,
            rawCarbsGrams = 240.0,
            rawFatGrams = 65.0,
        ),
    )

    private fun day(value: String): Long = LocalDate.parse(value).toEpochDay()
}
