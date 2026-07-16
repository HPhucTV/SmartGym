package com.example.myapplication.feature.today

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.myapplication.core.model.labelVi
import com.example.myapplication.core.program.ProgramPhase
import com.example.myapplication.ui.theme.EnergyOrange
import com.example.myapplication.ui.theme.SuccessGreen
import com.example.myapplication.ui.theme.customColors

@Composable
fun WorkoutContent(
    state: TodayUiState.Workout,
    onCheckedChange: (Int, Boolean) -> Unit,
    onComplete: () -> Unit,
    onNavigateToCatalog: () -> Unit,
    onNavigateToNutrition: () -> Unit,
    onRefreshCoachTip: () -> Unit,
    onRequestSubstitution: (Int) -> Unit,
    onApplyTimeBudget: (Int?) -> Unit,
    onToggleSoreMuscle: (String) -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    var timerInitialSeconds by remember { mutableIntStateOf(0) }
    var timerVisible by remember { mutableStateOf(false) }

    val musclesInWorkout = remember(state.rows) {
        state.rows.map { it.primaryMuscle }.distinct()
    }

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

            if (musclesInWorkout.isNotEmpty()) {
                item(key = "sore-muscles") {
                    Column(
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(
                            "Hôm nay bạn mỏi nhóm cơ nào? (Tập nhẹ giảm 50% hiệp 💡)",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold,
                            color = customColors.primaryText,
                        )
                        val chunkedMuscles = musclesInWorkout.chunked(3)
                        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            chunkedMuscles.forEach { rowList ->
                                Row(
                                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    rowList.forEach { muscle ->
                                        val isSelected = state.soreMuscles.contains(muscle.name)
                                        FilterChip(
                                            selected = isSelected,
                                            onClick = { onToggleSoreMuscle(muscle.name) },
                                            label = { Text(muscle.labelVi(), fontSize = 12.sp) },
                                            colors = FilterChipDefaults.filterChipColors(
                                                selectedContainerColor = EnergyOrange.copy(alpha = 0.15f),
                                                selectedLabelColor = EnergyOrange,
                                            ),
                                            modifier = Modifier.weight(1f)
                                        )
                                    }
                                    if (rowList.size < 3) {
                                        repeat(3 - rowList.size) {
                                            Spacer(modifier = Modifier.weight(1f))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            state.warmUp?.let { block ->
                item(key = "warmup:${block.id}") {
                    AdvisoryMovementBlockCard("Khởi động", block)
                }
            }

            // AI Coach Tip card
            item(key = "coach-tip") {
                AICoachTipCard(
                    tip = state.coachTip,
                    isRefreshing = state.isRefreshingCoach,
                    onRefresh = onRefreshCoachTip,
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

            state.coolDown?.let { block ->
                item(key = "cooldown:${block.id}") {
                    AdvisoryMovementBlockCard("Thả lỏng", block)
                }
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
                    onClose = { timerVisible = false },
                )
            }
        }
    }
}

@Composable
fun TodayHeaderCard(
    state: TodayUiState.Workout,
    onNavigateToCatalog: () -> Unit,
    onNavigateToNutrition: () -> Unit,
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
