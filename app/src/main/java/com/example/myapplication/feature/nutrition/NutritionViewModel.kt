package com.example.myapplication.feature.nutrition

import android.graphics.Bitmap
import kotlin.math.roundToInt
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.myapplication.core.model.FitnessGoal
import com.example.myapplication.core.nutrition.EntrySource
import com.example.myapplication.core.nutrition.Nutrients
import com.example.myapplication.core.nutrition.NutritionDay
import com.example.myapplication.core.nutrition.MealTemplate
import com.example.myapplication.data.NutritionData
import com.example.myapplication.data.NutritionRepository
import com.example.myapplication.core.nutrition.NutritionCsvParser
import com.example.myapplication.core.nutrition.NutritionXlsxParser
import com.example.myapplication.core.nutrition.NutritionTarget
import com.example.myapplication.core.nutrition.NutritionTargetAudit
import com.example.myapplication.core.nutrition.NutritionScoreCalculator
import com.example.myapplication.data.WorkoutRepository
import java.time.LocalDate
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.flatMapLatest

sealed interface NutritionUiState {
    data object Loading : NutritionUiState
    data class Content(
        val calorieLimit: Int,
        val caloriesEaten: Int,
        val nutritionScore: Int = 0,
        val nutritionScoreLabel: String = "",
        val nutritionScoreEmoji: String = "",
        val proteinEaten: Int,
        val proteinLimit: Int,
        val carbsEaten: Int,
        val carbsLimit: Int,
        val fatEaten: Int,
        val fatLimit: Int,
        val fiberEaten: Int = 0,
        val fiberLimit: Int = 30,
        val sweatActive: Boolean,
        val sweatExerciseName: String?,
        val sweatExtraSets: Int,
        val waterIntakeMl: Int,
        val scanResult: ScanResult?,
        val scanning: Boolean,
        val scanError: String?,
        val history: List<NutritionDay> = emptyList(),
        val draft: EditableNutritionDraft? = null,
        val mealTemplates: List<MealTemplate> = emptyList(),
        val savingDraft: Boolean = false,
        val pendingDeleteTemplateId: Long? = null,
        val templateNameEdit: TemplateNameEdit? = null,
        val foodCatalogCount: Int = 0,
        val foodCatalogItems: List<com.example.myapplication.data.local.FoodCatalogEntity> = emptyList(),
        val searchQuery: String = "",
        val importSuccess: Boolean? = null,
        val importErrorMessage: String? = null,
        val importWarnings: List<String> = emptyList(),
        val cart: List<CartItem> = emptyList(),
        val loggedFoods: List<com.example.myapplication.data.local.LoggedFoodEntity> = emptyList(),
        val favorites: List<com.example.myapplication.data.local.FoodCatalogEntity> = emptyList(),
        val recentFoods: List<com.example.myapplication.data.local.FoodCatalogEntity> = emptyList(),
    ) : NutritionUiState
}

data class CartItem(
    val food: com.example.myapplication.data.local.FoodCatalogEntity,
    val grams: Double,
    val mealTime: String = "BREAKFAST" // BREAKFAST, LUNCH, DINNER, SNACK
)

data class EditableNutritionDraft(
    val nameVi: String,
    val caloriesText: String,
    val proteinText: String,
    val carbsText: String,
    val fatText: String,
    val fiberText: String = "",
    val saveAsTemplate: Boolean = false,
    val errors: Map<String, String> = emptyMap(),
)

data class TemplateNameEdit(
    val id: Long,
    val nameVi: String,
    val error: String? = null,
)

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
    val calculationProcess: String? = null,
    val confidence: Double = 1.0,
    val needsUserConfirmation: Boolean = false,
    val recommendations: List<ScanRecommendation> = emptyList(),
)

