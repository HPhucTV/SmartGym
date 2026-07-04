package com.example.myapplication.core.catalog

import android.content.Context
import com.example.myapplication.core.model.ExerciseDefinition
import com.example.myapplication.core.model.ProgramTemplate
import com.example.myapplication.core.model.MovementBlock

class AssetCatalogRepository internal constructor(
    private val assetReader: (String) -> String,
) {
    constructor(context: Context) : this(
        assetReader = context.applicationContext.assets.let { assets ->
            { path -> assets.open(path).bufferedReader().use { it.readText() } }
        },
    )

    val exercises: List<ExerciseDefinition> by lazy {
        CatalogParser.parseExercises(readAsset(EXERCISES_ASSET)).also { parsed ->
            val issues = CatalogValidator.validateExercises(parsed)
            check(issues.isEmpty()) {
                "Invalid bundled exercise catalog:\n${issues.joinToString(separator = "\n")}"
            }
        }
    }

    val programs: List<ProgramTemplate> by lazy {
        CatalogParser.parsePrograms(readAsset(PROGRAMS_ASSET)).also { parsed ->
            val issues = CatalogValidator.validatePrograms(parsed, exercises.associateBy { it.id })
            require(issues.isEmpty()) {
                "Invalid bundled program catalog:\n${issues.joinToString(separator = "\n")}"
            }
        }
    }

    val movementBlocks: List<MovementBlock> by lazy {
        CatalogParser.parseMovementBlocks(readAsset(MOVEMENT_BLOCKS_ASSET)).also { parsed ->
            val issues = CatalogValidator.validateMovementBlocks(parsed)
            check(issues.isEmpty()) {
                "Invalid bundled movement blocks:\n${issues.joinToString(separator = "\n")}"
            }
        }
    }

    private fun readAsset(path: String): String = assetReader(path)

    private companion object {
        const val EXERCISES_ASSET = "catalog/exercises_vi.json"
        const val PROGRAMS_ASSET = "catalog/programs.json"
        const val MOVEMENT_BLOCKS_ASSET = "catalog/movement_blocks_vi.json"
    }
}
