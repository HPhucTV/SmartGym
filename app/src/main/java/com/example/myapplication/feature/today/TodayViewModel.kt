package com.example.myapplication.feature.today

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.myapplication.core.model.*
import com.example.myapplication.data.*
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class TodayViewModel(
    private val repository: WorkoutRepository,
    exercises: List<ExerciseDefinition>,
    private val restDayOverride: Flow<RestDayMode?> = flowOf(null),
    private val nutritionRepository: NutritionRepository? = null,
    private val currentEpochDay: () -> Long,
) : ViewModel() {
    private data class Operations(
        val completingSessionId: Long? = null,
        val pending: Set<Pair<Long, Int>> = emptySet(),
        val interactionError: Pair<Long, String>? = null,
        val completionError: Pair<Long, String>? = null,
    )

    private data class ActiveGoalFlowBundle(
        val goal: ActiveGoal?,
        val session: WorkoutSession?,
        val day: Long,
        val ops: Operations,
        val rest: RestDayMode?,
    )

    private val catalog = exercises.associateBy { it.id }
    private val today = MutableStateFlow(currentEpochDay())
    private val operations = MutableStateFlow(Operations())
    private val commandMutex = Mutex()
    private val _uiState = MutableStateFlow<TodayUiState>(TodayUiState.Loading)
    val uiState: StateFlow<TodayUiState> = _uiState.asStateFlow()
    private var retrySession: Long? = null

    private var lastGoalConfig: GoalConfig? = null
    private var lastSessionTitle: String? = ""
    private var lastSessionDue: Long = 0
    private val isRefreshingCoach = MutableStateFlow(false)

    private val okHttpClient = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()

    init {
        viewModelScope.launch {
            val nutritionFlow = nutritionRepository?.nutritionData ?: flowOf(NutritionData())
            val mainFlow = combine(
                repository.observeActiveGoal(),
                repository.observeCurrentWorkout(),
                today,
                operations,
                restDayOverride
            ) { goal, session, day, ops, rest ->
                ActiveGoalFlowBundle(goal, session, day, ops, rest)
            }

            combine(mainFlow, nutritionFlow) { bundle, nutrition ->
                resolve(bundle.goal, bundle.session, bundle.day, bundle.ops, bundle.rest, nutrition)
            }.collect { _uiState.value = it }
        }
    }

    fun refreshToday() { today.value = currentEpochDay() }

    fun setChecked(orderIndex: Int, checked: Boolean) {
        val state = _uiState.value as? TodayUiState.Workout ?: return
        if (state.isCompleting || orderIndex in state.pendingOrderIndices) return
        operations.update { it.copy(pending = it.pending + (state.sessionId to orderIndex), interactionError = null) }
        viewModelScope.launch {
            commandMutex.withLock {
                try {
                    repository.setExerciseChecked(state.sessionId, orderIndex, checked)
                } catch (cancelled: CancellationException) {
                    throw cancelled
                } catch (error: Exception) {
                    operations.update { it.copy(interactionError = state.sessionId to (error.message ?: "Lỗi phản hồi.")) }
                } finally {
                    operations.update { it.copy(pending = it.pending - (state.sessionId to orderIndex)) }
                }
            }
        }
    }

    fun completeWorkout() {
        val state = _uiState.value as? TodayUiState.Workout ?: return
        if (!state.canComplete || operations.value.completingSessionId != null ||
            operations.value.pending.any { it.first == state.sessionId }) return
        complete(state.sessionId)
    }

    fun retry() {
        val sessionId = retrySession ?: return
        if (operations.value.completingSessionId != null) return
        complete(sessionId)
    }

    private fun complete(sessionId: Long) {
        retrySession = sessionId
        operations.update { it.copy(completingSessionId = sessionId, completionError = null) }
        viewModelScope.launch {
            try {
                val result = commandMutex.withLock { repository.completeWorkout(sessionId, currentEpochDay()) }
                when (result) {
                    CompleteWorkoutResult.Completed, CompleteWorkoutResult.AlreadyCompleted -> {
                        nutritionRepository?.clearSweatPayment()
                    }
                    CompleteWorkoutResult.BlockedByUncheckedExercises -> {
                        operations.update { it.copy(
                            interactionError = sessionId to "Vẫn còn bài tập chưa được đánh dấu hoàn thành."
                        ) }
                    }
                }
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (_: Exception) {
                operations.update { it.copy(
                    completionError = sessionId to "Không thể hoàn thành buổi tập. Vui lòng thử lại."
                ) }
            } finally {
                operations.update {
                    if (it.completingSessionId == sessionId) {
                        it.copy(completingSessionId = null)
                    } else it
                }
            }
        }
    }

    fun refreshCoachTip() {
        val goalConfig = lastGoalConfig ?: return
        val sessionTitle = lastSessionTitle ?: ""
        val completedToday = lastSessionDue > today.value
        val nutrition = nutritionRepository ?: return

        if (isRefreshingCoach.value) return
        isRefreshingCoach.value = true
        operations.update { it.copy() }

        viewModelScope.launch {
            try {
                val nutritionData = nutrition.nutritionData.first()
                val limit = when (goalConfig.goal) {
                    FitnessGoal.MUSCLE_GAIN -> 2700
                    FitnessGoal.FAT_LOSS_CONDITIONING -> 1800
                    FitnessGoal.ENDURANCE -> 2200
                    FitnessGoal.GENERAL_FITNESS -> 2000
                }

                val jsonObject = JSONObject().apply {
                    put("goal", when (goalConfig.goal) {
                        FitnessGoal.MUSCLE_GAIN -> "Tăng cơ"
                        FitnessGoal.FAT_LOSS_CONDITIONING -> "Giảm cân"
                        FitnessGoal.ENDURANCE -> "Sức bền"
                        FitnessGoal.GENERAL_FITNESS -> "Khỏe mạnh"
                    })
                    put("level", when (goalConfig.level) {
                        ExperienceLevel.BEGINNER -> "Mới bắt đầu"
                        ExperienceLevel.INTERMEDIATE -> "Trung cấp"
                    })
                    put("sessionTitle", sessionTitle)
                    put("completedToday", completedToday)
                    put("caloriesEaten", nutritionData.caloriesEaten)
                    put("calorieLimit", limit)
                    put("proteinEaten", nutritionData.proteinEaten)
                    put("carbsEaten", nutritionData.carbsEaten)
                    put("fatEaten", nutritionData.fatEaten)
                    put("sweatActive", nutritionData.sweatActive)
                    put("sweatExerciseName", nutritionData.sweatExerciseName ?: "")
                    put("sweatExtraSets", nutritionData.sweatExtraSets)
                }

                val mediaType = "application/json; charset=utf-8".toMediaType()
                val requestBody = jsonObject.toString().toRequestBody(mediaType)
                val request = Request.Builder()
                    .url("http://10.0.2.2:3000/api/coach-review")
                    .post(requestBody)
                    .build()

                val reviewText = withContext(Dispatchers.IO) {
                    okHttpClient.newCall(request).execute().use { response ->
                        if (response.isSuccessful) {
                            val bodyString = response.body?.string()
                            if (!bodyString.isNullOrEmpty()) {
                                JSONObject(bodyString).optString("review")
                            } else null
                        } else null
                    }
                }

                if (!reviewText.isNullOrEmpty()) {
                    nutrition.updateAiCoachReview(reviewText)
                } else {
                    val fallbackAdvice = SmartCoachAdvisor.getLocalAdvice(
                        goalConfig.goal,
                        completedToday,
                        nutritionData,
                        sessionTitle
                    )
                    nutrition.updateAiCoachReview(fallbackAdvice)
                }
            } catch (e: Exception) {
                try {
                    val nutritionData = nutrition.nutritionData.first()
                    val fallbackAdvice = SmartCoachAdvisor.getLocalAdvice(
                        goalConfig.goal,
                        completedToday,
                        nutritionData,
                        sessionTitle
                    )
                    nutrition.updateAiCoachReview(fallbackAdvice)
                } catch (_: Exception) {}
            } finally {
                isRefreshingCoach.value = false
                operations.update { it.copy() }
            }
        }
    }

    private fun resolve(
        goal: ActiveGoal?,
        session: WorkoutSession?,
        day: Long,
        ops: Operations,
        restOverride: RestDayMode?,
        nutrition: NutritionData = NutritionData()
    ): TodayUiState {
        ops.completionError?.takeIf { it.first == session?.id }?.let { return TodayUiState.Error(it.second, canRetry = true) }
        if (goal == null) return TodayUiState.Error("Không tìm thấy mục tiêu đang hoạt động.")
        if (session == null) return TodayUiState.GoalComplete

        val isRecovery = session.dueEpochDay > day
        lastGoalConfig = goal.config
        lastSessionTitle = session.titleVi
        lastSessionDue = session.dueEpochDay

        val coachTip = nutrition.aiCoachReview?.takeIf { it.isNotEmpty() }
            ?: SmartCoachAdvisor.getLocalAdvice(
                goal = goal.config.goal,
                completedToday = isRecovery,
                nutrition = nutrition,
                sessionTitle = session.titleVi
            )

        if (isRecovery) return TodayUiState.Recovery(
            kind = if ((restOverride ?: goal.config.restDayMode) == RestDayMode.FULL_REST) RecoveryKind.FULL_REST else RecoveryKind.LIGHT_RECOVERY,
            nextDueEpochDay = session.dueEpochDay,
            coachTip = coachTip,
            isRefreshingCoach = isRefreshingCoach.value
        )

        val rows = session.exercises.sortedBy { it.orderIndex }.map { exercise ->
            val definition = catalog[exercise.exerciseId] ?: return TodayUiState.Error(
                "Không tìm thấy bài tập '${exercise.exerciseId}' trong dữ liệu ứng dụng.")

            val isSweatMatch = nutrition.sweatActive && nutrition.sweatExerciseId == exercise.exerciseId
            val finalPrescriptionText = if (isSweatMatch && nutrition.sweatExtraSets > 0) {
                exercise.prescription.displayText() + " (+${nutrition.sweatExtraSets} hiệp bù calo 🔥)"
            } else {
                exercise.prescription.displayText()
            }

            WorkoutRowUi(exercise.orderIndex, definition.nameVi, finalPrescriptionText,
                exercise.prescription.restSeconds, definition.instructionsVi, exercise.checked, exercise.exerciseId,
                definition.primaryMuscle)
        }
        val pending = ops.pending.filter { it.first == session.id }.map { it.second }.toSet()
        val checked = rows.count { it.checked }
        val hour = try { java.time.LocalTime.now().hour } catch (_: Exception) { 8 }
        return TodayUiState.Workout(
            sessionId = session.id,
            titleVi = session.titleVi,
            focusVi = session.focusVi,
            estimatedMinutes = session.estimatedMinutes,
            rows = rows,
            checkedCount = checked,
            total = rows.size,
            canComplete = rows.isNotEmpty() && checked == rows.size && pending.isEmpty(),
            isCompleting = ops.completingSessionId == session.id,
            pendingOrderIndices = pending,
            interactionError = ops.interactionError?.takeIf { it.first == session.id }?.second,
            greetingHour = hour,
            coachTip = coachTip,
            isRefreshingCoach = isRefreshingCoach.value
        )
    }
}

private fun ExercisePrescription.displayText(): String = when {
    durationSeconds != null -> "$durationSeconds giây"
    repsMin != null && repsMax != null -> if (repsMin == repsMax) "$sets × $repsMin" else "$sets × ${repsMin}–${repsMax}"
    else -> "$sets hiệp"
}
