package com.example.myapplication.feature.progress

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.myapplication.ui.theme.*
import com.example.myapplication.core.progress.GoalForecast
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@Composable
fun ProgressScreen(
    state: ProgressUiState,
    onPreviousMonth: () -> Unit,
    onNextMonth: () -> Unit,
    modifier: Modifier = Modifier,
    onNavigateToCatalog: () -> Unit = {},
) {
    val colors = MaterialTheme.colorScheme

    Box(modifier = modifier.fillMaxSize().background(colors.background)) {
        when (state) {
            ProgressUiState.Loading -> Box(modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = EnergyOrange, modifier = Modifier.semantics { contentDescription = "Đang tải tiến độ" })
            }
            is ProgressUiState.Content -> ProgressContent(state, onPreviousMonth, onNextMonth, onNavigateToCatalog)
            is ProgressUiState.NoActiveGoal -> ProgressWithoutGoal(state, onPreviousMonth, onNextMonth, onNavigateToCatalog)
        }
    }
}

@Composable
private fun ProgressContent(
    state: ProgressUiState.Content,
    previous: () -> Unit,
    next: () -> Unit,
    onNavigateToCatalog: () -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    ProgressLayout {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Tiến độ tập luyện", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = customColors.primaryText)
            Text(
                "📚 Tra cứu",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = EnergyOrange,
                modifier = Modifier.clickable { onNavigateToCatalog() }.padding(4.dp)
            )
        }

        SummaryCard(state)

        if (state.weeklyInsights.isNotEmpty()) {
            WeeklyInsightsCard(state.weeklyInsights.map { it.messageVi })
        }

        GoalForecastCard(state)

        // Progress Charts (Weekly frequency & MuscleFocus)
        ProgressChartsSection(
            weeklyStats = state.weeklyStats,
            targetPerWeek = state.targetPerWeek,
            muscleStats = state.muscleStats
        )

        ContributionGraphCard(markedEpochDays = state.markedEpochDays)

        CalendarCard(
            state.selectedMonth, state.markedEpochDays, state.completedInMonth,
            state.canNavigatePrevious, state.canNavigateNext, previous, next
        )
    }
}

@Composable
private fun GoalForecastCard(state: ProgressUiState.Content) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors
    val (title, detail) = when (val forecast = state.goalForecast) {
        GoalForecast.InsufficientData -> "Chưa đủ dữ liệu dự báo" to
            "Cần ít nhất 2 buổi hoàn thành trong 2 tuần trọn vẹn."
        GoalForecast.Complete -> "Đã hoàn thành mục tiêu" to "Toàn bộ buổi trong chương trình đã hoàn tất."
        is GoalForecast.OnTrack -> "Đang đúng tiến độ" to
            "Dự kiến hoàn thành ${formatForecastDate(forecast.projectedEpochDay)}."
        is GoalForecast.AtRisk -> "Có nguy cơ chậm tiến độ" to
            "Dự kiến ${formatForecastDate(forecast.projectedEpochDay)}, đang chậm ${forecast.sessionsBehind} buổi."
    }
    Surface(
        color = colors.surfaceVariant,
        shape = RoundedCornerShape(16.dp),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("Dự báo hoàn thành", color = EnergyOrange, fontWeight = FontWeight.Bold)
            Text(title, color = customColors.primaryText, fontWeight = FontWeight.Bold)
            Text(detail, color = customColors.primaryText)
            Text(
                "Dựa trên ${state.forecastCompletedSessions} buổi trong ${state.forecastElapsedWeeks} tuần.",
                color = customColors.mutedText,
                style = MaterialTheme.typography.bodySmall,
            )
            Text(
                "Đây là ước tính lịch tập, không phải dự đoán cân nặng, y khoa hay vóc dáng.",
                color = customColors.mutedText,
                style = MaterialTheme.typography.bodySmall,
            )
        }
    }
}

private val forecastDateFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy")
private fun formatForecastDate(epochDay: Long): String =
    LocalDate.ofEpochDay(epochDay).format(forecastDateFormatter)

@Composable
private fun WeeklyInsightsCard(messages: List<String>) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors
    Surface(
        color = colors.surfaceVariant,
        shape = RoundedCornerShape(16.dp),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("Nhận xét tuần", fontWeight = FontWeight.Bold, color = customColors.primaryText)
            messages.forEach { message ->
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("•", color = EnergyOrange, fontWeight = FontWeight.Bold)
                    Text(message, color = customColors.primaryText)
                }
            }
            Text(
                "Phân tích từ lịch tập và phản hồi đã lưu trên thiết bị.",
                color = customColors.mutedText,
                style = MaterialTheme.typography.bodySmall,
            )
        }
    }
}

@Composable
private fun ProgressWithoutGoal(
    state: ProgressUiState.NoActiveGoal,
    previous: () -> Unit,
    next: () -> Unit,
    onNavigateToCatalog: () -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    ProgressLayout {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Tiến độ tập luyện", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = customColors.primaryText)
            Text(
                "📚 Tra cứu",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = EnergyOrange,
                modifier = Modifier.clickable { onNavigateToCatalog() }.padding(4.dp)
            )
        }

        Surface(color = colors.surfaceVariant, shape = RoundedCornerShape(16.dp), modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(20.dp)) {
                Text("Chưa có mục tiêu đang hoạt động", fontWeight = FontWeight.Bold, color = customColors.primaryText)
                Text("Lịch vẫn lưu các buổi bạn đã hoàn thành.", color = customColors.mutedText)
            }
        }

        // Show weekly completed stats even without active goal
        if (state.weeklyStats.isNotEmpty()) {
            ProgressChartsSection(
                weeklyStats = state.weeklyStats,
                targetPerWeek = 3, // Default fallback target
                muscleStats = emptyList()
            )
        }

        ContributionGraphCard(markedEpochDays = state.markedEpochDays)

        CalendarCard(
            state.selectedMonth, state.markedEpochDays, state.completedInMonth,
            state.canNavigatePrevious, state.canNavigateNext, previous, next
        )
    }
}

@Composable
private fun ProgressLayout(content: @Composable ColumnScope.() -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
        content = content,
    )
}

@Composable
private fun SummaryCard(state: ProgressUiState.Content) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    Surface(color = colors.surfaceVariant, shape = RoundedCornerShape(16.dp), modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("${state.percentage}%", style = MaterialTheme.typography.displayMedium, fontWeight = FontWeight.Bold, color = customColors.primaryText)
            LinearProgressIndicator(
                progress = { state.percentage / 100f },
                modifier = Modifier.fillMaxWidth().height(10.dp),
                color = SuccessGreen,
                trackColor = colors.outline,
            )
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("${state.completedActive}/${state.totalActive} buổi", color = customColors.primaryText, fontWeight = FontWeight.SemiBold)
                Text("Chuỗi ${state.weeklyStreak} tuần", color = SuccessGreen, fontWeight = FontWeight.Bold)
            }
            Text("Mục tiêu ${state.targetPerWeek} buổi mỗi tuần", color = customColors.mutedText)
        }
    }
}

@Composable
private fun CalendarCard(
    month: java.time.YearMonth,
    marks: Set<Long>,
    count: Int,
    canPrevious: Boolean,
    canNext: Boolean,
    previous: () -> Unit,
    next: () -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    Surface(
        color = colors.surface,
        shape = RoundedCornerShape(16.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, colors.outline),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            MonthCalendar(month, marks, canPrevious, canNext, previous, next)
            Text("$count buổi hoàn thành trong tháng", color = customColors.mutedText, style = MaterialTheme.typography.bodySmall)
        }
    }
}
