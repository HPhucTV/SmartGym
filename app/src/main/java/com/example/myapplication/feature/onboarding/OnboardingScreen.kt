package com.example.myapplication.feature.onboarding

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.myapplication.core.model.*
import com.example.myapplication.data.WorkoutRepository
import com.example.myapplication.ui.theme.EnergyOrange
import com.example.myapplication.ui.theme.customColors
import java.time.LocalDate

@Composable
fun OnboardingRoute(programs: List<ProgramTemplate>, workoutRepository: WorkoutRepository, replacementMode: Boolean = false) {
    val factory = object : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            OnboardingViewModel(programs, workoutRepository) { LocalDate.now().toEpochDay() } as T
    }
    val vm: OnboardingViewModel = viewModel(factory = factory)
    val state by vm.uiState.collectAsStateWithLifecycle()
    OnboardingScreen(
        state = state,
        replacementMode = replacementMode,
        onGoalSelected = vm::selectGoal,
        onLevelSelected = vm::selectLevel,
        onEquipmentSelected = vm::selectEquipment,
        onCommitmentSelected = { vm.selectCommitment(it.sessionsPerWeek, it.durationWeeks) },
        onRestDayModeSelected = vm::selectRestDayMode,
        onNext = vm::next,
        onBack = vm::back,
        onCreateGoal = vm::createGoal,
    )
}

@Composable
fun OnboardingScreen(
    state: OnboardingUiState,
    replacementMode: Boolean = false,
    onGoalSelected: (FitnessGoal) -> Unit = {},
    onLevelSelected: (ExperienceLevel) -> Unit = {},
    onEquipmentSelected: (EquipmentProfile) -> Unit = {},
    onCommitmentSelected: (WorkoutCommitment) -> Unit = {},
    onRestDayModeSelected: (RestDayMode) -> Unit = {},
    onNext: () -> Unit = {},
    onBack: () -> Unit = {},
    onCreateGoal: () -> Unit = {},
) {
    val colors = MaterialTheme.colorScheme

    Surface(color = colors.background, modifier = Modifier.fillMaxSize()) {
        when (state) {
            is OnboardingUiState.Editing -> EditingContent(state, replacementMode, onGoalSelected, onLevelSelected,
                onEquipmentSelected, onCommitmentSelected, onRestDayModeSelected, onNext, onBack, onCreateGoal)
            is OnboardingUiState.Unsupported -> UnsupportedContent(state, onBack)
            OnboardingUiState.Created -> Box(Modifier.fillMaxSize())
        }
    }
}

@Composable
private fun EditingContent(
    state: OnboardingUiState.Editing,
    replacementMode: Boolean,
    onGoal: (FitnessGoal) -> Unit,
    onLevel: (ExperienceLevel) -> Unit,
    onEquipment: (EquipmentProfile) -> Unit,
    onCommitment: (WorkoutCommitment) -> Unit,
    onRest: (RestDayMode) -> Unit,
    onNext: () -> Unit,
    onBack: () -> Unit,
    onCreate: () -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    val title = when (state.step) {
        OnboardingStep.GOAL -> "Mục tiêu của bạn"
        OnboardingStep.LEVEL -> "Trình độ hiện tại"
        OnboardingStep.EQUIPMENT -> "Dụng cụ sẵn có"
        OnboardingStep.COMMITMENT -> "Lịch tập phù hợp"
        OnboardingStep.REST_BEHAVIOR -> "Ngày nghỉ"
        OnboardingStep.REVIEW -> "Xem lại mục tiêu"
    }
    LazyColumn(
        modifier = Modifier.fillMaxSize().padding(horizontal = 20.dp),
        contentPadding = PaddingValues(vertical = 28.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item { Text(if (replacementMode) "Đổi mục tiêu" else "Tạo mục tiêu", color = EnergyOrange, style = MaterialTheme.typography.labelLarge) }
        item { Text(title, color = customColors.primaryText, style = MaterialTheme.typography.headlineMedium) }
        item { Text(if (replacementMode) "Lịch sử tập luyện đã hoàn thành vẫn được giữ lại." else "Chọn chương trình có sẵn để nhận bài tập mỗi ngày.", color = customColors.primaryText.copy(alpha = .72f)) }
        when (state.step) {
            OnboardingStep.GOAL -> items(state.options.goals.toList()) { value -> Choice(value.labelVi(), state.draft.goal == value, "onboarding-goal-${value.name}") { onGoal(value) } }
            OnboardingStep.LEVEL -> items(state.options.levels.toList()) { value -> Choice(value.labelVi(), state.draft.level == value, "onboarding-level-${value.name}") { onLevel(value) } }
            OnboardingStep.EQUIPMENT -> items(state.options.equipment.toList()) { value -> Choice(value.labelVi(), state.draft.equipment == value, "onboarding-equipment-${value.name}") { onEquipment(value) } }
            OnboardingStep.COMMITMENT -> items(state.options.commitments.toList()) { value -> Choice("${value.sessionsPerWeek} buổi/tuần · ${value.durationWeeks} tuần", state.draft.sessionsPerWeek == value.sessionsPerWeek && state.draft.durationWeeks == value.durationWeeks, "onboarding-commitment-${value.sessionsPerWeek}-${value.durationWeeks}") { onCommitment(value) } }
            OnboardingStep.REST_BEHAVIOR -> items(state.options.restDayModes.toList()) { value -> Choice(value.labelVi(), state.draft.restDayMode == value, "onboarding-rest-${value.name}") { onRest(value) } }
            OnboardingStep.REVIEW -> item { ReviewCard(state.draft) }
        }
        state.saveError?.let { error -> item { Text(error, color = colors.error) } }
        item {
            Row(Modifier.fillMaxWidth().padding(top = 12.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                if (state.step != OnboardingStep.GOAL) OutlinedButton(
                    onClick = onBack,
                    enabled = !state.isSaving,
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = EnergyOrange),
                    border = BorderStroke(1.dp, EnergyOrange),
                    modifier = Modifier.weight(1f)
                ) { Text("Quay lại") }
                Button(
                    onClick = if (state.step == OnboardingStep.REVIEW) onCreate else onNext,
                    enabled = !state.isSaving && canAdvance(state),
                    colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange, contentColor = Color.White),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.weight(1f).testTag(if (state.step == OnboardingStep.REVIEW) "onboarding-create-goal" else "onboarding-next"),
                ) { Text(if (state.isSaving) "Đang tạo…" else if (state.step == OnboardingStep.REVIEW) "Tạo mục tiêu" else "Tiếp tục") }
            }
        }
    }
}

