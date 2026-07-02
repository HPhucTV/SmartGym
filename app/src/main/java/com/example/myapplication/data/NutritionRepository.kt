package com.example.myapplication.data

import android.content.Context
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import com.example.myapplication.core.nutrition.EntrySource
import com.example.myapplication.core.nutrition.Nutrients
import com.example.myapplication.core.nutrition.NutritionDay
import com.example.myapplication.core.nutrition.NutritionTarget
import com.example.myapplication.core.nutrition.NutritionTargetAudit
import com.example.myapplication.data.local.DailyNutritionEntity
import com.example.myapplication.data.local.PersonalizationDao
import java.io.IOException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.emitAll
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

data class NutritionData(
    val caloriesEaten: Int = 0,
    val proteinEaten: Int = 0,
    val carbsEaten: Int = 0,
    val fatEaten: Int = 0,
    val sweatExerciseId: String? = null,
    val sweatExerciseName: String? = null,
    val sweatExtraSets: Int = 0,
    val sweatActive: Boolean = false,
    val aiCoachReview: String? = null,
)

data class LegacyNutritionSnapshot(
    val caloriesEaten: Int = 0,
    val proteinEaten: Int = 0,
    val carbsEaten: Int = 0,
    val fatEaten: Int = 0,
    val sweatExerciseId: String? = null,
    val sweatExerciseName: String? = null,
    val sweatExtraSets: Int = 0,
    val sweatActive: Boolean = false,
    val aiCoachReview: String? = null,
)

data class NutritionPreferenceState(
    val roomMigrated: Boolean = false,
    val sweatExerciseId: String? = null,
    val sweatExerciseName: String? = null,
    val sweatExtraSets: Int = 0,
    val sweatActive: Boolean = false,
    val aiCoachReview: String? = null,
)

interface LegacyNutritionPreferences {
    val state: Flow<NutritionPreferenceState>
    suspend fun snapshotForMigration(): LegacyNutritionSnapshot
    suspend fun markRoomMigrated()
    suspend fun setSweatPayment(exerciseId: String, exerciseName: String, extraSets: Int, active: Boolean)
    suspend fun clearSweatPayment()
    suspend fun updateAiCoachReview(review: String)
    suspend fun clearAiCoachReview()
}

interface NutritionRepository {
    val nutritionData: Flow<NutritionData>
    fun observeDay(epochDay: Long): Flow<NutritionDay>
    fun observeRange(startEpochDay: Long, endEpochDay: Long): Flow<List<NutritionDay>>
    suspend fun addNutrients(epochDay: Long, nutrients: Nutrients, source: EntrySource)
    suspend fun setTarget(epochDay: Long, target: NutritionTarget)
    suspend fun setSweatPayment(exerciseId: String, exerciseName: String, extraSets: Int, active: Boolean)
    suspend fun clearSweatPayment()
    suspend fun updateAiCoachReview(review: String)
    suspend fun resetDaily()
}

