package com.example.myapplication.data

import com.example.myapplication.core.adaptation.AdaptationDecision
import com.example.myapplication.core.adaptation.AdaptationKind
import com.example.myapplication.core.adaptation.AdaptationMode
import com.example.myapplication.core.adaptation.AdaptationStatus
import com.example.myapplication.core.nutrition.NutritionTarget
import com.example.myapplication.core.nutrition.NutritionTargetAudit
import com.example.myapplication.data.local.AdaptationDecisionEntity
import com.example.myapplication.data.local.GymDatabase
import com.example.myapplication.data.local.PersonalizationDao
import androidx.room.withTransaction
import kotlinx.coroutines.flow.Flow

/**
 * Room-backed implementation of [AdaptationRepository].
 *
 * All state transitions run inside [GymDatabase.withTransaction] so that
 * validation, target mutation, and decision status updates are atomic.
 */
class RoomAdaptationRepository(
    private val database: GymDatabase,
    private val personalizationDao: PersonalizationDao,
    private val nutritionRepository: NutritionRepository,
    private val nowEpochMillis: () -> Long = { System.currentTimeMillis() },
    private val todayEpochDay: () -> Long = { java.time.LocalDate.now().toEpochDay() },
) : AdaptationRepository {

    override fun observeDecisions(): Flow<List<AdaptationDecisionEntity>> =
        personalizationDao.observeDecisionHistory()

    override suspend fun recordDecision(decision: AdaptationDecision): Long {
        val entity = AdaptationDecisionEntity(
            kind = decision.kind,
            mode = decision.mode,
            status = if (decision.mode == AdaptationMode.AUTO_APPLY) {
                AdaptationStatus.APPLIED
            } else {
                AdaptationStatus.PROPOSED
            },
            reasonVi = decision.reasonVi,
            payloadVersion = PAYLOAD_VERSION,
            inputsJson = "{}",
            beforeJson = decision.beforeValue,
            afterJson = decision.afterValue,
            undoJson = decision.undoPayload,
            createdAtEpochMillis = nowEpochMillis(),
            resolvedAtEpochMillis = if (decision.mode == AdaptationMode.AUTO_APPLY) {
                nowEpochMillis()
            } else {
                null
            },
        )

        return database.withTransaction {
            val id = personalizationDao.insertDecision(entity)
            // Auto-apply decisions take effect immediately
            if (decision.mode == AdaptationMode.AUTO_APPLY) {
                applyDecisionEffect(decision)
            }
            id
        }
    }

    override suspend fun acceptDecision(decisionId: Long): DecisionActionResult {
        return database.withTransaction {
            val entity = personalizationDao.decisionByIdNow(decisionId)
                ?: return@withTransaction DecisionActionResult.NotFound(decisionId)

            if (entity.status != AdaptationStatus.PROPOSED) {
                return@withTransaction DecisionActionResult.InvalidState(
                    currentStatus = entity.status,
                    expectedStatus = AdaptationStatus.PROPOSED,
                )
            }

            // Validate that the before-state still matches current state
            val staleCheck = validateBeforeState(entity)
            if (staleCheck != null) return@withTransaction staleCheck

            // Apply the effect
            val decision = entityToDecision(entity)
            applyDecisionEffect(decision)

            // Mark as applied
            personalizationDao.updateDecisionStatus(
                id = decisionId,
                status = AdaptationStatus.APPLIED,
                resolvedAt = nowEpochMillis(),
            )

            DecisionActionResult.Success
        }
    }

    override suspend fun rejectDecision(decisionId: Long): DecisionActionResult {
        return database.withTransaction {
            val entity = personalizationDao.decisionByIdNow(decisionId)
                ?: return@withTransaction DecisionActionResult.NotFound(decisionId)

            if (entity.status != AdaptationStatus.PROPOSED) {
                return@withTransaction DecisionActionResult.InvalidState(
                    currentStatus = entity.status,
                    expectedStatus = AdaptationStatus.PROPOSED,
                )
            }

            personalizationDao.updateDecisionStatus(
                id = decisionId,
                status = AdaptationStatus.REJECTED,
                resolvedAt = nowEpochMillis(),
            )

            DecisionActionResult.Success
        }
    }

    override suspend fun undoLatestDecision(kind: AdaptationKind): DecisionActionResult {
        return database.withTransaction {
            val entity = personalizationDao.latestDecisionByKindAndStatus(
                kind = kind,
                status = AdaptationStatus.APPLIED,
            ) ?: return@withTransaction DecisionActionResult.NotFound(-1)

            // Verify there is no newer conflicting decision of the same kind
            val allDecisions = personalizationDao.decisionHistoryNow()
            val newerConflict = allDecisions.any {
                it.kind == kind &&
                    it.id != entity.id &&
                    it.createdAtEpochMillis > entity.createdAtEpochMillis &&
                    it.status == AdaptationStatus.APPLIED
            }
            if (newerConflict) {
                return@withTransaction DecisionActionResult.Stale(
                    "Có quyết định mới hơn cùng loại đã được áp dụng. Không thể hoàn tác.",
                )
            }

            // Apply the undo payload to restore previous state
            applyUndoEffect(entity)

            // Mark as undone
            personalizationDao.updateDecisionStatus(
                id = entity.id,
                status = AdaptationStatus.UNDONE,
                resolvedAt = nowEpochMillis(),
            )

            DecisionActionResult.Success
        }
    }

    // ── Effect application ──────────────────────────────────────────────

    private suspend fun applyDecisionEffect(decision: AdaptationDecision) {
        when (decision.kind) {
            AdaptationKind.CALORIE_TARGET -> {
                val newCalories = extractCalories(decision.afterValue) ?: return
                val today = todayEpochDay()
                // Build a minimal target from the new calories, recalculating macros proportionally
                val currentDay = nutritionRepository.observeDay(today).let {
                    // We can't collect a flow inside a transaction, so use DAO directly
                    personalizationDao.nutritionRangeNow(today, today).firstOrNull()
                }
                val currentTarget = currentDay?.let {
                    val cal = it.targetCalories ?: return
                    val prot = it.targetProteinGrams ?: 0
                    val carbs = it.targetCarbsGrams ?: 0
                    val fat = it.targetFatGrams ?: 0
                    NutritionTarget(
                        basalCalories = it.targetBasalCalories ?: 0,
                        maintenanceCalories = it.targetMaintenanceCalories ?: 0,
                        calories = cal,
                        proteinGrams = prot,
                        carbsGrams = carbs,
                        fatGrams = fat,
                        audit = NutritionTargetAudit(
                            rawBasalCalories = (it.targetBasalCalories ?: 0).toDouble(),
                            rawMaintenanceCalories = (it.targetMaintenanceCalories ?: 0).toDouble(),
                            rawTargetCalories = cal.toDouble(),
                            rawProteinGrams = prot.toDouble(),
                            rawCarbsGrams = carbs.toDouble(),
                            rawFatGrams = fat.toDouble(),
                        ),
                    )
                }

                if (currentTarget != null) {
                    // Scale macros proportionally to the remaining non-protein calories
                    val proteinCalories = currentTarget.proteinGrams * 4.0
                    val currentNonProtein = currentTarget.calories - proteinCalories
                    val newNonProtein = newCalories - proteinCalories
                    val ratio = if (currentNonProtein > 0 && newNonProtein > 0) {
                        newNonProtein / currentNonProtein
                    } else {
                        newCalories.toDouble() / currentTarget.calories.coerceAtLeast(1)
                    }

                    val newTarget = currentTarget.copy(
                        calories = newCalories,
                        carbsGrams = (currentTarget.carbsGrams * ratio).toInt(),
                        fatGrams = (currentTarget.fatGrams * ratio).toInt(),
                        audit = currentTarget.audit.copy(
                            rawTargetCalories = newCalories.toDouble(),
                            rawCarbsGrams = currentTarget.carbsGrams * ratio,
                            rawFatGrams = currentTarget.fatGrams * ratio,
                        ),
                    )
                    nutritionRepository.setTarget(today, newTarget)
                } else {
                    // No existing target; create a minimal one using weight-proportional protein if profile exists
                    val profile = personalizationDao.profileNow()
                    val protein = if (profile != null) {
                        (profile.currentWeightKg * 1.6).toInt()
                    } else {
                        (newCalories * 0.30 / 4).toInt()
                    }
                    val fat = (newCalories * 0.25 / 9).toInt()
                    val carbs = (newCalories - protein * 4 - fat * 9).coerceAtLeast(0) / 4
                    val target = NutritionTarget(
                        basalCalories = 0,
                        maintenanceCalories = 0,
                        calories = newCalories,
                        proteinGrams = protein,
                        carbsGrams = carbs,
                        fatGrams = fat,
                        audit = NutritionTargetAudit(
                            rawBasalCalories = 0.0,
                            rawMaintenanceCalories = 0.0,
                            rawTargetCalories = newCalories.toDouble(),
                            rawProteinGrams = protein.toDouble(),
                            rawCarbsGrams = carbs.toDouble(),
                            rawFatGrams = fat.toDouble(),
                        ),
                    )
                    nutritionRepository.setTarget(today, target)
                }
            }
            AdaptationKind.RECOVERY_DAY -> {
                // Recovery suggestions are informational - no target mutation
            }
            AdaptationKind.WORKOUT_VOLUME,
            AdaptationKind.PROGRAM_CHANGE,
            AdaptationKind.MACRO_TARGET -> {
                // These are handled through existing confirmed workflows
                // (createGoal, settings changes). The decision record serves as audit trail.
            }
        }
    }

    private suspend fun applyUndoEffect(entity: AdaptationDecisionEntity) {
        when (entity.kind) {
            AdaptationKind.CALORIE_TARGET -> {
                val originalCalories = extractCalories(entity.undoJson) ?: return
                val today = todayEpochDay()
                val currentDay = personalizationDao.nutritionRangeNow(today, today).firstOrNull()
                val currentCalories = currentDay?.targetCalories ?: return

                val currentProt = currentDay.targetProteinGrams ?: 0
                val proteinCalories = currentProt * 4.0
                val currentNonProtein = currentCalories - proteinCalories
                val originalNonProtein = originalCalories - proteinCalories
                val ratio = if (currentNonProtein > 0 && originalNonProtein > 0) {
                    originalNonProtein / currentNonProtein
                } else {
                    originalCalories.toDouble() / currentCalories.coerceAtLeast(1)
                }

                val currentCarbs = currentDay.targetCarbsGrams ?: 0
                val currentFat = currentDay.targetFatGrams ?: 0

                val target = NutritionTarget(
                    basalCalories = currentDay.targetBasalCalories ?: 0,
                    maintenanceCalories = currentDay.targetMaintenanceCalories ?: 0,
                    calories = originalCalories,
                    proteinGrams = currentProt,
                    carbsGrams = (currentCarbs * ratio).toInt(),
                    fatGrams = (currentFat * ratio).toInt(),
                    audit = NutritionTargetAudit(
                        rawBasalCalories = (currentDay.targetBasalCalories ?: 0).toDouble(),
                        rawMaintenanceCalories = (currentDay.targetMaintenanceCalories ?: 0).toDouble(),
                        rawTargetCalories = originalCalories.toDouble(),
                        rawProteinGrams = currentProt.toDouble(),
                        rawCarbsGrams = currentCarbs * ratio,
                        rawFatGrams = currentFat * ratio,
                    ),
                )
                nutritionRepository.setTarget(today, target)
            }
            AdaptationKind.RECOVERY_DAY -> {
                // No target to undo
            }
            AdaptationKind.WORKOUT_VOLUME,
            AdaptationKind.PROGRAM_CHANGE,
            AdaptationKind.MACRO_TARGET -> {
                // Handled through existing workflows
            }
        }
    }

    // ── Validation ──────────────────────────────────────────────────────

    private suspend fun validateBeforeState(entity: AdaptationDecisionEntity): DecisionActionResult? {
        when (entity.kind) {
            AdaptationKind.CALORIE_TARGET -> {
                val expectedCalories = extractCalories(entity.beforeJson) ?: return null
                val today = todayEpochDay()
                val currentDay = personalizationDao.nutritionRangeNow(today, today).firstOrNull()
                val actualCalories = currentDay?.targetCalories ?: return null
                if (actualCalories != expectedCalories) {
                    return DecisionActionResult.Stale(
                        "Mục tiêu calorie hiện tại ($actualCalories) khác với giá trị dự kiến ($expectedCalories). " +
                            "Quyết định này đã bị lỗi thời.",
                    )
                }
            }
            else -> { /* Other kinds don't have simple before-state validation */ }
        }
        return null
    }

    // ── JSON parsing helpers ────────────────────────────────────────────

    private fun extractCalories(json: String): Int? {
        return Regex("\"calories\":(\\d+)").find(json)?.groupValues?.get(1)?.toIntOrNull()
    }

    private fun entityToDecision(entity: AdaptationDecisionEntity) = AdaptationDecision(
        kind = entity.kind,
        mode = entity.mode,
        reasonVi = entity.reasonVi,
        beforeValue = entity.beforeJson,
        afterValue = entity.afterJson,
        undoPayload = entity.undoJson,
    )

    companion object {
        const val PAYLOAD_VERSION = 1
    }
}
