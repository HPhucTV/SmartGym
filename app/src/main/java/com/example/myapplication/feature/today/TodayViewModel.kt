package com.example.myapplication.feature.today

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.myapplication.core.model.*
import com.example.myapplication.data.*
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

data class CelebrationState(
    val showConfetti: Boolean = false,
    val unlockedAchievements: List<com.example.myapplication.core.achievement.AchievementType> = emptyList(),
    val workoutTitle: String = "",
    val completedExercises: Int = 0,
    val totalExercises: Int = 0
)

class TodayViewModel(
    private val repository: WorkoutRepository,
    exercises: List<ExerciseDefinition>,
    private val restDayOverride: Flow<RestDayMode?> = flowOf(null),
    private val nutritionRepository: NutritionRepository? = null,
    private val achievementChecker: com.example.myapplication.core.achievement.AchievementChecker? = null,
    private val coachCoordinator: TodayCoachCoordinator? = null,
    private val cloudAiConsent: Flow<Boolean> = flowOf(false),
    private val currentEpochDay: () -> Long = { java.time.LocalDate.now().toEpochDay() },
) : ViewModel() {
    private val _celebration = MutableStateFlow(CelebrationState())
    val celebration: StateFlow<CelebrationState> = _celebration.asStateFlow()

    fun dismissCelebration() {
        _celebration.value = CelebrationState()
    }

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
    private var lastSessionTitle: String = ""
    private var lastSessionDue: Long = 0
    private val isRefreshingCoach = MutableStateFlow(false)

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

            combine(mainFlow, nutritionFlow, isRefreshingCoach) { bundle, nutrition, refreshingCoach ->
                resolve(
                    bundle.goal,
                    bundle.session,
                    bundle.day,
                    bundle.ops,
                    bundle.rest,
                    nutrition,
                    refreshingCoach,
                )
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
        val workoutState = _uiState.value as? TodayUiState.Workout
        val workoutTitle = workoutState?.titleVi ?: ""
        val checkedCount = workoutState?.checkedCount ?: 0
        val total = workoutState?.total ?: 0

        retrySession = sessionId
        operations.update { it.copy(completingSessionId = sessionId, completionError = null) }
        viewModelScope.launch {
            try {
                val result = commandMutex.withLock { repository.completeWorkout(sessionId, currentEpochDay()) }
                when (result) {
                    CompleteWorkoutResult.Completed -> {
                        nutritionRepository?.clearSweatPayment()
                        val completed = repository.observeCompletedWorkouts().first()
                        val activeGoal = repository.observeActiveGoal().first()
                        val totalSessions = activeGoal?.totalWorkouts ?: 0
                        val targetPerWeek = activeGoal?.config?.sessionsPerWeek ?: 0

                        val newlyUnlockedBadges = if (activeGoal == null) {
                            emptyList()
                        } else {
                            achievementChecker?.checkAll(
                                completed = completed,
                                activeGoalId = activeGoal.id,
                                totalProgramSessions = totalSessions,
                                targetPerWeek = targetPerWeek,
                            ).orEmpty()
                        }

                        _celebration.value = CelebrationState(
                            showConfetti = true,
                            unlockedAchievements = newlyUnlockedBadges,
                            workoutTitle = workoutTitle,
                            completedExercises = checkedCount,
                            totalExercises = total
                        )
                    }
                    CompleteWorkoutResult.AlreadyCompleted -> Unit
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
        val sessionTitle = lastSessionTitle
        val completedToday = lastSessionDue > today.value
        val nutrition = nutritionRepository ?: return

        if (isRefreshingCoach.value) return
        isRefreshingCoach.value = true

        viewModelScope.launch {
            try {
                val nutritionData = nutrition.nutritionData.first()
                val limit = when (goalConfig.goal) {
                    FitnessGoal.MUSCLE_GAIN -> 2700
                    FitnessGoal.FAT_LOSS_CONDITIONING -> 1800
                    FitnessGoal.ENDURANCE -> 2200
                    FitnessGoal.GENERAL_FITNESS -> 2000
                }

                val localAdvice = SmartCoachAdvisor.getLocalAdvice(
                    goalConfig.goal,
                    completedToday,
                    nutritionData,
                    sessionTitle,
                )
                val request = CoachReviewRequest(
                    goalVi = when (goalConfig.goal) {
                        FitnessGoal.MUSCLE_GAIN -> "Tăng cơ"
                        FitnessGoal.FAT_LOSS_CONDITIONING -> "Giảm cân"
                        FitnessGoal.ENDURANCE -> "Sức bền"
                        FitnessGoal.GENERAL_FITNESS -> "Khỏe mạnh"
                    },
                    levelVi = when (goalConfig.level) {
                        ExperienceLevel.BEGINNER -> "Mới bắt đầu"
                        ExperienceLevel.INTERMEDIATE -> "Trung cấp"
                    },
                    sessionTitle = sessionTitle,
                    completedToday = completedToday,
                    caloriesEaten = nutritionData.caloriesEaten,
                    calorieLimit = limit,
                    proteinEaten = nutritionData.proteinEaten,
                    carbsEaten = nutritionData.carbsEaten,
                    fatEaten = nutritionData.fatEaten,
                    sweatActive = nutritionData.sweatActive,
                    sweatExerciseName = nutritionData.sweatExerciseName.orEmpty(),
                    sweatExtraSets = nutritionData.sweatExtraSets,
                )
                val review = coachCoordinator?.review(
                    request = request,
                    cloudAiConsent = cloudAiConsent.first(),
                    localFallback = localAdvice,
                ) ?: localAdvice
                nutrition.updateAiCoachReview(review)
            } catch (cancelled: CancellationException) {
                throw cancelled
            } finally {
                isRefreshingCoach.value = false
            }
        }
    }

    private fun resolve(
        goal: ActiveGoal?,
        session: WorkoutSession?,
        day: Long,
        ops: Operations,
        restOverride: RestDayMode?,
        nutrition: NutritionData = NutritionData(),
        refreshingCoach: Boolean = false,
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
            isRefreshingCoach = refreshingCoach,
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
            isRefreshingCoach = refreshingCoach,
        )
    }
}

private fun ExercisePrescription.displayText(): String = when {
    durationSeconds != null -> "$durationSeconds giây"
    repsMin != null && repsMax != null -> if (repsMin == repsMax) "$sets × $repsMin" else "$sets × ${repsMin}–${repsMax}"
    else -> "$sets hiệp"
}
