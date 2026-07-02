package com.example.myapplication

import android.content.Context
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performScrollToNode
import androidx.datastore.preferences.core.edit
import androidx.test.core.app.ActivityScenario
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.myapplication.core.model.EquipmentProfile
import com.example.myapplication.core.model.ExperienceLevel
import com.example.myapplication.core.model.FitnessGoal
import com.example.myapplication.data.dataStore
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
        expectedExerciseCount = application.container.catalogRepository.programs.single {
            it.goal == FitnessGoal.GENERAL_FITNESS &&
                it.level == ExperienceLevel.BEGINNER &&
                it.equipmentProfile == EquipmentProfile.BODYWEIGHT_ONLY &&
                it.sessionsPerWeek == 3 && it.durationWeeks == 4
        }.workouts.first().exercises.size
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
        select("onboarding-commitment-3-4")
        next()
        select("onboarding-rest-FULL_REST")
        next()
        composeRule.onNodeWithTag("onboarding-create-goal").performClick()

        composeRule.waitUntil(timeoutMillis = 10_000) {
            composeRule.onAllNodesWithTag("today-workout").fetchSemanticsNodes().isNotEmpty()
        }
        composeRule.onNodeWithTag("exercise-expand-0").performClick()
        composeRule.onNodeWithTag("exercise-instructions-0").assertIsDisplayed()

        check(expectedExerciseCount > 0) { "Expected the real program to contain exercises" }
        repeat(expectedExerciseCount) { index ->
            composeRule.onNodeWithTag("today-workout")
                .performScrollToNode(hasTestTag("exercise-checkbox-$index"))
            composeRule.onNodeWithTag("exercise-checkbox-$index", useUnmergedTree = true).performClick()
        }
        composeRule.onNodeWithTag("today-workout").performScrollToNode(hasTestTag("today-complete"))
        composeRule.onNodeWithTag("today-complete").performClick()

        composeRule.onNodeWithTag("nav-progress").performClick()
        composeRule.waitUntil(timeoutMillis = 10_000) {
            composeRule.onAllNodesWithText("1/12 buổi").fetchSemanticsNodes().isNotEmpty()
        }
        val completedDate = LocalDate.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"))
        composeRule.onNodeWithContentDescription("Đã hoàn thành ngày $completedDate").performScrollTo().assertIsDisplayed()

        composeRule.onNodeWithTag("nav-today").performClick()
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
        composeRule.onNodeWithTag(tag).performClick()
    }

    private fun next() = composeRule.onNodeWithTag("onboarding-next").performClick()
}