class RoomNutritionRepository(
    private val personalizationDao: PersonalizationDao,
    private val legacyPreferences: LegacyNutritionPreferences,
    private val todayEpochDay: () -> Long,
    private val nowEpochMillis: () -> Long = { System.currentTimeMillis() },
) : NutritionRepository {
    private val migrationMutex = Mutex()
    private var migrationChecked = false

    override val nutritionData: Flow<NutritionData> = flow {
        ensureLegacyMigration()
        val today = todayEpochDay()
        emitAll(
            combine(
                personalizationDao.observeNutritionDay(today),
                legacyPreferences.state,
            ) { entity, preferences ->
                val day = entity.toNutritionDay(today)
                NutritionData(
                    caloriesEaten = day.consumed.calories,
                    proteinEaten = day.consumed.proteinGrams,
                    carbsEaten = day.consumed.carbsGrams,
                    fatEaten = day.consumed.fatGrams,
                    sweatExerciseId = preferences.sweatExerciseId,
                    sweatExerciseName = preferences.sweatExerciseName,
                    sweatExtraSets = preferences.sweatExtraSets,
                    sweatActive = preferences.sweatActive,
                    aiCoachReview = preferences.aiCoachReview,
                )
            },
        )
    }

    override fun observeDay(epochDay: Long): Flow<NutritionDay> = flow {
        ensureLegacyMigration()
        emitAll(personalizationDao.observeNutritionDay(epochDay).map { it.toNutritionDay(epochDay) })
    }

    override fun observeRange(startEpochDay: Long, endEpochDay: Long): Flow<List<NutritionDay>> = flow {
        ensureLegacyMigration()
        emitAll(
            personalizationDao.observeNutritionRange(startEpochDay, endEpochDay)
                .map { rows -> rows.map { it.toNutritionDay(it.epochDay) } },
        )
    }

    override suspend fun addNutrients(epochDay: Long, nutrients: Nutrients, source: EntrySource) {
        ensureLegacyMigration()
        val current = entityNow(epochDay)
        personalizationDao.upsertDailyNutrition(
            current.copy(
                consumedCalories = current.consumedCalories + nutrients.calories,
                consumedProteinGrams = current.consumedProteinGrams + nutrients.proteinGrams,
                consumedCarbsGrams = current.consumedCarbsGrams + nutrients.carbsGrams,
                consumedFatGrams = current.consumedFatGrams + nutrients.fatGrams,
                lastEntrySource = source.name,
                updatedAtEpochMillis = nowEpochMillis(),
            ),
        )
    }

    override suspend fun setTarget(epochDay: Long, target: NutritionTarget) {
        ensureLegacyMigration()
        val current = entityNow(epochDay)
        personalizationDao.upsertDailyNutrition(
            current.copy(
                targetBasalCalories = target.basalCalories,
                targetMaintenanceCalories = target.maintenanceCalories,
                targetCalories = target.calories,
                targetProteinGrams = target.proteinGrams,
                targetCarbsGrams = target.carbsGrams,
                targetFatGrams = target.fatGrams,
                updatedAtEpochMillis = nowEpochMillis(),
            ),
        )
    }

    override suspend fun setSweatPayment(
        exerciseId: String,
        exerciseName: String,
        extraSets: Int,
        active: Boolean,
    ) = legacyPreferences.setSweatPayment(exerciseId, exerciseName, extraSets, active)

    override suspend fun clearSweatPayment() = legacyPreferences.clearSweatPayment()

    override suspend fun updateAiCoachReview(review: String) = legacyPreferences.updateAiCoachReview(review)

    override suspend fun resetDaily() {
        ensureLegacyMigration()
        val today = todayEpochDay()
        val current = entityNow(today)
        personalizationDao.upsertDailyNutrition(
            current.copy(
                consumedCalories = 0,
                consumedProteinGrams = 0,
                consumedCarbsGrams = 0,
                consumedFatGrams = 0,
                lastEntrySource = null,
                updatedAtEpochMillis = nowEpochMillis(),
            ),
        )
        legacyPreferences.clearAiCoachReview()
    }

    private suspend fun ensureLegacyMigration() {
        if (migrationChecked) return
        migrationMutex.withLock {
            if (migrationChecked) return
            if (!legacyPreferences.state.first().roomMigrated) {
                val snapshot = legacyPreferences.snapshotForMigration()
                if (snapshot.hasNutritionTotals()) {
                    val today = todayEpochDay()
                    val current = entityNow(today)
                    personalizationDao.upsertDailyNutrition(
                        current.copy(
                            consumedCalories = current.consumedCalories + snapshot.caloriesEaten,
                            consumedProteinGrams = current.consumedProteinGrams + snapshot.proteinEaten,
                            consumedCarbsGrams = current.consumedCarbsGrams + snapshot.carbsEaten,
                            consumedFatGrams = current.consumedFatGrams + snapshot.fatEaten,
                            lastEntrySource = EntrySource.MANUAL.name,
                            updatedAtEpochMillis = nowEpochMillis(),
                        ),
                    )
                }
                legacyPreferences.markRoomMigrated()
            }
            migrationChecked = true
        }
    }

    private suspend fun entityNow(epochDay: Long): DailyNutritionEntity =
        personalizationDao.nutritionRangeNow(epochDay, epochDay).firstOrNull()
            ?: DailyNutritionEntity(epochDay = epochDay, updatedAtEpochMillis = nowEpochMillis())

    private fun LegacyNutritionSnapshot.hasNutritionTotals(): Boolean =
        caloriesEaten != 0 || proteinEaten != 0 || carbsEaten != 0 || fatEaten != 0
}

class DataStoreNutritionPreferences(context: Context) : LegacyNutritionPreferences {
    private val store = context.applicationContext.dataStore

    override val state: Flow<NutritionPreferenceState> = store.data
        .catch { error -> if (error is IOException) emit(emptyPreferences()) else throw error }
        .map(::preferencesToNutritionPreferenceState)

