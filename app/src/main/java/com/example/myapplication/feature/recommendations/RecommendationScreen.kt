package com.example.myapplication.feature.recommendations

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.myapplication.core.adaptation.AdaptationKind
import com.example.myapplication.core.adaptation.AdaptationMode
import com.example.myapplication.core.adaptation.AdaptationStatus
import com.example.myapplication.data.local.AdaptationDecisionEntity
import com.example.myapplication.ui.theme.EnergyOrange
import com.example.myapplication.ui.theme.SuccessGreen
import com.example.myapplication.ui.theme.Navy
import com.example.myapplication.ui.theme.White
import com.example.myapplication.ui.theme.SurfaceGray
import com.example.myapplication.ui.theme.BorderGray
import com.example.myapplication.ui.theme.MutedText

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecommendationScreen(
    state: RecommendationUiState,
    onAccept: (Long) -> Unit,
    onReject: (Long) -> Unit,
    onUndo: (AdaptationKind) -> Unit,
    onBack: () -> Unit,
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Đề xuất thích nghi", color = Navy, fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack, modifier = Modifier.testTag("recommendations-back-button")) {
                        Text("←", fontSize = 24.sp, color = Navy, fontWeight = FontWeight.Bold)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = White)
            )
        },
        containerColor = White
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .background(White)
        ) {
            when (state) {
                RecommendationUiState.Loading -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = EnergyOrange)
                    }
                }
                is RecommendationUiState.Success -> {
                    if (state.decisions.isEmpty()) {
                        EmptyState()
                    } else {
                        LazyColumn(
                            contentPadding = PaddingValues(16.dp),
                            verticalArrangement = Arrangement.spacedBy(16.dp),
                            modifier = Modifier.fillMaxSize()
                        ) {
                            items(state.decisions, key = { it.entity.id }) { uiDecision ->
                                DecisionCard(
                                    uiDecision = uiDecision,
                                    onAccept = onAccept,
                                    onReject = onReject,
                                    onUndo = onUndo
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun EmptyState() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("✅", fontSize = 48.sp)
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "Chưa có đề xuất thích nghi nào",
            style = MaterialTheme.typography.titleMedium,
            color = Navy,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Hãy hoàn thành tập luyện và check-in tuần để hệ thống phân tích và đưa ra đề xuất tối ưu.",
            style = MaterialTheme.typography.bodyMedium,
            color = MutedText,
            lineHeight = 20.sp
        )
    }
}

@Composable
private fun DecisionCard(
    uiDecision: UiDecision,
    onAccept: (Long) -> Unit,
    onReject: (Long) -> Unit,
    onUndo: (AdaptationKind) -> Unit,
) {
    val entity = uiDecision.entity
    val borderColors = when (entity.status) {
        AdaptationStatus.APPLIED -> SuccessGreen
        AdaptationStatus.REJECTED -> Color.Gray
        AdaptationStatus.UNDONE -> MutedText
        AdaptationStatus.PROPOSED -> EnergyOrange
    }

    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = SurfaceGray),
        border = BorderStroke(1.dp, borderColors),
        modifier = Modifier
            .fillMaxWidth()
            .testTag("decision-card-${entity.id}")
    ) {
        Column(
            modifier = Modifier
                .padding(16.dp)
                .fillMaxWidth()
        ) {
            // Header Row: Kind & Mode Badges
            Row(
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = translateKind(entity.kind),
                    style = MaterialTheme.typography.titleMedium,
                    color = Navy,
                    fontWeight = FontWeight.Bold
                )
                
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (entity.mode == AdaptationMode.AUTO_APPLY) {
                        Badge(containerColor = SuccessGreen.copy(alpha = 0.15f), contentColor = SuccessGreen) {
                            Text("Tự động", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                        }
                    } else {
                        Badge(containerColor = EnergyOrange.copy(alpha = 0.15f), contentColor = EnergyOrange) {
                            Text("Cần xác nhận", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                    
                    Badge(
                        containerColor = borderColors.copy(alpha = 0.15f),
                        contentColor = borderColors
                    ) {
                        Text(translateStatus(entity.status), fontSize = 11.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Explanation / Reason
            if (uiDecision.isExplaining) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.padding(vertical = 8.dp)
                ) {
                    CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp, color = EnergyOrange)
                    Text("Đang tải giải thích từ Coach AI...", style = MaterialTheme.typography.bodySmall, color = MutedText)
                }
            } else {
                Text(
                    text = uiDecision.explanationText,
                    style = MaterialTheme.typography.bodyMedium,
                    color = Navy,
                    lineHeight = 20.sp
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Details/Before-After values
            val beforeText = parseStateDetails(entity.beforeJson, entity.kind)
            val afterText = parseStateDetails(entity.afterJson, entity.kind)
            if (beforeText.isNotEmpty() && afterText.isNotEmpty()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(BorderGray.copy(alpha = 0.3f), RoundedCornerShape(8.dp))
                        .padding(12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column {
                        Text("Trạng thái cũ", style = MaterialTheme.typography.bodySmall, color = MutedText)
                        Text(beforeText, style = MaterialTheme.typography.bodyMedium, color = Navy, fontWeight = FontWeight.Bold)
                    }
                    Text("→", fontSize = 20.sp, color = Navy, modifier = Modifier.align(Alignment.CenterVertically))
                    Column(horizontalAlignment = Alignment.End) {
                        Text("Trạng thái mới", style = MaterialTheme.typography.bodySmall, color = MutedText)
                        Text(afterText, style = MaterialTheme.typography.bodyMedium, color = EnergyOrange, fontWeight = FontWeight.Bold)
                    }
                }
            }

            // Action Buttons
            if (entity.status == AdaptationStatus.PROPOSED) {
                Spacer(modifier = Modifier.height(16.dp))
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    OutlinedButton(
                        onClick = { onReject(entity.id) },
                        border = BorderStroke(1.dp, Navy),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = Navy),
                        modifier = Modifier
                            .weight(1f)
                            .height(48.dp)
                            .testTag("decision-reject-${entity.id}")
                    ) {
                        Text("Từ chối", fontWeight = FontWeight.Bold)
                    }

                    Button(
                        onClick = { onAccept(entity.id) },
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
                        modifier = Modifier
                            .weight(1f)
                            .height(48.dp)
                            .testTag("decision-accept-${entity.id}")
                    ) {
                        Text("Đồng ý", fontWeight = FontWeight.Bold, color = White)
                    }
                }
            } else if (uiDecision.isUndoEligible) {
                Spacer(modifier = Modifier.height(16.dp))
                OutlinedButton(
                    onClick = { onUndo(entity.kind) },
                    border = BorderStroke(1.dp, EnergyOrange),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = EnergyOrange),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp)
                        .testTag("decision-undo-${entity.id}")
                ) {
                    Text("HOÀN TÁC", fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

private fun translateKind(kind: AdaptationKind): String = when (kind) {
    AdaptationKind.CALORIE_TARGET -> "Mục tiêu Calorie"
    AdaptationKind.MACRO_TARGET -> "Mục tiêu dinh dưỡng (Macros)"
    AdaptationKind.RECOVERY_DAY -> "Đề xuất phục hồi"
    AdaptationKind.WORKOUT_VOLUME -> "Khối lượng tập luyện"
    AdaptationKind.PROGRAM_CHANGE -> "Đổi chương trình tập"
}

private fun translateStatus(status: AdaptationStatus): String = when (status) {
    AdaptationStatus.PROPOSED -> "Đề xuất mới"
    AdaptationStatus.APPLIED -> "Đã áp dụng"
    AdaptationStatus.REJECTED -> "Đã từ chối"
    AdaptationStatus.UNDONE -> "Đã hoàn tác"
}

private fun parseStateDetails(json: String, kind: AdaptationKind): String {
    return when (kind) {
        AdaptationKind.CALORIE_TARGET -> {
            val calories = Regex("\"calories\":(\\d+)").find(json)?.groupValues?.get(1)
            if (calories != null) "$calories kcal" else ""
        }
        AdaptationKind.WORKOUT_VOLUME -> {
            val sessions = Regex("\"scheduledSessions\":(\\d+)").find(json)?.groupValues?.get(1)
            if (sessions != null) "$sessions buổi/tuần" else ""
        }
        else -> ""
    }
}
