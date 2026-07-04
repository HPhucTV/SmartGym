package com.example.myapplication.feature.today

import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.myapplication.core.feedback.WorkoutDifficulty
import com.example.myapplication.core.program.ProgramPhase
import com.example.myapplication.ui.theme.*
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@Composable
fun TodayScreen(
    state: TodayUiState,
    onCheckedChange: (Int, Boolean) -> Unit,
    onComplete: () -> Unit,
    onRetry: () -> Unit,
    onNavigateToCatalog: () -> Unit = {},
    onNavigateToNutrition: () -> Unit = {},
    onRefreshCoachTip: () -> Unit = {},
    celebrationState: CelebrationState = CelebrationState(),
    onDismissCelebration: () -> Unit = {},
    pendingFeedback: PendingWorkoutFeedback? = null,
    onDifficultySelected: (WorkoutDifficulty) -> Unit = {},
    onDismissFeedback: () -> Unit = {},
    onRequestSubstitution: (Int) -> Unit = {},
    onApplySubstitution: (String) -> Unit = {},
    onDismissSubstitution: () -> Unit = {},
    onApplyTimeBudget: (Int?) -> Unit = {},
) {
    val colors = MaterialTheme.colorScheme

    Box(modifier = Modifier.fillMaxSize().background(colors.background)) {
        when (state) {
            TodayUiState.Loading -> Box(
                Modifier.fillMaxSize().testTag("today-loading"),
                contentAlignment = Alignment.Center,
            ) {
                CircularProgressIndicator(color = EnergyOrange, modifier = Modifier.semantics { contentDescription = "Đang tải bài tập" })
            }
            TodayUiState.GoalComplete -> GoalCompleteScreen()
            is TodayUiState.Recovery -> RecoveryScreen(state, onRefreshCoachTip)
            is TodayUiState.Error -> ErrorScreen(state, onRetry)
            is TodayUiState.Workout -> WorkoutContent(
                state = state,
                onCheckedChange = onCheckedChange,
                onComplete = onComplete,
                onNavigateToCatalog = onNavigateToCatalog,
                onNavigateToNutrition = onNavigateToNutrition,
                onRefreshCoachTip = onRefreshCoachTip,
                onRequestSubstitution = onRequestSubstitution,
                onApplyTimeBudget = onApplyTimeBudget,
            )
        }

        // Celebration Layer
        if (celebrationState.showConfetti) {
            com.example.myapplication.core.ui.ConfettiCelebration(
                isActive = true,
                onFinished = {
                    if (celebrationState.unlockedAchievements.isEmpty()) {
                        onDismissCelebration()
                    }
                }
            )

            // Simple celebratory banner at top if no achievements, or full dialog if achievements are unlocked
            if (celebrationState.unlockedAchievements.isEmpty()) {
                Surface(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 40.dp, start = 20.dp, end = 20.dp),
                    color = SuccessGreen,
                    shape = RoundedCornerShape(16.dp),
                    shadowElevation = 4.dp
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            "Tuyệt vời! Bạn đã hoàn thành buổi tập hôm nay! 💪🎉",
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                            textAlign = TextAlign.Center
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            val context = androidx.compose.ui.platform.LocalContext.current
                            OutlinedButton(
                                onClick = {
                                    shareWorkoutSummary(
                                        context = context,
                                        workoutTitle = celebrationState.workoutTitle,
                                        completed = celebrationState.completedExercises,
                                        total = celebrationState.totalExercises,
                                        achievements = emptyList()
                                    )
                                },
                                shape = RoundedCornerShape(12.dp),
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color.White),
                                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.White)
                            ) {
                                Text("Chia sẻ 🔗", fontWeight = FontWeight.Bold)
                            }
                            Button(
                                onClick = onDismissCelebration,
                                modifier = Modifier.testTag("celebration-dismiss"),
                                shape = RoundedCornerShape(12.dp),
                                colors = ButtonDefaults.buttonColors(containerColor = Color.White, contentColor = SuccessGreen)
                            ) {
                                Text("Đóng", fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            } else {
                // Achievement unlock dialog
                AchievementUnlockDialog(
                    badges = celebrationState.unlockedAchievements,
                    workoutTitle = celebrationState.workoutTitle,
                    completedExercises = celebrationState.completedExercises,
                    totalExercises = celebrationState.totalExercises,
                    onDismiss = onDismissCelebration
                )
            }
        }

        pendingFeedback?.let { feedback ->
            WorkoutFeedbackDialog(
                feedback = feedback,
                onDifficultySelected = onDifficultySelected,
                onDismiss = onDismissFeedback,
            )
        }

        (state as? TodayUiState.Workout)?.substitution?.let { substitution ->
            ExerciseSubstitutionDialog(
                state = substitution,
                onApply = onApplySubstitution,
                onDismiss = onDismissSubstitution,
            )
        }
    }
}

