package com.example.myapplication.feature.onboarding

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.myapplication.core.model.*
import com.example.myapplication.ui.theme.GymAppTheme
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.time.DayOfWeek

@RunWith(AndroidJUnit4::class)
class OnboardingScreenTest {
    @get:Rule val composeRule = createComposeRule()

    @Test fun scheduleStepExplainsProgressDaysAndTime() {
        setContent(
            editing(
                OnboardingStep.TRAINING_DAYS,
                OnboardingDraft(trainingDays = setOf(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY)),
            ),
        )
        composeRule.onNodeWithText("Bước 4/7").assertIsDisplayed()
        composeRule.onNodeWithText("Chọn ngày bạn thực sự có thể duy trì.").assertIsDisplayed()
        composeRule.onNodeWithText("Thứ Hai").assertIsSelected()
        composeRule.onNodeWithText("Thứ Tư").assertIsSelected()
    }

    @Test fun goalStep_selectsOneDecisionAndAdvances() {
        var selected: FitnessGoal? = null
        var nextCalls = 0
        setContent(editing(OnboardingStep.GOAL, OnboardingDraft(goal = FitnessGoal.MUSCLE_GAIN)), onGoal = { goal -> selected = goal }, onNext = { nextCalls++ })
        composeRule.onNodeWithTag("onboarding-goal-MUSCLE_GAIN").assertIsSelected().performClick()
        composeRule.onNodeWithTag("onboarding-goal-GENERAL_FITNESS").assertIsNotSelected()
        composeRule.runOnIdle { assertSame(FitnessGoal.MUSCLE_GAIN, selected) }
        composeRule.onNodeWithText("Tiếp tục").performClick()
        composeRule.runOnIdle { assertEquals(1, nextCalls) }
        composeRule.onAllNodesWithText("Trình độ").assertCountEquals(0)
    }

    @Test fun reviewShowsExactSelectionsAndSavingDisablesCreate() {
        val draft = OnboardingDraft(
            goal = FitnessGoal.GENERAL_FITNESS,
            level = ExperienceLevel.BEGINNER,
            equipment = EquipmentProfile.BODYWEIGHT_ONLY,
            sessionsPerWeek = 3,
            durationWeeks = 4,
            restDayMode = RestDayMode.LIGHT_RECOVERY,
            trainingDays = setOf(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY),
            sessionDurationMinutes = 45,
        )
        setContent(editing(OnboardingStep.REVIEW, draft, isSaving = true))
        composeRule.onNodeWithText("Thể lực tổng quát").assertIsDisplayed()
        composeRule.onNodeWithText("3 buổi/tuần").assertIsDisplayed()
        composeRule.onNodeWithText("Tối đa 45 phút").assertIsDisplayed()
        composeRule.onNodeWithText("Phục hồi nhẹ").assertIsDisplayed()
        composeRule.onNodeWithText("Đang tạo…").assertIsNotEnabled()
        composeRule.onNodeWithText("Quay lại").assertIsNotEnabled()
    }

    @Test fun unsupportedShowsExplanationAndAlternative() {
        setContent(OnboardingUiState.Unsupported(
            draft = OnboardingDraft(goal = FitnessGoal.MUSCLE_GAIN),
            explanation = "Chưa có chương trình phù hợp với lựa chọn này.",
            alternatives = listOf("Tăng cơ · Người mới · Tạ đơn · 3 buổi/tuần · 4 tuần"),
        ))
        composeRule.onNodeWithText("Chưa có chương trình phù hợp với lựa chọn này.").assertIsDisplayed()
        composeRule.onNodeWithText("Tăng cơ · Người mới · Tạ đơn · 3 buổi/tuần · 4 tuần").assertIsDisplayed()
        composeRule.onNodeWithText("Thay đổi lựa chọn").assertIsDisplayed()
    }

    @Test fun replacementModeHasDistinctHeadingAndExplanation() {
        setContent(editing(OnboardingStep.GOAL), replacementMode = true)
        composeRule.onNodeWithText("Đổi mục tiêu").assertIsDisplayed()
        composeRule.onNodeWithText("Lịch sử hoàn thành vẫn được giữ lại.").assertIsDisplayed()
        composeRule.onAllNodesWithText("Tạo mục tiêu").assertCountEquals(0)
    }
    @Test fun forbiddenAccountAndBodyFieldsAreAbsent() {
        setContent(editing(OnboardingStep.GOAL))
        listOf("Tài khoản", "Cân nặng", "Số đo", "Dinh dưỡng", "AI").forEach {
            composeRule.onAllNodesWithText(it, substring = true, ignoreCase = true).assertCountEquals(0)
        }
    }

    private fun setContent(
        state: OnboardingUiState,
        onGoal: (FitnessGoal) -> Unit = {},
        onNext: () -> Unit = {},
        replacementMode: Boolean = false,
    ) = composeRule.setContent {
        GymAppTheme {
            OnboardingScreen(state, replacementMode = replacementMode, onGoalSelected = onGoal, onNext = onNext)
        }
    }

    private fun editing(
        step: OnboardingStep,
        draft: OnboardingDraft = OnboardingDraft(),
        isSaving: Boolean = false,
    ) = OnboardingUiState.Editing(step, draft, OnboardingOptions(
        goals = setOf(FitnessGoal.GENERAL_FITNESS, FitnessGoal.MUSCLE_GAIN),
        levels = setOf(ExperienceLevel.BEGINNER),
        equipment = setOf(EquipmentProfile.BODYWEIGHT_ONLY),
        commitments = setOf(WorkoutCommitment(3, 4)),
        restDayModes = RestDayMode.entries.toSet(),
    ), isSaving)
}
