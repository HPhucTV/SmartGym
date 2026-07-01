package com.example.myapplication.feature.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.myapplication.core.model.*
import com.example.myapplication.data.*
import com.example.myapplication.notification.ReminderScheduler
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull

class SettingsViewModel(
    private val workoutRepository: WorkoutRepository,
    private val settingsRepository: SettingsRepository,
    private val scheduler: ReminderScheduler,
) : ViewModel() {
    private val saving = MutableStateFlow(false)
    private val confirmation = MutableStateFlow(PendingConfirmation.NONE)
    private val message = MutableStateFlow<String?>(null)
    private val _events = Channel<SettingsEvent>(Channel.BUFFERED)
    val events: Flow<SettingsEvent> = _events.receiveAsFlow()
    private val _uiState = MutableStateFlow<SettingsUiState>(SettingsUiState.Loading)
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            combine(workoutRepository.observeActiveGoal(), settingsRepository.settings, saving, confirmation, message) { goal, prefs, busy, pending, note ->
                if (goal == null) SettingsUiState.Error("Không tìm thấy mục tiêu đang hoạt động.") else SettingsUiState.Content(
                    GoalSummary(goal.config.goal, goal.config.level, goal.config.equipmentProfile, goal.config.sessionsPerWeek, goal.config.durationWeeks),
                    prefs.restDayMode ?: goal.config.restDayMode, prefs.reminderEnabled, prefs.reminderHour, prefs.reminderMinute,
                    busy, pending, note)
            }.collect { _uiState.value = it }
        }
    }

    fun setRestDayMode(mode: RestDayMode) = perform { settingsRepository.setRestDayMode(mode) }

    fun setReminderTime(hour: Int, minute: Int) {
        if (!startSaving()) return
        viewModelScope.launch {
            var previous: Settings? = null
            try {
                previous = settingsRepository.settings.first()
                settingsRepository.setReminderTime(hour, minute)
                if (previous.reminderEnabled) scheduler.schedule(hour, minute)
            } catch (cancelled: CancellationException) {
                previous?.let { restoreReminder(it) }; throw cancelled
            } catch (_: Exception) {
                previous?.let { restoreReminder(it) }; message.value = SAVE_ERROR
            } finally { saving.value = false }
        }
    }

    fun setReminderEnabled(enabled: Boolean) {
        if (!startSaving()) return
        viewModelScope.launch {
            var previous: Settings? = null
            try {
                previous = settingsRepository.settings.first()
                settingsRepository.setReminderEnabled(enabled)
                if (enabled) scheduler.schedule(previous.reminderHour, previous.reminderMinute) else scheduler.cancel()
                if (enabled) _events.send(SettingsEvent.RequestNotificationPermission)
            } catch (cancelled: CancellationException) {
                previous?.let { restoreReminder(it) }; throw cancelled
            } catch (_: Exception) {
                previous?.let { restoreReminder(it) }; message.value = SAVE_ERROR
            } finally { saving.value = false }
        }
    }

    private fun startSaving(): Boolean {
        if (saving.value) return false
        saving.value = true
        message.value = null
        return true
    }

    private suspend fun restoreReminder(previous: Settings) = withContext(NonCancellable) {
        runCatching { settingsRepository.setReminderTime(previous.reminderHour, previous.reminderMinute) }
        runCatching { settingsRepository.setReminderEnabled(previous.reminderEnabled) }
        runCatching {
            if (previous.reminderEnabled) scheduler.schedule(previous.reminderHour, previous.reminderMinute) else scheduler.cancel()
        }
    }

    fun requestReplaceGoal() { if (!saving.value) confirmation.value = PendingConfirmation.REPLACE }
    fun requestDeleteGoal() { if (!saving.value) confirmation.value = PendingConfirmation.DELETE }
    fun cancelConfirmation() { if (!saving.value) confirmation.value = PendingConfirmation.NONE }
    fun confirmGoalAction() {
        val action = confirmation.value
        if (action == PendingConfirmation.NONE || saving.value) return
        saving.value = true; confirmation.value = PendingConfirmation.NONE
        viewModelScope.launch {
            val replacing = action == PendingConfirmation.REPLACE
            var modeHoisted = false
            try {
                navigateAndAwait(replacing)
                modeHoisted = replacing
                workoutRepository.archiveActiveGoal()
            } catch (cancelled: CancellationException) {
                if (modeHoisted) resetReplacementMode()
                throw cancelled
            } catch (_: Exception) {
                if (modeHoisted) resetReplacementMode()
                message.value = "Không thể cập nhật mục tiêu. Vui lòng thử lại."
            } finally { saving.value = false }
        }
    }

    private suspend fun resetReplacementMode() = withContext(NonCancellable) {
        withTimeoutOrNull(1_000) { navigateAndAwait(false) }
    }

    private suspend fun navigateAndAwait(replacing: Boolean) {
        val event = SettingsEvent.GoToOnboarding(replacing)
        _events.send(event)
        event.awaitAcknowledgement()
    }

    private fun perform(block: suspend () -> Unit) {
        if (!startSaving()) return
        viewModelScope.launch {
            try { block() }
            catch (cancelled: CancellationException) { throw cancelled }
            catch (_: Exception) { message.value = SAVE_ERROR }
            finally { saving.value = false }
        }
    }

    private companion object { const val SAVE_ERROR = "Không thể lưu cài đặt. Vui lòng thử lại." }
}
