package com.example.myapplication.app

import android.content.Context
import androidx.room.Room
import com.example.myapplication.core.catalog.AssetCatalogRepository
import com.example.myapplication.data.RoomWorkoutRepository
import com.example.myapplication.data.DataStoreSettingsRepository
import com.example.myapplication.notification.AlarmReminderScheduler
import com.example.myapplication.data.local.GymDatabase

class AppContainer(context: Context) {
    private val applicationContext = context.applicationContext

    val database: GymDatabase = Room.databaseBuilder(
        applicationContext,
        GymDatabase::class.java,
        "gym.db",
    )
        .addMigrations(
            GymDatabase.MIGRATION_1_2,
            GymDatabase.MIGRATION_2_3,
            GymDatabase.MIGRATION_3_4,
            GymDatabase.MIGRATION_4_5,
            GymDatabase.MIGRATION_5_6,
            GymDatabase.MIGRATION_6_7,
            GymDatabase.MIGRATION_7_8,
        )
        .build()

    val catalogRepository = AssetCatalogRepository(applicationContext)
    val workoutRepository = RoomWorkoutRepository(database, catalogRepository.exercises)
    val workoutFeedbackRepository = com.example.myapplication.data.RoomWorkoutFeedbackRepository(database)
    val settingsRepository = DataStoreSettingsRepository(applicationContext)
    val reminderScheduler = AlarmReminderScheduler(applicationContext)
    val nutritionRepository = com.example.myapplication.data.RoomNutritionRepository(database.personalizationDao(), com.example.myapplication.data.DataStoreNutritionPreferences(applicationContext), { java.time.LocalDate.now().toEpochDay() })
    val adaptationRepository = com.example.myapplication.data.RoomAdaptationRepository(
        database = database,
        personalizationDao = database.personalizationDao(),
        nutritionRepository = nutritionRepository
    )
    private val weeklySnapshotProvider = com.example.myapplication.data.RoomWeeklySnapshotProvider(
        personalizationDao = database.personalizationDao(),
        workoutRepository = workoutRepository,
        feedbackRepository = workoutFeedbackRepository,
        nutritionRepository = nutritionRepository,
    )
    val weeklyAdaptationCoordinator = com.example.myapplication.data.WeeklyAdaptationCoordinator(
        snapshotProvider = weeklySnapshotProvider,
        adaptationRepository = adaptationRepository,
    )
    val coachExplanationClient = com.example.myapplication.data.OkHttpCoachExplanationClient()
    val coachReviewClient = com.example.myapplication.data.OkHttpCoachReviewClient()
    val foodAnalysisClient = com.example.myapplication.feature.nutrition.OkHttpFoodAnalysisClient()
    val motivationRepository = com.example.myapplication.core.motivation.MotivationRepository(applicationContext)
    val achievementChecker = com.example.myapplication.core.achievement.AchievementChecker(database.achievementDao())
}

