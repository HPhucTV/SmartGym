package com.example.myapplication.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Upsert
import com.example.myapplication.core.adaptation.AdaptationKind
import com.example.myapplication.core.adaptation.AdaptationStatus
import kotlinx.coroutines.flow.Flow

@Dao
interface PersonalizationDao {
    @Upsert
    suspend fun upsertProfile(profile: PersonalProfileEntity)

    @Query("SELECT * FROM personal_profiles WHERE id = 1 LIMIT 1")
    fun observeProfile(): Flow<PersonalProfileEntity?>

    @Query("SELECT * FROM personal_profiles WHERE id = 1 LIMIT 1")
    suspend fun profileNow(): PersonalProfileEntity?

    @Upsert
    suspend fun upsertWeight(measurement: WeightMeasurementEntity)

    @Query("SELECT * FROM weight_measurements ORDER BY epochDay DESC LIMIT 1")
    suspend fun latestWeightNow(): WeightMeasurementEntity?

    @Query("SELECT * FROM weight_measurements ORDER BY epochDay ASC")
    fun observeWeightHistory(): Flow<List<WeightMeasurementEntity>>

    @Query("SELECT * FROM weight_measurements ORDER BY epochDay ASC")
    suspend fun weightHistoryNow(): List<WeightMeasurementEntity>

    @Upsert
    suspend fun upsertDailyNutrition(day: DailyNutritionEntity)

    @Query("SELECT * FROM daily_nutrition WHERE epochDay = :epochDay LIMIT 1")
    fun observeNutritionDay(epochDay: Long): Flow<DailyNutritionEntity?>

    @Query("SELECT * FROM daily_nutrition WHERE epochDay BETWEEN :startEpochDay AND :endEpochDay ORDER BY epochDay ASC")
    fun observeNutritionRange(startEpochDay: Long, endEpochDay: Long): Flow<List<DailyNutritionEntity>>

    @Query("SELECT * FROM daily_nutrition WHERE epochDay BETWEEN :startEpochDay AND :endEpochDay ORDER BY epochDay ASC")
    suspend fun nutritionRangeNow(startEpochDay: Long, endEpochDay: Long): List<DailyNutritionEntity>

    @Upsert
    suspend fun upsertWeeklyCheckIn(checkIn: WeeklyCheckInEntity)

    @Query("SELECT * FROM weekly_check_ins ORDER BY weekStartEpochDay DESC LIMIT 1")
    fun observeLatestCheckIn(): Flow<WeeklyCheckInEntity?>

    @Query("SELECT * FROM weekly_check_ins ORDER BY weekStartEpochDay DESC LIMIT 1")
    suspend fun latestCheckInNow(): WeeklyCheckInEntity?

    @Insert
    suspend fun insertDecision(decision: AdaptationDecisionEntity): Long

    @Query("UPDATE adaptation_decisions SET status = :status, resolvedAtEpochMillis = :resolvedAt WHERE id = :id")
    suspend fun updateDecisionStatus(id: Long, status: AdaptationStatus, resolvedAt: Long)

    @Query("SELECT * FROM adaptation_decisions WHERE id = :id LIMIT 1")
    suspend fun decisionByIdNow(id: Long): AdaptationDecisionEntity?

    @Query("SELECT * FROM adaptation_decisions WHERE kind = :kind AND status = :status ORDER BY createdAtEpochMillis DESC, id DESC LIMIT 1")
    suspend fun latestDecisionByKindAndStatus(kind: AdaptationKind, status: AdaptationStatus): AdaptationDecisionEntity?

    @Query("SELECT * FROM adaptation_decisions ORDER BY createdAtEpochMillis DESC, id DESC")
    fun observeDecisionHistory(): Flow<List<AdaptationDecisionEntity>>

    @Query("SELECT * FROM adaptation_decisions ORDER BY createdAtEpochMillis DESC, id DESC")
    suspend fun decisionHistoryNow(): List<AdaptationDecisionEntity>
}
