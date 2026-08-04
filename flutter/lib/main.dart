import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/catalog/asset_catalog_repository.dart';
import 'core/motivation/motivation_repository.dart';
import 'data/providers/data_providers.dart';
import 'ui/theme/theme.dart';
import 'feature/onboarding/onboarding_screen.dart';
import 'feature/today/today_screen.dart';
import 'feature/progress/progress_screen.dart';
import 'feature/progress/progress_view_model.dart';
import 'feature/settings/settings_screen.dart';
import 'feature/settings/settings_view_model.dart';
import 'feature/profile/profile_screen.dart';
import 'feature/recommendations/recommendation_screen.dart';
import 'feature/roadmap/roadmap_screen.dart';
import 'feature/catalog/exercise_catalog_screen.dart';
import 'feature/checkin/weekly_checkin_screen.dart';
import 'feature/nutrition/nutrition_screen.dart';
import 'ui/components/gym_bottom_nav.dart';

Future<void> main({
  List<dynamic> overrides = const [],
  Future<String> Function(String)? assetReader,
}) async {
  print('MAIN: Calling WidgetsFlutterBinding.ensureInitialized...');
  WidgetsFlutterBinding.ensureInitialized();
  print('MAIN: WidgetsFlutterBinding.ensureInitialized done.');

  // Load SharedPreferences
  print('MAIN: Getting SharedPreferences instance...');
  final prefs = await SharedPreferences.getInstance();
  print('MAIN: SharedPreferences instance obtained.');

  final reader = assetReader ?? (path) => rootBundle.loadString(path);

  // Load and initialize Asset Catalog
  print('MAIN: Initializing AssetCatalogRepository...');
  final catalogRepo = AssetCatalogRepository(assetReader: reader);
  await catalogRepo.init();
  print('MAIN: AssetCatalogRepository initialized.');

  // Load and initialize Motivation quotes
  print('MAIN: Initializing MotivationRepository...');
  final motivationRepo = MotivationRepository(assetReader: reader);
  await motivationRepo.init();
  print('MAIN: MotivationRepository initialized.');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        assetCatalogRepositoryProvider.overrideWithValue(catalogRepo),
        motivationRepositoryProvider.overrideWithValue(motivationRepo),
        ...overrides,
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch settings to apply Dark/Light Mode system-wide
    final settingsAsync = ref.watch(settingsPrefsProvider);
    final settings = settingsAsync.value;

    final themeMode = settings?.darkModeEnabled == null
        ? ThemeMode.system
        : (settings!.darkModeEnabled! ? ThemeMode.dark : ThemeMode.light);

    return MaterialApp(
      title: 'SmartGym Companion',
      theme: getGymLightTheme(),
      darkTheme: getGymDarkTheme(),
      themeMode: themeMode,
      home: const AppRouterRoot(),
    );
  }
}

class CurrentSubRouteNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  set state(String? value) => super.state = value;
}

final currentSubRouteProvider =
    NotifierProvider<CurrentSubRouteNotifier, String?>(
      CurrentSubRouteNotifier.new,
    );

class CurrentShellTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  set state(int value) => super.state = value;
}

final currentShellTabProvider = NotifierProvider<CurrentShellTabNotifier, int>(
  CurrentShellTabNotifier.new,
);

class AppRouterRoot extends ConsumerStatefulWidget {
  const AppRouterRoot({super.key});

  @override
  ConsumerState<AppRouterRoot> createState() => _AppRouterRootState();
}

class _AppRouterRootState extends ConsumerState<AppRouterRoot> {
  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    final activeGoalAsync = ref.watch(progressActiveGoalProvider);
    final activeGoal = activeGoalAsync.value;
    final subRoute = ref.watch(currentSubRouteProvider);

