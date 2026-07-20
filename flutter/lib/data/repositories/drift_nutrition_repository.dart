import 'dart:async';
import 'dart:math' as math;
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/model/food_photo_analysis_models.dart';
import '../../core/model/nutrition_models.dart';
import '../local/database.dart';
import '../local/daos/personalization_dao.dart';
import '../local/daos/food_catalog_dao.dart';
import '../local/daos/logged_food_dao.dart';
import 'nutrition_repository.dart';
import 'drift_workout_repository.dart'; // import combineLatest2

class DriftNutritionRepository implements NutritionRepository {
  final GymDatabase database;
  final SharedPreferences prefs;
  final int Function() todayEpochDay;
  final int Function() nowEpochMillis;

  final _prefController = StreamController<NutritionPreferenceState>.broadcast();

  DriftNutritionRepository({
    required this.database,
    required this.prefs,
    required this.todayEpochDay,
    required this.nowEpochMillis,
  }) {
    _emitPrefs();
  }

  PersonalizationDao get personalizationDao => database.personalizationDao;
  FoodCatalogDao get foodCatalogDao => database.foodCatalogDao;
  LoggedFoodDao get loggedFoodDao => database.loggedFoodDao;

  static const _keySweatId = 'sweat_exercise_id';
  static const _keySweatName = 'sweat_exercise_name';
  static const _keySweatSets = 'sweat_extra_sets';
  static const _keySweatActive = 'sweat_active';
  static const _keyAiCoachReview = 'ai_coach_review';

  NutritionPreferenceState _getCurrentPrefs() {
    return NutritionPreferenceState(
      roomMigrated: true,
      sweatExerciseId: prefs.getString(_keySweatId),
      sweatExerciseName: prefs.getString(_keySweatName),
      sweatExtraSets: prefs.getInt(_keySweatSets) ?? 0,
      sweatActive: prefs.getBool(_keySweatActive) ?? false,
      aiCoachReview: prefs.getString(_keyAiCoachReview),
    );
  }

  void _emitPrefs() {
    _prefController.add(_getCurrentPrefs());
  }

  Stream<NutritionPreferenceState> get _prefsStream {
    final controller = StreamController<NutritionPreferenceState>();
    controller.add(_getCurrentPrefs());
    final subscription = _prefController.stream.listen(controller.add);
    controller.onCancel = () => subscription.cancel();
    return controller.stream;
  }

  @override
  Stream<NutritionData> get nutritionData {
    final today = todayEpochDay();
    final dayFlow = observeDay(today);
    final prefFlow = _prefsStream;

    return combineLatest2(dayFlow, prefFlow, (day, preferences) {
      return NutritionData(
        caloriesEaten: day.consumed.calories,
        proteinEaten: day.consumed.proteinGrams,
        carbsEaten: day.consumed.carbsGrams,
        fatEaten: day.consumed.fatGrams,
        fiberEaten: day.consumed.fiberGrams,
        sweatExerciseId: preferences.sweatExerciseId,
        sweatExerciseName: preferences.sweatExerciseName,
        sweatExtraSets: preferences.sweatExtraSets,
        sweatActive: preferences.sweatActive,
        aiCoachReview: preferences.aiCoachReview,
      );
    });
  }

  @override
  Stream<NutritionDay> observeDay(int epochDay) {
    return personalizationDao.observeNutritionDay(epochDay).map((entity) {
      return _entityToDomain(entity, epochDay);
    });
  }

  @override
  Stream<List<NutritionDay>> observeRange(int startEpochDay, int endEpochDay) {
    return personalizationDao.observeNutritionRange(startEpochDay, endEpochDay).map((rows) {
      return rows.map((r) => _entityToDomain(r, r.epochDay)).toList();
    });
  }

  @override
  Stream<List<NutritionDay>> observeAllNutrition() {
    return personalizationDao.observeAllNutrition().map((rows) {
      return rows.map((r) => _entityToDomain(r, r.epochDay)).toList();
    });
  }

