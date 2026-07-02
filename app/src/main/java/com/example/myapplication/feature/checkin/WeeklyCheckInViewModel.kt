package com.example.myapplication.feature.checkin

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.myapplication.core.nutrition.NutritionTargetCalculator
import com.example.myapplication.data.NutritionRepository
import com.example.myapplication.data.local.PersonalizationDao
import com.example.myapplication.data.local.WeeklyCheckInEntity
import com.example.myapplication.data.local.WeightMeasurementEntity
import java.time.LocalDate
import java.time.Period
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class WeeklyCheckInViewModel(
    private val personalizationDao: PersonalizationDao,
    private val nutritionRepository: NutritionRepository,
    private val currentEpochDay: () -> Long = { LocalDate.now().toEpochDay() },
    private val nowEpochMillis: () -> Long = { System.currentTimeMillis() },
) : ViewModel() {

    private val isSubmittingState = MutableStateFlow(false)
    private val errorState = MutableStateFlow<String?>(null)
    private val successState = MutableStateFlow(false)
    private val validationErrorsState = MutableStateFlow<List<String>>(emptyList())

    // Form fields
    private val weightState = MutableStateFlow("")
    private val energyState = MutableStateFlow(3)
    private val hungerState = MutableStateFlow(3)
    private val recoveryState = MutableStateFlow(3)
    private val sleepQualityState = MutableStateFlow(3)
    private val noteState = MutableStateFlow("")

    private val profileLoaded = MutableStateFlow<Boolean?>(null) // null = loading, false = no profile, true = loaded

    init {
        viewModelScope.launch {
            val profile = personalizationDao.profileNow()
            if (profile == null) {
                profileLoaded.value = false
            } else {
                profileLoaded.value = true
                val latestWeight = personalizationDao.latestWeightNow()?.weightKg ?: profile.currentWeightKg
                weightState.value = latestWeight.toString()
            }
        }
    }

    val uiState: StateFlow<WeeklyCheckInUiState> = combine(
        profileLoaded,
        weightState,
        energyState,
        hungerState,
        recoveryState,
        sleepQualityState,
        noteState,
        isSubmittingState,
        errorState,
        successState,
        validationErrorsState
    ) { args ->
        val loaded = args[0] as? Boolean
        val weight = args[1] as String
        val energy = args[2] as Int
        val hunger = args[3] as Int
        val recovery = args[4] as Int
        val sleep = args[5] as Int
        val note = args[6] as String
        val submitting = args[7] as Boolean
        val err = args[8] as? String
        val success = args[9] as Boolean
        val valErrors = args[10] as List<String>

        when (loaded) {
            null -> WeeklyCheckInUiState.Loading
            false -> WeeklyCheckInUiState.NoProfile
            true -> WeeklyCheckInUiState.Input(
                weightKgStr = weight,
                energy = energy,
                hunger = hunger,
                recovery = recovery,
                sleepQuality = sleep,
                note = note,
                isSubmitting = submitting,
                error = err,
                success = success,
                validationErrors = valErrors
            )
        }
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = WeeklyCheckInUiState.Loading
    )

    fun updateWeight(weight: String) {
        weightState.value = weight
    }

    fun updateEnergy(value: Int) {
        energyState.value = value.coerceIn(1, 5)
    }

    fun updateHunger(value: Int) {
        hungerState.value = value.coerceIn(1, 5)
    }

    fun updateRecovery(value: Int) {
        recoveryState.value = value.coerceIn(1, 5)
    }

    fun updateSleepQuality(value: Int) {
        sleepQualityState.value = value.coerceIn(1, 5)
    }

    fun updateNote(value: String) {
        noteState.value = value
    }

    fun clearSuccess() {
        successState.value = false
    }

    fun submitCheckIn() {
        val parsedWeight = parseDoubleLocaleSafe(weightState.value)
        val localErrors = mutableListOf<String>()

        if (parsedWeight == null || parsedWeight !in 30.0..350.0) {
            localErrors.add("Cân nặng hiện tại không hợp lệ (phải từ 30 đến 350 kg).")
        }

        if (localErrors.isNotEmpty()) {
            validationErrorsState.value = localErrors
            return
        }

        validationErrorsState.value = emptyList()
        isSubmittingState.value = true
        errorState.value = null

        viewModelScope.launch {
            try {
                val epochDayVal = currentEpochDay()
                val profile = personalizationDao.profileNow()

                if (profile == null) {
                    errorState.value = "Chưa thiết lập hồ sơ cá nhân."
                    isSubmittingState.value = false
                    return@launch
                }

                // 1. Save check-in
                val checkIn = WeeklyCheckInEntity(
                    weekStartEpochDay = epochDayVal,
                    weightKg = parsedWeight!!,
                    energy = energyState.value,
                    hunger = hungerState.value,
                    recovery = recoveryState.value,
                    sleepQuality = sleepQualityState.value,
                    note = noteState.value.trim().takeIf { it.isNotEmpty() },
                    createdAtEpochMillis = nowEpochMillis()
                )
                personalizationDao.upsertWeeklyCheckIn(checkIn)

                // 2. Log weight measurement
                personalizationDao.upsertWeight(
                    WeightMeasurementEntity(
                        epochDay = epochDayVal,
                        weightKg = parsedWeight,
                        recordedAtEpochMillis = nowEpochMillis()
                    )
                )

                // 3. Update currentWeightKg in profile
                val updatedProfile = profile.copy(
                    currentWeightKg = parsedWeight,
                    updatedAtEpochMillis = nowEpochMillis()
                )
                personalizationDao.upsertProfile(updatedProfile)

                // 4. Recalculate nutrition targets if consent is active
                if (updatedProfile.personalizationConsent) {
                    val domainProfile = com.example.myapplication.core.profile.PersonalProfile(
                        birthDateEpochDay = updatedProfile.birthDateEpochDay,
                        metabolicSex = updatedProfile.metabolicSex,
                        heightCm = updatedProfile.heightCm,
                        currentWeightKg = updatedProfile.currentWeightKg,
                        targetWeightKg = updatedProfile.targetWeightKg,
                        activityLevel = updatedProfile.activityLevel,
                        goalPace = updatedProfile.goalPace,
                        personalizationConsent = updatedProfile.personalizationConsent,
                        cloudAiConsent = updatedProfile.cloudAiConsent
                    )
                    val today = LocalDate.ofEpochDay(epochDayVal)
                    val age = Period.between(LocalDate.ofEpochDay(updatedProfile.birthDateEpochDay), today).years
                    val calculator = NutritionTargetCalculator()
                    val calcResult = calculator.calculate(domainProfile, age)
                    if (calcResult is com.example.myapplication.core.nutrition.CalculationResult.Target) {
                        nutritionRepository.setTarget(epochDayVal, calcResult.value)
                    }
                }

                successState.value = true
            } catch (e: Exception) {
                errorState.value = "Lỗi khi lưu check-in: ${e.message}"
            } finally {
                isSubmittingState.value = false
            }
        }
    }

    private fun parseDoubleLocaleSafe(value: String): Double? {
        val cleaned = value.trim().replace(',', '.')
        return cleaned.toDoubleOrNull()
    }
}