@Composable private fun Choice(label: String, selected: Boolean, testTag: String, onClick: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    Surface(
        border = BorderStroke(1.dp, if (selected) EnergyOrange else colors.outline),
        color = if (selected) customColors.orangeLight else colors.background,
        contentColor = customColors.primaryText,
        shape = RoundedCornerShape(14.dp),
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 56.dp)
            .testTag(testTag)
            .selectable(selected = selected, role = Role.RadioButton, onClick = onClick),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                label,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
                color = customColors.primaryText,
                modifier = Modifier.weight(1f)
            )
            RadioButton(
                selected = selected,
                onClick = null,
                colors = RadioButtonDefaults.colors(
                    selectedColor = EnergyOrange,
                    unselectedColor = colors.outline
                )
            )
        }
    }
}

@Composable private fun ReviewCard(draft: OnboardingDraft) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    Card(
        colors = CardDefaults.cardColors(containerColor = colors.surfaceVariant),
        shape = RoundedCornerShape(18.dp),
        border = BorderStroke(1.dp, colors.outline),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(
                "Tóm tắt cấu hình mục tiêu",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = EnergyOrange
            )
            HorizontalDivider(color = colors.outline.copy(alpha = 0.5f))

            ReviewItem("🎯 Mục tiêu:", draft.goal?.labelVi().orEmpty())
            ReviewItem("💪 Trình độ:", draft.level?.labelVi().orEmpty())
            ReviewItem("🏋️ Thiết bị:", draft.equipment?.labelVi().orEmpty())
            ReviewItem("📅 Tần suất:", "${draft.sessionsPerWeek} buổi/tuần · ${draft.durationWeeks} tuần")
            ReviewItem("🧘 Ngày nghỉ:", draft.restDayMode?.labelVi().orEmpty())
        }
    }
}

@Composable
private fun ReviewItem(label: String, value: String) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, style = MaterialTheme.typography.bodyMedium, color = customColors.mutedText)
        Text(
            value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Bold,
            color = customColors.primaryText
        )
    }
}

@Composable private fun UnsupportedContent(state: OnboardingUiState.Unsupported, onBack: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    LazyColumn(Modifier.fillMaxSize().padding(20.dp), contentPadding = PaddingValues(vertical = 28.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item { Text("Chưa thể tạo mục tiêu", color = customColors.primaryText, style = MaterialTheme.typography.headlineMedium) }
        item { Text(state.explanation, color = customColors.primaryText) }
        item { Text("Các lựa chọn đang được hỗ trợ", color = customColors.primaryText, style = MaterialTheme.typography.titleMedium) }
        items(state.alternatives) { Text(it, modifier = Modifier.fillMaxWidth().padding(12.dp), color = customColors.primaryText) }
        item { Button(onClick = onBack, colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange), shape = RoundedCornerShape(12.dp)) { Text("Thay đổi lựa chọn") } }
    }
}

private fun canAdvance(state: OnboardingUiState.Editing) = when (state.step) {
    OnboardingStep.GOAL -> state.draft.goal != null
    OnboardingStep.LEVEL -> state.draft.level != null
    OnboardingStep.EQUIPMENT -> state.draft.equipment != null
    OnboardingStep.COMMITMENT -> state.draft.sessionsPerWeek != null && state.draft.durationWeeks != null
    OnboardingStep.REST_BEHAVIOR -> state.draft.restDayMode != null
    OnboardingStep.REVIEW -> true
}
