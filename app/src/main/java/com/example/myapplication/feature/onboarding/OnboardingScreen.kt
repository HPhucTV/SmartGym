package com.example.myapplication.feature.onboarding

import androidx.compose.foundation.BorderStroke
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
import java.time.DayOfWeek
import java.time.LocalDate

@Composable
fun OnboardingRoute(
    programs: List<ProgramTemplate>,
    workoutRepository: WorkoutRepository,
    replacementMode: Boolean = false,
) {
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
        onTrainingDayToggle = vm::toggleTrainingDay,
        onSessionDurationSelected = vm::selectSessionDuration,
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
    onTrainingDayToggle: (DayOfWeek) -> Unit = {},
    onSessionDurationSelected: (Int) -> Unit = {},
    onRestDayModeSelected: (RestDayMode) -> Unit = {},
    onNext: () -> Unit = {},
    onBack: () -> Unit = {},
    onCreateGoal: () -> Unit = {},
) {
    Surface(
        color = MaterialTheme.colorScheme.background,
        modifier = Modifier
            .fillMaxSize()
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        when (state) {
            is OnboardingUiState.Editing -> EditingContent(
                state,
                replacementMode,
                onGoalSelected,
                onLevelSelected,
                onEquipmentSelected,
                onTrainingDayToggle,
                onSessionDurationSelected,
                onRestDayModeSelected,
                onNext,
                onBack,
                onCreateGoal,
            )
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
    onTrainingDay: (DayOfWeek) -> Unit,
    onDuration: (Int) -> Unit,
    onRest: (RestDayMode) -> Unit,
    onNext: () -> Unit,
    onBack: () -> Unit,
    onCreate: () -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors
    val stepNumber = state.step.ordinal + 1

    Column(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier.padding(start = 20.dp, end = 20.dp, top = 24.dp, bottom = 12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(if (replacementMode) "Đổi mục tiêu" else "Tạo mục tiêu", color = EnergyOrange, style = MaterialTheme.typography.labelLarge)
                Text("Bước $stepNumber/7", color = customColors.mutedText, style = MaterialTheme.typography.labelLarge)
            }
            LinearProgressIndicator(
                progress = { stepNumber / 7f },
                modifier = Modifier.fillMaxWidth().height(6.dp),
                color = EnergyOrange,
                trackColor = customColors.orangeLight,
            )
            Text(stepTitle(state.step), color = customColors.primaryText, style = MaterialTheme.typography.headlineMedium)
            Text(stepExplanation(state.step, replacementMode), color = customColors.mutedText)
            SelectionSummary(state.draft)
        }

        LazyColumn(
            modifier = Modifier.weight(1f).fillMaxWidth(),
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp, top = 4.dp, bottom = 16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            when (state.step) {
                OnboardingStep.GOAL -> items(state.options.goals.toList()) { value ->
                    Choice(value.labelVi(), goalExplanation(value), state.draft.goal == value, "onboarding-goal-${value.name}") { onGoal(value) }
                }
                OnboardingStep.LEVEL -> items(state.options.levels.toList()) { value ->
                    Choice(value.labelVi(), levelExplanation(value), state.draft.level == value, "onboarding-level-${value.name}") { onLevel(value) }
                }
                OnboardingStep.EQUIPMENT -> items(state.options.equipment.toList()) { value ->
                    Choice(value.labelVi(), equipmentExplanation(value), state.draft.equipment == value, "onboarding-equipment-${value.name}") { onEquipment(value) }
                }
                OnboardingStep.TRAINING_DAYS -> items(DayOfWeek.entries) { day ->
                    Choice(day.labelVi(), dayHint(day), day in state.draft.trainingDays, "onboarding-day-${day.name}") { onTrainingDay(day) }
                }
                OnboardingStep.SESSION_DURATION -> items(listOf(30, 45, 60, 75, 90)) { minutes ->
                    Choice("Tối đa $minutes phút", durationExplanation(minutes), state.draft.sessionDurationMinutes == minutes, "onboarding-duration-$minutes") { onDuration(minutes) }
                }
                OnboardingStep.REST_BEHAVIOR -> items(state.options.restDayModes.toList()) { value ->
                    Choice(value.labelVi(), restExplanation(value), state.draft.restDayMode == value, "onboarding-rest-${value.name}") { onRest(value) }
                }
                OnboardingStep.REVIEW -> item { ReviewCard(state.draft) }
            }
            state.saveError?.let { error -> item { Text(error, color = colors.error) } }
        }

        Surface(shadowElevation = 8.dp, color = colors.background) {
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 14.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                if (state.step != OnboardingStep.GOAL) {
                    OutlinedButton(
                        onClick = onBack,
                        enabled = !state.isSaving,
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = EnergyOrange),
                        border = BorderStroke(1.dp, EnergyOrange),
                        modifier = Modifier.weight(1f).heightIn(min = 52.dp),
                    ) { Text("Quay lại") }
                }
                Button(
                    onClick = if (state.step == OnboardingStep.REVIEW) onCreate else onNext,
                    enabled = !state.isSaving && canAdvance(state),
                    colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange, contentColor = Color.White),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.weight(1f).heightIn(min = 52.dp).testTag(if (state.step == OnboardingStep.REVIEW) "onboarding-create-goal" else "onboarding-next"),
                ) {
                    Text(if (state.isSaving) "Đang tạo…" else if (state.step == OnboardingStep.REVIEW) "Tạo mục tiêu" else "Tiếp tục")
                }
            }
        }
    }
}

