package com.example.myapplication.feature.settings

import com.example.myapplication.core.model.*
import com.example.myapplication.data.*
import com.example.myapplication.feature.onboarding.MainDispatcherRule
import com.example.myapplication.notification.ReminderScheduler
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.coroutines.test.*
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class SettingsViewModelTest {
    private val dispatcher = StandardTestDispatcher()
    @get:Rule val mainRule = MainDispatcherRule(dispatcher)

    @Test fun `rest override persists without scheduling`() = runTest(dispatcher) {
        val settings = FakeSettingsRepository(); val scheduler = FakeScheduler()
        val vm = SettingsViewModel(FakeWorkoutRepository(), settings, scheduler); runCurrent()
        vm.setRestDayMode(RestDayMode.LIGHT_RECOVERY); advanceUntilIdle()
        assertEquals(RestDayMode.LIGHT_RECOVERY, settings.value.value.restDayMode)
        assertTrue(scheduler.calls.isEmpty())
    }

    @Test fun `reminder enable time change and disable control scheduler exactly`() = runTest(dispatcher) {
        val settings = FakeSettingsRepository(Settings(reminderHour = 19, reminderMinute = 30)); val scheduler = FakeScheduler()
        val vm = SettingsViewModel(FakeWorkoutRepository(), settings, scheduler); runCurrent()
        vm.setReminderEnabled(true); advanceUntilIdle()
        vm.setReminderTime(6, 45); advanceUntilIdle()
        vm.setReminderEnabled(false); advanceUntilIdle()
        assertEquals(listOf("schedule:19:30", "schedule:6:45", "cancel"), scheduler.calls)
    }

    @Test fun `enabling emits permission request and duplicate action is guarded`() = runTest(dispatcher) {
        val settings = FakeSettingsRepository(delayWrite = true); val scheduler = FakeScheduler()
        val vm = SettingsViewModel(FakeWorkoutRepository(), settings, scheduler); runCurrent()
        vm.setReminderEnabled(true); vm.setReminderEnabled(true); advanceUntilIdle()
        assertEquals(1, settings.enabledWrites); assertEquals(1, scheduler.calls.size)
        assertEquals(SettingsEvent.RequestNotificationPermission, vm.events.first())
    }

    @Test fun `permission request is consumed once and is not replayed`() = runTest(dispatcher) {
        val vm = SettingsViewModel(FakeWorkoutRepository(), FakeSettingsRepository(), FakeScheduler()); runCurrent()
        vm.setReminderEnabled(true); advanceUntilIdle()
        assertEquals(SettingsEvent.RequestNotificationPermission, vm.events.first())
        assertNull(withTimeoutOrNull(1) { vm.events.first() })
    }

    @Test fun `replacement mode is acknowledged before archive and reset after failure`() = runTest(dispatcher) {
        val modes = mutableListOf<Boolean>()
        val repo = FakeWorkoutRepository(
            archiveFailure = IllegalStateException("boom"),
            onArchive = { assertEquals(listOf(true), modes) },
        )
        val vm = SettingsViewModel(repo, FakeSettingsRepository(), FakeScheduler()); runCurrent()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) {
            consumeSettingsEvents(vm.events, {}, modes::add)
        }
        runCurrent()

        vm.requestReplaceGoal(); vm.confirmGoalAction(); advanceUntilIdle()

        assertNotNull(repo.active.value)
        assertEquals(listOf(true, false), modes)
        assertNotNull((vm.uiState.value as SettingsUiState.Content).message)
    }

    @Test fun `replace and delete require confirmation archive once and retain history`() = runTest(dispatcher) {
        val modes = mutableListOf<Boolean>()
        val repo = FakeWorkoutRepository(); val vm = SettingsViewModel(repo, FakeSettingsRepository(), FakeScheduler()); runCurrent()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) {
            consumeSettingsEvents(vm.events, {}, modes::add)
        }
        runCurrent()
        vm.requestReplaceGoal(); vm.cancelConfirmation(); advanceUntilIdle(); assertEquals(0, repo.archives)
        vm.requestReplaceGoal(); vm.confirmGoalAction(); vm.confirmGoalAction(); advanceUntilIdle()
        assertEquals(1, repo.archives); assertEquals(1, repo.history.value.size)
        assertEquals(listOf(true), modes)

        repo.active.value = goal(); runCurrent()
        vm.requestDeleteGoal(); vm.cancelConfirmation(); advanceUntilIdle(); assertEquals(1, repo.archives)
        vm.requestDeleteGoal(); vm.confirmGoalAction(); vm.confirmGoalAction(); advanceUntilIdle()
        assertEquals(2, repo.archives); assertEquals(1, repo.history.value.size)
        assertEquals(listOf(true, false), modes)
    }

    @Test fun `write failure is recoverable and cancellation is not swallowed`() = runTest(dispatcher) {
        val failing = FakeSettingsRepository(failure = IllegalStateException("boom"))
        val vm = SettingsViewModel(FakeWorkoutRepository(), failing, FakeScheduler()); runCurrent()
        vm.setRestDayMode(RestDayMode.LIGHT_RECOVERY); advanceUntilIdle()
        assertTrue((vm.uiState.value as SettingsUiState.Content).message!!.isNotBlank())

        val cancelled = FakeSettingsRepository(failure = CancellationException("stop"))
        val cancelledVm = SettingsViewModel(FakeWorkoutRepository(), cancelled, FakeScheduler()); runCurrent()
        cancelledVm.setRestDayMode(RestDayMode.LIGHT_RECOVERY); advanceUntilIdle()
        assertNull((cancelledVm.uiState.value as SettingsUiState.Content).message)
    }


    @Test fun `scheduler failures compensate persisted reminder state and alarm`() = runTest(dispatcher) {
        suspend fun content(vm: SettingsViewModel) = (vm.uiState.first { it is SettingsUiState.Content } as SettingsUiState.Content)

        val enableSettings = FakeSettingsRepository()
        val enableScheduler = FakeScheduler(failOnceOn = "schedule:20:0")
        val enableVm = SettingsViewModel(FakeWorkoutRepository(), enableSettings, enableScheduler); runCurrent()
        enableVm.setReminderEnabled(true); advanceUntilIdle()
        assertFalse(enableSettings.value.value.reminderEnabled)
        assertEquals(listOf("schedule:20:0", "cancel"), enableScheduler.calls)
        assertNotNull(content(enableVm).message)

        val disableSettings = FakeSettingsRepository(Settings(reminderEnabled = true, reminderHour = 19, reminderMinute = 30))
        val disableScheduler = FakeScheduler(failOnceOn = "cancel")
        val disableVm = SettingsViewModel(FakeWorkoutRepository(), disableSettings, disableScheduler); runCurrent()
        disableVm.setReminderEnabled(false); advanceUntilIdle()
        assertTrue(disableSettings.value.value.reminderEnabled)
        assertEquals(listOf("cancel", "schedule:19:30"), disableScheduler.calls)
        assertNotNull(content(disableVm).message)

        val timeSettings = FakeSettingsRepository(Settings(reminderEnabled = true, reminderHour = 19, reminderMinute = 30))
        val timeScheduler = FakeScheduler(failOnceOn = "schedule:6:45")
        val timeVm = SettingsViewModel(FakeWorkoutRepository(), timeSettings, timeScheduler); runCurrent()
        timeVm.setReminderTime(6, 45); timeVm.setReminderTime(8, 0); advanceUntilIdle()
        assertEquals(19, timeSettings.value.value.reminderHour)
        assertEquals(30, timeSettings.value.value.reminderMinute)
        assertEquals(listOf("schedule:6:45", "schedule:19:30"), timeScheduler.calls)
        assertNotNull(content(timeVm).message)
    }

    @Test fun `replacement cancellation after acknowledgement resets mode without completing archive`() = runTest(dispatcher) {
        val modes = mutableListOf<Boolean>()
        val repo = FakeWorkoutRepository(archiveFailure = CancellationException("stop"))
        val vm = SettingsViewModel(repo, FakeSettingsRepository(), FakeScheduler()); runCurrent()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) {
            consumeSettingsEvents(vm.events, {}, modes::add)
        }
        vm.requestReplaceGoal(); vm.confirmGoalAction(); advanceUntilIdle()
        assertEquals(listOf(true, false), modes)
        assertEquals(0, repo.archives)
        assertNotNull(repo.active.value)
    }
    private fun goal() = ActiveGoal(1, GoalConfig(FitnessGoal.GENERAL_FITNESS, ExperienceLevel.BEGINNER,
        EquipmentProfile.BODYWEIGHT_ONLY, 3, 4, RestDayMode.FULL_REST), 12)

    private inner class FakeWorkoutRepository(
        private val archiveFailure: Throwable? = null,
        private val onArchive: () -> Unit = {},
    ) : WorkoutRepository {
        val active = MutableStateFlow<ActiveGoal?>(goal()); val history = MutableStateFlow(listOf(CompletedWorkout(1, 10))); var archives = 0
        override fun observeActiveGoal(): Flow<ActiveGoal?> = active
        override fun observeCompletedWorkouts(): Flow<List<CompletedWorkout>> = history
        override fun observeCurrentWorkout(): Flow<WorkoutSession?> = flowOf(null)
        override suspend fun archiveActiveGoal() { onArchive(); archiveFailure?.let { throw it }; archives++; active.value = null }
        override suspend fun createGoal(config: GoalConfig, program: ProgramTemplate, startEpochDay: Long) = Unit
        override suspend fun setExerciseChecked(sessionId: Long, orderIndex: Int, checked: Boolean) = Unit
        override suspend fun completeWorkout(sessionId: Long, completedEpochDay: Long) = CompleteWorkoutResult.Completed
    }
}