@Composable
private fun ExerciseSubstitutionDialog(
    state: ExerciseSubstitutionUi,
    onApply: (String) -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Thay ${state.currentNameVi}", fontWeight = FontWeight.Bold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                state.candidates.forEach { candidate ->
                    OutlinedButton(
                        onClick = { onApply(candidate.exerciseId) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("substitute-${candidate.exerciseId}"),
                        shape = RoundedCornerShape(12.dp),
                    ) {
                        Column(Modifier.fillMaxWidth()) {
                            Text(
                                if (candidate.restoresOriginal) "${candidate.nameVi} · Bài gốc" else candidate.nameVi,
                                fontWeight = FontWeight.Bold,
                            )
                            Text(
                                candidate.equipment.joinToString { it.name.lowercase().replace('_', ' ') },
                                style = MaterialTheme.typography.bodySmall,
                            )
                            candidate.instructionsVi.firstOrNull()?.let {
                                Text(it, style = MaterialTheme.typography.bodySmall)
                            }
                        }
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("Đóng") } },
        shape = RoundedCornerShape(20.dp),
        containerColor = MaterialTheme.colorScheme.surface,
    )
}

@Composable
private fun WorkoutFeedbackDialog(
    feedback: PendingWorkoutFeedback,
    onDifficultySelected: (WorkoutDifficulty) -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = { if (!feedback.saving) onDismiss() },
        title = {
            Text(
                text = "Buổi tập vừa rồi thế nào?",
                color = MaterialTheme.colorScheme.customColors.primaryText,
                fontWeight = FontWeight.Bold,
            )
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    text = "Phản hồi này giúp điều chỉnh các buổi sau mà không cần ghi tạ hay số lần tập.",
                    color = MaterialTheme.colorScheme.customColors.mutedText,
                )
                listOf(
                    WorkoutDifficulty.EASY to "Quá nhẹ",
                    WorkoutDifficulty.RIGHT to "Vừa sức",
                    WorkoutDifficulty.HARD to "Quá nặng",
                ).forEach { (difficulty, label) ->
                    OutlinedButton(
                        onClick = { onDifficultySelected(difficulty) },
                        enabled = !feedback.saving,
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("feedback-${difficulty.name.lowercase()}"),
                        shape = RoundedCornerShape(12.dp),
                    ) {
                        Text(label)
                    }
                }
                if (feedback.saving) {
                    LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
                }
                feedback.error?.let { message ->
                    Text(message, color = MaterialTheme.colorScheme.error)
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss, enabled = !feedback.saving) {
                Text("Để sau")
            }
        },
        shape = RoundedCornerShape(20.dp),
        containerColor = MaterialTheme.colorScheme.surface,
    )
}