  @override
  Stream<List<MealTemplate>> observeMealTemplates() {
    return personalizationDao.observeMealTemplates().map((rows) {
      return rows.map((r) => MealTemplate(
        id: r.id,
        nameVi: r.nameVi,
        nutrients: Nutrients(
          calories: r.calories,
          proteinGrams: r.proteinGrams,
          carbsGrams: r.carbsGrams,
          fatGrams: r.fatGrams,
          fiberGrams: r.fiberGrams,
        ),
        updatedAtEpochMillis: r.updatedAtEpochMillis,
      )).toList();
    });
  }

  @override
  Future<int> saveMealTemplate(int? id, String nameVi, Nutrients nutrients) async {
    final normalizedName = nameVi.trim();
    if (normalizedName.isEmpty || normalizedName.length > 60) {
      throw ArgumentError('Meal template name must contain 1..60 characters');
    }
    if (nutrients.calories <= 0) {
      throw ArgumentError('Calories must be greater than zero');
    }
    if (nutrients.proteinGrams < 0 || nutrients.carbsGrams < 0 || nutrients.fatGrams < 0) {
      throw ArgumentError('Nutrients must be non-negative');
    }

    final duplicate = await personalizationDao.mealTemplateByNameNow(normalizedName);
    if (duplicate != null && duplicate.id != id) {
      throw ArgumentError('Meal template name already exists');
    }

    if (id == null) {
      final companion = MealTemplatesCompanion(
        nameVi: Value(normalizedName),
        calories: Value(nutrients.calories),
        proteinGrams: Value(nutrients.proteinGrams),
        carbsGrams: Value(nutrients.carbsGrams),
        fatGrams: Value(nutrients.fatGrams),
        fiberGrams: Value(nutrients.fiberGrams),
        updatedAtEpochMillis: Value(nowEpochMillis()),
      );
      return personalizationDao.insertMealTemplate(companion);
    } else {
      final data = MealTemplateData(
        id: id,
        nameVi: normalizedName,
        calories: nutrients.calories,
        proteinGrams: nutrients.proteinGrams,
        carbsGrams: nutrients.carbsGrams,
        fatGrams: nutrients.fatGrams,
        fiberGrams: nutrients.fiberGrams,
        updatedAtEpochMillis: nowEpochMillis(),
      );
      final updated = await personalizationDao.updateMealTemplate(data);
      if (!updated) {
        throw StateError('Unknown meal template $id');
      }
      return id;
    }
  }

  @override
  Future<void> deleteMealTemplate(int id) async {
    await personalizationDao.deleteMealTemplate(id);
  }

  @override
  Future<void> applyMealTemplate(int id, int epochDay) async {
    await personalizationDao.applyMealTemplateToDay(
      id: id,
      epochDay: epochDay,
      source: EntrySource.template.name.toUpperCase(),
      updatedAtEpochMillis: nowEpochMillis(),
    );
  }

  @override
  Future<void> addNutrients(int epochDay, Nutrients nutrients, EntrySource source) async {
    await database.transaction(() async {
      final current = await _entityNow(epochDay);
      await personalizationDao.upsertDailyNutrition(
        current.copyWith(
          consumedCalories: current.consumedCalories + nutrients.calories,
          consumedProteinGrams: current.consumedProteinGrams + nutrients.proteinGrams,
          consumedCarbsGrams: current.consumedCarbsGrams + nutrients.carbsGrams,
          consumedFatGrams: current.consumedFatGrams + nutrients.fatGrams,
          consumedFiberGrams: current.consumedFiberGrams + nutrients.fiberGrams,
          lastEntrySource: Value(source.name.toUpperCase()),
          updatedAtEpochMillis: nowEpochMillis(),
        ),
      );
    });
  }

