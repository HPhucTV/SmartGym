import '../../core/model/food_photo_analysis_models.dart';
import '../../core/model/nutrition_models.dart';
import '../local/database.dart';

class NutritionData {
  final int caloriesEaten;
  final int proteinEaten;
  final int carbsEaten;
  final int fatEaten;
  final int fiberEaten;
  final String? sweatExerciseId;
  final String? sweatExerciseName;
  final int sweatExtraSets;
  final bool sweatActive;
  final String? aiCoachReview;

  const NutritionData({
    this.caloriesEaten = 0,
    this.proteinEaten = 0,
    this.carbsEaten = 0,
    this.fatEaten = 0,
    this.fiberEaten = 0,
    this.sweatExerciseId,
    this.sweatExerciseName,
    this.sweatExtraSets = 0,
    this.sweatActive = false,
    this.aiCoachReview,
  });
}

class NutritionPreferenceState {
  final bool roomMigrated;
  final String? sweatExerciseId;
  final String? sweatExerciseName;
  final int sweatExtraSets;
  final bool sweatActive;
  final String? aiCoachReview;

  const NutritionPreferenceState({
    this.roomMigrated = false,
    this.sweatExerciseId,
    this.sweatExerciseName,
    this.sweatExtraSets = 0,
    this.sweatActive = false,
    this.aiCoachReview,
  });
}

final class PhotoNutritionLog {
  final String name;
  final String mealTime;
  final FoodImageType imageType;
  final NutritionEstimate estimate;
  final AnalysisConfidenceLevel confidenceLevel;
  final String calculationSummary;

  const PhotoNutritionLog({
    required this.name,
    required this.mealTime,
    required this.imageType,
    required this.estimate,
    required this.confidenceLevel,
    required this.calculationSummary,
  });
}

abstract class NutritionRepository {
  Stream<NutritionData> get nutritionData;
  Stream<NutritionDay> observeDay(int epochDay);
  Stream<List<NutritionDay>> observeRange(int startEpochDay, int endEpochDay);
  Stream<List<NutritionDay>> observeAllNutrition();
  Stream<List<MealTemplate>> observeMealTemplates();
  Future<int> saveMealTemplate(int? id, String nameVi, Nutrients nutrients);
  Future<void> deleteMealTemplate(int id);
  Future<void> applyMealTemplate(int id, int epochDay);
  Future<void> addNutrients(
      int epochDay, Nutrients nutrients, EntrySource source);
  Future<void> addWater(int epochDay, int waterMl);
  Future<void> setTarget(int epochDay, NutritionTarget target);
  Future<void> setSweatPayment(
      String exerciseId, String exerciseName, int extraSets, bool active);
  Future<void> clearSweatPayment();
  Future<void> updateAiCoachReview(String review);
  Future<void> resetDaily();

  Stream<List<LoggedFoodData>> observeLoggedFoods(int epochDay);
  Future<List<LoggedFoodData>> loggedFoodsNow(int epochDay);
  Stream<List<FoodCatalogItem>> observeRecentFoods(int limit);
  Stream<List<FoodCatalogItem>> observeFavorites();
  Stream<List<FoodCatalogItem>> searchFavorites(String query);
  Future<void> toggleFavorite(int foodCatalogId, bool isFavorite);
  Future<void> logFood({
    required int epochDay,
    required String name,
    required String mealTime,
    required double grams,
    required int calories,
    required int proteinGrams,
    required int carbsGrams,
    required int fatGrams,
    required int fiberGrams,
    int? foodCatalogId,
  });
  Future<void> logPhotoEstimate({
    required int epochDay,
    required PhotoNutritionLog log,
  });
  Future<void> deleteLoggedFood(int id);
  Future<void> copyYesterdayMeals(int yesterdayEpochDay, int todayEpochDay);
}
