package com.example.myapplication.app

import android.content.Context
import androidx.room.Room
import com.example.myapplication.core.catalog.AssetCatalogRepository
import com.example.myapplication.data.RoomWorkoutRepository
import com.example.myapplication.data.local.GymDatabase

class AppContainer(context: Context) {
    private val applicationContext = context.applicationContext

    val database: GymDatabase = Room.databaseBuilder(
        applicationContext,
        GymDatabase::class.java,
        "gym.db",
    ).build()

    val catalogRepository = AssetCatalogRepository(applicationContext)
    val workoutRepository = RoomWorkoutRepository(database)
}