  @override
  Future<void> addWater(int epochDay, int waterMl) async {
    await database.transaction(() async {
      final current = await _entityNow(epochDay);
      await personalizationDao.upsertDailyNutrition(
        current.copyWith(
          waterIntakeMl: math.max(0, current.waterIntakeMl + waterMl),
          updatedAtEpochMillis: nowEpochMillis(),
        ),
      );
    });
  }

  @override
  Future<void> setTarget(int epochDay, NutritionTarget target) async {
    await database.transaction(() async {
      final current = await _entityNow(epochDay);
      await personalizationDao.upsertDailyNutrition(
        current.copyWith(
          targetBasalCalories: Value(target.basalCalories),
          targetMaintenanceCalories: Value(target.maintenanceCalories),
          targetCalories: Value(target.calories),
          targetProteinGrams: Value(target.proteinGrams),
          targetCarbsGrams: Value(target.carbsGrams),
          targetFatGrams: Value(target.fatGrams),
          updatedAtEpochMillis: nowEpochMillis(),
        ),
      );
    });
  }

  @override
  Future<void> setSweatPayment(String exerciseId, String exerciseName, int extraSets, bool active) async {
    await prefs.setString(_keySweatId, exerciseId);
    await prefs.setString(_keySweatName, exerciseName);
    await prefs.setInt(_keySweatSets, extraSets);
    await prefs.setBool(_keySweatActive, active);
    _emitPrefs();
  }

  @override
  Future<void> clearSweatPayment() async {
    await prefs.setBool(_keySweatActive, false);
    _emitPrefs();
  }

  @override
  Future<void> updateAiCoachReview(String review) async {
    await prefs.setString(_keyAiCoachReview, review);
    _emitPrefs();
  }

  @override
  Future<void> resetDaily() async {
    final today = todayEpochDay();
    await database.transaction(() async {
      final current = await _entityNow(today);
      await personalizationDao.upsertDailyNutrition(
        current.copyWith(
          consumedCalories: 0,
          consumedProteinGrams: 0,
          consumedCarbsGrams: 0,
          consumedFatGrams: 0,
          consumedFiberGrams: 0,
          lastEntrySource: const Value(null),
          updatedAtEpochMillis: nowEpochMillis(),
        ),
      );
    });
    await prefs.remove(_keyAiCoachReview);
    _emitPrefs();
  }

  @override
  Stream<List<LoggedFoodData>> observeLoggedFoods(int epochDay) {
    return loggedFoodDao.observeDay(epochDay);
  }

  @override
  Future<List<LoggedFoodData>> loggedFoodsNow(int epochDay) {
    return loggedFoodDao.dayNow(epochDay);
  }

  @override
  Stream<List<FoodCatalogItem>> observeRecentFoods(int limit) {
    return loggedFoodDao.observeRecentFoods(limit).map((logged) {
      final distinctLogged = <String, LoggedFoodData>{};
      for (final item in logged) {
        distinctLogged.putIfAbsent(item.name, () => item);
      }
      return distinctLogged.values.map((it) {
        final gramsFactor = it.grams > 0 ? it.grams : 100.0;
        final servingFactor = 100.0 / gramsFactor;
        return FoodCatalogItem(
          id: it.foodCatalogId ?? 0,
          name: it.name,
          gramsPerServing: 100.0,
          caloriesPerServing: it.calories * servingFactor,
          proteinPerServing: it.proteinGrams * servingFactor,
          carbsPerServing: it.carbsGrams * servingFactor,
          fatPerServing: it.fatGrams * servingFactor,
          fiberPerServing: it.fiberGrams * servingFactor,
          isFavorite: false,
        );
      }).toList();
    });
  }

  @override
  Stream<List<FoodCatalogItem>> observeFavorites() {
    return foodCatalogDao.observeFavorites().map((rows) {
      return rows.map(_catalogEntityToDomain).toList();
    });
  }

  @override
  Stream<List<FoodCatalogItem>> searchFavorites(String query) {
    return foodCatalogDao.searchFavorites(query).map((rows) {
      return rows.map(_catalogEntityToDomain).toList();
    });
  }

