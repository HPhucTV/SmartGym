import 'package:drift/drift.dart';

@DataClassName('BarcodeOverrideData')
class BarcodeOverrides extends Table {
  TextColumn get barcode => text().withLength(min: 8, max: 14)();
  TextColumn get dishName => text().withLength(min: 1, max: 150)();
  IntColumn get totalCalories => integer()();
  IntColumn get proteinGrams => integer()();
  IntColumn get carbsGrams => integer()();
  IntColumn get fatGrams => integer()();
  TextColumn get advice => text().withDefault(const Constant(''))();
  IntColumn get updatedAtEpochMillis => integer()();

  @override
  Set<Column> get primaryKey => {barcode};
}
