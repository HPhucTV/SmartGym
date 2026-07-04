package com.example.myapplication.core.catalog

import com.example.myapplication.core.model.ExerciseDefinition
import com.example.myapplication.core.model.ProgramTemplate
import com.example.myapplication.core.model.MovementBlock
import kotlinx.serialization.json.Json

object CatalogParser {
    private val json = Json {
        ignoreUnknownKeys = false
        explicitNulls = false
    }

    fun parseExercises(raw: String): List<ExerciseDefinition> = json.decodeFromString(raw)

    fun parsePrograms(raw: String): List<ProgramTemplate> = json.decodeFromString(raw)

    fun parseMovementBlocks(raw: String): List<MovementBlock> = json.decodeFromString(raw)
}
