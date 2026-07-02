package com.example.myapplication.feature.recommendations

import com.example.myapplication.core.adaptation.AdaptationKind
import com.example.myapplication.core.adaptation.AdaptationMode
import com.example.myapplication.core.adaptation.AdaptationStatus
import com.example.myapplication.data.AdaptationRepository
import com.example.myapplication.data.CoachExplanationClient
import com.example.myapplication.data.DecisionActionResult
import com.example.myapplication.data.local.AdaptationDecisionEntity
import com.example.myapplication.data.local.PersonalProfileEntity
import com.example.myapplication.data.local.PersonalizationDao
import com.example.myapplication.core.profile.ActivityLevel
import com.example.myapplication.core.profile.GoalPace
import com.example.myapplication.core.profile.MetabolicSex
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class RecommendationViewModelTest {
    private val dispatcher = StandardTestDispatcher()
    private val testScope = TestScope(dispatcher)

    @Before
    fun setUp() {
        Dispatchers.setMain(dispatcher)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial state is Loading`() = testScope.runTest {
        val fakeRepo = FakeAdaptationRepository()
        val fakeDao = FakePersonalizationDao()
        val fakeClient = FakeCoachExplanationClient()

        val viewModel = RecommendationViewModel(fakeRepo, fakeDao, fakeClient)
        assertEquals(RecommendationUiState.Loading, viewModel.uiState.value)
    }

    @Test
    fun `success state maps decisions correctly and shows local explanations when cloud consent is false`() = testScope.runTest {
        val fakeRepo = FakeAdaptationRepository()
        val fakeDao = FakePersonalizationDao()
        val fakeClient = FakeCoachExplanationClient()

        fakeDao.profile = defaultProfile(cloudAiConsent = false)

        val decisionEntity = AdaptationDecisionEntity(
            id = 1,
            kind = AdaptationKind.CALORIE_TARGET,
            mode = AdaptationMode.AUTO_APPLY,
            status = AdaptationStatus.APPLIED,
            reasonVi = "Local explanation",
            payloadVersion = 1,
            inputsJson = "{}",
            beforeJson = "{}",
            afterJson = "{}",
            undoJson = "{}",
            createdAtEpochMillis = 1000,
            resolvedAtEpochMillis = 1000
        )
        fakeRepo.decisionsFlow.value = listOf(decisionEntity)

        val viewModel = RecommendationViewModel(fakeRepo, fakeDao, fakeClient)
        val job = backgroundScope.launch(kotlinx.coroutines.ExperimentalCoroutinesApi::class.java.let { kotlinx.coroutines.test.UnconfinedTestDispatcher(testScheduler) }) {
            viewModel.uiState.collect {}
        }
        advanceUntilIdle()

        val state = viewModel.uiState.value as RecommendationUiState.Success
        assertEquals(1, state.decisions.size)
        val uiDecision = state.decisions.first()
        assertEquals("Local explanation", uiDecision.explanationText)
        assertTrue(uiDecision.isUndoEligible)
        assertFalse(state.cloudAiConsent)
        assertEquals(0, fakeClient.callCount)
    }

    @Test
    fun `fetches AI explanation when cloud consent is true for proposed decisions`() = testScope.runTest {
        val fakeRepo = FakeAdaptationRepository()
        val fakeDao = FakePersonalizationDao()
        val fakeClient = FakeCoachExplanationClient(reply = "AI explanation")

        fakeDao.profile = defaultProfile(cloudAiConsent = true)

        val decisionEntity = AdaptationDecisionEntity(
            id = 1,
            kind = AdaptationKind.CALORIE_TARGET,
            mode = AdaptationMode.REQUIRES_CONFIRMATION,
            status = AdaptationStatus.PROPOSED,
            reasonVi = "Local explanation",
            payloadVersion = 1,
            inputsJson = "{}",
            beforeJson = "{}",
            afterJson = "{}",
            undoJson = "{}",
            createdAtEpochMillis = 1000,
            resolvedAtEpochMillis = null
        )
        fakeRepo.decisionsFlow.value = listOf(decisionEntity)

        val viewModel = RecommendationViewModel(fakeRepo, fakeDao, fakeClient)
        val job = backgroundScope.launch(kotlinx.coroutines.ExperimentalCoroutinesApi::class.java.let { kotlinx.coroutines.test.UnconfinedTestDispatcher(testScheduler) }) {
            viewModel.uiState.collect {}
        }
        advanceUntilIdle()

        val state = viewModel.uiState.value as RecommendationUiState.Success
        assertEquals(1, state.decisions.size)
        val uiDecision = state.decisions.first()
        assertEquals("AI explanation", uiDecision.explanationText)
        assertTrue(state.cloudAiConsent)
        assertEquals(1, fakeClient.callCount)
    }

    @Test
    fun `falls back to local reasonVi when AI explanation request fails`() = testScope.runTest {
        val fakeRepo = FakeAdaptationRepository()
        val fakeDao = FakePersonalizationDao()
        val fakeClient = FakeCoachExplanationClient(reply = null) // failed request

        fakeDao.profile = defaultProfile(cloudAiConsent = true)

        val decisionEntity = AdaptationDecisionEntity(
            id = 1,
            kind = AdaptationKind.CALORIE_TARGET,
            mode = AdaptationMode.REQUIRES_CONFIRMATION,
            status = AdaptationStatus.PROPOSED,
            reasonVi = "Local explanation",
            payloadVersion = 1,
            inputsJson = "{}",
            beforeJson = "{}",
            afterJson = "{}",
            undoJson = "{}",
            createdAtEpochMillis = 1000,
            resolvedAtEpochMillis = null
        )
        fakeRepo.decisionsFlow.value = listOf(decisionEntity)

        val viewModel = RecommendationViewModel(fakeRepo, fakeDao, fakeClient)
        val job = backgroundScope.launch(kotlinx.coroutines.ExperimentalCoroutinesApi::class.java.let { kotlinx.coroutines.test.UnconfinedTestDispatcher(testScheduler) }) {
            viewModel.uiState.collect {}
        }
        advanceUntilIdle()

        val state = viewModel.uiState.value as RecommendationUiState.Success
        assertEquals(1, state.decisions.size)
        val uiDecision = state.decisions.first()
        assertEquals("Local explanation", uiDecision.explanationText)
    }

    // ── Helper Fakes ───────────────────────────────────────────────────

    private fun defaultProfile(cloudAiConsent: Boolean) = PersonalProfileEntity(
        birthDateEpochDay = 9300,
        metabolicSex = MetabolicSex.MALE,
        heightCm = 175.0,
        currentWeightKg = 78.0,
        targetWeightKg = 72.0,
        activityLevel = ActivityLevel.MODERATE,
        goalPace = GoalPace.GRADUAL,
        personalizationConsent = true,
        cloudAiConsent = cloudAiConsent,
        updatedAtEpochMillis = 1000
    )

    private class FakeAdaptationRepository : AdaptationRepository {
        val decisionsFlow = MutableStateFlow<List<AdaptationDecisionEntity>>(emptyList())

        override fun observeDecisions(): Flow<List<AdaptationDecisionEntity>> = decisionsFlow

        override suspend fun recordDecision(decision: com.example.myapplication.core.adaptation.AdaptationDecision): Long = 0

        override suspend fun acceptDecision(decisionId: Long): DecisionActionResult {
            decisionsFlow.value = decisionsFlow.value.map {
                if (it.id == decisionId) it.copy(status = AdaptationStatus.APPLIED) else it
            }
            return DecisionActionResult.Success
        }

        override suspend fun rejectDecision(decisionId: Long): DecisionActionResult {
            decisionsFlow.value = decisionsFlow.value.map {
                if (it.id == decisionId) it.copy(status = AdaptationStatus.REJECTED) else it
            }
            return DecisionActionResult.Success
        }

        override suspend fun undoLatestDecision(kind: AdaptationKind): DecisionActionResult {
            decisionsFlow.value = decisionsFlow.value.map {
                if (it.kind == kind && it.status == AdaptationStatus.APPLIED) it.copy(status = AdaptationStatus.UNDONE) else it
            }
            return DecisionActionResult.Success
        }
    }

    private class FakePersonalizationDao : PersonalizationDao {
        var profile: PersonalProfileEntity? = null
        override suspend fun upsertProfile(profile: PersonalProfileEntity) = Unit
        override fun observeProfile(): Flow<PersonalProfileEntity?> = flowOf(profile)
        override suspend fun profileNow(): PersonalProfileEntity? = profile
        override suspend fun upsertWeight(measurement: com.example.myapplication.data.local.WeightMeasurementEntity) = Unit
        override suspend fun latestWeightNow(): com.example.myapplication.data.local.WeightMeasurementEntity? = null
        override fun observeWeightHistory(): Flow<List<com.example.myapplication.data.local.WeightMeasurementEntity>> = flowOf(emptyList())
        override suspend fun weightHistoryNow(): List<com.example.myapplication.data.local.WeightMeasurementEntity> = emptyList()
        override suspend fun upsertDailyNutrition(day: com.example.myapplication.data.local.DailyNutritionEntity) = Unit
        override fun observeNutritionDay(epochDay: Long): Flow<com.example.myapplication.data.local.DailyNutritionEntity?> = flowOf(null)
        override fun observeNutritionRange(startEpochDay: Long, endEpochDay: Long): Flow<List<com.example.myapplication.data.local.DailyNutritionEntity>> = flowOf(emptyList())
        override suspend fun nutritionRangeNow(startEpochDay: Long, endEpochDay: Long): List<com.example.myapplication.data.local.DailyNutritionEntity> = emptyList()
        override suspend fun upsertWeeklyCheckIn(checkIn: com.example.myapplication.data.local.WeeklyCheckInEntity) = Unit
        override fun observeLatestCheckIn(): Flow<com.example.myapplication.data.local.WeeklyCheckInEntity?> = flowOf(null)
        override suspend fun latestCheckInNow(): com.example.myapplication.data.local.WeeklyCheckInEntity? = null
        override suspend fun insertDecision(decision: AdaptationDecisionEntity): Long = 0
        override suspend fun updateDecisionStatus(id: Long, status: AdaptationStatus, resolvedAt: Long) = Unit
        override suspend fun decisionByIdNow(id: Long): AdaptationDecisionEntity? = null
        override suspend fun latestDecisionByKindAndStatus(kind: AdaptationKind, status: AdaptationStatus): AdaptationDecisionEntity? = null
        override fun observeDecisionHistory(): Flow<List<AdaptationDecisionEntity>> = flowOf(emptyList())
        override suspend fun decisionHistoryNow(): List<AdaptationDecisionEntity> = emptyList()
    }

    private class FakeCoachExplanationClient(private val reply: String? = null) : CoachExplanationClient {
        var callCount = 0
        override suspend fun explainDecision(
            kind: AdaptationKind,
            reasonVi: String,
            beforeValue: String,
            afterValue: String
        ): String? {
            callCount++
            return reply
        }
    }
}
