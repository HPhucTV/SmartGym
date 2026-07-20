import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/goals.dart';
import 'tables/workout_sessions.dart';
import 'tables/session_exercises.dart';
import 'tables/personal_profiles.dart';
import 'tables/weight_measurements.dart';
import 'tables/daily_nutrition.dart';
import 'tables/weekly_check_ins.dart';
import 'tables/adaptation_decisions.dart';
import 'tables/achievements.dart';
import 'tables/workout_feedback.dart';
import 'tables/meal_templates.dart';
import 'tables/user_food_overrides.dart';
import 'tables/food_catalog.dart';
import 'tables/logged_foods.dart';
import 'converters.dart';

import '../../core/model/profile_models.dart';
import '../../core/model/goal_models.dart';
import '../../core/model/adaptation_models.dart';
import '../../core/model/feedback_models.dart';

import 'daos/workout_dao.dart';
import 'daos/personalization_dao.dart';
import 'daos/achievement_dao.dart';
import 'daos/workout_feedback_dao.dart';
import 'daos/food_catalog_dao.dart';
import 'daos/logged_food_dao.dart';

part 'database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gym_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(
  tables: [
    Goals,
    WorkoutSessions,
    SessionExercises,
    PersonalProfiles,
    WeightMeasurements,
    DailyNutritions,
    WeeklyCheckIns,
    AdaptationDecisions,
    Achievements,
    WorkoutFeedbacks,
    MealTemplates,
    UserFoodOverrides,
    FoodCatalog,
    LoggedFoods,
  ],
  daos: [
    WorkoutDao,
    PersonalizationDao,
    AchievementDao,
    WorkoutFeedbackDao,
    FoodCatalogDao,
    LoggedFoodDao,
  ],
)
class GymDatabase extends _$GymDatabase {
  GymDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_logged_foods_day_time ON logged_foods (epoch_day, timestamp);');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_food_catalog_name ON food_catalog (name);');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_food_catalog_fav_name ON food_catalog (is_favorite, name);');
          }
          if (from < 3) {
            await m.addColumn(loggedFoods, loggedFoods.source);
            await m.addColumn(loggedFoods, loggedFoods.calorieMin);
            await m.addColumn(loggedFoods, loggedFoods.calorieMax);
            await m.addColumn(loggedFoods, loggedFoods.proteinMinGrams);
            await m.addColumn(loggedFoods, loggedFoods.proteinMaxGrams);
            await m.addColumn(loggedFoods, loggedFoods.carbsMinGrams);
            await m.addColumn(loggedFoods, loggedFoods.carbsMaxGrams);
            await m.addColumn(loggedFoods, loggedFoods.fatMinGrams);
            await m.addColumn(loggedFoods, loggedFoods.fatMaxGrams);
            await m.addColumn(loggedFoods, loggedFoods.analysisConfidence);
            await m.addColumn(loggedFoods, loggedFoods.analysisImageType);
            await m.addColumn(loggedFoods, loggedFoods.calculationSummary);
          }
        },
      );
}