@Composable
private fun AchievementUnlockDialog(
    badges: List<com.example.myapplication.core.achievement.AchievementType>,
    workoutTitle: String,
    completedExercises: Int,
    totalExercises: Int,
    onDismiss: () -> Unit
) {
    val context = androidx.compose.ui.platform.LocalContext.current
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedButton(
                    onClick = {
                        shareWorkoutSummary(
                            context = context,
                            workoutTitle = workoutTitle,
                            completed = completedExercises,
                            total = totalExercises,
                            achievements = badges
                        )
                    },
                    shape = RoundedCornerShape(12.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, EnergyOrange),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = EnergyOrange)
                ) {
                    Text("Chia sẻ 🔗", fontWeight = FontWeight.Bold)
                }
                Button(
                    onClick = onDismiss,
                    modifier = Modifier.testTag("celebration-dismiss"),
                    colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text("Đóng 🌟", fontWeight = FontWeight.Bold)
                }
            }
        },
        title = {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("🏆 THÀNH TỰU MỚI!", color = EnergyOrange, fontWeight = FontWeight.Black, fontSize = 22.sp)
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Chúc mừng bạn đã mở khóa huy hiệu mới!",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.customColors.mutedText,
                    textAlign = TextAlign.Center
                )
            }
        },
        text = {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.fillMaxWidth()
            ) {
                badges.forEach { badge ->
                    Surface(
                        color = MaterialTheme.colorScheme.surfaceVariant,
                        shape = RoundedCornerShape(16.dp),
                        border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 6.dp)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Text(badge.icon, fontSize = 42.sp)
                            Spacer(modifier = Modifier.width(16.dp))
                            Column {
                                Text(
                                    badge.titleVi,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.customColors.primaryText,
                                    fontSize = 16.sp
                                )
                                Text(
                                    badge.descriptionVi,
                                    color = MaterialTheme.colorScheme.customColors.mutedText,
                                    fontSize = 13.sp
                                )
                            }
                        }
                    }
                }
            }
        },
        shape = RoundedCornerShape(24.dp),
        containerColor = MaterialTheme.colorScheme.surface
    )
}

// ── Hero Header Card ──────────────────────────────────────────────

@Composable
private fun TodayHeaderCard(
    state: TodayUiState.Workout,
    onNavigateToCatalog: () -> Unit,
    onNavigateToNutrition: () -> Unit
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    val greeting = when {
        state.greetingHour < 12 -> "Chào buổi sáng! 🌅"
        state.greetingHour < 18 -> "Chào buổi chiều! ☀️"
        else -> "Chào buổi tối! 🌙"
    }
    val progress = if (state.total > 0) state.checkedCount.toFloat() / state.total else 0f

    Surface(
        color = colors.surfaceVariant,
        shape = RoundedCornerShape(20.dp),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(
            modifier = Modifier.padding(20.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(greeting, style = MaterialTheme.typography.labelLarge, color = EnergyOrange)
                Spacer(Modifier.height(4.dp))
                Row(
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        "📚 Tra cứu",
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = EnergyOrange,
                        modifier = Modifier
                            .clickable { onNavigateToCatalog() }
                            .padding(vertical = 4.dp)
                    )
                    Text(
                        "🥗 Dinh dưỡng",
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = SuccessGreen,
                        modifier = Modifier
                            .clickable { onNavigateToNutrition() }
                            .padding(vertical = 4.dp)
                    )
                }
                Spacer(Modifier.height(6.dp))
                Text(state.titleVi, style = MaterialTheme.typography.titleLarge, color = customColors.primaryText)
                Spacer(Modifier.height(4.dp))
                Text(
                    state.phase.labelVi(),
                    color = EnergyOrange,
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.Bold,
                )
                Spacer(Modifier.height(4.dp))
                Text(
                    "${state.focusVi} · ${state.estimatedMinutes} phút",
                    color = customColors.mutedText,
                    style = MaterialTheme.typography.bodyMedium,
                )
                Spacer(Modifier.height(8.dp))
                Text(
                    "${state.checkedCount}/${state.total} bài đã xong",
                    color = SuccessGreen,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                )
            }
            Spacer(Modifier.width(16.dp))
            // Circular progress ring
            Box(contentAlignment = Alignment.Center, modifier = Modifier.size(80.dp)) {
                CircularProgressIndicator(
                    progress = { 1f },
                    modifier = Modifier.size(80.dp),
                    color = colors.outline,
                    strokeWidth = 8.dp,
                    strokeCap = StrokeCap.Round,
                )
                CircularProgressIndicator(
                    progress = { progress },
                    modifier = Modifier.size(80.dp),
                    color = if (progress >= 1f) SuccessGreen else EnergyOrange,
                    strokeWidth = 8.dp,
                    strokeCap = StrokeCap.Round,
                )
                Text(
                    "${(progress * 100).toInt()}%",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = customColors.primaryText,
                )
            }
        }
    }
}

