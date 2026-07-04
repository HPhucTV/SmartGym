package com.example.myapplication.data.local

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index

@Entity(
    tableName = "session_exercises",
    primaryKeys = ["sessionId", "orderIndex"],
    foreignKeys = [
        ForeignKey(
            entity = WorkoutSessionEntity::class,
            parentColumns = ["id"],
            childColumns = ["sessionId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index("sessionId")],
)
data class SessionExerciseEntity(
    val sessionId: Long,
    val orderIndex: Int,
    val exerciseId: String,
    val originalExerciseId: String? = null,
    val sets: Int,
    val repsMin: Int?,
    val repsMax: Int?,
    val durationSeconds: Int?,
    val restSeconds: Int,
    val checked: Boolean = false,
    val omittedByTimeBudget: Boolean = false,
)
