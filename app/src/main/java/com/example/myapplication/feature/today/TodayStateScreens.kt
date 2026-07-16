package com.example.myapplication.feature.today

import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.myapplication.ui.theme.EnergyOrange
import com.example.myapplication.ui.theme.customColors

@Composable
fun GoalCompleteScreen() {
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

@Composable
fun ErrorScreen(state: TodayUiState.Error, onRetry: () -> Unit) {
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

@Composable
fun AICoachTipCard(
    tip: String?,
    isRefreshing: Boolean,
    onRefresh: () -> Unit,
) {
    if (tip.isNullOrEmpty()) return

    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    Surface(
        color = colors.surfaceVariant,
        shape = RoundedCornerShape(16.dp),
        border = BorderStroke(1.dp, colors.outline),
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
                        style = MaterialTheme.typography.titleMedium,
                    )
                }

                if (isRefreshing) {
                    CircularProgressIndicator(
                        color = EnergyOrange,
                        strokeWidth = 2.dp,
                        modifier = Modifier.size(16.dp),
                    )
                } else {
                    Text(
                        "Cập nhật 🔄",
                        color = EnergyOrange,
                        fontWeight = FontWeight.Bold,
                        style = MaterialTheme.typography.labelMedium,
                        modifier = Modifier
                            .clickable { onRefresh() }
                            .padding(4.dp),
                    )
                }
            }
            Spacer(modifier = Modifier.height(10.dp))
            Text(
                text = tip,
                style = MaterialTheme.typography.bodyMedium,
                color = customColors.primaryText,
                lineHeight = 20.sp,
            )
        }
    }
}

@Composable
fun AdvisoryMovementBlockCard(
    sectionLabel: String,
    block: AdvisoryMovementBlockUi,
) {
    var expanded by rememberSaveable(block.id) { mutableStateOf(false) }
    val customColors = MaterialTheme.colorScheme.customColors
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.surfaceVariant,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { expanded = !expanded }
                    .heightIn(min = 48.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f)) {
                    Text(sectionLabel, color = EnergyOrange, style = MaterialTheme.typography.labelMedium)
                    Text(block.titleVi, color = customColors.primaryText, fontWeight = FontWeight.Bold)
                    Text("${block.estimatedMinutes} phút · Không tính vào tiến độ", color = customColors.mutedText)
                }
                Text(if (expanded) "▲" else "▼", color = EnergyOrange)
            }
            if (expanded) {
                block.stepsVi.forEachIndexed { index, step ->
                    Text("${index + 1}. $step", color = customColors.primaryText)
                }
            }
        }
    }
}
