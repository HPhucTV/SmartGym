import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/catalog/asset_catalog_repository.dart';
import '../../core/motivation/motivation_repository.dart';
import '../local/database.dart';
import '../repositories/settings_repository.dart';
import '../repositories/shared_prefs_settings_repository.dart';
import '../repositories/workout_repository.dart';
import '../repositories/drift_workout_repository.dart';
import '../repositories/nutrition_repository.dart';
import '../repositories/drift_nutrition_repository.dart';
import '../repositories/adaptation_repository.dart';
import '../repositories/drift_adaptation_repository.dart';
import '../repositories/workout_feedback_repository.dart';
import '../repositories/drift_workout_feedback_repository.dart';
import '../repositories/weekly_adaptation_coordinator.dart';
import '../repositories/food_photo_consent_repository.dart';

// Provider cho SharedPreferences, cần override ở ProviderScope lúc khởi chạy
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final foodPhotoConsentRepositoryProvider = Provider<FoodPhotoConsentRepository>((ref) {
  return SharedPrefsFoodPhotoConsentRepository(ref.watch(sharedPreferencesProvider));
});

// Provider cho AssetCatalogRepository, cần override ở ProviderScope sau khi load asset
final assetCatalogRepositoryProvider = Provider<AssetCatalogRepository>((ref) {
  throw UnimplementedError('assetCatalogRepositoryProvider must be overridden');
});

// Provider cho MotivationRepository, cần override ở ProviderScope sau khi load asset
final motivationRepositoryProvider = Provider<MotivationRepository>((ref) {
  throw UnimplementedError('motivationRepositoryProvider must be overridden');
});

// Database Provider
final gymDatabaseProvider = Provider<GymDatabase>((ref) {
  final db = GymDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Settings Repository
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefsSettingsRepository(prefs);
});

int? debugMockEpochDay;

/// Số ngày kể từ epoch cho ngày *dương lịch địa phương* hiện tại.
///
/// Phải dựng bằng [DateTime.utc]: `DateTime(y, m, d)` là nửa đêm giờ địa
/// phương, nên `millisecondsSinceEpoch` của nó là một thời điểm UTC lệch đi
/// theo offset múi giờ — ở UTC+7 đó là 17:00 UTC của ngày *hôm trước*, và chia
/// nguyên sẽ làm tròn xuống thành epoch day sai. Mọi nơi đọc lại giá trị này
/// đều dùng `isUtc: true`, nên hai đầu phải cùng quy ước UTC để ngày và
/// **thứ trong tuần** được bảo toàn.
int currentLocalEpochDay() {
  if (debugMockEpochDay != null) {
    return debugMockEpochDay!;
  }
  final now = DateTime.now();
  return epochDayFromLocalDate(now);
}

/// Chuyển một [DateTime] địa phương thành epoch day, giữ đúng ngày dương lịch.
int epochDayFromLocalDate(DateTime local) =>
    DateTime.utc(local.year, local.month, local.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;

/// Đọc ngược một epoch day về [DateTime] UTC lúc nửa đêm.
///
/// Dùng hàm này thay cho `DateTime.fromMillisecondsSinceEpoch(...)` viết tay để
/// không quên `isUtc: true` — thiếu cờ đó là nguồn gốc lệch ngày khi render.
DateTime dateFromEpochDay(int epochDay) =>
    DateTime.fromMillisecondsSinceEpoch(
      epochDay * Duration.millisecondsPerDay,
      isUtc: true,
    );

// Workout Repository
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final database = ref.watch(gymDatabaseProvider);
  final catalogRepo = ref.watch(assetCatalogRepositoryProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);

  return DriftWorkoutRepository(
    database: database,
    exercisesProvider: () => catalogRepo.exercises,
    settingsRepository: settingsRepo,
    currentEpochDay: currentLocalEpochDay,
  );
});

// Nutrition Repository
final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  final database = ref.watch(gymDatabaseProvider);
  final prefs = ref.watch(sharedPreferencesProvider);

  return DriftNutritionRepository(
    database: database,
    prefs: prefs,
    todayEpochDay: currentLocalEpochDay,
    nowEpochMillis: () => DateTime.now().millisecondsSinceEpoch,
  );
});

// Adaptation Repository
final adaptationRepositoryProvider = Provider<AdaptationRepository>((ref) {
  final database = ref.watch(gymDatabaseProvider);
  final nutritionRepo = ref.watch(nutritionRepositoryProvider);

  return DriftAdaptationRepository(
    database: database,
    nutritionRepository: nutritionRepo,
    nowEpochMillis: () => DateTime.now().millisecondsSinceEpoch,
    todayEpochDay: currentLocalEpochDay,
  );
});

// Workout Feedback Repository
final workoutFeedbackRepositoryProvider = Provider<WorkoutFeedbackRepository>((ref) {
  final database = ref.watch(gymDatabaseProvider);

  return DriftWorkoutFeedbackRepository(
    database: database,
    nowEpochMillis: () => DateTime.now().millisecondsSinceEpoch,
  );
});

// Weekly Snapshot Provider
final weeklySnapshotProvider = Provider<WeeklySnapshotProvider>((ref) {
  final database = ref.watch(gymDatabaseProvider);
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final feedbackRepo = ref.watch(workoutFeedbackRepositoryProvider);
  final nutritionRepo = ref.watch(nutritionRepositoryProvider);

  return DriftWeeklySnapshotProvider(
    database: database,
    workoutRepository: workoutRepo,
    feedbackRepository: feedbackRepo,
    nutritionRepository: nutritionRepo,
    nowEpochMillis: () => DateTime.now().millisecondsSinceEpoch,
  );
});

// Weekly Adaptation Coordinator
final weeklyAdaptationCoordinatorProvider = Provider<WeeklyAdaptationCoordinator>((ref) {
  final snapshotProv = ref.watch(weeklySnapshotProvider);
  final adaptationRepo = ref.watch(adaptationRepositoryProvider);

  return WeeklyAdaptationCoordinator(
    snapshotProvider: snapshotProv,
    adaptationRepository: adaptationRepo,
  );
});