private class FakeSettingsRepository(initial: Settings = Settings(), private val delayWrite: Boolean = false,
    private val failure: Throwable? = null) : SettingsRepository {
    val value = MutableStateFlow(initial); var enabledWrites = 0
    override val settings: Flow<Settings> = value
    private suspend fun fail() { failure?.let { throw it }; if (delayWrite) kotlinx.coroutines.yield() }
    override suspend fun setReminderEnabled(enabled: Boolean) { enabledWrites++; fail(); value.value = value.value.copy(reminderEnabled = enabled) }
    override suspend fun setReminderTime(hour: Int, minute: Int) { fail(); value.value = value.value.copy(reminderHour = hour, reminderMinute = minute) }
    override suspend fun setRestDayMode(mode: RestDayMode?) { fail(); value.value = value.value.copy(restDayMode = mode) }
    override suspend fun setCustomServerUrl(url: String?) { fail(); value.value = value.value.copy(customServerUrl = url) }
    override suspend fun setDarkModeEnabled(enabled: Boolean?) { fail(); value.value = value.value.copy(darkModeEnabled = enabled) }
}

private class FakeScheduler(private var failOnceOn: String? = null) : ReminderScheduler {
    val calls = mutableListOf<String>()
    private fun record(call: String) { calls += call; if (failOnceOn == call) { failOnceOn = null; error("scheduler failure") } }
    override fun schedule(hour: Int, minute: Int) = record("schedule:$hour:$minute")
    override fun cancel() = record("cancel")
}
