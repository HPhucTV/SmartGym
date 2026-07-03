package com.example.myapplication.data.local

import androidx.room.Entity
import androidx.room.ColumnInfo
import androidx.room.PrimaryKey
import com.example.myapplication.core.model.EquipmentProfile
import com.example.myapplication.core.model.ExperienceLevel
import com.example.myapplication.core.model.FitnessGoal
import com.example.myapplication.core.model.RestDayMode

@Entity(tableName = "goals")
data class GoalEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val programId: String,
    val goal: FitnessGoal,
    val level: ExperienceLevel,
    val equipmentProfile: EquipmentProfile,
    val sessionsPerWeek: Int,
    val durationWeeks: Int,
    val restDayMode: RestDayMode,
    @ColumnInfo(defaultValue = "1") val trainingDaysMask: Int = 1,
    @ColumnInfo(defaultValue = "45") val sessionDurationMinutes: Int = 45,
    val createdEpochDay: Long,
    val archived: Boolean = false,
)