internal fun ProgramPhase.labelVi(): String = when (this) {
    ProgramPhase.FOUNDATION -> "Giai đoạn làm quen"
    ProgramPhase.BUILD -> "Giai đoạn phát triển"
    ProgramPhase.CONSOLIDATE -> "Giai đoạn củng cố"
    ProgramPhase.DELOAD -> "Giai đoạn giảm tải"
}

// ── Workout Content ───────────────────────────────────────────────

@Composable
private fun WorkoutContent(
    state: TodayUiState.Workout,
    onCheckedChange: (Int, Boolean) -> Unit,
    onComplete: () -> Unit,
    onNavigateToCatalog: () -> Unit,
    onNavigateToNutrition: () -> Unit,
    onRefreshCoachTip: () -> Unit,
    onRequestSubstitution: (Int) -> Unit,
    onApplyTimeBudget: (Int?) -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    var timerInitialSeconds by remember { mutableIntStateOf(0) }
    var timerVisible by remember { mutableStateOf(false) }

    Box(modifier = Modifier.fillMaxSize()) {
        LazyColumn(
            modifier = Modifier.fillMaxSize().testTag("today-workout"),
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp, top = 20.dp, bottom = 120.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            // Header card
            item(key = "header") {
                TodayHeaderCard(state, onNavigateToCatalog, onNavigateToNutrition)
            }

            item(key = "time-budget") {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        "Thời lượng buổi tập",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        color = customColors.primaryText,
                    )
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        state.timeBudgetChoices.forEach { minutes ->
                            FilterChip(
                                selected = state.selectedTimeBudgetMinutes == minutes,
                                onClick = { onApplyTimeBudget(minutes) },
                                enabled = state.canChangeTimeBudget,
                                label = { Text(minutes?.let { "$it phút" } ?: "Đầy đủ") },
                                modifier = Modifier.weight(1f),
                            )
                        }
                    }
                    if (state.omittedExerciseCount > 0) {
                        Text(
                            "${state.omittedExerciseCount} bài phụ được lược bớt",
                            color = customColors.mutedText,
                            style = MaterialTheme.typography.bodySmall,
                        )
                    }
                }
            }

            // AI Coach Tip card
            item(key = "coach-tip") {
                AICoachTipCard(
                    tip = state.coachTip,
                    isRefreshing = state.isRefreshingCoach,
                    onRefresh = onRefreshCoachTip
                )
            }

            // Exercise list
            items(state.rows, key = { "${state.sessionId}:${it.orderIndex}:${it.exerciseId}" }) { row ->
                ExerciseCard(
                    state.sessionId,
                    row,
                    enabled = !state.isCompleting && row.orderIndex !in state.pendingOrderIndices,
                    onCheckedChange = { checked ->
                        onCheckedChange(row.orderIndex, checked)
                        if (checked && row.restSeconds > 0) {
                            timerInitialSeconds = row.restSeconds
                            timerVisible = true
                        }
                    },
                    onSubstitute = { onRequestSubstitution(row.orderIndex) },
                )
            }

            // Interaction error
            state.interactionError?.let { message ->
                item(key = "error") { Text(message, color = colors.error) }
            }

            // Completion section
            item(key = "complete") {
                Column(
                    modifier = Modifier.fillMaxWidth().padding(top = 4.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    // Status hint
                    val remaining = state.total - state.checkedCount
                    Text(
                        when {
                            state.isCompleting -> "Đang lưu kết quả..."
                            remaining == 0 -> "Sẵn sàng hoàn thành! ✓"
                            remaining == 1 -> "Còn 1 bài nữa"
                            else -> "Còn $remaining bài nữa"
                        },
                        color = if (remaining == 0) SuccessGreen else customColors.mutedText,
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = if (remaining == 0) FontWeight.Bold else FontWeight.Normal,
                    )
                    Spacer(Modifier.height(10.dp))

                    Button(
                        onClick = onComplete,
                        enabled = state.canComplete && !state.isCompleting,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = EnergyOrange,
                            contentColor = Color.White,
                            disabledContainerColor = colors.outline,
                            disabledContentColor = customColors.mutedText,
                        ),
                        shape = RoundedCornerShape(16.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(min = 56.dp)
                            .testTag("today-complete"),
                    ) {
                        Text(
                            if (state.isCompleting) "Đang hoàn thành…" else "Hoàn thành buổi tập ✓",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                        )
                    }
                }
            }
        }

        // Floating Rest Timer at the bottom
        if (timerVisible && timerInitialSeconds > 0) {
            Box(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                RestTimerSection(
                    initialSeconds = timerInitialSeconds,
                    onFinished = { timerVisible = false },
                    onClose = { timerVisible = false }
                )
            }
        }
    }
}