  @override
  Future<void> toggleFavorite(int foodCatalogId, bool isFavorite) async {
    if (foodCatalogId > 0) {
      await foodCatalogDao.toggleFavorite(foodCatalogId, isFavorite);
    }
  }

  @override
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
  }) async {
    final companion = LoggedFoodsCompanion(
      epochDay: Value(epochDay),
      name: Value(name),
      mealTime: Value(mealTime),
      grams: Value(grams),
      calories: Value(calories),
      proteinGrams: Value(proteinGrams),
      carbsGrams: Value(carbsGrams),
      fatGrams: Value(fatGrams),
      fiberGrams: Value(fiberGrams),
      foodCatalogId: Value(foodCatalogId),
      timestamp: Value(nowEpochMillis()),
    );

    await database.transaction(() async {
      await loggedFoodDao.insert(companion);

      final current = await _entityNow(epochDay);
      await personalizationDao.upsertDailyNutrition(
        current.copyWith(
          consumedCalories: current.consumedCalories + calories,
          consumedProteinGrams: current.consumedProteinGrams + proteinGrams,
          consumedCarbsGrams: current.consumedCarbsGrams + carbsGrams,
          consumedFatGrams: current.consumedFatGrams + fatGrams,
          consumedFiberGrams: current.consumedFiberGrams + fiberGrams,
          lastEntrySource: Value(EntrySource.manual.name.toUpperCase()),
          updatedAtEpochMillis: nowEpochMillis(),
        ),
      );
    });
  }

  @override
  Future<void> logPhotoEstimate({
    required int epochDay,
    required PhotoNutritionLog log,
  }) async {
    final normalizedName = log.name.trim();
    final normalizedSummary = log.calculationSummary.trim();
    _validatePhotoLog(
      log,
      normalizedName: normalizedName,
      normalizedSummary: normalizedSummary,
    );

    final estimate = log.estimate;
    final calories = _roundPhotoNutritionValue(estimate.calories.mid);
    final proteinGrams = _roundPhotoNutritionValue(estimate.proteinGrams.mid);
    final carbsGrams = _roundPhotoNutritionValue(estimate.carbsGrams.mid);
    final fatGrams = _roundPhotoNutritionValue(estimate.fatGrams.mid);
    final companion = LoggedFoodsCompanion(
      epochDay: Value(epochDay),
      name: Value(normalizedName),
      mealTime: Value(log.mealTime),
      grams: const Value(0.0),
      calories: Value(calories),
      proteinGrams: Value(proteinGrams),
      carbsGrams: Value(carbsGrams),
      fatGrams: Value(fatGrams),
      fiberGrams: const Value(0),
      timestamp: Value(nowEpochMillis()),
      source: Value(FoodNutritionSource.cameraAnalysis.wireValue),
      calorieMin: Value(_roundPhotoNutritionValue(estimate.calories.min)),
      calorieMax: Value(_roundPhotoNutritionValue(estimate.calories.max)),
      proteinMinGrams: Value(estimate.proteinGrams.min),
      proteinMaxGrams: Value(estimate.proteinGrams.max),
      carbsMinGrams: Value(estimate.carbsGrams.min),
      carbsMaxGrams: Value(estimate.carbsGrams.max),
      fatMinGrams: Value(estimate.fatGrams.min),
      fatMaxGrams: Value(estimate.fatGrams.max),
      analysisConfidence: Value(log.confidenceLevel.wireValue),
      analysisImageType: Value(log.imageType.wireValue),
      calculationSummary: Value(normalizedSummary),
    );

    await database.transaction(() async {
      await loggedFoodDao.insert(companion);

      final current = await _entityNow(epochDay);
      await personalizationDao.upsertDailyNutrition(
        current.copyWith(
          consumedCalories: current.consumedCalories + calories,
          consumedProteinGrams: current.consumedProteinGrams + proteinGrams,
          consumedCarbsGrams: current.consumedCarbsGrams + carbsGrams,
          consumedFatGrams: current.consumedFatGrams + fatGrams,
          lastEntrySource: Value(FoodNutritionSource.cameraAnalysis.wireValue),
          updatedAtEpochMillis: nowEpochMillis(),
        ),
      );
    });
  }

  @override
  Future<void> deleteLoggedFood(int id) async {
    await database.transaction(() async {
      final food = await loggedFoodDao.getById(id);
      if (food == null) return;

      await loggedFoodDao.deleteLoggedFood(id);

      final current = await _entityNow(food.epochDay);
      await personalizationDao.upsertDailyNutrition(
        current.copyWith(
          consumedCalories: math.max(0, current.consumedCalories - food.calories),
          consumedProteinGrams: math.max(0, current.consumedProteinGrams - food.proteinGrams),
          consumedCarbsGrams: math.max(0, current.consumedCarbsGrams - food.carbsGrams),
          consumedFatGrams: math.max(0, current.consumedFatGrams - food.fatGrams),
          consumedFiberGrams: math.max(0, current.consumedFiberGrams - food.fiberGrams),
          updatedAtEpochMillis: nowEpochMillis(),
        ),
      );
    });
  }

  @override
  Future<void> copyYesterdayMeals(int yesterdayEpochDay, int todayEpochDay) async {
    await database.transaction(() async {
      final yesterdayFoods = await loggedFoodDao.dayNow(yesterdayEpochDay);
      if (yesterdayFoods.isEmpty) return;

      final companions = yesterdayFoods.map((it) {
        return LoggedFoodsCompanion(
          epochDay: Value(todayEpochDay),
          name: Value(it.name),
          mealTime: Value(it.mealTime),
          grams: Value(it.grams),
          calories: Value(it.calories),
          proteinGrams: Value(it.proteinGrams),
          carbsGrams: Value(it.carbsGrams),
          fatGrams: Value(it.fatGrams),
          fiberGrams: Value(it.fiberGrams),
          foodCatalogId: Value(it.foodCatalogId),
          timestamp: Value(nowEpochMillis()),
        );
      }).toList();

      await loggedFoodDao.insertAll(companions);

      int totalCalories = 0;
      int totalProtein = 0;
      int totalCarbs = 0;
      int totalFat = 0;
      int totalFiber = 0;

      for (final f in yesterdayFoods) {
        totalCalories += f.calories;
        totalProtein += f.proteinGrams;
        totalCarbs += f.carbsGrams;
        totalFat += f.fatGrams;
        totalFiber += f.fiberGrams;
      }

      final current = await _entityNow(todayEpochDay);
      await personalizationDao.upsertDailyNutrition(
        current.copyWith(
          consumedCalories: current.consumedCalories + totalCalories,
          consumedProteinGrams: current.consumedProteinGrams + totalProtein,
          consumedCarbsGrams: current.consumedCarbsGrams + totalCarbs,
          consumedFatGrams: current.consumedFatGrams + totalFat,
          consumedFiberGrams: current.consumedFiberGrams + totalFiber,
          lastEntrySource: Value(EntrySource.manual.name.toUpperCase()),
          updatedAtEpochMillis: nowEpochMillis(),
        ),
      );
    });
  }

  Future<DailyNutritionData> _entityNow(int epochDay) async {
    final currentDayList = await personalizationDao.nutritionRangeNow(epochDay, epochDay);
    final current = currentDayList.firstOrNull;
    if (current != null) return current;

    return DailyNutritionData(
      epochDay: epochDay,
      updatedAtEpochMillis: nowEpochMillis(),
      consumedCalories: 0,
      consumedProteinGrams: 0,
      consumedCarbsGrams: 0,
      consumedFatGrams: 0,
      consumedFiberGrams: 0,
      waterIntakeMl: 0,
    );
  }

  NutritionDay _entityToDomain(DailyNutritionData? entity, int epochDay) {
    if (entity == null) {
      return NutritionDay(
        epochDay: epochDay,
        consumed: const Nutrients(),
        target: null,
      );
    }

    final target = entity.targetCalories != null &&
            entity.targetProteinGrams != null &&
            entity.targetCarbsGrams != null &&
            entity.targetFatGrams != null
        ? NutritionTarget(
            basalCalories: entity.targetBasalCalories ?? 0,
            maintenanceCalories: entity.targetMaintenanceCalories ?? 0,
            calories: entity.targetCalories!,
            proteinGrams: entity.targetProteinGrams!,
            carbsGrams: entity.targetCarbsGrams!,
            fatGrams: entity.targetFatGrams!,
            audit: NutritionTargetAudit(
              rawBasalCalories: (entity.targetBasalCalories ?? 0).toDouble(),
              rawMaintenanceCalories: (entity.targetMaintenanceCalories ?? 0).toDouble(),
              rawTargetCalories: entity.targetCalories!.toDouble(),
              rawProteinGrams: entity.targetProteinGrams!.toDouble(),
              rawCarbsGrams: entity.targetCarbsGrams!.toDouble(),
              rawFatGrams: entity.targetFatGrams!.toDouble(),
            ),
          )
        : null;

    return NutritionDay(
      epochDay: entity.epochDay,
      consumed: Nutrients(
        calories: entity.consumedCalories,
        proteinGrams: entity.consumedProteinGrams,
        carbsGrams: entity.consumedCarbsGrams,
        fatGrams: entity.consumedFatGrams,
        fiberGrams: entity.consumedFiberGrams,
      ),
      target: target,
      waterIntakeMl: entity.waterIntakeMl,
    );
  }

  FoodCatalogItem _catalogEntityToDomain(FoodCatalogData r) {
    return FoodCatalogItem(
      id: r.id,
      name: r.name,
      gramsPerServing: r.gramsPerServing,
      caloriesPerServing: r.caloriesPerServing,
      proteinPerServing: r.proteinPerServing,
      carbsPerServing: r.carbsPerServing,
      fatPerServing: r.fatPerServing,
      fiberPerServing: r.fiberPerServing,
      isFavorite: r.isFavorite,
      importBatchId: r.importBatchId,
    );
  }
}

