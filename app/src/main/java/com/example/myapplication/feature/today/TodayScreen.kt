package com.example.myapplication.feature.today

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.example.myapplication.ui.theme.*

@Composable
fun TodayScreen(
    state: TodayUiState,
    onCheckedChange: (Int, Boolean) -> Unit,
    onComplete: () -> Unit,
    onRetry: () -> Unit,
) {
    when (state) {
        TodayUiState.Loading -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = EnergyOrange) }
        TodayUiState.GoalComplete -> MessageScreen("Hoàn thành mục tiêu", "Bạn đã hoàn thành tất cả buổi tập trong chương trình. Tuyệt vời!")
        is TodayUiState.Recovery -> if (state.kind == RecoveryKind.FULL_REST) {
            MessageScreen("Nghỉ ngơi hoàn toàn", "Hôm nay hãy nghỉ ngơi. Buổi tập tiếp theo vào ngày ${state.nextDueEpochDay}.")
        } else {
            MessageScreen("Phục hồi nhẹ", "Bạn có thể đi bộ hoặc vận động nhẹ. Buổi tập tiếp theo vào ngày ${state.nextDueEpochDay}.")
        }
        is TodayUiState.Error -> MessageScreen("Đã có lỗi", state.message, if (state.canRetry) "Thử lại" else null, onRetry)
        is TodayUiState.Workout -> WorkoutContent(state, onCheckedChange, onComplete)
    }
}

@Composable
private fun WorkoutContent(state: TodayUiState.Workout, onCheckedChange: (Int, Boolean) -> Unit, onComplete: () -> Unit) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        item {
            Text("Bài tập hôm nay", style = MaterialTheme.typography.headlineMedium, color = Navy)
            Spacer(Modifier.height(8.dp))
            Text(state.titleVi, style = MaterialTheme.typography.titleLarge, color = Navy)
            Text("${state.focusVi} · ${state.estimatedMinutes} phút", color = MutedText)
            Spacer(Modifier.height(8.dp))
            Text("${state.checkedCount}/${state.total} bài đã xong", color = SuccessGreen, style = MaterialTheme.typography.titleMedium)
        }
        items(state.rows, key = { it.orderIndex }) { row ->
            ExerciseCard(row, enabled = !state.isCompleting) { checked -> onCheckedChange(row.orderIndex, checked) }
        }
        item {
            Button(
                onClick = onComplete,
                enabled = state.canComplete && !state.isCompleting,
                colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange, contentColor = Color.White),
                modifier = Modifier.fillMaxWidth().heightIn(min = 52.dp),
            ) { Text(if (state.isCompleting) "Đang hoàn thành…" else "Hoàn thành buổi tập") }
        }
    }
}

@Composable
private fun MessageScreen(title: String, message: String, action: String? = null, onAction: () -> Unit = {}) {
    Column(Modifier.fillMaxSize().padding(24.dp), verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally) {
        Text(title, style = MaterialTheme.typography.headlineMedium, color = Navy)
        Spacer(Modifier.height(12.dp)); Text(message, color = MutedText)
        if (action != null) { Spacer(Modifier.height(20.dp)); Button(onClick = onAction, colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange)) { Text(action) } }
    }
}
