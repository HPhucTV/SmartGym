package com.example.myapplication.app

import androidx.compose.runtime.mutableStateOf
import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.myapplication.core.model.FitnessGoal
import com.example.myapplication.feature.onboarding.OnboardingDraft
import com.example.myapplication.feature.onboarding.OnboardingOptions
import com.example.myapplication.feature.onboarding.OnboardingScreen
import com.example.myapplication.feature.onboarding.OnboardingStep
import com.example.myapplication.feature.onboarding.OnboardingUiState
import com.example.myapplication.ui.theme.GymAppTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class GymAppNavigationTest {
    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun homeActions_navigateToWorkoutNutritionCheckInAndRecommendations() {
        composeRule.setContent {
            GymAppTheme {
                GymApp(
                    rootState = GymRootState.ActiveGoal,
                    homeContent = { workouts, nutrition, checkIn, recommendations, _ ->
                        Column {
                            Button(onClick = workouts) { Text("Home workout") }
                            Button(onClick = nutrition) { Text("Home nutrition") }
                            Button(onClick = checkIn) { Text("Home check-in") }
                            Button(onClick = recommendations) { Text("Home recommendations") }
                        }
                    },
                    todayContent = { _, _ -> Text("Workout destination") },
                    nutritionContent = { Text("Nutrition destination") },
                    checkinContent = { _, _ -> Text("Check-in destination") },
                    recommendationsContent = { Text("Recommendations destination") },
                )
            }
        }

        composeRule.onNodeWithText("Home workout").performClick()
        composeRule.onNodeWithText("Workout destination").assertIsDisplayed()
        composeRule.onNodeWithText("Hôm nay").performClick()
        composeRule.onNodeWithText("Home nutrition").performClick()
        composeRule.onNodeWithText("Nutrition destination").assertIsDisplayed()
        composeRule.onNodeWithText("Hôm nay").performClick()
        composeRule.onNodeWithText("Home check-in").performClick()
        composeRule.onNodeWithText("Check-in destination").assertIsDisplayed()
        composeRule.onNodeWithText("Hôm nay").performClick()
        composeRule.onNodeWithText("Home recommendations").performClick()
        composeRule.onNodeWithText("Recommendations destination").assertIsDisplayed()
    }

    @Test
    fun rootStateTransitions_replaceLoadingOnboardingAndNavigationWithoutStaleUi() {
        val rootState = mutableStateOf<GymRootState>(GymRootState.Loading)
        composeRule.setContent {
            GymAppTheme { GymApp(rootState = rootState.value) }
        }

        composeRule.onAllNodesWithText("Tạo mục tiêu").assertCountEquals(0)
        composeRule.onAllNodesWithText("Hôm nay").assertCountEquals(0)

        composeRule.runOnIdle { rootState.value = GymRootState.NoGoal }
        composeRule.onNodeWithText("Tạo mục tiêu").assertIsDisplayed()
        composeRule.onAllNodesWithText("Hôm nay").assertCountEquals(0)

        composeRule.runOnIdle { rootState.value = GymRootState.ActiveGoal }
        composeRule.onNodeWithText("SmartGym Dashboard").assertIsDisplayed()
        composeRule.onNodeWithText("Hôm nay").assertIsDisplayed()
        composeRule.onNodeWithText("Tiến độ").assertIsDisplayed()
        composeRule.onNodeWithText("Cài đặt").assertIsDisplayed()

        composeRule.runOnIdle { rootState.value = GymRootState.NoGoal }
        composeRule.onNodeWithText("Tạo mục tiêu").assertIsDisplayed()
        composeRule.onAllNodesWithText("Hôm nay").assertCountEquals(0)
        composeRule.onAllNodesWithText("Tiến độ").assertCountEquals(0)
        composeRule.onAllNodesWithText("Cài đặt").assertCountEquals(0)
    }
    @Test
    fun activeGoal_startsToday_andNavigatesAcrossPrimaryDestinations() {
        composeRule.setContent {
            GymAppTheme { GymApp(rootState = GymRootState.ActiveGoal) }
        }

        composeRule.onNodeWithText("SmartGym Dashboard").assertIsDisplayed()
        composeRule.onNodeWithText("Hôm nay").assertIsDisplayed()
        composeRule.onNodeWithText("Tiến độ").assertIsDisplayed().performClick()
        composeRule.onNodeWithText("Tiến độ tập luyện").assertIsDisplayed()
        composeRule.onNodeWithText("Cài đặt").assertIsDisplayed().performClick()
        composeRule.onNodeWithText("Cài đặt ứng dụng").assertIsDisplayed()
        composeRule.onNodeWithText("Hôm nay").performClick()
        composeRule.onNodeWithText("SmartGym Dashboard").assertIsDisplayed()
    }

    @Test
    fun noGoal_showsGoalCreation_withoutBottomNavigation() {
        composeRule.setContent {
            GymAppTheme { GymApp(rootState = GymRootState.NoGoal) }
        }

        composeRule.onNodeWithText("Tạo mục tiêu").assertIsDisplayed()
        composeRule.onAllNodesWithText("Hôm nay").assertCountEquals(0)
        composeRule.onAllNodesWithText("Tiến độ").assertCountEquals(0)
        composeRule.onAllNodesWithText("Cài đặt").assertCountEquals(0)
    }
    @Test
    fun noGoal_passesReplacementModeToRealOnboardingContent() {
        val replacementMode = mutableStateOf(true)
        val onboarding = OnboardingUiState.Editing(
            step = OnboardingStep.GOAL,
            draft = OnboardingDraft(),
            options = OnboardingOptions(
                goals = setOf(FitnessGoal.GENERAL_FITNESS),
                levels = emptySet(),
                equipment = emptySet(),
                commitments = emptySet(),
                restDayModes = emptySet(),
            ),
        )

        composeRule.setContent {
            GymAppTheme {
                GymApp(
                    rootState = GymRootState.NoGoal,
                    replacementMode = replacementMode.value,
                    noGoalContent = { replacing ->
                        OnboardingScreen(state = onboarding, replacementMode = replacing)
                    },
                )
            }
        }

        composeRule.onNodeWithText("Đổi mục tiêu").assertIsDisplayed()
        composeRule.onNodeWithText("Lịch sử hoàn thành vẫn được giữ lại.").assertIsDisplayed()
        composeRule.onAllNodesWithText("Tạo mục tiêu").assertCountEquals(0)

        composeRule.runOnIdle { replacementMode.value = false }
        composeRule.onNodeWithText("Tạo mục tiêu").assertIsDisplayed()
        composeRule.onNodeWithText("Mục tiêu quyết định trọng tâm của chương trình.").assertIsDisplayed()
        composeRule.onAllNodesWithText("Đổi mục tiêu").assertCountEquals(0)
    }
}