@Composable
private fun SelectionSummary(draft: OnboardingDraft) {
    val values = listOfNotNull(
        draft.goal?.labelVi(),
        draft.level?.labelVi(),
        draft.equipment?.labelVi(),
        draft.trainingDays.takeIf { it.isNotEmpty() }?.let { "${it.size} buổi/tuần" },
        draft.sessionDurationMinutes?.let { "$it phút" },
    )
    if (values.isEmpty()) return
    Surface(color = MaterialTheme.colorScheme.surfaceVariant, shape = RoundedCornerShape(10.dp)) {
        Text(
            values.joinToString("  •  "),
            modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 9.dp),
            color = MaterialTheme.colorScheme.customColors.mutedText,
            style = MaterialTheme.typography.bodySmall,
        )
    }
}

@Composable
private fun Choice(title: String, subtitle: String, selected: Boolean, testTag: String, onClick: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors
    Surface(
        border = BorderStroke(1.dp, if (selected) EnergyOrange else colors.outline),
        color = if (selected) customColors.orangeLight else colors.background,
        contentColor = customColors.primaryText,
        shape = RoundedCornerShape(14.dp),
        modifier = Modifier.fillMaxWidth().heightIn(min = 72.dp).testTag(testTag)
            .selectable(selected = selected, role = Role.RadioButton, onClick = onClick),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 18.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(title, style = MaterialTheme.typography.bodyLarge, fontWeight = if (selected) FontWeight.Bold else FontWeight.SemiBold, color = customColors.primaryText)
                Text(subtitle, style = MaterialTheme.typography.bodySmall, color = customColors.mutedText)
            }
            RadioButton(
                selected = selected,
                onClick = null,
                colors = RadioButtonDefaults.colors(selectedColor = EnergyOrange, unselectedColor = colors.outline),
            )
        }
    }
}

