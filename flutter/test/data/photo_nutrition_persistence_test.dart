import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/model/food_photo_analysis_models.dart';
import 'package:gym_app/data/local/database.dart';
import 'package:gym_app/data/repositories/drift_nutrition_repository.dart';
import 'package:gym_app/data/repositories/nutrition_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const epochDay = 20654;
  const nowEpochMillis = 1770000000000;

  late GymDatabase database;
  late DriftNutritionRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = GymDatabase(NativeDatabase.memory());
    repository = DriftNutritionRepository(
      database: database,
      prefs: await SharedPreferences.getInstance(),
      todayEpochDay: () => epochDay,
      nowEpochMillis: () => nowEpochMillis,
    );
  });

  tearDown(() async {
    await database.close();
  });

  PhotoNutritionLog photoLog({
    String name = 'Cơm với ức gà',
    String summary = '1 bát cơm vừa + 1 phần ức gà vừa.',
    NutritionEstimate? estimate,
  }) {
    return PhotoNutritionLog(
      name: name,
      mealTime: 'LUNCH',
      imageType: FoodImageType.meal,
      estimate: estimate ??
          NutritionEstimate(
            calories: NutritionRange(min: 430.4, mid: 505.6, max: 580.4),
            proteinGrams: NutritionRange(min: 34.1, mid: 39.6, max: 44.9),
            carbsGrams: NutritionRange(min: 48.2, mid: 55.4, max: 62.8),
            fatGrams: NutritionRange(min: 8.1, mid: 11.5, max: 16.2),
          ),
      confidenceLevel: AnalysisConfidenceLevel.medium,
      calculationSummary: summary,
    );
  }

  test('photo log atomically stores ranges and adds rounded midpoints',
      () async {
    expect(await repository.loggedFoodsNow(epochDay), isEmpty);

    await repository.logPhotoEstimate(
      epochDay: epochDay,
      log: photoLog(),
    );

    final rows = await repository.loggedFoodsNow(epochDay);
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.name, 'Cơm với ức gà');
    expect(row.mealTime, 'LUNCH');
    expect(row.grams, 0);
    expect(row.calories, 506);
    expect(row.proteinGrams, 40);
    expect(row.carbsGrams, 55);
    expect(row.fatGrams, 12);
    expect(row.fiberGrams, 0);
    expect(row.foodCatalogId, isNull);
    expect(row.timestamp, nowEpochMillis);
    expect(row.source, 'CAMERA_ANALYSIS');
    expect(row.calorieMin, 430);
    expect(row.calorieMax, 580);
    expect(row.proteinMinGrams, 34.1);
    expect(row.proteinMaxGrams, 44.9);
    expect(row.carbsMinGrams, 48.2);
    expect(row.carbsMaxGrams, 62.8);
    expect(row.fatMinGrams, 8.1);
    expect(row.fatMaxGrams, 16.2);
    expect(row.analysisConfidence, 'MEDIUM');
    expect(row.analysisImageType, 'MEAL');
    expect(row.calculationSummary, '1 bát cơm vừa + 1 phần ức gà vừa.');

    final day = (await database.personalizationDao
            .nutritionRangeNow(epochDay, epochDay))
        .single;
    expect(day.consumedCalories, 506);
    expect(day.consumedProteinGrams, 40);
    expect(day.consumedCarbsGrams, 55);
    expect(day.consumedFatGrams, 12);
    expect(day.consumedFiberGrams, 0);
    expect(day.lastEntrySource, 'CAMERA_ANALYSIS');

    await repository.deleteLoggedFood(row.id);

    expect(await repository.loggedFoodsNow(epochDay), isEmpty);
    final afterDelete = (await database.personalizationDao
            .nutritionRangeNow(epochDay, epochDay))
        .single;
    expect(afterDelete.consumedCalories, 0);
    expect(afterDelete.consumedProteinGrams, 0);
    expect(afterDelete.consumedCarbsGrams, 0);
    expect(afterDelete.consumedFatGrams, 0);
  });

  test('daily nutrition failure rolls back the photo row', () async {
    await database.customStatement('''
      CREATE TRIGGER fail_photo_daily_nutrition
      BEFORE INSERT ON daily_nutritions
      BEGIN
        SELECT RAISE(ABORT, 'forced daily nutrition failure');
      END;
    ''');

    await expectLater(
      repository.logPhotoEstimate(epochDay: epochDay, log: photoLog()),
      throwsA(anything),
    );

    expect(await repository.loggedFoodsNow(epochDay), isEmpty);
    expect(
      await database.personalizationDao.nutritionRangeNow(epochDay, epochDay),
      isEmpty,
    );
  });

  test('accepts canonical upstream maximum estimate values', () async {
    final estimate = NutritionEstimate(
      calories: NutritionRange(min: 50000, mid: 50000, max: 50000),
      proteinGrams: NutritionRange(min: 5000, mid: 5000, max: 5000),
      carbsGrams: NutritionRange(min: 5000, mid: 5000, max: 5000),
      fatGrams: NutritionRange(min: 5000, mid: 5000, max: 5000),
    );

    await repository.logPhotoEstimate(
      epochDay: epochDay,
      log: photoLog(estimate: estimate),
    );

    final row = (await repository.loggedFoodsNow(epochDay)).single;
    expect(row.calories, 50000);
    expect(row.proteinGrams, 5000);
    expect(row.carbsGrams, 5000);
    expect(row.fatGrams, 5000);
    expect(row.calorieMin, 50000);
    expect(row.calorieMax, 50000);
    expect(row.proteinMinGrams, 5000);
    expect(row.proteinMaxGrams, 5000);
  });

  test('manual logging retains MANUAL source and null analysis metadata',
      () async {
    await repository.logFood(
      epochDay: epochDay,
      name: 'Bữa nhập tay',
      mealTime: 'DINNER',
      grams: 120,
      calories: 321,
      proteinGrams: 20,
      carbsGrams: 30,
      fatGrams: 9,
      fiberGrams: 4,
    );

    final row = (await repository.loggedFoodsNow(epochDay)).single;
    expect(row.source, 'MANUAL');
    expect(row.calorieMin, isNull);
    expect(row.calorieMax, isNull);
    expect(row.proteinMinGrams, isNull);
    expect(row.proteinMaxGrams, isNull);
    expect(row.carbsMinGrams, isNull);
    expect(row.carbsMaxGrams, isNull);
    expect(row.fatMinGrams, isNull);
    expect(row.fatMaxGrams, isNull);
    expect(row.analysisConfidence, isNull);
    expect(row.analysisImageType, isNull);
    expect(row.calculationSummary, isNull);
  });

  test('invalid photo input is rejected before any database write', () async {
    final invalidLogs = [
      photoLog(name: '   '),
      photoLog(summary: '   '),
    ];

    for (final log in invalidLogs) {
      await expectLater(
        repository.logPhotoEstimate(epochDay: epochDay, log: log),
        throwsArgumentError,
      );
    }

    expect(await repository.loggedFoodsNow(epochDay), isEmpty);
    expect(
      await database.personalizationDao.nutritionRangeNow(epochDay, epochDay),
      isEmpty,
    );
  });
}
