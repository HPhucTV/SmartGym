package com.example.myapplication.feature.nutrition

import android.graphics.Bitmap
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.myapplication.core.model.FitnessGoal
import com.example.myapplication.core.nutrition.EntrySource
import com.example.myapplication.core.nutrition.Nutrients
import com.example.myapplication.core.nutrition.NutritionDay
import com.example.myapplication.data.NutritionData
import com.example.myapplication.data.NutritionRepository
import com.example.myapplication.data.WorkoutRepository
import java.time.LocalDate
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

sealed interface NutritionUiState {
    data object Loading : NutritionUiState
    data class Content(
        val calorieLimit: Int,
        val caloriesEaten: Int,
        val proteinEaten: Int,
        val carbsEaten: Int,
        val fatEaten: Int,
        val sweatActive: Boolean,
        val sweatExerciseName: String?,
        val sweatExtraSets: Int,
        val scanResult: ScanResult?,
        val scanning: Boolean,
        val scanError: String?,
    ) : NutritionUiState
}

data class ScanResult(
    val dishName: String,
    val totalCalories: Int,
    val proteinGrams: Int,
    val carbsGrams: Int,
    val fatGrams: Int,
    val fitnessScore: Int,
    val advice: String,
    val constituents: List<Constituent>,
    val sweatPayment: SweatPaymentProposal?,
)

data class Constituent(
    val name: String,
    val calories: Int,
    val protein: Int,
    val carbs: Int,
    val fat: Int,
)

data class SweatPaymentProposal(
    val exerciseId: String,
    val exerciseName: String,
    val extraSets: Int,
)

class NutritionViewModel(
    private val workoutRepository: WorkoutRepository,
    private val nutritionRepository: NutritionRepository,
    private val foodAnalysisClient: FoodAnalysisClient = OkHttpFoodAnalysisClient(),
    private val currentEpochDay: () -> Long = { LocalDate.now().toEpochDay() },
) : ViewModel() {
    private val scanningState = MutableStateFlow(false)
    private val scanResultState = MutableStateFlow<ScanResult?>(null)
    private val scanErrorState = MutableStateFlow<String?>(null)
    private val todayEpochDay = currentEpochDay()
    private val nutritionParts = combine(
        nutritionRepository.nutritionData,
        nutritionRepository.observeDay(todayEpochDay),
        ::NutritionStateParts,
    )

    val uiState: StateFlow<NutritionUiState> = combine(
        workoutRepository.observeActiveGoal(),
        nutritionParts,
        scanningState,
        scanResultState,
        scanErrorState,
    ) { goal, nutrition, scanning, scanResult, scanError ->
        val fallbackLimit = when (goal?.config?.goal) {
            FitnessGoal.MUSCLE_GAIN -> 2700
            FitnessGoal.FAT_LOSS_CONDITIONING -> 1800
            FitnessGoal.ENDURANCE -> 2200
            FitnessGoal.GENERAL_FITNESS -> 2000
            null -> 2000
        }
        NutritionUiState.Content(
            calorieLimit = nutrition.today.target?.calories ?: fallbackLimit,
            caloriesEaten = nutrition.data.caloriesEaten,
            proteinEaten = nutrition.data.proteinEaten,
            carbsEaten = nutrition.data.carbsEaten,
            fatEaten = nutrition.data.fatEaten,
            sweatActive = nutrition.data.sweatActive,
            sweatExerciseName = nutrition.data.sweatExerciseName,
            sweatExtraSets = nutrition.data.sweatExtraSets,
            scanResult = scanResult,
            scanning = scanning,
            scanError = scanError,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = NutritionUiState.Loading,
    )

    fun scanFood(bitmap: Bitmap?) {
        viewModelScope.launch {
            scanningState.value = true
            scanErrorState.value = null
            scanResultState.value = null

            try {
                val result = foodAnalysisClient.analyze(bitmap)
                if (result != null) {
                    scanResultState.value = result
                } else {
                    scanErrorState.value = "Khong the phan tich du lieu mon an tra ve."
                }
            } catch (cancelled: CancellationException) {
                scanErrorState.value = null
                throw cancelled
            } catch (error: Exception) {
                scanErrorState.value = "Loi ket noi toi server backend: ${error.message}"
            } finally {
                scanningState.value = false
            }
        }
    }

    fun acceptScanResult() {
        val result = scanResultState.value ?: return
        viewModelScope.launch {
            nutritionRepository.addNutrients(
                epochDay = currentEpochDay(),
                nutrients = Nutrients(
                    calories = result.totalCalories,
                    proteinGrams = result.proteinGrams,
                    carbsGrams = result.carbsGrams,
                    fatGrams = result.fatGrams,
                ),
                source = EntrySource.CAMERA_ANALYSIS,
            )
            result.sweatPayment?.let { proposal ->
                nutritionRepository.setSweatPayment(
                    exerciseId = proposal.exerciseId,
                    exerciseName = proposal.exerciseName,
                    extraSets = proposal.extraSets,
                    active = true,
                )
            }
            scanResultState.value = null
        }
    }

    fun discardScanResult() {
        scanResultState.value = null
    }

    fun clearSweat() {
        viewModelScope.launch { nutritionRepository.clearSweatPayment() }
    }

    fun resetDaily() {
        viewModelScope.launch { nutritionRepository.resetDaily() }
    }
}

private data class NutritionStateParts(
    val data: NutritionData,
    val today: NutritionDay,
)