// ── Recovery Screen ───────────────────────────────────────────────

@Composable
private fun RecoveryScreen(
    state: TodayUiState.Recovery,
    onRefreshCoachTip: () -> Unit
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp)
            .verticalScroll(rememberScrollState())
            .testTag("today-recovery"),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        val emoji = if (state.kind == RecoveryKind.FULL_REST) "🧘" else "🚶"
        Text(emoji, fontSize = 64.sp)
        Spacer(Modifier.height(20.dp))

        Text(
            if (state.kind == RecoveryKind.FULL_REST) "Nghỉ ngơi hoàn toàn" else "Phục hồi nhẹ",
            style = MaterialTheme.typography.headlineMedium,
            color = customColors.primaryText,
            fontWeight = FontWeight.Bold,
        )
        Spacer(Modifier.height(12.dp))

        Text(
            if (state.kind == RecoveryKind.FULL_REST)
                "Hôm nay hãy nghỉ ngơi để cơ thể phục hồi."
            else
                "Bạn có thể đi bộ hoặc vận động nhẹ nhàng.",
            color = customColors.mutedText,
            textAlign = TextAlign.Center,
            style = MaterialTheme.typography.bodyLarge,
        )
        Spacer(Modifier.height(24.dp))

        // Next workout info card
        Surface(
            color = customColors.recoveryBlueBg,
            shape = RoundedCornerShape(16.dp),
            modifier = Modifier.fillMaxWidth(),
        ) {
            Row(
                modifier = Modifier.padding(20.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("📅", fontSize = 28.sp)
                Spacer(Modifier.width(14.dp))
                Column {
                    Text("Buổi tập tiếp theo", color = customColors.primaryText, fontWeight = FontWeight.SemiBold)
                    Text(
                        formatEpochDay(state.nextDueEpochDay),
                        color = customColors.recoveryBlue,
                        fontWeight = FontWeight.Bold,
                        style = MaterialTheme.typography.titleLarge,
                    )
                }
            }
        }

        Spacer(Modifier.height(20.dp))

        AICoachTipCard(
            tip = state.coachTip,
            isRefreshing = state.isRefreshingCoach,
            onRefresh = onRefreshCoachTip
        )
    }
}

// ── Goal Complete Screen ──────────────────────────────────────────