data class ScanRecommendation(
    val dishName: String,
    val confidence: Double,
    val calories: Int,
    val proteinGrams: Int,
    val carbsGrams: Int,
    val fatGrams: Int
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
    private val personalizationDao: com.example.myapplication.data.local.PersonalizationDao? = null,
    private val foodCatalogDao: com.example.myapplication.data.local.FoodCatalogDao? = null,
    private val foodAnalysisClient: FoodAnalysisClient = OkHttpFoodAnalysisClient(),
    private val cloudAiConsent: Flow<Boolean> = flowOf(false),
    private val currentEpochDay: () -> Long = { LocalDate.now().toEpochDay() },
    private val ioDispatcher: kotlinx.coroutines.CoroutineDispatcher = kotlinx.coroutines.Dispatchers.IO,
) : ViewModel() {
    private val scanningState = MutableStateFlow(false)
    private val scanResultState = MutableStateFlow<ScanResult?>(null)
    private val scanErrorState = MutableStateFlow<String?>(null)
    private val draftState = MutableStateFlow<EditableNutritionDraft?>(null)
    private val savingDraftState = MutableStateFlow(false)
    private val pendingDeleteTemplateId = MutableStateFlow<Long?>(null)
    private val templateNameEdit = MutableStateFlow<TemplateNameEdit?>(null)
    private var draftEntrySource = EntrySource.MANUAL
    private var draftSweatPayment: SweatPaymentProposal? = null
    private var draftNutrientsRecorded = false
    private val todayEpochDay = currentEpochDay()

    private val searchQueryState = MutableStateFlow("")
    private val importSuccessState = MutableStateFlow<Boolean?>(null)
    private val importErrorMessageState = MutableStateFlow<String?>(null)
    private val importWarningsState = MutableStateFlow<List<String>>(emptyList())

    private val cartState = MutableStateFlow<List<CartItem>>(emptyList())
    private val mealBuilderParts = combine(
        cartState,
        nutritionRepository.observeLoggedFoods(todayEpochDay),
        nutritionRepository.observeFavorites(),
        nutritionRepository.observeRecentFoods(20)
    ) { cart, logged, favs, recents ->
        MealBuilderParts(cart, logged, favs, recents)
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    private val foodCatalogFlow = searchQueryState.flatMapLatest { query ->
        if (query.isEmpty()) {
            foodCatalogDao?.observeAll() ?: flowOf(emptyList())
        } else {
            foodCatalogDao?.searchByName(query) ?: flowOf(emptyList())
        }
    }

    private val foodCatalogCountFlow = foodCatalogDao?.observeCount() ?: flowOf(0)

    private val nutritionParts = combine(
        nutritionRepository.nutritionData,
        nutritionRepository.observeDay(todayEpochDay)
    ) { data, today ->
        NutritionStateParts(data, today)
    }
    private val scanParts = combine(scanningState, scanResultState, scanErrorState) { scanning, result, error ->
        ScanStateParts(scanning, result, error)
    }
    private val draftParts = combine(
        draftState,
        savingDraftState,
        pendingDeleteTemplateId,
        templateNameEdit
    ) { draft, saving, pendingDeleteTemplateId, templateNameEdit ->
        DraftStateParts(draft, saving, pendingDeleteTemplateId, templateNameEdit)
    }
    private val interactionParts = combine(scanParts, draftParts) { scan, draft ->
        NutritionInteractionParts(scan, draft)
    }

    private val catalogParts = combine(
        foodCatalogFlow,
        foodCatalogCountFlow,
        searchQueryState,
        importSuccessState,
        importErrorMessageState,
        importWarningsState
    ) { array ->
        @Suppress("UNCHECKED_CAST")
        CatalogStateParts(
            items = array[0] as List<com.example.myapplication.data.local.FoodCatalogEntity>,
            count = array[1] as Int,
            query = array[2] as String,
            success = array[3] as Boolean?,
            error = array[4] as String?,
            warnings = array[5] as List<String>,
        )
    }

    private val combinedParts = combine(interactionParts, catalogParts, mealBuilderParts) { interaction, catalog, mealBuilder ->
        Triple(interaction, catalog, mealBuilder)
    }

    val uiState: StateFlow<NutritionUiState> = combine(
        workoutRepository.observeActiveGoal(),
        nutritionParts,
        nutritionRepository.observeAllNutrition(),
        nutritionRepository.observeMealTemplates(),
        combinedParts,
    ) { goal, nutrition, allNutrition, templates, parts ->
        val interaction = parts.first
        val catalog = parts.second
        val mealBuilder = parts.third
        val fallbackLimit = when (goal?.config?.goal) {
            com.example.myapplication.core.model.FitnessGoal.MUSCLE_GAIN -> 2400
            com.example.myapplication.core.model.FitnessGoal.FAT_LOSS_CONDITIONING -> 1600
            com.example.myapplication.core.model.FitnessGoal.ENDURANCE -> 2000
            com.example.myapplication.core.model.FitnessGoal.GENERAL_FITNESS -> 1800
            null -> 1800
        }
        val history = allNutrition.filter { it.epochDay < todayEpochDay && it.consumed.calories > 0 }
        val target = nutrition.today.target
        val proteinLimit = target?.proteinGrams ?: when (goal?.config?.goal) {
            com.example.myapplication.core.model.FitnessGoal.MUSCLE_GAIN -> (fallbackLimit * 0.30 / 4).toInt()
            com.example.myapplication.core.model.FitnessGoal.FAT_LOSS_CONDITIONING -> (fallbackLimit * 0.35 / 4).toInt()
            else -> (fallbackLimit * 0.25 / 4).toInt()
        }
        val fatLimit = target?.fatGrams ?: when (goal?.config?.goal) {
            com.example.myapplication.core.model.FitnessGoal.MUSCLE_GAIN -> (fallbackLimit * 0.25 / 9).toInt()
            com.example.myapplication.core.model.FitnessGoal.FAT_LOSS_CONDITIONING -> (fallbackLimit * 0.25 / 9).toInt()
            else -> (fallbackLimit * 0.25 / 9).toInt()
        }
        val carbsLimit = target?.carbsGrams ?: when (goal?.config?.goal) {
            com.example.myapplication.core.model.FitnessGoal.MUSCLE_GAIN -> (fallbackLimit * 0.45 / 4).toInt()
            com.example.myapplication.core.model.FitnessGoal.FAT_LOSS_CONDITIONING -> (fallbackLimit * 0.40 / 4).toInt()
            else -> (fallbackLimit * 0.50 / 4).toInt()
        }

        val consumedNutrients = Nutrients(
            calories = nutrition.data.caloriesEaten,
            proteinGrams = nutrition.data.proteinEaten,
            carbsGrams = nutrition.data.carbsEaten,
            fatGrams = nutrition.data.fatEaten,
            fiberGrams = nutrition.today.consumed.fiberGrams,
        )
        val targetForScore = target ?: NutritionTarget(
            basalCalories = fallbackLimit,
            maintenanceCalories = fallbackLimit,
            calories = fallbackLimit,
            proteinGrams = proteinLimit,
            carbsGrams = carbsLimit,
            fatGrams = fatLimit,
            audit = NutritionTargetAudit(fallbackLimit.toDouble(), fallbackLimit.toDouble(), fallbackLimit.toDouble(), proteinLimit.toDouble(), carbsLimit.toDouble(), fatLimit.toDouble())
        )
        val scoreResult = NutritionScoreCalculator.calculateScore(
            consumed = consumedNutrients,
            target = targetForScore,
            waterIntakeMl = nutrition.today.waterIntakeMl
        )

        NutritionUiState.Content(
            calorieLimit = target?.calories ?: fallbackLimit,
            caloriesEaten = nutrition.data.caloriesEaten,
            nutritionScore = scoreResult.score,
            nutritionScoreLabel = scoreResult.label,
            nutritionScoreEmoji = scoreResult.emoji,
            proteinEaten = nutrition.data.proteinEaten,
            proteinLimit = proteinLimit,
            carbsEaten = nutrition.data.carbsEaten,
            carbsLimit = carbsLimit,
            fatEaten = nutrition.data.fatEaten,
            fatLimit = fatLimit,
            fiberEaten = nutrition.today.consumed.fiberGrams,
            fiberLimit = 30,
            sweatActive = nutrition.data.sweatActive,
            sweatExerciseName = nutrition.data.sweatExerciseName,
            sweatExtraSets = nutrition.data.sweatExtraSets,
            waterIntakeMl = nutrition.today.waterIntakeMl,
            scanResult = interaction.scan.result,
            scanning = interaction.scan.scanning,
            scanError = interaction.scan.error,
            history = history,
            draft = interaction.draft.draft,
            mealTemplates = templates,
            savingDraft = interaction.draft.saving,
            pendingDeleteTemplateId = interaction.draft.pendingDeleteTemplateId,
            templateNameEdit = interaction.draft.templateNameEdit,
            foodCatalogCount = catalog.count,
            foodCatalogItems = catalog.items,
            searchQuery = catalog.query,
            importSuccess = catalog.success,
            importErrorMessage = catalog.error,
            importWarnings = catalog.warnings,
            cart = mealBuilder.cart,
            loggedFoods = mealBuilder.loggedFoods,
            favorites = mealBuilder.favorites,
            recentFoods = mealBuilder.recentFoods,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = NutritionUiState.Loading,
    )

    fun scanFood(bitmap: Bitmap?) {
        viewModelScope.launch {
            if (!cloudAiConsent.first()) {
                scanningState.value = false
                scanResultState.value = null
                scanErrorState.value = "Hãy bật đồng ý AI Cloud trong Hồ sơ trước khi quét món ăn."
                return@launch
            }
            if (com.example.myapplication.app.BackendConfig.baseUrl == null) {
                scanningState.value = false
                scanResultState.value = null
                scanErrorState.value = "Chưa cấu hình địa chỉ máy chủ trong mục Cài đặt."
                return@launch
            }
            scanningState.value = true
            scanErrorState.value = null
            scanResultState.value = null

            try {
                val result = foodAnalysisClient.analyze(bitmap)
                if (result != null) {
                    scanResultState.value = result
                    // Automatically pre-select the first recommendation as the initial draft
                    if (result.recommendations.isNotEmpty()) {
                        val firstRec = result.recommendations.first()
                        draftEntrySource = EntrySource.CAMERA_ANALYSIS
                        draftSweatPayment = result.sweatPayment
                        draftNutrientsRecorded = false
                        draftState.value = EditableNutritionDraft(
                            nameVi = firstRec.dishName,
                            caloriesText = firstRec.calories.toString(),
                            proteinText = firstRec.proteinGrams.toString(),
                            carbsText = firstRec.carbsGrams.toString(),
                            fatText = firstRec.fatGrams.toString(),
                            saveAsTemplate = false,
                            errors = emptyMap()
                        )
                    } else {
                        draftEntrySource = EntrySource.CAMERA_ANALYSIS
                        draftSweatPayment = result.sweatPayment
                        draftNutrientsRecorded = false
                        draftState.value = result.toEditableDraft()
                    }
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
        acceptDraft()
    }

    fun startManualEntry() {
        if (savingDraftState.value) return
        draftEntrySource = EntrySource.MANUAL
        draftSweatPayment = null
        draftNutrientsRecorded = false
        draftState.value = EditableNutritionDraft("", "", "", "", "", "")
    }

    fun selectScanRecommendation(recommendation: ScanRecommendation) {
        val result = scanResultState.value ?: return
        draftEntrySource = EntrySource.CAMERA_ANALYSIS
        draftSweatPayment = result.sweatPayment
        draftNutrientsRecorded = false
        draftState.value = EditableNutritionDraft(
            nameVi = recommendation.dishName,
            caloriesText = recommendation.calories.toString(),
            proteinText = recommendation.proteinGrams.toString(),
            carbsText = recommendation.carbsGrams.toString(),
            fatText = recommendation.fatGrams.toString(),
            fiberText = "0",
            saveAsTemplate = false,
            errors = emptyMap()
        )
        scanResultState.value = null
    }

    fun updateDraftName(value: String) = updateDraft { copy(nameVi = value, errors = emptyMap()) }
    fun updateDraftCalories(value: String) = updateDraft { copy(caloriesText = value, errors = emptyMap()) }
    fun updateDraftProtein(value: String) = updateDraft { copy(proteinText = value, errors = emptyMap()) }
    fun updateDraftCarbs(value: String) = updateDraft { copy(carbsText = value, errors = emptyMap()) }
    fun updateDraftFat(value: String) = updateDraft { copy(fatText = value, errors = emptyMap()) }
    fun updateDraftFiber(value: String) = updateDraft { copy(fiberText = value, errors = emptyMap()) }
    fun setDraftSaveAsTemplate(value: Boolean) = updateDraft { copy(saveAsTemplate = value) }

    fun acceptDraft() {
        val draft = draftState.value ?: return
        if (savingDraftState.value) return
        val parsed = draft.validateAndParse()
        if (parsed.errors.isNotEmpty()) {
            draftState.value = draft.copy(errors = parsed.errors)
            return
        }
        val nutrients = requireNotNull(parsed.nutrients)
        val normalizedName = draft.nameVi.trim()
        val source = draftEntrySource
        val sweatPayment = draftSweatPayment
        savingDraftState.value = true
        viewModelScope.launch {
            try {
                if (!draftNutrientsRecorded) {
                    val hour = java.time.LocalTime.now().hour
                    val mealTime = when {
                        hour < 10 -> "BREAKFAST"
                        hour < 14 -> "LUNCH"
                        hour < 17 -> "SNACK"
                        else -> "DINNER"
                    }
                    nutritionRepository.logFood(
                        epochDay = currentEpochDay(),
                        name = normalizedName,
                        mealTime = mealTime,
                        grams = 100.0,
                        calories = nutrients.calories,
                        proteinGrams = nutrients.proteinGrams,
                        carbsGrams = nutrients.carbsGrams,
                        fatGrams = nutrients.fatGrams,
                        fiberGrams = nutrients.fiberGrams,
                        foodCatalogId = null
                    )
                    sweatPayment?.let { proposal ->
                        nutritionRepository.setSweatPayment(
                            proposal.exerciseId,
                            proposal.exerciseName,
                            proposal.extraSets,
                            true,
                        )
                    }
                    draftNutrientsRecorded = true
                }
                if (draft.saveAsTemplate) {
                    nutritionRepository.saveMealTemplate(null, normalizedName, nutrients)
                }
                draftState.value = null
                draftSweatPayment = null
                draftNutrientsRecorded = false
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (_: Exception) {
                draftState.value = draft.copy(
                    errors = mapOf("submit" to "Không thể lưu món ăn. Vui lòng thử lại."),
                )
            } finally {
                savingDraftState.value = false
            }
        }
    }

    fun discardScanResult() {
        scanResultState.value = null
        draftState.value = null
        draftSweatPayment = null
        draftNutrientsRecorded = false
    }

    fun applyTemplate(id: Long) {
        if (savingDraftState.value) return
        savingDraftState.value = true
        viewModelScope.launch {
            try {
                nutritionRepository.applyMealTemplate(id, currentEpochDay())
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (_: Exception) {
                scanErrorState.value = "Không thể thêm bữa ăn đã lưu. Vui lòng thử lại."
            } finally {
                savingDraftState.value = false
            }
        }
    }

    fun requestDeleteTemplate(id: Long) {
        if (!savingDraftState.value) pendingDeleteTemplateId.value = id
    }

    fun cancelDeleteTemplate() {
        if (!savingDraftState.value) pendingDeleteTemplateId.value = null
    }

    fun confirmDeleteTemplate() {
        val id = pendingDeleteTemplateId.value ?: return
        if (savingDraftState.value) return
        pendingDeleteTemplateId.value = null
        savingDraftState.value = true
        viewModelScope.launch {
            try {
                nutritionRepository.deleteMealTemplate(id)
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (_: Exception) {
                scanErrorState.value = "Không thể xóa bữa ăn đã lưu. Vui lòng thử lại."
            } finally {
                savingDraftState.value = false
            }
        }
    }

    fun startRenameTemplate(id: Long) {
        if (savingDraftState.value) return
        val template = (uiState.value as? NutritionUiState.Content)
            ?.mealTemplates?.firstOrNull { it.id == id } ?: return
        templateNameEdit.value = TemplateNameEdit(id, template.nameVi)
    }

    fun updateTemplateName(value: String) {
        if (!savingDraftState.value) templateNameEdit.value = templateNameEdit.value?.copy(nameVi = value, error = null)
    }

    fun cancelRenameTemplate() {
        if (!savingDraftState.value) templateNameEdit.value = null
    }

    fun confirmRenameTemplate() {
        val edit = templateNameEdit.value ?: return
        val template = (uiState.value as? NutritionUiState.Content)
            ?.mealTemplates?.firstOrNull { it.id == edit.id } ?: return
        val normalized = edit.nameVi.trim()
        if (normalized.length !in 1..60) {
            templateNameEdit.value = edit.copy(error = "Tên món cần từ 1 đến 60 ký tự.")
            return
        }
        if (savingDraftState.value) return
        savingDraftState.value = true
        viewModelScope.launch {
            try {
                nutritionRepository.saveMealTemplate(template.id, normalized, template.nutrients)
                templateNameEdit.value = null
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (_: Exception) {
                templateNameEdit.value = edit.copy(error = "Không thể đổi tên. Vui lòng thử lại.")
            } finally {
                savingDraftState.value = false
            }
        }
    }

    fun updateScanResult(
        dishName: String,
        totalCalories: Int,
        proteinGrams: Int,
        carbsGrams: Int,
        fatGrams: Int,
    ) {
        val current = scanResultState.value ?: return
        scanResultState.value = current.copy(
            dishName = dishName,
            totalCalories = totalCalories,
            proteinGrams = proteinGrams,
            carbsGrams = carbsGrams,
            fatGrams = fatGrams,
        )
    }

    fun addWater(waterMl: Int) {
        viewModelScope.launch {
            nutritionRepository.addWater(todayEpochDay, waterMl)
        }
    }

    fun clearSweat() {
        viewModelScope.launch { nutritionRepository.clearSweatPayment() }
    }

    fun resetDaily() {
        viewModelScope.launch { nutritionRepository.resetDaily() }
    }

    fun importNutritionFromCsv(csvText: String) {
        importNutritionFile("import.csv", csvText.toByteArray(Charsets.UTF_8))
    }

    fun importNutritionFile(fileName: String, fileData: ByteArray) {
        val dao = foodCatalogDao ?: return
        importSuccessState.value = null
        importErrorMessageState.value = null
        importWarningsState.value = emptyList()
        viewModelScope.launch {
            try {
                val batchId = System.currentTimeMillis().toString()
                val parseResult = kotlinx.coroutines.withContext(ioDispatcher) {
                    if (fileName.endsWith(".xlsx", ignoreCase = true)) {
                        NutritionXlsxParser.parse(fileData, batchId)
                    } else {
                        val csvText = String(fileData, Charsets.UTF_8)
                        NutritionCsvParser.parse(csvText, batchId)
                    }
                }
                
                if (parseResult.items.isEmpty()) {
                    importSuccessState.value = false
                    importErrorMessageState.value = parseResult.warnings.firstOrNull() ?: "Tệp trống hoặc không đúng cấu trúc."
                } else {
                    kotlinx.coroutines.withContext(ioDispatcher) {
                        dao.insertAll(parseResult.items)
                    }
                    importWarningsState.value = parseResult.warnings
                    importSuccessState.value = true
                }
            } catch (e: Exception) {
                importSuccessState.value = false
                importErrorMessageState.value = "Lỗi xử lý file: ${e.localizedMessage}"
            }
        }
    }

    suspend fun exportFoodCatalogToXlsx(): ByteArray {
        val dao = foodCatalogDao ?: return ByteArray(0)
        val items = kotlinx.coroutines.withContext(ioDispatcher) {
            dao.getAllNow()
        }
        return com.example.myapplication.core.nutrition.NutritionXlsxWriter.write(items)
    }

    fun searchFoodCatalog(query: String) {
        searchQueryState.value = query
    }

    fun clearFoodCatalog() {
        val dao = foodCatalogDao ?: return
        importSuccessState.value = null
        importErrorMessageState.value = null
        importWarningsState.value = emptyList()
        viewModelScope.launch {
            try {
                dao.deleteAll()
                searchQueryState.value = ""
                importSuccessState.value = null
                importErrorMessageState.value = null
            } catch (_: Exception) {}
        }
    }

    fun addFoodFromCatalog(food: com.example.myapplication.data.local.FoodCatalogEntity, servingGrams: Double) {
        viewModelScope.launch {
            try {
                val factor = servingGrams / food.gramsPerServing
                val calories = (food.caloriesPerServing * factor).roundToInt()
                val protein = (food.proteinPerServing * factor).roundToInt()
                val carbs = (food.carbsPerServing * factor).roundToInt()
                val fat = (food.fatPerServing * factor).roundToInt()

                val hour = java.time.LocalTime.now().hour
                val mealTime = when {
                    hour < 10 -> "BREAKFAST"
                    hour < 14 -> "LUNCH"
                    hour < 17 -> "SNACK"
                    else -> "DINNER"
                }

                nutritionRepository.logFood(
                    epochDay = todayEpochDay,
                    name = food.name,
                    mealTime = mealTime,
                    grams = servingGrams,
                    calories = calories,
                    proteinGrams = protein,
                    carbsGrams = carbs,
                    fatGrams = fat,
                    foodCatalogId = food.id
                )
            } catch (_: Exception) {}
        }
    }

    fun addToCart(food: com.example.myapplication.data.local.FoodCatalogEntity, grams: Double, mealTime: String) {
        val current = cartState.value.toMutableList()
        val existingIndex = current.indexOfFirst { it.food.id == food.id && it.mealTime == mealTime }
        if (existingIndex >= 0) {
            val existing = current[existingIndex]
            current[existingIndex] = existing.copy(grams = existing.grams + grams)
        } else {
            current.add(CartItem(food, grams, mealTime))
        }
        cartState.value = current
    }

    fun removeFromCart(foodCatalogId: Long, mealTime: String) {
        val current = cartState.value.toMutableList()
        current.removeAll { it.food.id == foodCatalogId && it.mealTime == mealTime }
        cartState.value = current
    }

    fun updateCartGrams(foodCatalogId: Long, mealTime: String, grams: Double) {
        val current = cartState.value.toMutableList()
        val index = current.indexOfFirst { it.food.id == foodCatalogId && it.mealTime == mealTime }
        if (index >= 0) {
            current[index] = current[index].copy(grams = grams)
        }
        cartState.value = current
    }

    fun clearCart() {
        cartState.value = emptyList()
    }

    fun confirmEatCart() {
        val cart = cartState.value
        if (cart.isEmpty()) return
        viewModelScope.launch {
            cart.forEach { item ->
                val factor = item.grams / item.food.gramsPerServing
                val calories = (item.food.caloriesPerServing * factor).roundToInt()
                val protein = (item.food.proteinPerServing * factor).roundToInt()
                val carbs = (item.food.carbsPerServing * factor).roundToInt()
                val fat = (item.food.fatPerServing * factor).roundToInt()
                nutritionRepository.logFood(
                    epochDay = todayEpochDay,
                    name = item.food.name,
                    mealTime = item.mealTime,
                    grams = item.grams,
                    calories = calories,
                    proteinGrams = protein,
                    carbsGrams = carbs,
                    fatGrams = fat,
                    foodCatalogId = if (item.food.id > 0) item.food.id else null
                )
            }
            cartState.value = emptyList()
        }
    }

    fun toggleFavoriteCatalog(id: Long, isFavorite: Boolean) {
        viewModelScope.launch {
            nutritionRepository.toggleFavorite(id, isFavorite)
        }
    }

    fun deleteLoggedFood(id: Long) {
        viewModelScope.launch {
            nutritionRepository.deleteLoggedFood(id)
        }
    }

    fun copyYesterdayMeals() {
        viewModelScope.launch {
            nutritionRepository.copyYesterdayMeals(todayEpochDay - 1, todayEpochDay)
        }
    }

    private fun updateDraft(transform: EditableNutritionDraft.() -> EditableNutritionDraft) {
        if (savingDraftState.value) return
        draftState.value = draftState.value?.transform()
    }
}

private data class CatalogStateParts(
    val items: List<com.example.myapplication.data.local.FoodCatalogEntity>,
    val count: Int,
    val query: String,
    val success: Boolean?,
    val error: String?,
    val warnings: List<String>,
)

private data class NutritionStateParts(
    val data: NutritionData,
    val today: NutritionDay,
)

private data class ScanStateParts(val scanning: Boolean, val result: ScanResult?, val error: String?)
private data class DraftStateParts(
    val draft: EditableNutritionDraft?,
    val saving: Boolean,
    val pendingDeleteTemplateId: Long?,
    val templateNameEdit: TemplateNameEdit?,
)
private data class NutritionInteractionParts(val scan: ScanStateParts, val draft: DraftStateParts)
private data class ParsedDraft(val nutrients: Nutrients?, val errors: Map<String, String>)

private fun ScanResult.toEditableDraft() = EditableNutritionDraft(
    nameVi = dishName,
    caloriesText = totalCalories.toString(),
    proteinText = proteinGrams.toString(),
    carbsText = carbsGrams.toString(),
    fatText = fatGrams.toString(),
    fiberText = "0",
)

private fun EditableNutritionDraft.validateAndParse(): ParsedDraft {
    val errors = mutableMapOf<String, String>()
    val normalizedName = nameVi.trim()
    if (normalizedName.length !in 1..60) errors["nameVi"] = "Tên món cần từ 1 đến 60 ký tự."
    fun parse(field: String, raw: String): Int? {
        val cleaned = raw.trim().replace(',', '.')
        val doubleValue = cleaned.toDoubleOrNull()
        if (doubleValue == null || doubleValue < 0.0) {
            errors[field] = "Nhập số không âm."
            return null
        }
        return doubleValue.roundToInt()
    }
    val calories = parse("calories", caloriesText)
    val protein = parse("protein", proteinText)
    val carbs = parse("carbs", carbsText)
    val fat = parse("fat", fatText)
    val fiberTextOrZero = if (fiberText.isBlank()) "0" else fiberText
    val fiber = parse("fiber", fiberTextOrZero)
    if (calories != null && calories <= 0) errors["calories"] = "Calo phải lớn hơn 0."
    return ParsedDraft(
        nutrients = if (errors.isEmpty()) Nutrients(calories!!, protein!!, carbs!!, fat!!, fiber!!) else null,
        errors = errors,
    )
}

private data class MealBuilderParts(
    val cart: List<CartItem>,
    val loggedFoods: List<com.example.myapplication.data.local.LoggedFoodEntity>,
    val favorites: List<com.example.myapplication.data.local.FoodCatalogEntity>,
    val recentFoods: List<com.example.myapplication.data.local.FoodCatalogEntity>
)
