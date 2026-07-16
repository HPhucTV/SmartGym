package com.example.myapplication.feature.today

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.myapplication.ui.theme.customColors
import java.time.LocalDate
import java.time.format.DateTimeFormatter

internal val todayDateFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy")
internal fun formatEpochDay(epochDay: Long): String = LocalDate.ofEpochDay(epochDay).format(todayDateFormatter)

@Composable
fun RecoveryScreen(
    state: TodayUiState.Recovery,
    onRefreshCoachTip: () -> Unit,
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
            onRefresh = onRefreshCoachTip,
        )
    }
}
