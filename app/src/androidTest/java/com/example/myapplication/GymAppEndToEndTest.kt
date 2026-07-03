package com.example.myapplication

import android.content.Context
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsOn
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.test.printToString
import androidx.compose.ui.semantics.SemanticsActions
import androidx.datastore.preferences.core.edit
import androidx.test.core.app.ActivityScenario
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.myapplication.core.model.EquipmentProfile
import com.example.myapplication.core.model.ExperienceLevel
import com.example.myapplication.core.model.FitnessGoal
import com.example.myapplication.core.model.GoalConfig
import com.example.myapplication.core.model.RestDayMode
import com.example.myapplication.core.program.AdaptiveProgramPlanner
import com.example.myapplication.data.dataStore
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class GymAppEndToEndTest {
    @get:Rule
    val composeRule = createEmptyComposeRule()

    private lateinit var scenario: ActivityScenario<MainActivity>
    private var expectedExerciseCount: Int = 0

    @Before
    fun resetPersistentStateBeforeActivityLaunch() = runBlocking {
        val application = ApplicationProvider.getApplicationContext<GymApplication>()
        val baseProgram = application.container.catalogRepository.programs.single {
            it.goal == FitnessGoal.GENERAL_FITNESS &&
                it.level == ExperienceLevel.BEGINNER &&
                it.equipmentProfile == EquipmentProfile.BODYWEIGHT_ONLY &&
                it.sessionsPerWeek == 3 && it.durationWeeks == 4
        }
        expectedExerciseCount = AdaptiveProgramPlanner.adapt(
            baseProgram,
            GoalConfig(
                FitnessGoal.GENERAL_FITNESS,
                ExperienceLevel.BEGINNER,
                EquipmentProfile.BODYWEIGHT_ONLY,
                3,
                4,
                RestDayMode.FULL_REST,
                setOf(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY),
                45,
            ),
        ).first().exercises.size
        application.container.database.clearAllTables()
        application.dataStore.edit { it.clear() }
        scenario = ActivityScenario.launch(MainActivity::class.java)
    }

    @After
    fun closeActivity() {
        if (::scenario.isInitialized) scenario.close()
    }

    @Test
    fun onboardingCompleteProgressAndRecreation_useRealOfflineStack() {
        select("onboarding-goal-GENERAL_FITNESS")
        next()
        select("onboarding-level-BEGINNER")
        next()
        select("onboarding-equipment-BODYWEIGHT_ONLY")
        next()
        val todayValue = LocalDate.now().dayOfWeek.value
        listOf(0, 2, 4).map { offset -> DayOfWeek.of((todayValue + offset - 1) % 7 + 1) }
            .forEach { day -> select("onboarding-day-${day.name}") }
        next()
        select("onboarding-duration-45")
        next()
        select("onboarding-rest-FULL_REST")
        next()
        composeRule.onNodeWithTag("onboarding-create-goal").performSemanticsAction(SemanticsActions.OnClick)

        composeRule.waitUntil(timeoutMillis = 10_000) {
            composeRule.onAllNodesWithTag("home-workout-action").fetchSemanticsNodes().isNotEmpty()
        }
        composeRule.onNodeWithTag("home-workout-action").performSemanticsAction(SemanticsActions.OnClick)
        composeRule.waitUntil(timeoutMillis = 10_000) {
            listOf("today-workout", "today-recovery", "today-goal-complete", "today-error")
                .any { composeRule.onAllNodesWithTag(it).fetchSemanticsNodes().isNotEmpty() }
        }
        check(composeRule.onAllNodesWithTag("today-workout").fetchSemanticsNodes().isNotEmpty()) {
            "Expected today's workout after onboarding:\n${composeRule.onRoot(useUnmergedTree = true).printToString()}"
        }
        composeRule.onNodeWithTag("exercise-expand-0").performSemanticsAction(SemanticsActions.OnClick)
        composeRule.onNodeWithTag("exercise-instructions-0").assertIsDisplayed()

        check(expectedExerciseCount > 0) { "Expected the real program to contain exercises" }
        repeat(expectedExerciseCount) { index ->
            composeRule.onNodeWithTag("today-workout")
                .performScrollToNode(hasTestTag("exercise-checkbox-$index"))
            composeRule.onNodeWithTag("exercise-checkbox-$index", useUnmergedTree = true)
                .performSemanticsAction(SemanticsActions.OnClick)
            runCatching {
                composeRule.waitUntil(timeoutMillis = 5_000) {
                    runCatching {
                        composeRule.onNodeWithTag("exercise-checkbox-$index", useUnmergedTree = true).assertIsOn()
                    }.isSuccess
                }
            }.getOrElse { throw AssertionError("Exercise checkbox $index did not persist", it) }
        }
        composeRule.onNodeWithTag("today-workout").performScrollToNode(hasTestTag("today-complete"))
        composeRule.onNodeWithTag("today-complete").assertIsEnabled()
            .performSemanticsAction(SemanticsActions.OnClick)
        composeRule.waitUntil(timeoutMillis = 10_000) {
            composeRule.onAllNodesWithTag("celebration-dismiss").fetchSemanticsNodes().isNotEmpty()
        }
        composeRule.onNodeWithTag("celebration-dismiss").performSemanticsAction(SemanticsActions.OnClick)

        composeRule.onNodeWithTag("nav-progress").performSemanticsAction(SemanticsActions.OnClick)
        composeRule.waitUntil(timeoutMillis = 10_000) {
            composeRule.onAllNodesWithText("1/12 buổi").fetchSemanticsNodes().isNotEmpty()
        }
        val completedDate = LocalDate.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"))
        composeRule.onNodeWithContentDescription("Đã hoàn thành ngày $completedDate").performScrollTo().assertIsDisplayed()

        composeRule.onNodeWithTag("nav-home").performSemanticsAction(SemanticsActions.OnClick)
        composeRule.onNodeWithTag("home-workout-action").performSemanticsAction(SemanticsActions.OnClick)
        scenario.recreate()
        composeRule.waitUntil(timeoutMillis = 10_000) {
            composeRule.onAllNodesWithTag("today-workout").fetchSemanticsNodes().isNotEmpty() ||
                composeRule.onAllNodesWithTag("today-recovery").fetchSemanticsNodes().isNotEmpty()
        }
        check(composeRule.onAllNodesWithTag("today-workout").fetchSemanticsNodes().isNotEmpty() ||
            composeRule.onAllNodesWithTag("today-recovery").fetchSemanticsNodes().isNotEmpty())
    }

    private fun select(tag: String) {
        composeRule.waitUntil(timeoutMillis = 10_000) {
            composeRule.onAllNodesWithTag(tag).fetchSemanticsNodes().isNotEmpty()
        }
        composeRule.onNodeWithTag(tag).performSemanticsAction(SemanticsActions.OnClick)
    }

    private fun next() = composeRule.onNodeWithTag("onboarding-next")
        .performSemanticsAction(SemanticsActions.OnClick)
}
