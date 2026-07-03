package com.example.myapplication.feature.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.myapplication.core.model.ActiveGoal
import com.example.myapplication.core.nutrition.NutritionTargetCalculator
import com.example.myapplication.core.nutrition.CalculationResult
import com.example.myapplication.core.profile.ActivityLevel
import com.example.myapplication.core.profile.GoalPace
import com.example.myapplication.core.profile.MetabolicSex
import com.example.myapplication.core.profile.PersonalProfile
import com.example.myapplication.core.profile.ProfileGoalValidator
import com.example.myapplication.data.NutritionRepository
import com.example.myapplication.data.WorkoutRepository
import com.example.myapplication.data.local.PersonalProfileEntity
import com.example.myapplication.data.local.PersonalizationDao
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

class ProfileViewModel(
    private val personalizationDao: PersonalizationDao,
    private val workoutRepository: WorkoutRepository,
    private val nutritionRepository: NutritionRepository,
    private val currentEpochDay: () -> Long = { LocalDate.now().toEpochDay() },
    private val nowEpochMillis: () -> Long = { System.currentTimeMillis() },
) : ViewModel() {

    private val isSavingState = MutableStateFlow(false)
    private val saveErrorState = MutableStateFlow<String?>(null)
    private val successState = MutableStateFlow(false)
    private val validationErrorsState = MutableStateFlow<List<String>>(emptyList())

    // Form fields drafts
    private val birthDateState = MutableStateFlow<Long?>(null)
    private val sexState = MutableStateFlow<MetabolicSex?>(null)
    private val heightState = MutableStateFlow("")
    private val currentWeightState = MutableStateFlow("")
    private val targetWeightState = MutableStateFlow("")
    private val activityLevelState = MutableStateFlow<ActivityLevel?>(null)
    private val goalPaceState = MutableStateFlow<GoalPace?>(null)
    private val personalizationConsentState = MutableStateFlow(false)
    private val cloudAiConsentState = MutableStateFlow(false)

    init {
        viewModelScope.launch {
            val dbProfile = personalizationDao.observeProfile().first()
            if (dbProfile != null) {
                birthDateState.value = dbProfile.birthDateEpochDay
                sexState.value = dbProfile.metabolicSex
                heightState.value = dbProfile.heightCm.toString()
                currentWeightState.value = dbProfile.currentWeightKg.toString()
                targetWeightState.value = dbProfile.targetWeightKg.toString()
                activityLevelState.value = dbProfile.activityLevel
                goalPaceState.value = dbProfile.goalPace
                personalizationConsentState.value = dbProfile.personalizationConsent
                cloudAiConsentState.value = dbProfile.cloudAiConsent
            } else {
                // Set default reasonable values
                val defaultBirthDate = LocalDate.now().minusYears(25).toEpochDay()
                birthDateState.value = defaultBirthDate
                sexState.value = MetabolicSex.MALE
                heightState.value = "170"
                currentWeightState.value = "70"
                targetWeightState.value = "65"
                activityLevelState.value = ActivityLevel.MODERATE
                goalPaceState.value = GoalPace.GRADUAL
                personalizationConsentState.value = false
                cloudAiConsentState.value = false
            }
        }
    }

    private val bodyState = combine(
        birthDateState,
        sexState,
        heightState,
        currentWeightState,
        targetWeightState,
        ::ProfileBodyState,
    )
    private val preferenceState = combine(
        activityLevelState,
        goalPaceState,
        personalizationConsentState,
        cloudAiConsentState,
        ::ProfilePreferenceState,
    )
    private val saveState = combine(
        isSavingState,
        saveErrorState,
        successState,
        validationErrorsState,
        ::ProfileSaveState,
    )

    val uiState: StateFlow<ProfileUiState> = combine(
        bodyState,
        preferenceState,
        saveState,
    ) { body, preferences, save ->
        if (body.birthDate == null || body.sex == null || preferences.activity == null || preferences.pace == null) {
            ProfileUiState.Loading
        } else {
            ProfileUiState.Content(
                birthDateEpochDay = body.birthDate,
                metabolicSex = body.sex,
                heightCmStr = body.height,
                currentWeightKgStr = body.currentWeight,
                targetWeightKgStr = body.targetWeight,
                activityLevel = preferences.activity,
                goalPace = preferences.pace,
                personalizationConsent = preferences.personalizationConsent,
                cloudAiConsent = preferences.cloudAiConsent,
                isSaving = save.isSaving,
                saveError = save.error,
                success = save.success,
                validationErrors = save.validationErrors,
            )
        }
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = ProfileUiState.Loading
    )

    fun updateBirthDate(dateEpochDay: Long) {
        birthDateState.value = dateEpochDay
    }

    fun updateMetabolicSex(sex: MetabolicSex) {
        sexState.value = sex
    }

    fun updateHeight(height: String) {
        heightState.value = height
    }

    fun updateCurrentWeight(weight: String) {
        currentWeightState.value = weight
    }

    fun updateTargetWeight(weight: String) {
        targetWeightState.value = weight
    }

    fun updateActivityLevel(level: ActivityLevel) {
        activityLevelState.value = level
    }

    fun updateGoalPace(pace: GoalPace) {
        goalPaceState.value = pace
    }

    fun updatePersonalizationConsent(consent: Boolean) {
        personalizationConsentState.value = consent
    }

    fun updateCloudAiConsent(consent: Boolean) {
        cloudAiConsentState.value = consent
    }

    fun clearSuccess() {
        successState.value = false
    }

    fun saveProfile() {
        val today = LocalDate.ofEpochDay(currentEpochDay())
        val height = parseDoubleLocaleSafe(heightState.value)
        val currentWeight = parseDoubleLocaleSafe(currentWeightState.value)
        val targetWeight = parseDoubleLocaleSafe(targetWeightState.value)

        val localErrors = mutableListOf<String>()
        if (height == null || height <= 0) {
            localErrors.add("Chiều cao không hợp lệ.")
        }
        if (currentWeight == null || currentWeight <= 0) {
            localErrors.add("Cân nặng hiện tại không hợp lệ.")
        }
        if (targetWeight == null || targetWeight <= 0) {
            localErrors.add("Cân nặng mục tiêu không hợp lệ.")
        }

        if (localErrors.isNotEmpty()) {
            validationErrorsState.value = localErrors
            return
        }

        val profile = PersonalProfile(
            birthDateEpochDay = birthDateState.value ?: 0,
            metabolicSex = sexState.value ?: MetabolicSex.MALE,
            heightCm = height!!,
            currentWeightKg = currentWeight!!,
            targetWeightKg = targetWeight!!,
            activityLevel = activityLevelState.value ?: ActivityLevel.MODERATE,
            goalPace = goalPaceState.value ?: GoalPace.GRADUAL,
            personalizationConsent = personalizationConsentState.value,
            cloudAiConsent = cloudAiConsentState.value
        )

        val profileIssues = profile.validationIssues(today)
        localErrors.addAll(profileIssues)

        viewModelScope.launch {
            val activeGoal = workoutRepository.observeActiveGoal().first()
            if (activeGoal != null) {
                val goalIssues = ProfileGoalValidator.validate(profile, activeGoal.config.goal)
                localErrors.addAll(goalIssues)
            }

            if (localErrors.isNotEmpty()) {
                validationErrorsState.value = localErrors
                return@launch
            }

            validationErrorsState.value = emptyList()
            isSavingState.value = true
            saveErrorState.value = null

            try {
                // Save Profile to db
                val entity = PersonalProfileEntity(
                    birthDateEpochDay = profile.birthDateEpochDay,
                    metabolicSex = profile.metabolicSex,
                    heightCm = profile.heightCm,
                    currentWeightKg = profile.currentWeightKg,
                    targetWeightKg = profile.targetWeightKg,
                    activityLevel = profile.activityLevel,
                    goalPace = profile.goalPace,
                    personalizationConsent = profile.personalizationConsent,
                    cloudAiConsent = profile.cloudAiConsent,
                    updatedAtEpochMillis = nowEpochMillis()
                )
                personalizationDao.upsertProfile(entity)

                // Log weight measurement
                val epochDayVal = currentEpochDay()
                personalizationDao.upsertWeight(
                    WeightMeasurementEntity(
                        epochDay = epochDayVal,
                        weightKg = profile.currentWeightKg,
                        recordedAtEpochMillis = nowEpochMillis()
                    )
                )

                // Recalculate nutrition targets if consent is active
                if (profile.personalizationConsent) {
                    val age = Period.between(LocalDate.ofEpochDay(profile.birthDateEpochDay), today).years
                    val calculator = NutritionTargetCalculator()
                    val calcResult = calculator.calculate(profile, age)
                    if (calcResult is com.example.myapplication.core.nutrition.CalculationResult.Target) {
                        nutritionRepository.setTarget(epochDayVal, calcResult.value)
                    }
                }

                successState.value = true
            } catch (e: Exception) {
                saveErrorState.value = "Lỗi khi lưu hồ sơ: ${e.message}"
            } finally {
                isSavingState.value = false
            }
        }
    }

    private fun parseDoubleLocaleSafe(value: String): Double? {
        val cleaned = value.trim().replace(',', '.')
        return cleaned.toDoubleOrNull()
    }
}

private data class ProfileBodyState(
    val birthDate: Long?,
    val sex: MetabolicSex?,
    val height: String,
    val currentWeight: String,
    val targetWeight: String,
)

private data class ProfilePreferenceState(
    val activity: ActivityLevel?,
    val pace: GoalPace?,
    val personalizationConsent: Boolean,
    val cloudAiConsent: Boolean,
)

private data class ProfileSaveState(
    val isSaving: Boolean,
    val error: String?,
    val success: Boolean,
    val validationErrors: List<String>,
)
