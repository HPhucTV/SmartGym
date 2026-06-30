package com.example.myapplication.app

import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.runtime.mutableStateOf
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.myapplication.ui.theme.GymAppTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class GymAppNavigationTest {
    @get:Rule
    val composeRule = createComposeRule()

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
        composeRule.onNodeWithText("Bài tập hôm nay").assertIsDisplayed()
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

        composeRule.onNodeWithText("Bài tập hôm nay").assertIsDisplayed()
        composeRule.onNodeWithText("Hôm nay").assertIsDisplayed()
        composeRule.onNodeWithText("Tiến độ").assertIsDisplayed().performClick()
        composeRule.onNodeWithText("Tiến độ tập luyện").assertIsDisplayed()
        composeRule.onNodeWithText("Cài đặt").assertIsDisplayed().performClick()
        composeRule.onNodeWithText("Cài đặt ứng dụng").assertIsDisplayed()
        composeRule.onNodeWithText("Hôm nay").performClick()
        composeRule.onNodeWithText("Bài tập hôm nay").assertIsDisplayed()
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
}
