package com.example.myapplication.feature.onboarding

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.myapplication.core.model.*
import com.example.myapplication.core.program.ProgramSelectionResult
import com.example.myapplication.core.program.ProgramSelector
import com.example.myapplication.core.program.TrainingSchedule
import com.example.myapplication.data.WorkoutRepository
import java.time.DayOfWeek
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class OnboardingViewModel(
    private val programs: List<ProgramTemplate>,
    private val workoutRepository: WorkoutRepository,
    private val currentEpochDay: () -> Long,
) : ViewModel() {
    private val _uiState = MutableStateFlow<OnboardingUiState>(editing(OnboardingStep.GOAL, OnboardingDraft()))
    val uiState: StateFlow<OnboardingUiState> = _uiState.asStateFlow()

    fun selectGoal(value: FitnessGoal) = updateDraft { OnboardingDraft(goal = value) }

    fun selectLevel(value: ExperienceLevel) = updateDraft {
        it.copy(
            level = value,
            equipment = null,
            sessionsPerWeek = null,
            durationWeeks = null,
            restDayMode = null,
            trainingDays = emptySet(),
            sessionDurationMinutes = null,
        )
    }

    fun selectEquipment(value: EquipmentProfile) = updateDraft { draft ->
        val durationWeeks = programs.firstOrNull {
            it.goal == draft.goal && it.level == draft.level && it.equipmentProfile == value
        }?.durationWeeks
        draft.copy(
            equipment = value,
            sessionsPerWeek = null,
            durationWeeks = durationWeeks,
            restDayMode = null,
            trainingDays = emptySet(),
            sessionDurationMinutes = null,
        )
    }

    /** Legacy helper retained for older callers while the UI migrates. */
    fun selectCommitment(sessionsPerWeek: Int, durationWeeks: Int) = updateDraft {
        it.copy(
            sessionsPerWeek = sessionsPerWeek,
            durationWeeks = durationWeeks,
            restDayMode = null,
            trainingDays = legacyTrainingDays(sessionsPerWeek),
            sessionDurationMinutes = 45,
        )
    }

    fun toggleTrainingDay(day: DayOfWeek) = updateDraft { draft ->
        val days = when {
            day in draft.trainingDays -> draft.trainingDays - day
            draft.trainingDays.size < 6 -> draft.trainingDays + day
            else -> draft.trainingDays
        }
        draft.copy(trainingDays = days, sessionsPerWeek = days.size.takeIf { it > 0 })
    }

    fun selectSessionDuration(minutes: Int) = updateDraft { draft ->
        if (minutes in TrainingSchedule.durationBuckets) draft.copy(sessionDurationMinutes = minutes) else draft
    }

    fun selectRestDayMode(value: RestDayMode) = updateDraft { it.copy(restDayMode = value) }

    fun next() {
        val state = _uiState.value as? OnboardingUiState.Editing ?: return
        if (state.isSaving) return
        if (canAdvance(state)) {
            _uiState.value = editing(OnboardingStep.entries[state.step.ordinal + 1], state.draft)
        }
    }

    fun back() {
        when (val state = _uiState.value) {
            is OnboardingUiState.Editing -> if (!state.isSaving && state.step != OnboardingStep.GOAL) {
                _uiState.value = editing(OnboardingStep.entries[state.step.ordinal - 1], state.draft)
            }
            is OnboardingUiState.Unsupported -> _uiState.value = editing(OnboardingStep.REVIEW, state.draft)
            OnboardingUiState.Created -> Unit
        }
    }

    fun createGoal() {
        val state = _uiState.value as? OnboardingUiState.Editing ?: return
        if (state.isSaving) return
        val draft = state.draft
        val matchingPrograms = programs.filter {
            it.goal == draft.goal && it.level == draft.level && it.equipmentProfile == draft.equipment
        }
        if (matchingPrograms.size != 1) {
            _uiState.value = OnboardingUiState.Unsupported(
                draft,
                "Chưa có chương trình phù hợp với mục tiêu, trình độ và dụng cụ đã chọn.",
                programs.map(::programLabel).distinct(),
            )
            return
        }
        val baseProgram = matchingPrograms.single()
        val config = GoalConfig(
            goal = draft.goal ?: return,
            level = draft.level ?: return,
            equipmentProfile = draft.equipment ?: return,
            sessionsPerWeek = draft.trainingDays.size.takeIf { it in 1..6 } ?: return,
            durationWeeks = baseProgram.durationWeeks,
            restDayMode = draft.restDayMode ?: return,
            trainingDays = draft.trainingDays,
            sessionDurationMinutes = draft.sessionDurationMinutes ?: return,
        )
        when (val selection = ProgramSelector.select(config, listOf(baseProgram))) {
            ProgramSelectionResult.Unsupported -> _uiState.value = OnboardingUiState.Unsupported(
                draft,
                "Chưa có chương trình phù hợp với lựa chọn này. Hãy thay đổi mục tiêu, trình độ hoặc dụng cụ.",
                programs.map(::programLabel).distinct(),
            )
            is ProgramSelectionResult.Found -> {
                _uiState.value = state.copy(isSaving = true, saveError = null)
                viewModelScope.launch {
                    try {
                        workoutRepository.createGoal(config, selection.program, currentEpochDay())
                        _uiState.value = OnboardingUiState.Created
                    } catch (cancelled: CancellationException) {
                        throw cancelled
                    } catch (_: Exception) {
                        _uiState.value = editing(state.step, draft).copy(
                            saveError = "Không thể lưu mục tiêu. Vui lòng thử lại.",
                        )
                    }
                }
            }
        }
    }

    private fun updateDraft(transform: (OnboardingDraft) -> OnboardingDraft) {
        val state = _uiState.value as? OnboardingUiState.Editing ?: return
        if (state.isSaving) return
        _uiState.value = editing(state.step, transform(state.draft))
    }

    private fun editing(step: OnboardingStep, draft: OnboardingDraft) = OnboardingUiState.Editing(
        step = step,
        draft = draft,
        options = OnboardingOptions(
            goals = programs.map { it.goal }.toSet(),
            levels = programs.filter { draft.goal == null || it.goal == draft.goal }.map { it.level }.toSet(),
            equipment = programs.filter {
                (draft.goal == null || it.goal == draft.goal) &&
                    (draft.level == null || it.level == draft.level)
            }.map { it.equipmentProfile }.toSet(),
            commitments = emptySet(),
            restDayModes = RestDayMode.entries.toSet(),
        ),
    )

    private fun canAdvance(state: OnboardingUiState.Editing): Boolean = when (state.step) {
        OnboardingStep.GOAL -> state.draft.goal != null
        OnboardingStep.LEVEL -> state.draft.level != null
        OnboardingStep.EQUIPMENT -> state.draft.equipment != null
        OnboardingStep.TRAINING_DAYS -> state.draft.trainingDays.size in 1..6
        OnboardingStep.SESSION_DURATION -> state.draft.sessionDurationMinutes != null
        OnboardingStep.REST_BEHAVIOR -> state.draft.restDayMode != null
        OnboardingStep.REVIEW -> true
    }
}

