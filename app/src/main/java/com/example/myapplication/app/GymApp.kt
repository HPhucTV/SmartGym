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
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
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
import com.example.myapplication.feature.today.CelebrationState
import com.example.myapplication.feature.progress.ProgressScreen
import com.example.myapplication.feature.progress.ProgressViewModel
import com.example.myapplication.feature.settings.SettingsRoute
import com.example.myapplication.feature.settings.SettingsViewModel
import com.example.myapplication.data.Settings
import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
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
    val settingsFlow = remember(container.settingsRepository) {
        container.settingsRepository.settings
    }
    val settingsState by settingsFlow.collectAsStateWithLifecycle(initialValue = null)
    LaunchedEffect(settingsState) {
        settingsState?.let {
            BackendConfig.customServerUrl = it.customServerUrl
        }
    }
    var replacementMode by rememberSaveable { mutableStateOf(false) }
    var replacementWasShown by rememberSaveable { mutableStateOf(false) }
    LaunchedEffect(rootState) {
        when (rootState) {
            GymRootState.NoGoal -> if (replacementMode) replacementWasShown = true
            GymRootState.ActiveGoal -> if (replacementWasShown) { replacementMode = false; replacementWasShown = false }
            GymRootState.Loading -> Unit
        }
    }
    GymApp(
        rootState = rootState,
        replacementMode = replacementMode,
        noGoalContent = { replacing ->
            OnboardingRoute(
                programs = container.catalogRepository.programs,
                workoutRepository = container.workoutRepository,
                replacementMode = replacing,
                onCancel = { replacementMode = false },
                onGoalCreated = { replacementMode = false },
            )
        },
        homeContent = { onNavigateToWorkouts, onNavigateToNutrition, onNavigateToCheckIn, onNavigateToRecommendations, onNavigateToAchievements, onNavigateToRoadmap ->
            val factory = remember(container) {
                viewModelFactory {
                    initializer {
                        com.example.myapplication.feature.home.HomeViewModel(
                            container.workoutRepository,
                            container.nutritionRepository,
                            container.motivationRepository
                        )
                    }
                }
            }
            val homeViewModel: com.example.myapplication.feature.home.HomeViewModel = viewModel(factory = factory)
            val state by homeViewModel.uiState.collectAsStateWithLifecycle()
            com.example.myapplication.feature.home.HomeScreen(
                state = state,
                onNavigateToWorkouts = onNavigateToWorkouts,
                onNavigateToNutrition = onNavigateToNutrition,
                onNavigateToCheckIn = onNavigateToCheckIn,
                onNavigateToRecommendations = onNavigateToRecommendations,
                onNavigateToAchievements = onNavigateToAchievements,
                onNavigateToRoadmap = onNavigateToRoadmap,
            )
        },
        todayContent = { onNavigateToCatalog, onNavigateToNutrition ->
            val factory = remember(container) {
                viewModelFactory {
                    initializer {
                        TodayViewModel(
                            repository = container.workoutRepository,
                            exercises = container.catalogRepository.exercises,
                            restDayOverride = container.settingsRepository.settings.map { it.restDayMode },
                            nutritionRepository = container.nutritionRepository,
                            currentEpochDay = { LocalDate.now().toEpochDay() },
                            achievementChecker = container.achievementChecker,
                            coachCoordinator = com.example.myapplication.feature.today.TodayCoachCoordinator(
                                container.coachReviewClient,
                            ),
                            cloudAiConsent = container.database.personalizationDao().observeProfile()
                                .map { profile -> profile?.cloudAiConsent == true },
                            feedbackRepository = container.workoutFeedbackRepository,
                            movementBlocks = container.catalogRepository.movementBlocks,
                        )
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
            val celebrationState by todayViewModel.celebration.collectAsStateWithLifecycle()
            val pendingFeedback by todayViewModel.pendingFeedback.collectAsStateWithLifecycle()
            TodayScreen(
                state = state,
                onCheckedChange = todayViewModel::setChecked,
                onComplete = todayViewModel::completeWorkout,
                onRetry = todayViewModel::retry,
                onNavigateToCatalog = onNavigateToCatalog,
                onNavigateToNutrition = onNavigateToNutrition,
                onRefreshCoachTip = todayViewModel::refreshCoachTip,
                celebrationState = celebrationState,
                onDismissCelebration = todayViewModel::dismissCelebration,
                pendingFeedback = pendingFeedback,
                onDifficultySelected = todayViewModel::submitDifficulty,
                onDismissFeedback = todayViewModel::dismissFeedback,
                onRequestSubstitution = todayViewModel::requestSubstitution,
                onApplySubstitution = todayViewModel::applySubstitution,
                onDismissSubstitution = todayViewModel::dismissSubstitution,
                onApplyTimeBudget = todayViewModel::applyTimeBudget,
            )
        },
        progressContent = { onNavigateToCatalog, onNavigateToRoadmap ->
            val factory = remember(container) {
                viewModelFactory {
                    initializer {
                        ProgressViewModel(
                            container.workoutRepository,
                            container.catalogRepository.programs,
                            container.catalogRepository.exercises,
                            container.workoutFeedbackRepository,
                            container.database.personalizationDao(),
                        ) { LocalDate.now().toEpochDay() }
                    }
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
            ProgressScreen(
                state = state,
                onPreviousMonth = progressViewModel::previousMonth,
                onNextMonth = progressViewModel::nextMonth,
                onNavigateToCatalog = onNavigateToCatalog,
                onNavigateToRoadmap = onNavigateToRoadmap,
                onWeightFilterSelected = progressViewModel::changeWeightFilter,
            )
        },
        settingsContent = { onNavigateToProfile, onNavigateToCheckIn, onNavigateToRecommendations ->
            val factory = remember(container) { viewModelFactory { initializer {
                SettingsViewModel(container.workoutRepository, container.settingsRepository, container.reminderScheduler)
            } } }
            val settingsViewModel: SettingsViewModel = viewModel(factory = factory)
            val permission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { }
            SettingsRoute(
                viewModel = settingsViewModel,
                onRequestNotificationPermission = {
                    if (Build.VERSION.SDK_INT >= 33) permission.launch(Manifest.permission.POST_NOTIFICATIONS)
                },
                onNavigateToOnboarding = { replacing -> replacementMode = replacing },
                onNavigateToProfile = onNavigateToProfile,
                onNavigateToCheckIn = onNavigateToCheckIn,
                onNavigateToRecommendations = onNavigateToRecommendations,
            )
        },
        catalogContent = { onBack ->
            com.example.myapplication.feature.catalog.ExerciseCatalogScreen(
                exercises = container.catalogRepository.exercises,
                onBack = onBack
            )
        },
        nutritionContent = { onBack ->
            val factory = remember(container) {
                viewModelFactory {
                    initializer {
                        com.example.myapplication.feature.nutrition.NutritionViewModel(
                            workoutRepository = container.workoutRepository,
                            nutritionRepository = container.nutritionRepository,
                            personalizationDao = container.database.personalizationDao(),
                            foodCatalogDao = container.database.foodCatalogDao(),
                            foodAnalysisClient = container.foodAnalysisClient,
                            cloudAiConsent = container.database.personalizationDao().observeProfile()
                                .map { profile -> profile?.cloudAiConsent == true },
                        )
                    }
                }
            }
            val nutritionViewModel: com.example.myapplication.feature.nutrition.NutritionViewModel = viewModel(factory = factory)
            val state by nutritionViewModel.uiState.collectAsStateWithLifecycle()
            com.example.myapplication.feature.nutrition.NutritionScreen(
                state = state,
                onBack = onBack,
                onScan = nutritionViewModel::scanFood,
                onAccept = nutritionViewModel::acceptDraft,
                onDiscard = nutritionViewModel::discardScanResult,
                onUpdateResult = nutritionViewModel::updateScanResult,
                onClearSweat = nutritionViewModel::clearSweat,
                onReset = nutritionViewModel::resetDaily,
                onAddWater = nutritionViewModel::addWater,
                onStartManual = nutritionViewModel::startManualEntry,
                onDraftName = nutritionViewModel::updateDraftName,
                onDraftCalories = nutritionViewModel::updateDraftCalories,
                onDraftProtein = nutritionViewModel::updateDraftProtein,
                onDraftCarbs = nutritionViewModel::updateDraftCarbs,
                onDraftFat = nutritionViewModel::updateDraftFat,
                onDraftFiber = nutritionViewModel::updateDraftFiber,
                onDraftSaveAsTemplate = nutritionViewModel::setDraftSaveAsTemplate,
                onApplyTemplate = nutritionViewModel::applyTemplate,
                onRequestDeleteTemplate = nutritionViewModel::requestDeleteTemplate,
                onCancelDeleteTemplate = nutritionViewModel::cancelDeleteTemplate,
                onConfirmDeleteTemplate = nutritionViewModel::confirmDeleteTemplate,
                onStartRenameTemplate = nutritionViewModel::startRenameTemplate,
                onUpdateTemplateName = nutritionViewModel::updateTemplateName,
                onCancelRenameTemplate = nutritionViewModel::cancelRenameTemplate,
                onConfirmRenameTemplate = nutritionViewModel::confirmRenameTemplate,
                onImportCsv = nutritionViewModel::importNutritionFromCsv,
                onSearchCatalog = nutritionViewModel::searchFoodCatalog,
                onClearCatalog = nutritionViewModel::clearFoodCatalog,
                onAddFoodFromCatalog = nutritionViewModel::addFoodFromCatalog,
                onAddToCart = nutritionViewModel::addToCart,
                onRemoveFromCart = nutritionViewModel::removeFromCart,
                onUpdateCartGrams = nutritionViewModel::updateCartGrams,
                onClearCart = nutritionViewModel::clearCart,
                onConfirmEatCart = nutritionViewModel::confirmEatCart,
                onToggleFavoriteCatalog = nutritionViewModel::toggleFavoriteCatalog,
                onDeleteLoggedFood = nutritionViewModel::deleteLoggedFood,
                onCopyYesterdayMeals = nutritionViewModel::copyYesterdayMeals,
                onSelectScanRecommendation = nutritionViewModel::selectScanRecommendation,
            )
        },
        roadmapContent = { onBack ->
            val factory = remember(container) {
                viewModelFactory {
                    initializer {
                        com.example.myapplication.feature.roadmap.RoadmapViewModel(
                            repository = container.workoutRepository,
                            programs = container.catalogRepository.programs,
                        )
                    }
                }
            }
            val roadmapViewModel: com.example.myapplication.feature.roadmap.RoadmapViewModel = viewModel(factory = factory)
            val state by roadmapViewModel.uiState.collectAsStateWithLifecycle()
            com.example.myapplication.feature.roadmap.WorkoutRoadmapScreen(
                state = state,
                onBack = onBack
            )
        },
        profileContent = { onBack, onNavigateToSettings ->
            val factory = remember(container) {
                viewModelFactory {
                    initializer {
                        com.example.myapplication.feature.profile.ProfileViewModel(
                            personalizationDao = container.database.personalizationDao(),
                            workoutRepository = container.workoutRepository,
                            nutritionRepository = container.nutritionRepository,
                        )
                    }
                }
            }
            val profileViewModel: com.example.myapplication.feature.profile.ProfileViewModel = viewModel(factory = factory)
            val state by profileViewModel.uiState.collectAsStateWithLifecycle()
            com.example.myapplication.feature.profile.ProfileScreen(
                state = state,
                onBirthDateChanged = profileViewModel::updateBirthDate,
                onMetabolicSexChanged = profileViewModel::updateMetabolicSex,
                onHeightChanged = profileViewModel::updateHeight,
                onCurrentWeightChanged = profileViewModel::updateCurrentWeight,
                onTargetWeightChanged = profileViewModel::updateTargetWeight,
                onActivityLevelChanged = profileViewModel::updateActivityLevel,
                onGoalPaceChanged = profileViewModel::updateGoalPace,
                onPersonalizationConsentChanged = profileViewModel::updatePersonalizationConsent,
                onCloudAiConsentChanged = profileViewModel::updateCloudAiConsent,
                onSave = profileViewModel::saveProfile,
                onBack = {
                    profileViewModel.clearSuccess()
                    onBack()
                },
                onNavigateToSettings = onNavigateToSettings
            )
        },
        checkinContent = { onBack, onNavigateToProfile ->
            val factory = remember(container) {
                viewModelFactory {
                    initializer {
                        com.example.myapplication.feature.checkin.WeeklyCheckInViewModel(
                            personalizationDao = container.database.personalizationDao(),
                            nutritionRepository = container.nutritionRepository,
                            adaptationCoordinator = container.weeklyAdaptationCoordinator,
                        )
                    }
                }
            }
            val checkInViewModel: com.example.myapplication.feature.checkin.WeeklyCheckInViewModel = viewModel(factory = factory)
            val state by checkInViewModel.uiState.collectAsStateWithLifecycle()
            com.example.myapplication.feature.checkin.WeeklyCheckInScreen(
                state = state,
                onWeightChanged = checkInViewModel::updateWeight,
                onEnergyChanged = checkInViewModel::updateEnergy,
                onHungerChanged = checkInViewModel::updateHunger,
                onRecoveryChanged = checkInViewModel::updateRecovery,
                onSleepQualityChanged = checkInViewModel::updateSleepQuality,
                onNoteChanged = checkInViewModel::updateNote,
                onSubmit = checkInViewModel::submitCheckIn,
                onBack = {
                    checkInViewModel.clearSuccess()
                    onBack()
                },
                onNavigateToProfile = onNavigateToProfile
            )
        },
        recommendationsContent = { onBack ->
            val factory = remember(container) {
                viewModelFactory {
                    initializer {
                        com.example.myapplication.feature.recommendations.RecommendationViewModel(
                            adaptationRepository = container.adaptationRepository,
                            personalizationDao = container.database.personalizationDao(),
                            coachExplanationClient = container.coachExplanationClient,
                        )
                    }
                }
            }
            val recViewModel: com.example.myapplication.feature.recommendations.RecommendationViewModel = viewModel(factory = factory)
            val state by recViewModel.uiState.collectAsStateWithLifecycle()
            com.example.myapplication.feature.recommendations.RecommendationScreen(
                state = state,
                onAccept = recViewModel::acceptDecision,
                onReject = recViewModel::rejectDecision,
                onUndo = recViewModel::undoDecision,
                onBack = onBack
            )
        },
        achievementsContent = { onBack ->
            val achievementsFlow = remember(container) { container.database.achievementDao().observeAll() }
            val unlockedList by achievementsFlow.collectAsStateWithLifecycle(initialValue = emptyList())
            com.example.myapplication.feature.achievement.AchievementScreen(
                unlockedList = unlockedList,
                onBack = onBack
            )
        }
    )
}

@Composable
fun GymApp(
    rootState: GymRootState,
    replacementMode: Boolean = false,
    noGoalContent: @Composable (Boolean) -> Unit = { DestinationScreen(AppDestination.ONBOARDING.heading) },
    homeContent: @Composable (
        onNavigateToWorkouts: () -> Unit,
        onNavigateToNutrition: () -> Unit,
        onNavigateToCheckIn: () -> Unit,
        onNavigateToRecommendations: () -> Unit,
        onNavigateToAchievements: () -> Unit,
        onNavigateToRoadmap: () -> Unit,
    ) -> Unit = { _, _, _, _, _, _ -> DestinationScreen(AppDestination.HOME.heading) },
    todayContent: @Composable (onNavigateToCatalog: () -> Unit, onNavigateToNutrition: () -> Unit) -> Unit = { _, _ -> DestinationScreen(AppDestination.WORKOUTS.heading) },
    progressContent: @Composable (onNavigateToCatalog: () -> Unit, onNavigateToRoadmap: () -> Unit) -> Unit = { _, _ -> DestinationScreen(AppDestination.PROGRESS.heading) },
    settingsContent: @Composable (onNavigateToProfile: () -> Unit, onNavigateToCheckIn: () -> Unit, onNavigateToRecommendations: () -> Unit) -> Unit = { _, _, _ -> DestinationScreen(AppDestination.SETTINGS.heading) },
    catalogContent: @Composable (onBack: (() -> Unit)?) -> Unit = {},
    nutritionContent: @Composable (onBack: () -> Unit) -> Unit = {},
    roadmapContent: @Composable (onBack: () -> Unit) -> Unit = {},
    profileContent: @Composable (onBack: () -> Unit, onNavigateToSettings: (() -> Unit)?) -> Unit = { _, _ -> },
    checkinContent: @Composable (onBack: () -> Unit, onNavigateToProfile: () -> Unit) -> Unit = { _, _ -> },
    recommendationsContent: @Composable (onBack: () -> Unit) -> Unit = {},
    achievementsContent: @Composable (onBack: () -> Unit) -> Unit = {},
) {
    if (replacementMode) {
        noGoalContent(true)
    } else {
        when (rootState) {
            GymRootState.Loading -> LoadingScreen()
            GymRootState.NoGoal -> noGoalContent(false)
            GymRootState.ActiveGoal -> ActiveGoalNavigation(
                homeContent, todayContent, progressContent, settingsContent,
                catalogContent, nutritionContent, roadmapContent, profileContent, checkinContent, recommendationsContent,
                achievementsContent
            )
        }
    }
}

@Composable
private fun ActiveGoalNavigation(
    homeContent: @Composable (
        onNavigateToWorkouts: () -> Unit,
        onNavigateToNutrition: () -> Unit,
        onNavigateToCheckIn: () -> Unit,
        onNavigateToRecommendations: () -> Unit,
        onNavigateToAchievements: () -> Unit,
        onNavigateToRoadmap: () -> Unit,
    ) -> Unit,
    todayContent: @Composable (onNavigateToCatalog: () -> Unit, onNavigateToNutrition: () -> Unit) -> Unit,
    progressContent: @Composable (onNavigateToCatalog: () -> Unit, onNavigateToRoadmap: () -> Unit) -> Unit,
    settingsContent: @Composable (onNavigateToProfile: () -> Unit, onNavigateToCheckIn: () -> Unit, onNavigateToRecommendations: () -> Unit) -> Unit,
    catalogContent: @Composable (onBack: (() -> Unit)?) -> Unit,
    nutritionContent: @Composable (onBack: () -> Unit) -> Unit,
    roadmapContent: @Composable (onBack: () -> Unit) -> Unit,
    profileContent: @Composable (onBack: () -> Unit, onNavigateToSettings: (() -> Unit)?) -> Unit,
    checkinContent: @Composable (onBack: () -> Unit, onNavigateToProfile: () -> Unit) -> Unit,
    recommendationsContent: @Composable (onBack: () -> Unit) -> Unit,
    achievementsContent: @Composable (onBack: () -> Unit) -> Unit,
) {
    val navController = rememberNavController()
    val destinations = listOf(
        AppDestination.HOME,
        AppDestination.PROGRESS,
        AppDestination.SETTINGS,
    )
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route

    Scaffold(
        bottomBar = {
            NavigationBar(containerColor = MaterialTheme.colorScheme.surface) {
                destinations.forEach { destination ->
                    NavigationBarItem(
                        selected = currentRoute == destination.route,
                        onClick = {
                            if (destination == AppDestination.HOME) {
                                navController.popBackStack(AppDestination.HOME.route, inclusive = false)
                            } else {
                                navController.navigate(destination.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                        },
                        modifier = Modifier.testTag("nav-${destination.route}"),
                        icon = { Text(destination.iconText, fontSize = 20.sp) },
                        label = { Text(destination.navigationLabel) },
                    )
                }
            }
        },
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = AppDestination.HOME.route,
            modifier = Modifier.padding(innerPadding),
        ) {
            destinations.forEach { destination ->
                composable(destination.route) {
                    when (destination) {
                        AppDestination.HOME -> homeContent(
                            {
                                navController.navigate(AppDestination.WORKOUTS.route) {
                                    popUpTo(AppDestination.HOME.route) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            { navController.navigate("nutrition") },
                            { navController.navigate("checkin") },
                            { navController.navigate("recommendations") },
                            { navController.navigate("achievements") },
                            { navController.navigate("roadmap") },
                        )
                        AppDestination.PROGRESS -> progressContent(
                            { navController.navigate("exercise_catalog") },
                            { navController.navigate("roadmap") }
                        )
                        AppDestination.SETTINGS -> settingsContent(
                            { navController.navigate(AppDestination.PROFILE.route) },
                            { navController.navigate("checkin") },
                            { navController.navigate("recommendations") },
                        )
                        else -> DestinationScreen(destination.heading)
                    }
                }
            }
            composable(AppDestination.WORKOUTS.route) {
                todayContent(
                    { navController.navigate("exercise_catalog") },
                    { navController.navigate("nutrition") },
                )
            }
            composable(AppDestination.SEARCH.route) {
                catalogContent { navController.popBackStack() }
            }
            composable(AppDestination.PROFILE.route) {
                profileContent(
                    { navController.popBackStack() },
                    { navController.popBackStack(AppDestination.SETTINGS.route, inclusive = false) },
                )
            }
            composable("exercise_catalog") {
                catalogContent { navController.popBackStack() }
            }
            composable("nutrition") {
                nutritionContent { navController.popBackStack() }
            }
            composable("roadmap") {
                roadmapContent { navController.popBackStack() }
            }
            composable("checkin") {
                checkinContent(
                    { navController.popBackStack() },
                    {
                        navController.navigate(AppDestination.PROFILE.route) {
                            popUpTo("checkin") { inclusive = true }
                        }
                    }
                )
            }
            composable("recommendations") {
                recommendationsContent { navController.popBackStack() }
            }
            composable("achievements") {
                achievementsContent { navController.popBackStack() }
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
