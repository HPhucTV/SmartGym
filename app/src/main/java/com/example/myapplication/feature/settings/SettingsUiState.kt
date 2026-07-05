package com.example.myapplication.feature.settings

import com.example.myapplication.core.model.*
import kotlinx.coroutines.CompletableDeferred
import com.example.myapplication.core.program.ScheduleChangePreview

data class GoalSummary(val goal: FitnessGoal, val level: ExperienceLevel, val equipment: EquipmentProfile,
    val sessionsPerWeek: Int, val durationWeeks: Int)
enum class PendingConfirmation { NONE, REPLACE, DELETE }
sealed interface SettingsUiState {
    data object Loading : SettingsUiState
    data class Content(
        val goal: GoalSummary,
        val effectiveRestDayMode: RestDayMode,
        val reminderEnabled: Boolean,
        val reminderHour: Int,
        val reminderMinute: Int,
        val customServerUrl: String? = null,
        val darkModeEnabled: Boolean? = null,
        val saving: Boolean = false,
        val confirmation: PendingConfirmation = PendingConfirmation.NONE,
        val message: String? = null,
        val currentSessionId: Long? = null,
        val currentDueEpochDay: Long? = null,
        val schedulePreview: ScheduleChangePreview? = null,
    ) : SettingsUiState
    data class Error(val message: String) : SettingsUiState
}

sealed interface SettingsEvent {
    data object RequestNotificationPermission : SettingsEvent
    class GoToOnboarding(
        val replacing: Boolean,
        private val consumed: CompletableDeferred<Unit> = CompletableDeferred(),
    ) : SettingsEvent {
        internal fun acknowledge() { consumed.complete(Unit) }
        internal fun fail(throwable: Throwable) { consumed.completeExceptionally(throwable) }
        internal suspend fun awaitAcknowledgement() { consumed.await() }
        override fun equals(other: Any?) = other is GoToOnboarding && replacing == other.replacing
        override fun hashCode() = replacing.hashCode()
        override fun toString() = "GoToOnboarding(replacing=$replacing)"
    }
}
