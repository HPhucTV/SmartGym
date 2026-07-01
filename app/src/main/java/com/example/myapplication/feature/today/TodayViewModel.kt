package com.example.myapplication.feature.today

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.myapplication.core.model.*
import com.example.myapplication.data.*
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

class TodayViewModel(
    private val repository: WorkoutRepository,
    exercises: List<ExerciseDefinition>,
    private val currentEpochDay: () -> Long,
) : ViewModel() {
    private val catalog = exercises.associateBy { it.id }
    private val _uiState = MutableStateFlow<TodayUiState>(TodayUiState.Loading)
    val uiState: StateFlow<TodayUiState> = _uiState.asStateFlow()
    private var completing = false
    private var retrySession: Long? = null

    init {
        viewModelScope.launch {
            combine(repository.observeActiveGoal(), repository.observeCurrentWorkout(), ::resolve)
                .collect { _uiState.value = it }
        }
    }

    fun setChecked(orderIndex: Int, checked: Boolean) {
        val state = _uiState.value as? TodayUiState.Workout ?: return
        if (state.isCompleting || state.rows.none { it.orderIndex == orderIndex }) return
        viewModelScope.launch {
            try {
                repository.setExerciseChecked(state.sessionId, orderIndex, checked)
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (_: Exception) {
                _uiState.value = TodayUiState.Error("Không thể cập nhật bài tập. Vui lòng thử lại.")
            }
        }
    }

    fun completeWorkout() {
        val state = _uiState.value as? TodayUiState.Workout ?: return
        if (!state.canComplete || completing) return
        complete(state.sessionId, state)
    }

    fun retry() {
        val sessionId = retrySession ?: return
        if (completing) return
        complete(sessionId, null)
    }

    private fun complete(sessionId: Long, visibleWorkout: TodayUiState.Workout?) {
        completing = true
        retrySession = sessionId
        if (visibleWorkout != null) _uiState.value = visibleWorkout.copy(isCompleting = true)
        viewModelScope.launch {
            try {
                when (repository.completeWorkout(sessionId, currentEpochDay())) {
                    CompleteWorkoutResult.Completed, CompleteWorkoutResult.AlreadyCompleted -> Unit
                    CompleteWorkoutResult.BlockedByUncheckedExercises -> {
                        _uiState.value = TodayUiState.Error("Vẫn còn bài tập chưa được đánh dấu hoàn thành.")
                        retrySession = null
                    }
                }
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (_: Exception) {
                _uiState.value = TodayUiState.Error("Không thể hoàn thành buổi tập. Vui lòng thử lại.", canRetry = true)
            } finally {
                completing = false
            }
        }
    }

    private fun resolve(goal: ActiveGoal?, session: WorkoutSession?): TodayUiState {
        if (goal == null) return TodayUiState.Error("Không tìm thấy mục tiêu đang hoạt động.")
        if (session == null) return TodayUiState.GoalComplete
        val today = currentEpochDay()
        if (session.dueEpochDay > today) return TodayUiState.Recovery(
            if (goal.config.restDayMode == RestDayMode.FULL_REST) RecoveryKind.FULL_REST else RecoveryKind.LIGHT_RECOVERY,
            session.dueEpochDay,
        )
        val rows = session.exercises.sortedBy { it.orderIndex }.map { exercise ->
            val definition = catalog[exercise.exerciseId] ?: return TodayUiState.Error(
                "Không tìm thấy bài tập '${exercise.exerciseId}' trong dữ liệu ứng dụng.")
            WorkoutRowUi(exercise.orderIndex, definition.nameVi, exercise.prescription.displayText(),
                exercise.prescription.restSeconds, definition.instructionsVi, exercise.checked)
        }
        val checked = rows.count { it.checked }
        return TodayUiState.Workout(session.id, session.titleVi, session.focusVi, session.estimatedMinutes,
            rows, checked, rows.size, rows.isNotEmpty() && checked == rows.size, completing)
    }
}

private fun ExercisePrescription.displayText(): String = when {
    durationSeconds != null -> "$durationSeconds giây"
    repsMin != null && repsMax != null -> if (repsMin == repsMax) "$sets × $repsMin" else "$sets × $repsMin–$repsMax"
    else -> "$sets hiệp"
}
