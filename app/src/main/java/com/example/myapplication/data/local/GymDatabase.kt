package com.example.myapplication.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverter
import androidx.room.TypeConverters
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import com.example.myapplication.core.adaptation.AdaptationKind
import com.example.myapplication.core.adaptation.AdaptationMode
import com.example.myapplication.core.adaptation.AdaptationStatus
import com.example.myapplication.core.feedback.WorkoutDifficulty
import com.example.myapplication.core.model.EquipmentProfile
import com.example.myapplication.core.model.ExperienceLevel
import com.example.myapplication.core.model.FitnessGoal
import com.example.myapplication.core.model.RestDayMode
import com.example.myapplication.core.profile.ActivityLevel
import com.example.myapplication.core.profile.GoalPace
import com.example.myapplication.core.profile.MetabolicSex

class WorkoutTypeConverters {
    @TypeConverter fun fitnessGoalToString(value: FitnessGoal): String = value.name
    @TypeConverter fun stringToFitnessGoal(value: String): FitnessGoal = FitnessGoal.valueOf(value)
    @TypeConverter fun experienceLevelToString(value: ExperienceLevel): String = value.name
    @TypeConverter fun stringToExperienceLevel(value: String): ExperienceLevel = ExperienceLevel.valueOf(value)
    @TypeConverter fun equipmentProfileToString(value: EquipmentProfile): String = value.name
    @TypeConverter fun stringToEquipmentProfile(value: String): EquipmentProfile = EquipmentProfile.valueOf(value)
    @TypeConverter fun restDayModeToString(value: RestDayMode): String = value.name
    @TypeConverter fun stringToRestDayMode(value: String): RestDayMode = RestDayMode.valueOf(value)
    @TypeConverter fun workoutDifficultyToString(value: WorkoutDifficulty): String = value.name
    @TypeConverter fun stringToWorkoutDifficulty(value: String): WorkoutDifficulty = WorkoutDifficulty.valueOf(value)
}

class PersonalizationTypeConverters {
    @TypeConverter fun metabolicSexToString(value: MetabolicSex): String = value.name
    @TypeConverter fun stringToMetabolicSex(value: String): MetabolicSex = MetabolicSex.valueOf(value)
    @TypeConverter fun activityLevelToString(value: ActivityLevel): String = value.name
    @TypeConverter fun stringToActivityLevel(value: String): ActivityLevel = ActivityLevel.valueOf(value)
    @TypeConverter fun goalPaceToString(value: GoalPace): String = value.name
    @TypeConverter fun stringToGoalPace(value: String): GoalPace = GoalPace.valueOf(value)
    @TypeConverter fun adaptationKindToString(value: AdaptationKind): String = value.name
    @TypeConverter fun stringToAdaptationKind(value: String): AdaptationKind = AdaptationKind.valueOf(value)
    @TypeConverter fun adaptationModeToString(value: AdaptationMode): String = value.name
    @TypeConverter fun stringToAdaptationMode(value: String): AdaptationMode = AdaptationMode.valueOf(value)
    @TypeConverter fun adaptationStatusToString(value: AdaptationStatus): String = value.name
    @TypeConverter fun stringToAdaptationStatus(value: String): AdaptationStatus = AdaptationStatus.valueOf(value)
}

@Database(
    entities = [
        GoalEntity::class,
        WorkoutSessionEntity::class,
        SessionExerciseEntity::class,
        PersonalProfileEntity::class,
        WeightMeasurementEntity::class,
        DailyNutritionEntity::class,
        WeeklyCheckInEntity::class,
        AdaptationDecisionEntity::class,
        AchievementEntity::class,
        WorkoutFeedbackEntity::class,
    ],
    version = 8,
    exportSchema = true,
)
@TypeConverters(WorkoutTypeConverters::class, PersonalizationTypeConverters::class)
abstract class GymDatabase : RoomDatabase() {
    abstract fun workoutDao(): WorkoutDao
    abstract fun personalizationDao(): PersonalizationDao
    abstract fun achievementDao(): AchievementDao
    abstract fun workoutFeedbackDao(): WorkoutFeedbackDao

