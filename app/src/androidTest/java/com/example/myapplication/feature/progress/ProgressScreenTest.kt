package com.example.myapplication.feature.progress

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.myapplication.ui.theme.GymAppTheme
import java.time.LocalDate
import java.time.YearMonth
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ProgressScreenTest {
    @get:Rule val rule = createComposeRule()

    @Test fun summary_and_exact_seven_completed_dates_are_visible() {
        val marks = (1L..7L).map { LocalDate.of(2026, 6, it.toInt()).toEpochDay() }.toSet()
        set(content(marks))
        rule.onNodeWithText("58%").assertIsDisplayed()
        rule.onNodeWithText("7/12 buổi").assertIsDisplayed()
        rule.onNodeWithText("Chuỗi 2 tuần").assertIsDisplayed()
        marks.forEach { epoch ->
            val date = LocalDate.ofEpochDay(epoch)
            rule.onNodeWithContentDescription("Đã hoàn thành ngày %02d/%02d/%04d".format(date.dayOfMonth, date.monthValue, date.year)).assertExists()
        }
    }

    @Test fun empty_state_remains_meaningful() {
        set(content(emptySet()).copy(percentage = 0, completedActive = 0, weeklyStreak = 0))
        rule.onNodeWithText("0%").assertIsDisplayed()
        rule.onNodeWithText("0/12 buổi").assertIsDisplayed()
        rule.onNodeWithText("Chuỗi 0 tuần").assertIsDisplayed()
    }

    @Test fun month_buttons_invoke_callbacks() {
        var previous = 0; var next = 0
        rule.setContent { GymAppTheme { ProgressScreen(content(emptySet()), { previous++ }, { next++ }) } }
        rule.onNodeWithContentDescription("Tháng trước").performClick()
        rule.onNodeWithContentDescription("Tháng sau").performClick()
        rule.runOnIdle { assertEquals(1, previous); assertEquals(1, next) }
    }

    @Test fun leap_month_has_monday_headers_and_day_29() {
        val state = content(emptySet()).copy(selectedMonth = YearMonth.of(2024, 2))
        set(state)
        listOf("T2", "T3", "T4", "T5", "T6", "T7", "CN").forEach { rule.onNodeWithText(it).assertExists() }
        rule.onNodeWithContentDescription("Ngày 29/02/2024").assertExists()
        rule.onAllNodesWithContentDescription("Ngày 30/02/2024").assertCountEquals(0)
        rule.onNodeWithTag("calendar-blank-0").assertExists()
        rule.onNodeWithTag("calendar-blank-1").assertExists()
        rule.onNodeWithTag("calendar-blank-2").assertExists()
    }

    @Test fun no_active_goal_still_shows_archived_calendar_mark() {
        val epoch = LocalDate.of(2026, 6, 8).toEpochDay()
        set(ProgressUiState.NoActiveGoal(YearMonth.of(2026, 6), setOf(epoch), 1, true, true))
        rule.onNodeWithText("Chưa có mục tiêu đang hoạt động").assertIsDisplayed()
        rule.onNodeWithContentDescription("Đã hoàn thành ngày 08/06/2026").assertExists()
    }

    private fun content(marks: Set<Long>) = ProgressUiState.Content(58, 7, 12, 2, 3,
        YearMonth.of(2026, 6), marks, marks.size, true, true)
    private fun set(state: ProgressUiState) = rule.setContent {
        GymAppTheme { ProgressScreen(state, {}, {}) }
    }
}
