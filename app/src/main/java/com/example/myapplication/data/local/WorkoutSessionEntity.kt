package com.example.myapplication.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "workout_sessions",
    foreignKeys = [
        ForeignKey(
            entity = GoalEntity::class,
            parentColumns = ["id"],
            childColumns = ["goalId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index(value = ["goalId", "sequenceIndex"], unique = true)],
)
data class WorkoutSessionEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val goalId: Long,
    val sequenceIndex: Int,
    val titleVi: String,
    val focusVi: String,
    val estimatedMinutes: Int,
    val dueEpochDay: Long,
    val completedEpochDay: Long? = null,
    @ColumnInfo(defaultValue = "100") val volumeScalePercent: Int = 100,
    val selectedTimeBudgetMinutes: Int? = null,
)