    if (activeGoalAsync.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      );
    }

    // Determine the child widget based on routing state
    Widget child;
    if (activeGoal == null) {
      child = OnboardingScreen(
        replacementMode: false,
        onCancel: () {},
        onGoalCreated: () {
          ref.read(currentSubRouteProvider.notifier).state = null;
          ref.read(currentShellTabProvider.notifier).state = 0;
        },
      );
    } else if (subRoute == 'onboarding_replace') {
      child = OnboardingScreen(
        replacementMode: true,
        onCancel: () {
          ref.read(currentSubRouteProvider.notifier).state = null;
        },
        onGoalCreated: () {
          ref.read(currentSubRouteProvider.notifier).state = null;
          ref.read(currentShellTabProvider.notifier).state = 0;
        },
      );
    } else if (subRoute == 'profile') {
      child = ProfileScreen(
        onBack: () => ref.read(currentSubRouteProvider.notifier).state = null,
      );
    } else if (subRoute == 'checkin') {
      child = WeeklyCheckInScreen(
        onBack: () => ref.read(currentSubRouteProvider.notifier).state = null,
        onNavigateToProfile: () =>
            ref.read(currentSubRouteProvider.notifier).state = 'profile',
      );
    } else if (subRoute == 'recommendations') {
      child = RecommendationScreen(
        onBack: () => ref.read(currentSubRouteProvider.notifier).state = null,
      );
    } else if (subRoute == 'roadmap') {
      child = RoadmapScreen(
        onBack: () => ref.read(currentSubRouteProvider.notifier).state = null,
      );
    } else if (subRoute == 'catalog') {
      child = ExerciseCatalogScreen(
        onBack: () => ref.read(currentSubRouteProvider.notifier).state = null,
      );
    } else if (subRoute == 'nutrition') {
      child = NutritionScreen(
        onBack: () => ref.read(currentSubRouteProvider.notifier).state = null,
        onOpenProfile: () =>
            ref.read(currentSubRouteProvider.notifier).state = 'profile',
      );
    } else {
      child = const MainNavigationShell();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. If in a sub-page, navigate back to main shell
        if (subRoute != null) {
          ref.read(currentSubRouteProvider.notifier).state = null;
          return;
        }

        // 2. If already in main shell, exit on double back press
        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nhấn trở lại một lần nữa để thoát ứng dụng'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          await SystemNavigator.pop();
        }
      },
      child: child,
    );
  }
}

class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(currentShellTabProvider);

    final List<Widget> screens = [
      TodayScreen(
        onNavigateToCatalog: () {
          ref.read(currentSubRouteProvider.notifier).state = 'catalog';
        },
        onNavigateToNutrition: () {
          ref.read(currentShellTabProvider.notifier).state = 2; // Jump to tab 2
        },
      ),
      ProgressScreen(
        onNavigateToCatalog: () {
          ref.read(currentSubRouteProvider.notifier).state = 'catalog';
        },
        onNavigateToRoadmap: () {
          ref.read(currentSubRouteProvider.notifier).state = 'recommendations';
        },
      ),
      NutritionScreen(
        onOpenProfile: () =>
            ref.read(currentSubRouteProvider.notifier).state = 'profile',
      ),
      SettingsScreen(
        onNavigateToProfile: () {
          ref.read(currentSubRouteProvider.notifier).state = 'profile';
        },
        onNavigateToCheckIn: () {
          ref.read(currentSubRouteProvider.notifier).state = 'checkin';
        },
        onNavigateToRecommendations: () {
          ref.read(currentSubRouteProvider.notifier).state = 'recommendations';
        },
        onGoToOnboardingReplacment: () {
          ref.read(currentSubRouteProvider.notifier).state =
              'onboarding_replace';
        },
        onGoToOnboardingNew: () {
          ref.read(currentSubRouteProvider.notifier).state =
              'onboarding_replace';
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: selectedTab, children: screens),
      bottomNavigationBar: GymBottomNav(
        currentIndex: selectedTab,
        onTap: (index) {
          ref.read(currentShellTabProvider.notifier).state = index;
        },
      ),
    );
  }
}