@Composable
private fun ReviewCard(draft: OnboardingDraft) {
    val colors = MaterialTheme.colorScheme
    Card(
        colors = CardDefaults.cardColors(containerColor = colors.surfaceVariant),
        shape = RoundedCornerShape(18.dp),
        border = BorderStroke(1.dp, colors.outline),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("Kế hoạch của bạn", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = colors.customColors.primaryText)
            Text("Chương trình được chọn từ preset đã kiểm duyệt, không tạo bài ngẫu nhiên.", color = colors.customColors.mutedText)
            HorizontalDivider(color = colors.outline)
            ReviewItem("Mục tiêu", draft.goal?.labelVi().orEmpty())
            ReviewItem("Trình độ", draft.level?.labelVi().orEmpty())
            ReviewItem("Dụng cụ", draft.equipment?.labelVi().orEmpty())
            ReviewItem("Ngày tập", draft.trainingDays.sortedBy { it.value }.joinToString(", ") { it.shortLabelVi() })
            ReviewItem("Tần suất", "${draft.trainingDays.size} buổi/tuần")
            ReviewItem("Mỗi buổi", "Tối đa ${draft.sessionDurationMinutes ?: 0} phút")
            ReviewItem("Thời gian chương trình", "${draft.durationWeeks ?: 0} tuần")
            ReviewItem("Ngày nghỉ", draft.restDayMode?.labelVi().orEmpty())
        }
    }
}

@Composable
private fun ReviewItem(label: String, value: String) {
    val customColors = MaterialTheme.colorScheme.customColors
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.Top) {
        Text(label, style = MaterialTheme.typography.bodyMedium, color = customColors.mutedText, modifier = Modifier.weight(.45f))
        Text(value, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold, color = customColors.primaryText, modifier = Modifier.weight(.55f))
    }
}

@Composable
private fun UnsupportedContent(state: OnboardingUiState.Unsupported, onBack: () -> Unit) {
    val customColors = MaterialTheme.colorScheme.customColors
    LazyColumn(Modifier.fillMaxSize().padding(20.dp), contentPadding = PaddingValues(vertical = 28.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item { Text("Chưa thể tạo mục tiêu", color = customColors.primaryText, style = MaterialTheme.typography.headlineMedium) }
        item { Text(state.explanation, color = customColors.primaryText) }
        item { Text("Các cấu hình đang được hỗ trợ", color = customColors.primaryText, style = MaterialTheme.typography.titleMedium) }
        items(state.alternatives) { Text(it, modifier = Modifier.fillMaxWidth().padding(12.dp), color = customColors.primaryText) }
        item { Button(onClick = onBack, colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange)) { Text("Thay đổi lựa chọn") } }
    }
}

private fun canAdvance(state: OnboardingUiState.Editing) = when (state.step) {
    OnboardingStep.GOAL -> state.draft.goal != null
    OnboardingStep.LEVEL -> state.draft.level != null
    OnboardingStep.EQUIPMENT -> state.draft.equipment != null
    OnboardingStep.TRAINING_DAYS -> state.draft.trainingDays.size in 1..6
    OnboardingStep.SESSION_DURATION -> state.draft.sessionDurationMinutes != null
    OnboardingStep.REST_BEHAVIOR -> state.draft.restDayMode != null
    OnboardingStep.REVIEW -> true
}

private fun stepTitle(step: OnboardingStep) = when (step) {
    OnboardingStep.GOAL -> "Bạn muốn đạt điều gì?"
    OnboardingStep.LEVEL -> "Kinh nghiệm tập luyện"
    OnboardingStep.EQUIPMENT -> "Bạn có dụng cụ gì?"
    OnboardingStep.TRAINING_DAYS -> "Chọn ngày tập"
    OnboardingStep.SESSION_DURATION -> "Thời gian mỗi buổi"
    OnboardingStep.REST_BEHAVIOR -> "Bạn muốn nghỉ thế nào?"
    OnboardingStep.REVIEW -> "Xem lại kế hoạch"
}

