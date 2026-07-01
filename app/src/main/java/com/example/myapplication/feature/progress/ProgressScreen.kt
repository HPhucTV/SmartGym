package com.example.myapplication.feature.progress

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

@Composable
fun ProgressScreen(
    state: ProgressUiState,
    onPreviousMonth: () -> Unit,
    onNextMonth: () -> Unit,
    modifier: Modifier = Modifier,
) {
    when (state) {
        ProgressUiState.Loading -> Box(modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(color = EnergyOrange, modifier = Modifier.semantics { contentDescription = "Đang tải tiến độ" })
        }
        is ProgressUiState.Content -> ProgressContent(state, onPreviousMonth, onNextMonth, modifier)
        is ProgressUiState.NoActiveGoal -> ProgressWithoutGoal(state, onPreviousMonth, onNextMonth, modifier)
    }
}

@Composable
private fun ProgressContent(state: ProgressUiState.Content, previous: () -> Unit, next: () -> Unit, modifier: Modifier) {
    ProgressLayout(modifier) {
        Text("Tiến độ tập luyện", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = Navy)
        SummaryCard(state)
        CalendarCard(state.selectedMonth, state.markedEpochDays, state.completedInMonth,
            state.canNavigatePrevious, state.canNavigateNext, previous, next)
    }
}

@Composable
private fun ProgressWithoutGoal(state: ProgressUiState.NoActiveGoal, previous: () -> Unit, next: () -> Unit, modifier: Modifier) {
    ProgressLayout(modifier) {
        Text("Tiến độ tập luyện", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = Navy)
        Surface(color = SurfaceGray, shape = RoundedCornerShape(16.dp), modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(20.dp)) {
                Text("Chưa có mục tiêu đang hoạt động", fontWeight = FontWeight.Bold, color = Navy)
                Text("Lịch vẫn lưu các buổi bạn đã hoàn thành.", color = MutedText)
            }
        }
        CalendarCard(state.selectedMonth, state.markedEpochDays, state.completedInMonth,
            state.canNavigatePrevious, state.canNavigateNext, previous, next)
    }
}

@Composable
private fun ProgressLayout(modifier: Modifier, content: @Composable ColumnScope.() -> Unit) {
    Column(
        modifier = modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
        content = content,
    )
}

@Composable
private fun SummaryCard(state: ProgressUiState.Content) {
    Surface(color = SurfaceGray, shape = RoundedCornerShape(16.dp), modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("${state.percentage}%", style = MaterialTheme.typography.displayMedium, fontWeight = FontWeight.Bold, color = Navy)
            LinearProgressIndicator(
                progress = { state.percentage / 100f },
                modifier = Modifier.fillMaxWidth().height(10.dp),
                color = SuccessGreen,
                trackColor = BorderGray,
            )
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("${state.completedActive}/${state.totalActive} buổi", color = Navy, fontWeight = FontWeight.SemiBold)
                Text("Chuỗi ${state.weeklyStreak} tuần", color = SuccessGreen, fontWeight = FontWeight.Bold)
            }
            Text("Mục tiêu ${state.targetPerWeek} buổi mỗi tuần", color = MutedText)
        }
    }
}

@Composable
private fun CalendarCard(month: java.time.YearMonth, marks: Set<Long>, count: Int, canPrevious: Boolean,
                         canNext: Boolean, previous: () -> Unit, next: () -> Unit) {
    Surface(color = White, shape = RoundedCornerShape(16.dp), border = androidx.compose.foundation.BorderStroke(1.dp, BorderGray),
        modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            MonthCalendar(month, marks, canPrevious, canNext, previous, next)
            Text("$count buổi hoàn thành trong tháng", color = MutedText, style = MaterialTheme.typography.bodySmall)
        }
    }
}