    companion object {
        val MIGRATION_7_8: Migration = object : Migration(7, 8) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "ALTER TABLE `session_exercises` ADD COLUMN `omittedByTimeBudget` INTEGER NOT NULL DEFAULT 0",
                )
                db.execSQL(
                    "ALTER TABLE `workout_sessions` ADD COLUMN `selectedTimeBudgetMinutes` INTEGER",
                )
            }
        }

        val MIGRATION_6_7: Migration = object : Migration(6, 7) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "ALTER TABLE `session_exercises` ADD COLUMN `originalExerciseId` TEXT",
                )
            }
        }

        val MIGRATION_5_6: Migration = object : Migration(5, 6) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "ALTER TABLE `workout_sessions` ADD COLUMN `volumeScalePercent` INTEGER NOT NULL DEFAULT 100",
                )
            }
        }

        val MIGRATION_4_5: Migration = object : Migration(4, 5) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS `workout_feedback` (
                        `sessionId` INTEGER NOT NULL,
                        `goalId` INTEGER NOT NULL,
                        `completedEpochDay` INTEGER NOT NULL,
                        `difficulty` TEXT NOT NULL,
                        `recordedAtEpochMillis` INTEGER NOT NULL,
                        PRIMARY KEY(`sessionId`),
                        FOREIGN KEY(`sessionId`) REFERENCES `workout_sessions`(`id`)
                            ON UPDATE NO ACTION ON DELETE CASCADE
                    )
                    """.trimIndent(),
                )
                db.execSQL(
                    """
                    CREATE INDEX IF NOT EXISTS `index_workout_feedback_goalId_completedEpochDay`
                    ON `workout_feedback` (`goalId`, `completedEpochDay`)
                    """.trimIndent(),
                )
            }
        }

        val MIGRATION_3_4: Migration = object : Migration(3, 4) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS `achievements` (
                        `type` TEXT NOT NULL,
                        `unlockedAtEpochMillis` INTEGER NOT NULL,
                        PRIMARY KEY(`type`)
                    )
                    """.trimIndent(),
                )
            }
        }

        val MIGRATION_2_3: Migration = object : Migration(2, 3) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE `goals` ADD COLUMN `trainingDaysMask` INTEGER NOT NULL DEFAULT 1")
                db.execSQL("ALTER TABLE `goals` ADD COLUMN `sessionDurationMinutes` INTEGER NOT NULL DEFAULT 45")
                db.execSQL(
                    """
                    UPDATE `goals` SET `trainingDaysMask` = CASE `sessionsPerWeek`
                        WHEN 1 THEN 1
                        WHEN 2 THEN 9
                        WHEN 3 THEN 21
                        WHEN 4 THEN 27
                        WHEN 5 THEN 55
                        WHEN 6 THEN 63
                        ELSE 1
                    END
                    """.trimIndent(),
                )
            }
        }

        val MIGRATION_1_2: Migration = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS `personal_profiles` (
                        `id` INTEGER NOT NULL,
                        `birthDateEpochDay` INTEGER NOT NULL,
                        `metabolicSex` TEXT NOT NULL,
                        `heightCm` REAL NOT NULL,
                        `currentWeightKg` REAL NOT NULL,
                        `targetWeightKg` REAL NOT NULL,
                        `activityLevel` TEXT NOT NULL,
                        `goalPace` TEXT NOT NULL,
                        `personalizationConsent` INTEGER NOT NULL,
                        `cloudAiConsent` INTEGER NOT NULL,
                        `updatedAtEpochMillis` INTEGER NOT NULL,
                        PRIMARY KEY(`id`)
                    )
                    """.trimIndent(),
                )
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS `weight_measurements` (
                        `epochDay` INTEGER NOT NULL,
                        `weightKg` REAL NOT NULL,
                        `recordedAtEpochMillis` INTEGER NOT NULL,
                        PRIMARY KEY(`epochDay`)
                    )
                    """.trimIndent(),
                )
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS `daily_nutrition` (
                        `epochDay` INTEGER NOT NULL,
                        `consumedCalories` INTEGER NOT NULL,
                        `consumedProteinGrams` INTEGER NOT NULL,
                        `consumedCarbsGrams` INTEGER NOT NULL,
                        `consumedFatGrams` INTEGER NOT NULL,
                        `targetBasalCalories` INTEGER,
                        `targetMaintenanceCalories` INTEGER,
                        `targetCalories` INTEGER,
                        `targetProteinGrams` INTEGER,
                        `targetCarbsGrams` INTEGER,
                        `targetFatGrams` INTEGER,
                        `lastEntrySource` TEXT,
                        `updatedAtEpochMillis` INTEGER NOT NULL,
                        PRIMARY KEY(`epochDay`)
                    )
                    """.trimIndent(),
                )
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS `weekly_check_ins` (
                        `weekStartEpochDay` INTEGER NOT NULL,
                        `weightKg` REAL NOT NULL,
                        `energy` INTEGER NOT NULL,
                        `hunger` INTEGER NOT NULL,
                        `recovery` INTEGER NOT NULL,
                        `sleepQuality` INTEGER NOT NULL,
                        `note` TEXT,
                        `createdAtEpochMillis` INTEGER NOT NULL,
                        PRIMARY KEY(`weekStartEpochDay`)
                    )
                    """.trimIndent(),
                )
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS `adaptation_decisions` (
                        `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        `kind` TEXT NOT NULL,
                        `mode` TEXT NOT NULL,
                        `status` TEXT NOT NULL,
                        `reasonVi` TEXT NOT NULL,
                        `payloadVersion` INTEGER NOT NULL,
                        `inputsJson` TEXT NOT NULL,
                        `beforeJson` TEXT NOT NULL,
                        `afterJson` TEXT NOT NULL,
                        `undoJson` TEXT NOT NULL,
                        `createdAtEpochMillis` INTEGER NOT NULL,
                        `resolvedAtEpochMillis` INTEGER
                    )
                    """.trimIndent(),
                )
                db.execSQL(
                    "CREATE INDEX IF NOT EXISTS `index_adaptation_decisions_status_createdAtEpochMillis` ON `adaptation_decisions` (`status`, `createdAtEpochMillis`)",
                )
                db.execSQL(
                    "CREATE INDEX IF NOT EXISTS `index_adaptation_decisions_kind_createdAtEpochMillis` ON `adaptation_decisions` (`kind`, `createdAtEpochMillis`)",
                )
            }
        }
    }
}