private fun stepExplanation(step: OnboardingStep, replacementMode: Boolean) = when (step) {
    OnboardingStep.GOAL -> if (replacementMode) "Lịch sử hoàn thành vẫn được giữ lại." else "Mục tiêu quyết định trọng tâm của chương trình."
    OnboardingStep.LEVEL -> "Chọn đúng mức để khối lượng tập không quá nhẹ hoặc quá sức."
    OnboardingStep.EQUIPMENT -> "App chỉ phát những bài bạn có thể thực hiện với dụng cụ này."
    OnboardingStep.TRAINING_DAYS -> "Chọn ngày bạn thực sự có thể duy trì."
    OnboardingStep.SESSION_DURATION -> "Hệ thống điều chỉnh số bài theo thời gian bạn có."
    OnboardingStep.REST_BEHAVIOR -> "Ngày không tập chính có thể nghỉ hoàn toàn hoặc vận động nhẹ."
    OnboardingStep.REVIEW -> "Kiểm tra lịch trước khi app tạo các buổi tập offline."
}

private fun goalExplanation(value: FitnessGoal) = when (value) {
    FitnessGoal.MUSCLE_GAIN -> "Ưu tiên sức mạnh và phát triển nhóm cơ."
    FitnessGoal.FAT_LOSS_CONDITIONING -> "Kết hợp vận động toàn thân và sức bền."
    FitnessGoal.ENDURANCE -> "Tăng khả năng duy trì vận động lâu hơn."
    FitnessGoal.GENERAL_FITNESS -> "Cân bằng sức mạnh, vận động và thể lực nền."
}

private fun levelExplanation(value: ExperienceLevel) = if (value == ExperienceLevel.BEGINNER) "Kỹ thuật cơ bản, khối lượng vừa phải." else "Khối lượng cao hơn và bài phối hợp đa dạng hơn."

private fun equipmentExplanation(value: EquipmentProfile) = when (value) {
    EquipmentProfile.BODYWEIGHT_ONLY -> "Tập ở bất kỳ đâu, không cần thiết bị."
    EquipmentProfile.DUMBBELLS -> "Chương trình xoay quanh tạ đơn và trọng lượng cơ thể."
    EquipmentProfile.RESISTANCE_BANDS -> "Phù hợp khi có dây kháng lực."
    EquipmentProfile.FULL_GYM -> "Sử dụng máy, cáp, thanh đòn và ghế tập."
}

private fun durationExplanation(minutes: Int) = when (minutes) {
    30 -> "Khoảng 3–5 bài, tập trung vào phần cốt lõi."
    45 -> "Khoảng 5–7 bài, cân bằng bài chính và bổ trợ."
    60 -> "Khoảng 6–8 bài với thời gian nghỉ đầy đủ."
    75 -> "Buổi tập dài, thêm nhóm bài bổ trợ."
    else -> "Khối lượng đầy đủ nhất từ preset đã kiểm duyệt."
}

private fun restExplanation(value: RestDayMode) = if (value == RestDayMode.FULL_REST) "Không xếp hoạt động tập luyện vào ngày nghỉ." else "Gợi ý vận động nhẹ và mobility vào ngày nghỉ."

private fun DayOfWeek.labelVi() = when (this) {
    DayOfWeek.MONDAY -> "Thứ Hai"
    DayOfWeek.TUESDAY -> "Thứ Ba"
    DayOfWeek.WEDNESDAY -> "Thứ Tư"
    DayOfWeek.THURSDAY -> "Thứ Năm"
    DayOfWeek.FRIDAY -> "Thứ Sáu"
    DayOfWeek.SATURDAY -> "Thứ Bảy"
    DayOfWeek.SUNDAY -> "Chủ Nhật"
}

private fun DayOfWeek.shortLabelVi() = when (this) {
    DayOfWeek.MONDAY -> "T2"
    DayOfWeek.TUESDAY -> "T3"
    DayOfWeek.WEDNESDAY -> "T4"
    DayOfWeek.THURSDAY -> "T5"
    DayOfWeek.FRIDAY -> "T6"
    DayOfWeek.SATURDAY -> "T7"
    DayOfWeek.SUNDAY -> "CN"
}

private fun dayHint(day: DayOfWeek) = if (day == DayOfWeek.SATURDAY || day == DayOfWeek.SUNDAY) "Cuối tuần" else "Ngày trong tuần"