void _validatePhotoLog(
  PhotoNutritionLog log, {
  required String normalizedName,
  required String normalizedSummary,
}) {
  if (normalizedName.isEmpty || normalizedName.length > 160) {
    throw ArgumentError.value(
      log.name,
      'log.name',
      'Photo nutrition name must contain 1..160 characters',
    );
  }
  if (normalizedSummary.isEmpty) {
    throw ArgumentError.value(
      log.calculationSummary,
      'log.calculationSummary',
      'Photo nutrition calculation summary must not be empty',
    );
  }
  if (log.imageType == FoodImageType.unknown) {
    throw ArgumentError.value(
      log.imageType,
      'log.imageType',
      'A saved photo estimate must have a recognized image type',
    );
  }

  _validatePhotoRange(
    log.estimate.calories,
    field: 'log.estimate.calories',
  );
  _validatePhotoRange(
    log.estimate.proteinGrams,
    field: 'log.estimate.proteinGrams',
  );
  _validatePhotoRange(
    log.estimate.carbsGrams,
    field: 'log.estimate.carbsGrams',
  );
  _validatePhotoRange(
    log.estimate.fatGrams,
    field: 'log.estimate.fatGrams',
  );
}

void _validatePhotoRange(
  NutritionRange range, {
  required String field,
}) {
  if (!range.min.isFinite ||
      !range.mid.isFinite ||
      !range.max.isFinite ||
      range.min < 0 ||
      range.min > range.mid ||
      range.mid > range.max) {
    throw ArgumentError.value(
      range,
      field,
      'Nutrition range must be finite, ordered, and non-negative',
    );
  }
}

/// Legacy daily totals are integer-based, so confirmed non-negative midpoint
/// values use Dart's nearest-integer rounding before both row and total writes.
int _roundPhotoNutritionValue(double value) => value.round();
