package com.example.myapplication.app

import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
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
