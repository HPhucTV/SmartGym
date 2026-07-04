package com.example.myapplication.core.catalog

import com.example.myapplication.core.model.Equipment
import com.example.myapplication.core.model.EquipmentProfile
import com.example.myapplication.core.model.ExerciseDefinition

class ExerciseSubstitutionEngine(exercises: List<ExerciseDefinition>) {
    private val byId = exercises.associateBy(ExerciseDefinition::id)

    fun candidates(exerciseId: String, profile: EquipmentProfile): List<ExerciseDefinition> {
        val source = byId[exerciseId] ?: return emptyList()
        return source.substituteIds
            .mapNotNull(byId::get)
            .filter { it.primaryMuscle == source.primaryMuscle }
            .filter { it.movementPattern == source.movementPattern }
            .filter { it.supports(profile) }
            .distinctBy(ExerciseDefinition::id)
            .sortedWith(
                compareBy<ExerciseDefinition> { it.level != source.level }
                    .thenBy(ExerciseDefinition::nameVi),
            )
    }
}

internal fun ExerciseDefinition.supports(profile: EquipmentProfile): Boolean {
    val allowed = when (profile) {
        EquipmentProfile.BODYWEIGHT_ONLY -> setOf(Equipment.BODYWEIGHT)
        EquipmentProfile.DUMBBELLS -> setOf(Equipment.BODYWEIGHT, Equipment.DUMBBELL)
        EquipmentProfile.RESISTANCE_BANDS -> setOf(Equipment.BODYWEIGHT, Equipment.BAND)
        EquipmentProfile.FULL_GYM -> Equipment.entries.toSet()
    }
    return equipment.all { it in allowed }
}
