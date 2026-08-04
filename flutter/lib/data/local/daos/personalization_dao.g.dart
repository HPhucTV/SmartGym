// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personalization_dao.dart';

// ignore_for_file: type=lint
mixin _$PersonalizationDaoMixin on DatabaseAccessor<GymDatabase> {
  $PersonalProfilesTable get personalProfiles =>
      attachedDatabase.personalProfiles;
  $WeightMeasurementsTable get weightMeasurements =>
      attachedDatabase.weightMeasurements;
  $DailyNutritionsTable get dailyNutritions => attachedDatabase.dailyNutritions;
  $MealTemplatesTable get mealTemplates => attachedDatabase.mealTemplates;
  $WeeklyCheckInsTable get weeklyCheckIns => attachedDatabase.weeklyCheckIns;
  $AdaptationDecisionsTable get adaptationDecisions =>
      attachedDatabase.adaptationDecisions;
  $UserFoodOverridesTable get userFoodOverrides =>
      attachedDatabase.userFoodOverrides;
  $BarcodeOverridesTable get barcodeOverrides =>
      attachedDatabase.barcodeOverrides;
  PersonalizationDaoManager get managers => PersonalizationDaoManager(this);
}

class PersonalizationDaoManager {
  final _$PersonalizationDaoMixin _db;
  PersonalizationDaoManager(this._db);
  $$PersonalProfilesTableTableManager get personalProfiles =>
      $$PersonalProfilesTableTableManager(
        _db.attachedDatabase,
        _db.personalProfiles,
      );
  $$WeightMeasurementsTableTableManager get weightMeasurements =>
      $$WeightMeasurementsTableTableManager(
        _db.attachedDatabase,
        _db.weightMeasurements,
      );
  $$DailyNutritionsTableTableManager get dailyNutritions =>
      $$DailyNutritionsTableTableManager(
        _db.attachedDatabase,
        _db.dailyNutritions,
      );
  $$MealTemplatesTableTableManager get mealTemplates =>
      $$MealTemplatesTableTableManager(_db.attachedDatabase, _db.mealTemplates);
  $$WeeklyCheckInsTableTableManager get weeklyCheckIns =>
      $$WeeklyCheckInsTableTableManager(
        _db.attachedDatabase,
        _db.weeklyCheckIns,
      );
  $$AdaptationDecisionsTableTableManager get adaptationDecisions =>
      $$AdaptationDecisionsTableTableManager(
        _db.attachedDatabase,
        _db.adaptationDecisions,
      );
  $$UserFoodOverridesTableTableManager get userFoodOverrides =>
      $$UserFoodOverridesTableTableManager(
        _db.attachedDatabase,
        _db.userFoodOverrides,
      );
  $$BarcodeOverridesTableTableManager get barcodeOverrides =>
      $$BarcodeOverridesTableTableManager(
        _db.attachedDatabase,
        _db.barcodeOverrides,
      );
}