@Composable
private fun GoalCompleteScreen() {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    Column(
        modifier = Modifier.fillMaxSize().padding(32.dp).testTag("today-goal-complete"),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text("🏆", fontSize = 72.sp)
        Spacer(Modifier.height(20.dp))
        Text(
            "Hoàn thành mục tiêu!",
            style = MaterialTheme.typography.headlineMedium,
            color = customColors.primaryText,
            fontWeight = FontWeight.Bold,
        )
        Spacer(Modifier.height(12.dp))
        Text(
            "Bạn đã hoàn thành tất cả buổi tập trong chương trình. Tuyệt vời! 🎉",
            color = customColors.mutedText,
            textAlign = TextAlign.Center,
            style = MaterialTheme.typography.bodyLarge,
        )
        Spacer(Modifier.height(24.dp))
        Surface(
            color = customColors.greenLight,
            shape = RoundedCornerShape(16.dp),
            modifier = Modifier.fillMaxWidth(),
        ) {
            Column(
                Modifier.padding(20.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text(
                    "Hãy vào Cài đặt để tạo mục tiêu mới!",
                    color = customColors.primaryText,
                    fontWeight = FontWeight.SemiBold,
                    textAlign = TextAlign.Center,
                )
            }
        }
    }
}

// ── Error Screen ──────────────────────────────────────────────────

@Composable
private fun ErrorScreen(state: TodayUiState.Error, onRetry: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    Column(
        Modifier.fillMaxSize().padding(32.dp).testTag("today-error"),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text("⚠️", fontSize = 56.sp)
        Spacer(Modifier.height(16.dp))
        Text(
            "Đã có lỗi",
            style = MaterialTheme.typography.headlineMedium,
            color = customColors.primaryText,
            fontWeight = FontWeight.Bold,
        )
        Spacer(Modifier.height(12.dp))
        Text(state.message, color = customColors.mutedText, textAlign = TextAlign.Center)
        if (state.canRetry) {
            Spacer(Modifier.height(20.dp))
            Button(
                onClick = onRetry,
                colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
                shape = RoundedCornerShape(12.dp),
            ) { Text("Thử lại") }
        }
    }
}

// ── Helpers ───────────────────────────────────────────────────────

private val todayDateFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy")
private fun formatEpochDay(epochDay: Long): String = LocalDate.ofEpochDay(epochDay).format(todayDateFormatter)

@Composable
private fun AICoachTipCard(
    tip: String?,
    isRefreshing: Boolean,
    onRefresh: () -> Unit
) {
    if (tip.isNullOrEmpty()) return

    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    Surface(
        color = colors.surfaceVariant,
        shape = RoundedCornerShape(16.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, colors.outline),
        modifier = Modifier.fillMaxWidth().animateContentSize()
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("🤖", fontSize = 24.sp, modifier = Modifier.padding(end = 8.dp))
                    Text(
                        "Trợ lý AI Coach",
                        fontWeight = FontWeight.Bold,
                        color = customColors.primaryText,
                        style = MaterialTheme.typography.titleMedium
                    )
                }

                if (isRefreshing) {
                    CircularProgressIndicator(
                        color = EnergyOrange,
                        strokeWidth = 2.dp,
                        modifier = Modifier.size(16.dp)
                    )
                } else {
                    Text(
                        "Cập nhật 🔄",
                        color = EnergyOrange,
                        fontWeight = FontWeight.Bold,
                        style = MaterialTheme.typography.labelMedium,
                        modifier = Modifier
                            .clickable { onRefresh() }
                            .padding(4.dp)
                    )
                }
            }
            Spacer(modifier = Modifier.height(10.dp))
            Text(
                text = tip,
                style = MaterialTheme.typography.bodyMedium,
                color = customColors.primaryText,
                lineHeight = 20.sp
            )
        }
    }
}

private fun shareWorkoutSummary(
    context: android.content.Context,
    workoutTitle: String,
    completed: Int,
    total: Int,
    achievements: List<com.example.myapplication.core.achievement.AchievementType>
) {
    val shareText = buildWorkoutShareText(workoutTitle, completed, total, achievements)

    val sendIntent = android.content.Intent().apply {
        action = android.content.Intent.ACTION_SEND
        putExtra(android.content.Intent.EXTRA_TEXT, shareText)
        type = "text/plain"
    }
    val shareIntent = android.content.Intent.createChooser(sendIntent, "Chia sẻ kết quả tập")
    context.startActivity(shareIntent)
}