    override suspend fun snapshotForMigration(): LegacyNutritionSnapshot {
        val preferences = store.data
            .catch { error -> if (error is IOException) emit(emptyPreferences()) else throw error }
            .first()
        return LegacyNutritionSnapshot(
            caloriesEaten = preferences[CALORIES] ?: 0,
            proteinEaten = preferences[PROTEIN] ?: 0,
            carbsEaten = preferences[CARBS] ?: 0,
            fatEaten = preferences[FAT] ?: 0,
            sweatExerciseId = preferences[SWEAT_ID],
            sweatExerciseName = preferences[SWEAT_NAME],
            sweatExtraSets = preferences[SWEAT_SETS] ?: 0,
            sweatActive = preferences[SWEAT_ACTIVE] ?: false,
            aiCoachReview = preferences[AI_COACH_REVIEW],
        )
    }

    override suspend fun markRoomMigrated() {
        store.edit { preferences -> preferences[NUTRITION_ROOM_MIGRATED] = true }
    }

    override suspend fun setSweatPayment(
        exerciseId: String,
        exerciseName: String,
        extraSets: Int,
        active: Boolean,
    ) {
        store.edit { preferences ->
            preferences[SWEAT_ID] = exerciseId
            preferences[SWEAT_NAME] = exerciseName
            preferences[SWEAT_SETS] = extraSets
            preferences[SWEAT_ACTIVE] = active
        }
    }

    override suspend fun clearSweatPayment() {
        store.edit { preferences -> preferences[SWEAT_ACTIVE] = false }
    }

    override suspend fun updateAiCoachReview(review: String) {
        store.edit { preferences -> preferences[AI_COACH_REVIEW] = review }
    }

    override suspend fun clearAiCoachReview() {
        store.edit { preferences -> preferences[AI_COACH_REVIEW] = "" }
    }
}

private val CALORIES = intPreferencesKey("nutrition_calories")
private val PROTEIN = intPreferencesKey("nutrition_protein")
private val CARBS = intPreferencesKey("nutrition_carbs")
private val FAT = intPreferencesKey("nutrition_fat")
private val SWEAT_ID = stringPreferencesKey("sweat_exercise_id")
private val SWEAT_NAME = stringPreferencesKey("sweat_exercise_name")
private val SWEAT_SETS = intPreferencesKey("sweat_extra_sets")
private val SWEAT_ACTIVE = booleanPreferencesKey("sweat_active")
private val AI_COACH_REVIEW = stringPreferencesKey("ai_coach_review")
private val NUTRITION_ROOM_MIGRATED = booleanPreferencesKey("nutrition_room_migrated")

private fun preferencesToNutritionPreferenceState(preferences: Preferences) = NutritionPreferenceState(
    roomMigrated = preferences[NUTRITION_ROOM_MIGRATED] ?: false,
    sweatExerciseId = preferences[SWEAT_ID],
    sweatExerciseName = preferences[SWEAT_NAME],
    sweatExtraSets = preferences[SWEAT_SETS] ?: 0,
    sweatActive = preferences[SWEAT_ACTIVE] ?: false,
    aiCoachReview = preferences[AI_COACH_REVIEW],
)

private fun DailyNutritionEntity?.toNutritionDay(epochDay: Long): NutritionDay {
    if (this == null) {
        return NutritionDay(
            epochDay = epochDay,
            consumed = Nutrients(),
            target = null,
        )
    }
    return NutritionDay(
        epochDay = this.epochDay,
        consumed = Nutrients(
            calories = consumedCalories,
            proteinGrams = consumedProteinGrams,
            carbsGrams = consumedCarbsGrams,
            fatGrams = consumedFatGrams,
        ),
        target = toNutritionTarget(),
    )
}

private fun DailyNutritionEntity.toNutritionTarget(): NutritionTarget? {
    val basal = targetBasalCalories ?: return null
    val maintenance = targetMaintenanceCalories ?: return null
    val calories = targetCalories ?: return null
    val protein = targetProteinGrams ?: return null
    val carbs = targetCarbsGrams ?: return null
    val fat = targetFatGrams ?: return null
    return NutritionTarget(
        basalCalories = basal,
        maintenanceCalories = maintenance,
        calories = calories,
        proteinGrams = protein,
        carbsGrams = carbs,
        fatGrams = fat,
        audit = NutritionTargetAudit(
            rawBasalCalories = basal.toDouble(),
            rawMaintenanceCalories = maintenance.toDouble(),
            rawTargetCalories = calories.toDouble(),
            rawProteinGrams = protein.toDouble(),
            rawCarbsGrams = carbs.toDouble(),
            rawFatGrams = fat.toDouble(),
        ),
    )
}
