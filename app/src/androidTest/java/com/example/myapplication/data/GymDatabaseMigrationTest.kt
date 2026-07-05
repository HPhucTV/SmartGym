package com.example.myapplication.data

import android.database.Cursor
import androidx.room.testing.MigrationTestHelper
import androidx.sqlite.db.SupportSQLiteDatabase
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.example.myapplication.data.local.GymDatabase
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class GymDatabaseMigrationTest {
    @get:Rule
    val helper = MigrationTestHelper(
        InstrumentationRegistry.getInstrumentation(),
        GymDatabase::class.java,
    )

    @Test
    fun migration_1_2_preserves_workouts_and_creates_personalization_tables() {
        helper.createDatabase(TEST_DATABASE, 1).apply {
            execSQL(
                """
                INSERT INTO goals (
                    id, programId, goal, level, equipmentProfile, sessionsPerWeek,
                    durationWeeks, restDayMode, createdEpochDay, archived
                ) VALUES (1, 'general', 'GENERAL_FITNESS', 'BEGINNER', 'BODYWEIGHT_ONLY', 3, 4, 'FULL_REST', 20600, 0)
                """.trimIndent(),
            )
            close()
        }

        helper.runMigrationsAndValidate(
            TEST_DATABASE,
            2,
            true,
            GymDatabase.MIGRATION_1_2,
        ).use { migrated ->
            assertEquals(1, migrated.singleInt("SELECT COUNT(*) FROM goals"))
            val tables = migrated.stringSet(
                "SELECT name FROM sqlite_master WHERE type = 'table'",
            )
            assertTrue(
                tables.containsAll(
                    setOf(
                        "personal_profiles",
                        "weight_measurements",
                        "daily_nutrition",
                        "weekly_check_ins",
                        "adaptation_decisions",
                    ),
                ),
            )
        }
    }

    @Test
    fun migration_2_3_adds_deterministic_legacy_schedule_without_losing_goal() {
        helper.createDatabase(TEST_DATABASE, 2).apply {
            execSQL(
                """
                INSERT INTO goals (
                    id, programId, goal, level, equipmentProfile, sessionsPerWeek,
                    durationWeeks, restDayMode, createdEpochDay, archived
                ) VALUES (1, 'general', 'GENERAL_FITNESS', 'BEGINNER', 'BODYWEIGHT_ONLY', 3, 4, 'FULL_REST', 20600, 0)
                """.trimIndent(),
            )
            close()
        }

        helper.runMigrationsAndValidate(
            TEST_DATABASE,
            3,
            true,
            GymDatabase.MIGRATION_2_3,
        ).use { migrated ->
            assertEquals(1, migrated.singleInt("SELECT COUNT(*) FROM goals"))
            assertEquals(21, migrated.singleInt("SELECT trainingDaysMask FROM goals WHERE id = 1"))
            assertEquals(45, migrated.singleInt("SELECT sessionDurationMinutes FROM goals WHERE id = 1"))
        }
    }

    @Test
    fun migration_4_5_preserves_workouts_and_creates_empty_feedback_table() {
        helper.createDatabase(TEST_DATABASE, 4).apply {
            execSQL(
                """
                INSERT INTO goals (
                    id, programId, goal, level, equipmentProfile, sessionsPerWeek,
                    durationWeeks, restDayMode, trainingDaysMask, sessionDurationMinutes,
                    createdEpochDay, archived
                ) VALUES (1, 'general', 'GENERAL_FITNESS', 'BEGINNER', 'BODYWEIGHT_ONLY', 3, 4, 'FULL_REST', 21, 45, 20600, 0)
                """.trimIndent(),
            )
            execSQL(
                """
                INSERT INTO workout_sessions (
                    id, goalId, sequenceIndex, titleVi, focusVi, estimatedMinutes,
                    dueEpochDay, completedEpochDay
                ) VALUES (10, 1, 0, 'Buổi 1', 'Toàn thân', 45, 20640, 20640)
                """.trimIndent(),
            )
            close()
        }

        helper.runMigrationsAndValidate(
            TEST_DATABASE,
            5,
            true,
            GymDatabase.MIGRATION_4_5,
        ).use { migrated ->
            assertEquals(1, migrated.singleInt("SELECT COUNT(*) FROM goals"))
            assertEquals(1, migrated.singleInt("SELECT COUNT(*) FROM workout_sessions"))
            assertEquals(0, migrated.singleInt("SELECT COUNT(*) FROM workout_feedback"))
        }
    }

    @Test
    fun migration_5_6_preserves_session_and_defaults_full_volume() {
        helper.createDatabase(TEST_DATABASE, 5).apply {
            execSQL(
                """
                INSERT INTO goals (
                    id, programId, goal, level, equipmentProfile, sessionsPerWeek,
                    durationWeeks, restDayMode, trainingDaysMask, sessionDurationMinutes,
                    createdEpochDay, archived
                ) VALUES (1, 'general', 'GENERAL_FITNESS', 'BEGINNER', 'BODYWEIGHT_ONLY', 3, 4, 'FULL_REST', 21, 45, 20600, 0)
                """.trimIndent(),
            )
            execSQL(
                """
                INSERT INTO workout_sessions (
                    id, goalId, sequenceIndex, titleVi, focusVi, estimatedMinutes,
                    dueEpochDay, completedEpochDay
                ) VALUES (10, 1, 0, 'Buổi 1', 'Toàn thân', 45, 20640, NULL)
                """.trimIndent(),
            )
            close()
        }

        helper.runMigrationsAndValidate(
            TEST_DATABASE,
            6,
            true,
            GymDatabase.MIGRATION_5_6,
        ).use { migrated ->
            assertEquals(1, migrated.singleInt("SELECT COUNT(*) FROM workout_sessions"))
            assertEquals(100, migrated.singleInt("SELECT volumeScalePercent FROM workout_sessions WHERE id = 10"))
        }
    }

    @Test
    fun migration_6_7_preserves_exercise_and_defaults_original_id_to_null() {
        helper.createDatabase(TEST_DATABASE, 6).apply {
            execSQL(
                """
                INSERT INTO goals (
                    id, programId, goal, level, equipmentProfile, sessionsPerWeek,
                    durationWeeks, restDayMode, trainingDaysMask, sessionDurationMinutes,
                    createdEpochDay, archived
                ) VALUES (1, 'general', 'GENERAL_FITNESS', 'BEGINNER', 'BODYWEIGHT_ONLY', 3, 4, 'FULL_REST', 21, 45, 20600, 0)
                """.trimIndent(),
            )
            execSQL(
                """
                INSERT INTO workout_sessions (
                    id, goalId, sequenceIndex, titleVi, focusVi, estimatedMinutes,
                    dueEpochDay, completedEpochDay, volumeScalePercent
                ) VALUES (10, 1, 0, 'Buổi 1', 'Toàn thân', 45, 20640, NULL, 100)
                """.trimIndent(),
            )
            execSQL(
                """
                INSERT INTO session_exercises (
                    sessionId, orderIndex, exerciseId, sets, repsMin, repsMax,
                    durationSeconds, restSeconds, checked
                ) VALUES (10, 0, 'squat', 3, 8, 12, NULL, 60, 0)
                """.trimIndent(),
            )
            close()
        }

        helper.runMigrationsAndValidate(
            TEST_DATABASE,
            7,
            true,
            GymDatabase.MIGRATION_6_7,
        ).use { migrated ->
            migrated.query(
                "SELECT exerciseId, originalExerciseId FROM session_exercises WHERE sessionId = 10",
            ).use { cursor ->
                assertTrue(cursor.moveToFirst())
                assertEquals("squat", cursor.getString(0))
                assertTrue(cursor.isNull(1))
            }
        }
    }

    @Test
    fun migration_7_8_preservesWorkoutAndDefaultsToFullVariant() {
        helper.createDatabase(TEST_DATABASE, 7).apply {
            execSQL(
                """
                INSERT INTO goals (
                    id, programId, goal, level, equipmentProfile, sessionsPerWeek,
                    durationWeeks, restDayMode, trainingDaysMask, sessionDurationMinutes,
                    createdEpochDay, archived
                ) VALUES (1, 'general', 'GENERAL_FITNESS', 'BEGINNER', 'BODYWEIGHT_ONLY', 3, 4, 'FULL_REST', 21, 45, 20600, 0)
                """.trimIndent(),
            )
            execSQL(
                """
                INSERT INTO workout_sessions (
                    id, goalId, sequenceIndex, titleVi, focusVi, estimatedMinutes,
                    dueEpochDay, completedEpochDay, volumeScalePercent
                ) VALUES (10, 1, 0, 'Buổi 1', 'Toàn thân', 45, 20640, NULL, 100)
                """.trimIndent(),
            )
            execSQL(
                """
                INSERT INTO session_exercises (
                    sessionId, orderIndex, exerciseId, originalExerciseId, sets,
                    repsMin, repsMax, durationSeconds, restSeconds, checked
                ) VALUES (10, 0, 'squat', NULL, 3, 8, 12, NULL, 60, 0)
                """.trimIndent(),
            )
            close()
        }

        helper.runMigrationsAndValidate(
            TEST_DATABASE,
            8,
            true,
            GymDatabase.MIGRATION_7_8,
        ).use { migrated ->
            assertEquals(
                0,
                migrated.singleInt("SELECT omittedByTimeBudget FROM session_exercises WHERE sessionId = 10"),
            )
            migrated.query("SELECT selectedTimeBudgetMinutes FROM workout_sessions WHERE id = 10").use {
                assertTrue(it.moveToFirst())
                assertTrue(it.isNull(0))
            }
        }
    }

    @Test
    fun migration_8_9_preservesNutritionAndCreatesEmptyMealTemplates() {
        helper.createDatabase(TEST_DATABASE, 8).apply {
            execSQL(
                """
                INSERT INTO daily_nutrition (
                    epochDay, consumedCalories, consumedProteinGrams, consumedCarbsGrams,
                    consumedFatGrams, updatedAtEpochMillis
                ) VALUES (20640, 500, 30, 60, 15, 1000)
                """.trimIndent(),
            )
            close()
        }

        helper.runMigrationsAndValidate(
            TEST_DATABASE,
            9,
            true,
            GymDatabase.MIGRATION_8_9,
        ).use { migrated ->
            assertEquals(500, migrated.singleInt("SELECT consumedCalories FROM daily_nutrition WHERE epochDay = 20640"))
            assertEquals(0, migrated.singleInt("SELECT COUNT(*) FROM meal_templates"))
        }
    }

    @Test
    fun migration_9_10_preservesTemplatesAndCreatesEmptyOverrides() {
        helper.createDatabase(TEST_DATABASE, 9).apply {
            execSQL(
                """
                INSERT INTO meal_templates (
                    id, nameVi, calories, proteinGrams, carbsGrams, fatGrams, updatedAtEpochMillis
                ) VALUES (7, 'Bữa quen', 400, 25, 45, 10, 1)
                """.trimIndent(),
            )
            close()
        }

        helper.runMigrationsAndValidate(
            TEST_DATABASE,
            10,
            true,
            GymDatabase.MIGRATION_9_10,
        ).use { migrated ->
            assertEquals(1, migrated.singleInt("SELECT COUNT(*) FROM meal_templates"))
            assertEquals(400, migrated.singleInt("SELECT calories FROM meal_templates WHERE id = 7"))
            assertEquals(0, migrated.singleInt("SELECT COUNT(*) FROM user_food_overrides"))
        }
    }

    private fun SupportSQLiteDatabase.singleInt(sql: String): Int = query(sql).use { cursor ->
        check(cursor.moveToFirst())
        cursor.getInt(0)
    }

    private fun SupportSQLiteDatabase.stringSet(sql: String): Set<String> = query(sql).use { cursor ->
        cursor.toStringSet()
    }

    private fun Cursor.toStringSet(): Set<String> = buildSet {
        while (moveToNext()) add(getString(0))
    }

    private companion object {
        const val TEST_DATABASE = "personalization-migration-test"
    }
}
