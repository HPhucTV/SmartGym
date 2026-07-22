import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/local/database.dart';

void main() {
  late Directory tempDirectory;
  late File databaseFile;
  GymDatabase? database;

  setUp(() async {
    tempDirectory =
        await Directory.systemTemp.createTemp('gym-database-v2-migration-');
    databaseFile =
        File('${tempDirectory.path}${Platform.pathSeparator}v2.sqlite');
  });

  Future<void> seedFixture(int userVersion) async {
    GymDatabase? fixture;
    try {
      fixture = GymDatabase(NativeDatabase(databaseFile, logStatements: false));
      await fixture.customStatement('DROP TABLE logged_foods');
      await fixture.customStatement('''
        CREATE TABLE logged_foods (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          epoch_day INTEGER NOT NULL,
          name TEXT NOT NULL,
          meal_time TEXT NOT NULL,
          grams REAL NOT NULL,
          calories INTEGER NOT NULL,
          protein_grams INTEGER NOT NULL,
          carbs_grams INTEGER NOT NULL,
          fat_grams INTEGER NOT NULL,
          fiber_grams INTEGER NOT NULL DEFAULT 0,
          food_catalog_id INTEGER NULL,
          timestamp INTEGER NOT NULL
        )
      ''');
      if (userVersion >= 2) {
        await fixture.customStatement(
          'CREATE INDEX idx_logged_foods_day_time '
          'ON logged_foods (epoch_day, timestamp)',
        );
      }
      await fixture.customStatement(
        '''
        INSERT INTO logged_foods (
          epoch_day, name, meal_time, grams, calories,
          protein_grams, carbs_grams, fat_grams, fiber_grams, timestamp
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [20653, 'Bữa cũ', 'LUNCH', 200.0, 500, 30, 50, 20, 5, 123456789],
      );
      await fixture.customStatement('PRAGMA user_version = $userVersion');
    } finally {
      await fixture?.close();
    }
  }

  for (final userVersion in [1, 2]) {
    test(
        'v$userVersion migration preserves manual rows and defaults photo metadata',
        () async {
      await seedFixture(userVersion);
      database =
          GymDatabase(NativeDatabase(databaseFile, logStatements: false));

      expect(database!.schemaVersion, 3);
      final row = (await database!.select(database!.loggedFoods).get()).single;

      expect(row.name, 'Bữa cũ');
      expect(row.calories, 500);
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
  }

  tearDown(() async {
    await database?.close();
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });
}
