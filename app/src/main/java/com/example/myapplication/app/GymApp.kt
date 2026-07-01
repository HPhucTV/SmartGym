package com.example.myapplication.app

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.repeatOnLifecycle
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.example.myapplication.feature.onboarding.OnboardingRoute
import com.example.myapplication.feature.today.TodayScreen
import com.example.myapplication.feature.today.TodayViewModel
import com.example.myapplication.feature.progress.ProgressScreen
import com.example.myapplication.feature.progress.ProgressViewModel
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import java.time.LocalDate
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.map

sealed interface GymRootState {
    data object Loading : GymRootState
    data object NoGoal : GymRootState
    data object ActiveGoal : GymRootState
}

@Composable
fun GymApp(container: AppContainer) {
    val rootStateFlow = remember(container.workoutRepository) {
        container.workoutRepository.observeActiveGoal()
            .map { goal -> if (goal == null) GymRootState.NoGoal else GymRootState.ActiveGoal }
    }
    val rootState by rootStateFlow.collectAsStateWithLifecycle(initialValue = GymRootState.Loading)
    GymApp(
        rootState = rootState,
        noGoalContent = {
            OnboardingRoute(
                programs = container.catalogRepository.programs,
                workoutRepository = container.workoutRepository,
            )
        },
        todayContent = {
            val factory = remember(container) {
                viewModelFactory {
                    initializer {
                        TodayViewModel(container.workoutRepository, container.catalogRepository.exercises) {
                            LocalDate.now().toEpochDay()
                        }
                    }
                }
            }
            val todayViewModel: TodayViewModel = viewModel(factory = factory)
            val lifecycleOwner = LocalLifecycleOwner.current
            LaunchedEffect(todayViewModel, lifecycleOwner) {
                lifecycleOwner.lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) {
                    while (true) {
                        todayViewModel.refreshToday()
                        delay(60_000)
                    }
                }
            }
            val state by todayViewModel.uiState.collectAsStateWithLifecycle()
            TodayScreen(state, todayViewModel::setChecked, todayViewModel::completeWorkout, todayViewModel::retry)
        },
        progressContent = {
            val factory = remember(container) {
                viewModelFactory {
                    initializer { ProgressViewModel(container.workoutRepository) { LocalDate.now().toEpochDay() } }
                }
            }
            val progressViewModel: ProgressViewModel = viewModel(factory = factory)
            val lifecycleOwner = LocalLifecycleOwner.current
            LaunchedEffect(progressViewModel, lifecycleOwner) {
                lifecycleOwner.lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) {
                    while (true) {
                        progressViewModel.refreshToday()
                        delay(60_000)
                    }
                }
            }
            val state by progressViewModel.uiState.collectAsStateWithLifecycle()
            ProgressScreen(state, progressViewModel::previousMonth, progressViewModel::nextMonth)
        },
    )
}

@Composable
fun GymApp(
    rootState: GymRootState,
    noGoalContent: @Composable () -> Unit = { DestinationScreen(AppDestination.ONBOARDING.heading) },
    todayContent: @Composable () -> Unit = { DestinationScreen(AppDestination.TODAY.heading) },
    progressContent: @Composable () -> Unit = { DestinationScreen(AppDestination.PROGRESS.heading) },
) {
    when (rootState) {
        GymRootState.Loading -> LoadingScreen()
        GymRootState.NoGoal -> noGoalContent()
        GymRootState.ActiveGoal -> ActiveGoalNavigation(todayContent, progressContent)
    }
}

@Composable
private fun ActiveGoalNavigation(todayContent: @Composable () -> Unit, progressContent: @Composable () -> Unit) {
    val navController = rememberNavController()
    val destinations = listOf(
        AppDestination.TODAY,
        AppDestination.PROGRESS,
        AppDestination.SETTINGS,
    )
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route

    Scaffold(
        bottomBar = {
            NavigationBar {
                destinations.forEach { destination ->
                    NavigationBarItem(
                        selected = currentRoute == destination.route,
                        onClick = {
                            navController.navigate(destination.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = {},
                        label = { Text(destination.navigationLabel) },
                    )
                }
            }
        },
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = AppDestination.TODAY.route,
            modifier = Modifier.padding(innerPadding),
        ) {
            destinations.forEach { destination ->
                composable(destination.route) {
                    when (destination) {
                        AppDestination.TODAY -> todayContent()
                        AppDestination.PROGRESS -> progressContent()
                        else -> DestinationScreen(destination.heading)
                    }
                }
            }
        }
    }
}

@Composable
private fun DestinationScreen(heading: String) {
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(text = heading, style = MaterialTheme.typography.headlineMedium)
    }
}

@Composable
private fun LoadingScreen() {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        CircularProgressIndicator()
    }
}