internal fun programLabel(program: ProgramTemplate): String = listOf(
    program.goal.labelVi(),
    program.level.labelVi(),
    program.equipmentProfile.labelVi(),
    "Chương trình ${program.durationWeeks} tuần",
).joinToString(" · ")

internal fun FitnessGoal.labelVi() = when (this) {
    FitnessGoal.MUSCLE_GAIN -> "Tăng cơ"
    FitnessGoal.FAT_LOSS_CONDITIONING -> "Giảm mỡ & thể lực"
    FitnessGoal.ENDURANCE -> "Sức bền"
    FitnessGoal.GENERAL_FITNESS -> "Thể lực tổng quát"
}

internal fun ExperienceLevel.labelVi() = if (this == ExperienceLevel.BEGINNER) "Người mới" else "Trung cấp"

internal fun EquipmentProfile.labelVi() = when (this) {
    EquipmentProfile.BODYWEIGHT_ONLY -> "Không dụng cụ"
    EquipmentProfile.DUMBBELLS -> "Tạ đơn"
    EquipmentProfile.RESISTANCE_BANDS -> "Dây kháng lực"
    EquipmentProfile.FULL_GYM -> "Phòng gym đầy đủ"
}

internal fun RestDayMode.labelVi() = if (this == RestDayMode.FULL_REST) "Nghỉ hoàn toàn" else "Phục hồi nhẹ"
