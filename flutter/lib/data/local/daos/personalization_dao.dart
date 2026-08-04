import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/personal_profiles.dart';
import '../tables/weight_measurements.dart';
import '../tables/daily_nutrition.dart';
import '../tables/meal_templates.dart';
import '../tables/weekly_check_ins.dart';
import '../tables/adaptation_decisions.dart';
import '../tables/user_food_overrides.dart';
import '../tables/barcode_overrides.dart';
import '../../../core/model/adaptation_models.dart';

part 'personalization_dao.g.dart';

@DriftAccessor(tables: [
  PersonalProfiles,
  WeightMeasurements,
  DailyNutritions,
  MealTemplates,
  WeeklyCheckIns,
  AdaptationDecisions,
  UserFoodOverrides,
  BarcodeOverrides,
])
class PersonalizationDao extends DatabaseAccessor<GymDatabase>
    with _$PersonalizationDaoMixin {
  PersonalizationDao(super.db);

  Future<void> upsertProfile(PersonalProfileData profile) {
    return into(personalProfiles).insertOnConflictUpdate(profile);
  }

  Stream<PersonalProfileData?> observeProfile() {
    final query = select(personalProfiles)
      ..where((tbl) => tbl.id.equals(1))
      ..limit(1);
    return query.watchSingleOrNull();
  }

  Future<PersonalProfileData?> profileNow() {
    final query = select(personalProfiles)
      ..where((tbl) => tbl.id.equals(1))
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<void> upsertWeight(WeightMeasurement measurement) {
    return into(weightMeasurements).insertOnConflictUpdate(measurement);
  }

  Future<WeightMeasurement?> latestWeightNow() {
    final query = select(weightMeasurements)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.epochDay)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Stream<List<WeightMeasurement>> observeWeightHistory() {
    final query = select(weightMeasurements)
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.epochDay)]);
    return query.watch();
  }

  Future<List<WeightMeasurement>> weightHistoryNow() {
    final query = select(weightMeasurements)
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.epochDay)]);
    return query.get();
  }

  Future<void> upsertDailyNutrition(DailyNutritionData day) {
    return into(dailyNutritions).insertOnConflictUpdate(day);
  }

  Stream<DailyNutritionData?> observeNutritionDay(int epochDay) {
    final query = select(dailyNutritions)
      ..where((tbl) => tbl.epochDay.equals(epochDay))
      ..limit(1);
    return query.watchSingleOrNull();
  }

  Stream<List<DailyNutritionData>> observeNutritionRange(
      int startEpochDay, int endEpochDay) {
    final query = select(dailyNutritions)
      ..where((tbl) => tbl.epochDay.isBetweenValues(startEpochDay, endEpochDay))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.epochDay)]);
    return query.watch();
  }

  Future<List<DailyNutritionData>> nutritionRangeNow(
      int startEpochDay, int endEpochDay) {
    final query = select(dailyNutritions)
      ..where((tbl) => tbl.epochDay.isBetweenValues(startEpochDay, endEpochDay))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.epochDay)]);
    return query.get();
  }

  Stream<List<DailyNutritionData>> observeAllNutrition() {
    final query = select(dailyNutritions)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.epochDay)]);
    return query.watch();
  }

  Stream<List<MealTemplateData>> observeMealTemplates() {
    // Sắp xếp theo nameVi không phân biệt hoa thường (collate NOCASE), Drift tự hiểu qua cột được định nghĩa
    final query = select(mealTemplates)
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.nameVi),
        (tbl) => OrderingTerm.asc(tbl.id)
      ]);
    return query.watch();
  }

  Future<MealTemplateData?> mealTemplateNow(int id) {
    final query = select(mealTemplates)
      ..where((tbl) => tbl.id.equals(id))
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<MealTemplateData?> mealTemplateByNameNow(String nameVi) {
    // Ở SQLite, COLLATE NOCASE sẽ tự động không phân biệt hoa thường khi so sánh.
    final query = select(mealTemplates)
      ..where((tbl) => tbl.nameVi.equals(nameVi))
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<int> insertMealTemplate(MealTemplatesCompanion template) {
    return into(mealTemplates).insert(template);
  }

  Future<bool> updateMealTemplate(MealTemplateData template) {
    return update(mealTemplates).replace(template);
  }

  Future<int> deleteMealTemplate(int id) {
    final query = delete(mealTemplates)..where((tbl) => tbl.id.equals(id));
    return query.go();
  }

  Future<void> applyMealTemplateToDay({
    required int id,
    required int epochDay,
    required String source,
    required int updatedAtEpochMillis,
  }) async {
    await transaction(() async {
      final template = await mealTemplateNow(id);
      if (template == null) {
        throw ArgumentError('Unknown meal template $id');
      }
      final currentList = await nutritionRangeNow(epochDay, epochDay);
      final current = currentList.firstOrNull ??
          DailyNutritionData(
            epochDay: epochDay,
            consumedCalories: 0,
            consumedProteinGrams: 0,
            consumedCarbsGrams: 0,
            consumedFatGrams: 0,
            consumedFiberGrams: 0,
            waterIntakeMl: 0,
            updatedAtEpochMillis: updatedAtEpochMillis,
          );

      await upsertDailyNutrition(
        current.copyWith(
          consumedCalories: current.consumedCalories + template.calories,
          consumedProteinGrams:
              current.consumedProteinGrams + template.proteinGrams,
          consumedCarbsGrams: current.consumedCarbsGrams + template.carbsGrams,
          consumedFatGrams: current.consumedFatGrams + template.fatGrams,
          consumedFiberGrams: current.consumedFiberGrams + template.fiberGrams,
          lastEntrySource: Value(source),
          updatedAtEpochMillis: updatedAtEpochMillis,
        ),
      );
    });
  }

  Future<void> upsertWeeklyCheckIn(WeeklyCheckInData checkIn) {
    return into(weeklyCheckIns).insertOnConflictUpdate(checkIn);
  }

  Stream<WeeklyCheckInData?> observeLatestCheckIn() {
    final query = select(weeklyCheckIns)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.weekStartEpochDay)])
      ..limit(1);
    return query.watchSingleOrNull();
  }

  Stream<List<WeeklyCheckInData>> observeAllCheckIns() {
    final query = select(weeklyCheckIns)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.weekStartEpochDay)]);
    return query.watch();
  }

  Future<WeeklyCheckInData?> latestCheckInNow() {
    final query = select(weeklyCheckIns)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.weekStartEpochDay)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<int> insertDecision(AdaptationDecisionsCompanion decision) {
    return into(adaptationDecisions).insert(decision);
  }

  Future<int> updateDecisionStatus(
      int id, AdaptationStatus status, int resolvedAt) {
    final query = update(adaptationDecisions)
      ..where((tbl) => tbl.id.equals(id));
    return query.write(AdaptationDecisionsCompanion(
      status: Value(status),
      resolvedAtEpochMillis: Value(resolvedAt),
    ));
  }

  Future<int> updateDecisionPayloads(
      int id, String afterJson, String undoJson) {
    final query = update(adaptationDecisions)
      ..where((tbl) => tbl.id.equals(id));
    return query.write(AdaptationDecisionsCompanion(
      afterJson: Value(afterJson),
      undoJson: Value(undoJson),
    ));
  }

  Future<AdaptationDecisionData?> decisionByIdNow(int id) {
    final query = select(adaptationDecisions)
      ..where((tbl) => tbl.id.equals(id))
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<AdaptationDecisionData?> latestDecisionByKindAndStatus(
      AdaptationKind kind, AdaptationStatus status) {
    final query = select(adaptationDecisions)
      ..where(
          (tbl) => tbl.kind.equalsValue(kind) & tbl.status.equalsValue(status))
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.createdAtEpochMillis),
        (tbl) => OrderingTerm.desc(tbl.id)
      ])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Stream<List<AdaptationDecisionData>> observeDecisionHistory() {
    final query = select(adaptationDecisions)
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.createdAtEpochMillis),
        (tbl) => OrderingTerm.desc(tbl.id)
      ]);
    return query.watch();
  }

  Future<List<AdaptationDecisionData>> decisionHistoryNow() {
    final query = select(adaptationDecisions)
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.createdAtEpochMillis),
        (tbl) => OrderingTerm.desc(tbl.id)
      ]);
    return query.get();
  }

  Future<void> upsertFoodOverride(UserFoodOverrideData override) {
    return into(userFoodOverrides).insertOnConflictUpdate(override);
  }

  Future<UserFoodOverrideData?> foodOverrideNow(String dishName) {
    // COLLATE NOCASE tự động so sánh không phân biệt hoa thường trong SQLite
    final query = select(userFoodOverrides)
      ..where((tbl) => tbl.dishName.equals(dishName))
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<void> upsertBarcodeOverride(BarcodeOverridesCompanion override) {
    return into(barcodeOverrides).insertOnConflictUpdate(override);
  }

  Future<BarcodeOverrideData?> barcodeOverrideNow(String barcode) {
    final query = select(barcodeOverrides)
      ..where((table) => table.barcode.equals(barcode))
      ..limit(1);
    return query.getSingleOrNull();
  }
}
