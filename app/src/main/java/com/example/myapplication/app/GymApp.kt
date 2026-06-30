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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import kotlinx.coroutines.flow.map

sealed interface GymRootState {
    data object Loading : GymRootState
    data object NoGoal : GymRootState
    data object ActiveGoal : GymRootState
}

@Composable
fun GymApp(container: AppContainer) {
    val rootState by container.workoutRepository.observeActiveGoal()
        .map { goal -> if (goal == null) GymRootState.NoGoal else GymRootState.ActiveGoal }
        .collectAsStateWithLifecycle(initialValue = GymRootState.Loading)
    GymApp(rootState = rootState)
}

@Composable
fun GymApp(rootState: GymRootState) {
    when (rootState) {
        GymRootState.Loading -> LoadingScreen()
        GymRootState.NoGoal -> DestinationScreen(AppDestination.ONBOARDING.heading)
        GymRootState.ActiveGoal -> ActiveGoalNavigation()
    }
}

@Composable
private fun ActiveGoalNavigation() {
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
                    DestinationScreen(destination.heading)
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
