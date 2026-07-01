package com.example.myapplication.feature.today

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.myapplication.ui.theme.GymAppTheme
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class TodayScreenTest {
    @get:Rule val rule = createComposeRule()

    @Test fun workout_content_expand_check_and_complete_state() {
        var checks = 0
        set(WorkoutRowUi(0, "Chống đẩy", "3 × 8–12", 60, listOf("Bước một", "Bước hai"), false), false) { checks++ }
        rule.onNodeWithText("Chống đẩy").assertIsDisplayed()
        rule.onNodeWithText("3 × 8–12 · nghỉ 60 giây").assertIsDisplayed()
        rule.onNodeWithText("Hoàn thành buổi tập").assertIsNotEnabled()
        rule.onNodeWithContentDescription("Đánh dấu Chống đẩy hoàn thành").performClick()
        rule.runOnIdle { assertEquals(1, checks) }
        rule.onNodeWithContentDescription("Mở hướng dẫn Chống đẩy").performClick()
        rule.onNodeWithText("1. Bước một").assertIsDisplayed()
    }

    @Test fun checked_row_has_semantics_and_completion_enabled() {
        set(WorkoutRowUi(0, "Chống đẩy", "30 giây", 30, listOf("Một", "Hai"), true), true)
        rule.onNodeWithContentDescription("Đánh dấu Chống đẩy hoàn thành").assertIsOn()
        rule.onNodeWithContentDescription("Đã hoàn thành Chống đẩy").assertExists()
        rule.onNodeWithText("Hoàn thành buổi tập").assertIsEnabled()
    }

    @Test fun recovery_goal_and_error_have_distinct_copy_and_retry() {
        setState(TodayUiState.Recovery(RecoveryKind.FULL_REST, 101))
        rule.onNodeWithText("Nghỉ ngơi hoàn toàn").assertIsDisplayed()
        setState(TodayUiState.Recovery(RecoveryKind.LIGHT_RECOVERY, 101))
        rule.onNodeWithText("Phục hồi nhẹ").assertIsDisplayed()
        setState(TodayUiState.GoalComplete)
        rule.onNodeWithText("Hoàn thành mục tiêu").assertIsDisplayed()
        setState(TodayUiState.Error("Có lỗi", canRetry = true))
        rule.onNodeWithText("Thử lại").assertIsEnabled()
    }

    private fun set(row: WorkoutRowUi, complete: Boolean, onCheck: () -> Unit = {}) = setState(
        TodayUiState.Workout(7, "Toàn thân", "Ngực", 25, listOf(row), if (row.checked) 1 else 0, 1, complete, false),
        onCheckedChange = { _, _ -> onCheck() })
    private fun setState(state: TodayUiState, onCheckedChange: (Int, Boolean) -> Unit = { _, _ -> }) = rule.setContent {
        GymAppTheme { TodayScreen(state, onCheckedChange, {}, {}) }
    }
}
