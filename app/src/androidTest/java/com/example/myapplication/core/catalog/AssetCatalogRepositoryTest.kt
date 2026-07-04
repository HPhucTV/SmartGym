package com.example.myapplication.core.catalog

import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import com.example.myapplication.core.model.MovementBlockKind

class AssetCatalogRepositoryTest {
    @Test
    fun constructingRepositoryDoesNotOpenMissingProgramsAsset() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext

        AssetCatalogRepository(context)
    }

    @Test
    fun repositoryLoadsAndValidatesBundledExercises() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val repository = AssetCatalogRepository(context)

        val exercises = repository.exercises

        assertEquals(64, exercises.size)
        assertEquals(64, exercises.map { it.id }.toSet().size)
        assertTrue(CatalogValidator.validateExercises(exercises).isEmpty())
    }

    @Test
    fun repositoryLoadsAndValidatesReviewedMovementBlocks() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val blocks = AssetCatalogRepository(context).movementBlocks

        assertEquals(14, blocks.size)
        assertEquals(14, blocks.map { it.id }.toSet().size)
        assertEquals(setOf(MovementBlockKind.WARM_UP, MovementBlockKind.COOL_DOWN), blocks.map { it.kind }.toSet())
        assertTrue(CatalogValidator.validateMovementBlocks(blocks).isEmpty())
    }
}
