import 'package:drift/drift.dart';

@DataClassName('LoggedFoodData')
@TableIndex(name: 'idx_logged_foods_day_time', columns: {#epochDay, #timestamp})
class LoggedFoods extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get epochDay => integer()();
  TextColumn get name => text()();
  TextColumn get mealTime => text()(); // BREAKFAST, LUNCH, DINNER, SNACK
  RealColumn get grams => real()();
  IntColumn get calories => integer()();
  IntColumn get proteinGrams => integer()();
  IntColumn get carbsGrams => integer()();
  IntColumn get fatGrams => integer()();
  IntColumn get fiberGrams => integer().withDefault(const Constant(0))();
  IntColumn get foodCatalogId => integer().nullable()();
  IntColumn get timestamp => integer()();
  TextColumn get source => text().withDefault(const Constant('MANUAL'))();
  IntColumn get calorieMin => integer().nullable()();
  IntColumn get calorieMax => integer().nullable()();
  RealColumn get proteinMinGrams => real().nullable()();
  RealColumn get proteinMaxGrams => real().nullable()();
  RealColumn get carbsMinGrams => real().nullable()();
  RealColumn get carbsMaxGrams => real().nullable()();
  RealColumn get fatMinGrams => real().nullable()();
  RealColumn get fatMaxGrams => real().nullable()();
  TextColumn get analysisConfidence => text().nullable()();
  TextColumn get analysisImageType => text().nullable()();
  TextColumn get calculationSummary => text().nullable()();
}
