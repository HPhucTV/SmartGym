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
