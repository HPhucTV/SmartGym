package com.example.myapplication.feature.profile

import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.myapplication.core.profile.ActivityLevel
import com.example.myapplication.core.profile.GoalPace
import com.example.myapplication.core.profile.MetabolicSex
import com.example.myapplication.ui.theme.GymAppTheme
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ProfileScreenTest {
    @get:Rule val rule = createComposeRule()

    @Test
    fun profile_inputs_and_validation_errors_are_displayed() {
        val state = ProfileUiState.Content(
            birthDateEpochDay = 9128L, // ~ 1995-01-01
            metabolicSex = MetabolicSex.MALE,
            heightCmStr = "175",
            currentWeightKgStr = "75",
            targetWeightKgStr = "70",
            activityLevel = ActivityLevel.MODERATE,
            goalPace = GoalPace.GRADUAL,
            personalizationConsent = true,
            cloudAiConsent = false,
            validationErrors = listOf("Độ tuổi phải từ 18 đến 100.")
        )

        rule.setContent {
            GymAppTheme {
                ProfileScreen(
                    state = state,
                    onBirthDateChanged = {},
                    onMetabolicSexChanged = {},
                    onHeightChanged = {},
                    onCurrentWeightChanged = {},
                    onTargetWeightChanged = {},
                    onActivityLevelChanged = {},
                    onGoalPaceChanged = {},
                    onPersonalizationConsentChanged = {},
                    onCloudAiConsentChanged = {},
                    onSave = {},
                    onBack = {}
                )
            }
        }

        rule.onNodeWithText("HỒ SƠ CÁ NHÂN").assertIsDisplayed()
        rule.onNodeWithText("Chiều cao").assertIsDisplayed()
        rule.onNodeWithText("Cân nặng").assertIsDisplayed()
        rule.onNodeWithText("Độ tuổi phải từ 18 đến 100.").assertIsDisplayed()
        rule.onNodeWithTag("profile-save-button").assertIsDisplayed()
    }

    @Test
    fun callbacks_are_triggered_on_user_interaction() {
        var saved = false
        val state = ProfileUiState.Content(
            birthDateEpochDay = 9128L,
            metabolicSex = MetabolicSex.MALE,
            heightCmStr = "175",
            currentWeightKgStr = "75",
            targetWeightKgStr = "70",
            activityLevel = ActivityLevel.MODERATE,
            goalPace = GoalPace.GRADUAL,
            personalizationConsent = true,
            cloudAiConsent = false
        )

        rule.setContent {
            GymAppTheme {
                ProfileScreen(
                    state = state,
                    onBirthDateChanged = {},
                    onMetabolicSexChanged = {},
                    onHeightChanged = {},
                    onCurrentWeightChanged = {},
                    onTargetWeightChanged = {},
                    onActivityLevelChanged = {},
                    onGoalPaceChanged = {},
                    onPersonalizationConsentChanged = {},
                    onCloudAiConsentChanged = {},
                    onSave = { saved = true },
                    onBack = {}
                )
            }
        }

        rule.onNodeWithTag("profile-save-button").performClick()
        rule.runOnIdle {
            assertTrue(saved)
        }
    }
}
