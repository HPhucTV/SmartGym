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
        .addMigrations(GymDatabase.MIGRATION_1_2)
        .build()

    val catalogRepository = AssetCatalogRepository(applicationContext)
    val workoutRepository = RoomWorkoutRepository(database)
    val settingsRepository = DataStoreSettingsRepository(applicationContext)
    val reminderScheduler = AlarmReminderScheduler(applicationContext)
    val nutritionRepository = com.example.myapplication.data.RoomNutritionRepository(database.personalizationDao(), com.example.myapplication.data.DataStoreNutritionPreferences(applicationContext), { java.time.LocalDate.now().toEpochDay() })
    val adaptationRepository = com.example.myapplication.data.RoomAdaptationRepository(
        database = database,
        personalizationDao = database.personalizationDao(),
        nutritionRepository = nutritionRepository
    )
    val coachExplanationClient = com.example.myapplication.data.OkHttpCoachExplanationClient()
}

