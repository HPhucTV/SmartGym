package com.example.myapplication.core.model

import kotlinx.serialization.Serializable

@Serializable
enum class Equipment {
    BODYWEIGHT,
    DUMBBELL,
    BAND,
    BARBELL,
    BENCH,
    CABLE,
    MACHINE,
    CARDIO_MACHINE,
}

@Serializable
enum class MuscleGroup {
    CHEST,
    BACK,
    SHOULDERS,
    BICEPS,
    TRICEPS,
    CORE,
    QUADS,
    HAMSTRINGS,
    GLUTES,
    CALVES,
    FULL_BODY,
    CARDIO,
    MOBILITY,
}

@Serializable
enum class MovementPattern {
    SQUAT,
    HINGE,
    LUNGE,
    HORIZONTAL_PUSH,
    VERTICAL_PUSH,
    HORIZONTAL_PULL,
    VERTICAL_PULL,
    CARRY,
    CORE,
    LOCOMOTION,
    MOBILITY,
}

@Serializable
data class ExerciseDefinition(
    val id: String,
    val sourceId: String,
    val nameVi: String,
    val level: ExperienceLevel,
    val equipment: List<Equipment>,
    val movementPattern: MovementPattern,
    val primaryMuscle: MuscleGroup,
    val secondaryMuscles: List<MuscleGroup> = emptyList(),
    val instructionsVi: List<String>,
    val substituteIds: List<String> = emptyList(),
)

@Serializable
data class ExercisePrescription(
    val exerciseId: String,
    val sets: Int,
    val repsMin: Int? = null,
    val repsMax: Int? = null,
    val durationSeconds: Int? = null,
    val restSeconds: Int,
)

@Serializable
data class WorkoutTemplate(
    val sequence: Int,
    val week: Int,
    val titleVi: String,
    val focusVi: String,
    val estimatedMinutes: Int,
    val restDaysAfter: Int,
    val exercises: List<ExercisePrescription>,
)

@Serializable
data class ProgramTemplate(
    val id: String,
    val goal: FitnessGoal,
    val level: ExperienceLevel,
    val equipmentProfile: EquipmentProfile,
    val sessionsPerWeek: Int,
    val durationWeeks: Int,
    val workouts: List<WorkoutTemplate>,
)
