package com.example.myapplication.feature.home

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.myapplication.ui.theme.GymAppTheme
import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class HomeScreenTest {
    @get:Rule val rule = createComposeRule()

    @Test
    fun populated_dashboard_exposes_primary_and_secondary_actions() {
        var workoutCalls = 0
        var nutritionCalls = 0
        var checkInCalls = 0
        var recommendationCalls = 0
        rule.setContent {
            GymAppTheme {
                HomeScreen(
                    state = populatedState(),
                    onNavigateToWorkouts = { workoutCalls++ },
                    onNavigateToNutrition = { nutritionCalls++ },
                    onNavigateToCheckIn = { checkInCalls++ },
                    onNavigateToRecommendations = { recommendationCalls++ },
                )
            }
        }

        rule.onNodeWithTag("home-workout-action").performClick()
        rule.onNodeWithTag("home-nutrition-action").performScrollTo().performClick()
        rule.onNodeWithTag("home-checkin-action").performScrollTo().performClick()
        rule.onNodeWithTag("home-recommendations-action").performScrollTo().performClick()

        rule.runOnIdle {
            assertEquals(1, workoutCalls)
            assertEquals(1, nutritionCalls)
            assertEquals(1, checkInCalls)
            assertEquals(1, recommendationCalls)
        }
    }

    @Test
    fun missing_workout_and_target_are_explicit_without_fake_numbers() {
        rule.setContent {
            GymAppTheme {
                HomeScreen(
                    state = HomeUiState(epochDay = day("2026-07-02")),
                    onNavigateToWorkouts = {},
                    onNavigateToNutrition = {},
                    onNavigateToCheckIn = {},
                    onNavigateToRecommendations = {},
                )
            }
        }

        rule.onNodeWithText("Chưa có buổi tập hiện tại").assertIsDisplayed()
        rule.onNodeWithTag("home-workout-action").assertIsNotEnabled()
        rule.onNodeWithText("Chưa có mục tiêu", substring = true).performScrollTo().assertIsDisplayed()
    }

    private fun populatedState() = HomeUiState(
        epochDay = day("2026-07-02"),
        workoutTitle = "Toàn thân A",
        workoutFocus = "Toàn thân",
        durationMinutes = 42,
        completedExercises = 2,
        totalExercises = 5,
        completedThisWeek = 3,
        streakDays = 4,
        caloriesConsumed = 1_240,
        caloriesTarget = 2_100,
    )

    private fun day(value: String): Long = LocalDate.parse(value).toEpochDay()
}
