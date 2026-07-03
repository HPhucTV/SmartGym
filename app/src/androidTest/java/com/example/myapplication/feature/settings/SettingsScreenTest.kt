package com.example.myapplication.feature.settings

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.runtime.mutableStateOf
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.myapplication.core.model.*
import com.example.myapplication.ui.theme.GymAppTheme
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class SettingsScreenTest {
    @get:Rule val rule = createComposeRule()

    @Test fun summary_rest_and_reminder_callbacks_are_visible() {
        var rest: RestDayMode? = null; var enabled = false
        set(content(), onRest = { rest = it }, onReminder = { enabled = it })
        rule.onNodeWithText("Thể lực tổng quát").assertIsDisplayed()
        rule.onNodeWithText("Nghỉ hoàn toàn").performClick()
        rule.onNodeWithText("Nhắc tập luyện").performClick()
        rule.runOnIdle { assertEquals(RestDayMode.FULL_REST, rest); assertEquals(true, enabled) }
    }

    @Test fun replace_and_delete_have_distinct_confirmation_and_cancel_paths() {
        var replace = 0; var delete = 0
        val state = mutableStateOf(content())
        rule.setContent {
            GymAppTheme {
                SettingsScreen(
                    state = state.value,
                    onRest = {},
                    onReminder = {},
                    onTime = { _, _ -> },
                    onServerUrlChanged = {},
                    onDarkModeChanged = {},
                    onRequestReplace = { state.value = state.value.copy(confirmation = PendingConfirmation.REPLACE) },
                    onRequestDelete = { state.value = state.value.copy(confirmation = PendingConfirmation.DELETE) },
                    onCancel = { state.value = state.value.copy(confirmation = PendingConfirmation.NONE) },
                    onConfirm = {
                        if (state.value.confirmation == PendingConfirmation.DELETE) delete++ else replace++
                        state.value = state.value.copy(confirmation = PendingConfirmation.NONE)
                    },
                    onNavigateToProfile = {},
                    onNavigateToCheckIn = {},
                    onNavigateToRecommendations = {},
                )
            }
        }
        rule.onNodeWithText("Đổi mục tiêu").performScrollTo().performClick()
        rule.onNodeWithText("Lịch sử buổi tập đã hoàn thành vẫn được giữ lại.").assertIsDisplayed()
        rule.onNodeWithText("Hủy").performClick()
        rule.onNodeWithText("Xóa mục tiêu hiện tại").performScrollTo().performClick()
        rule.onNodeWithText("Xóa mục tiêu").assertExists()
        rule.onNodeWithText("Xác nhận").performClick()
        rule.runOnIdle { assertEquals(0, replace); assertEquals(1, delete) }
    }

    @Test fun saving_disables_actions_and_unrelated_settings_absent() {
        set(content().copy(saving = true))
        rule.onNodeWithText("Đổi mục tiêu").assertIsNotEnabled()
        rule.onAllNodesWithText("Dinh dưỡng").assertCountEquals(0)
        rule.onAllNodesWithText("Tài khoản").assertCountEquals(0)
    }

    private fun content() = SettingsUiState.Content(
        GoalSummary(FitnessGoal.GENERAL_FITNESS, ExperienceLevel.BEGINNER, EquipmentProfile.BODYWEIGHT_ONLY, 3, 4),
        RestDayMode.LIGHT_RECOVERY, false, 20, 0)
    private fun set(state: SettingsUiState.Content, onRest: (RestDayMode) -> Unit = {}, onReminder: (Boolean) -> Unit = {},
        onReplace: () -> Unit = {}, onDelete: () -> Unit = {}) = rule.setContent {
        GymAppTheme {
            SettingsScreen(
                state = state,
                onRest = onRest,
                onReminder = onReminder,
                onTime = { _, _ -> },
                onServerUrlChanged = {},
                onDarkModeChanged = {},
                onRequestReplace = onReplace,
                onRequestDelete = onDelete,
                onCancel = {},
                onConfirm = {},
                onNavigateToProfile = {},
                onNavigateToCheckIn = {},
                onNavigateToRecommendations = {},
            )
        }
    }
}
