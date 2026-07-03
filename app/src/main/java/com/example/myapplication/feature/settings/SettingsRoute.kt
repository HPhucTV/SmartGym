package com.example.myapplication.feature.settings

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.flow.Flow

@Composable
fun SettingsRoute(
    viewModel: SettingsViewModel,
    onRequestNotificationPermission: () -> Unit,
    onNavigateToOnboarding: (Boolean) -> Unit,
    onNavigateToProfile: () -> Unit,
    onNavigateToCheckIn: () -> Unit,
    onNavigateToRecommendations: () -> Unit,
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    LaunchedEffect(viewModel) {
        consumeSettingsEvents(
            events = viewModel.events,
            onRequestNotificationPermission = onRequestNotificationPermission,
            onNavigateToOnboarding = onNavigateToOnboarding,
        )
    }
    SettingsScreen(
        state = state,
        onRest = viewModel::setRestDayMode,
        onReminder = viewModel::setReminderEnabled,
        onTime = viewModel::setReminderTime,
        onServerUrlChanged = viewModel::setCustomServerUrl,
        onDarkModeChanged = viewModel::setDarkModeEnabled,
        onRequestReplace = viewModel::requestReplaceGoal,
        onRequestDelete = viewModel::requestDeleteGoal,
        onCancel = viewModel::cancelConfirmation,
        onConfirm = viewModel::confirmGoalAction,
        onNavigateToProfile = onNavigateToProfile,
        onNavigateToCheckIn = onNavigateToCheckIn,
        onNavigateToRecommendations = onNavigateToRecommendations,
        onBack = onNavigateToProfile
    )
}

suspend fun consumeSettingsEvents(
    events: Flow<SettingsEvent>,
    onRequestNotificationPermission: () -> Unit,
    onNavigateToOnboarding: (Boolean) -> Unit,
) {
    events.collect { event ->
        when (event) {
            SettingsEvent.RequestNotificationPermission -> onRequestNotificationPermission()
            is SettingsEvent.GoToOnboarding -> {
                try { onNavigateToOnboarding(event.replacing) } finally { event.acknowledge() }
            }
        }
    }
}