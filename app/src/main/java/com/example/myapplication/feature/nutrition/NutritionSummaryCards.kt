package com.example.myapplication.feature.nutrition

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.myapplication.ui.theme.EnergyOrange
import com.example.myapplication.ui.theme.SuccessGreen
import com.example.myapplication.ui.theme.customColors

@Composable
fun CalorieCard(state: NutritionUiState.Content) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    val progress = if (state.calorieLimit > 0) state.caloriesEaten.toFloat() / state.calorieLimit else 0f
    val isOverLimit = state.caloriesEaten > state.calorieLimit

    Surface(
        color = colors.surfaceVariant,
        shape = RoundedCornerShape(20.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(20.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    "Ngân sách calo hôm nay",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = customColors.primaryText,
                    modifier = Modifier.weight(1f)
                )

                Surface(
                    color = colors.primaryContainer.copy(alpha = 0.4f),
                    shape = RoundedCornerShape(12.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, colors.primary.copy(alpha = 0.2f))
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Text(state.nutritionScoreEmoji, fontSize = 12.sp)
                        Text(
                            text = "Score: ${state.nutritionScore}",
                            style = MaterialTheme.typography.labelLarge,
                            fontWeight = FontWeight.Bold,
                            color = colors.primary
                        )
                        Text(
                            text = "(${state.nutritionScoreLabel})",
                            style = MaterialTheme.typography.bodySmall,
                            color = colors.primary.copy(alpha = 0.8f)
                        )
                    }
                }
            }
            Spacer(Modifier.height(16.dp))

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text("Đã nạp", style = MaterialTheme.typography.bodyMedium, color = customColors.mutedText)
                    Text(
                        "${state.caloriesEaten} / ${state.calorieLimit} kcal",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = if (isOverLimit) colors.error else SuccessGreen
                    )
                }

                Box(contentAlignment = Alignment.Center, modifier = Modifier.size(72.dp)) {
                    CircularProgressIndicator(
                        progress = { 1f },
                        modifier = Modifier.size(72.dp),
                        color = colors.outline,
                        strokeWidth = 6.dp,
                        strokeCap = StrokeCap.Round
                    )
                    CircularProgressIndicator(
                        progress = { progress.coerceAtMost(1f) },
                        modifier = Modifier.size(72.dp),
                        color = if (isOverLimit) colors.error else SuccessGreen,
                        strokeWidth = 6.dp,
                        strokeCap = StrokeCap.Round
                    )
                    Text(
                        "${(progress * 100).toInt()}%",
                        fontWeight = FontWeight.Bold,
                        color = customColors.primaryText
                    )
                }
            }

            Spacer(Modifier.height(16.dp))
            // Macronutrients linear bars
            MacroRow("Đạm (Protein)", state.proteinEaten, state.proteinLimit, "g", SuccessGreen)
            MacroRow("Tinh bột (Carbs)", state.carbsEaten, state.carbsLimit, "g", EnergyOrange)
            MacroRow("Chất béo (Fat)", state.fatEaten, state.fatLimit, "g", customColors.recoveryBlue)
            MacroRow("Chất xơ (Fiber)", state.fiberEaten, state.fiberLimit, "g", colors.tertiary)
        }
    }
}

@Composable
fun WaterCard(state: NutritionUiState.Content, onAddWater: (Int) -> Unit) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors
    val targetWater = 2000 // 2L target
    val progress = (state.waterIntakeMl.toFloat() / targetWater).coerceAtMost(1f)

    Surface(
        color = colors.surfaceVariant,
        shape = RoundedCornerShape(20.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(20.dp)) {
            Text(
                "Theo dõi Nước uống 💧",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = customColors.primaryText
            )
            Spacer(Modifier.height(12.dp))

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text("Đã nạp", style = MaterialTheme.typography.bodyMedium, color = customColors.mutedText)
                    Text(
                        "${state.waterIntakeMl} / $targetWater ml",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = customColors.recoveryBlue ?: EnergyOrange
                    )
                }

                Row(
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    modifier = Modifier.weight(2f)
                ) {
                    OutlinedButton(
                        onClick = { onAddWater(-250) },
                        enabled = state.waterIntakeMl >= 250,
                        shape = RoundedCornerShape(8.dp),
                        contentPadding = PaddingValues(horizontal = 2.dp, vertical = 2.dp),
                        modifier = Modifier.weight(1f).height(36.dp)
                    ) {
                        Text("-250", fontSize = 10.sp, fontWeight = FontWeight.Bold)
                    }
                    Button(
                        onClick = { onAddWater(100) },
                        colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
                        shape = RoundedCornerShape(8.dp),
                        contentPadding = PaddingValues(horizontal = 2.dp, vertical = 2.dp),
                        modifier = Modifier.weight(1f).height(36.dp)
                    ) {
                        Text("+100", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Color.White)
                    }
                    Button(
                        onClick = { onAddWater(250) },
                        colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
                        shape = RoundedCornerShape(8.dp),
                        contentPadding = PaddingValues(horizontal = 2.dp, vertical = 2.dp),
                        modifier = Modifier.weight(1f).height(36.dp)
                    ) {
                        Text("+250", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Color.White)
                    }
                    Button(
                        onClick = { onAddWater(500) },
                        colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
                        shape = RoundedCornerShape(8.dp),
                        contentPadding = PaddingValues(horizontal = 2.dp, vertical = 2.dp),
                        modifier = Modifier.weight(1f).height(36.dp)
                    ) {
                        Text("+500", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Color.White)
                    }
                }
            }

            Spacer(Modifier.height(12.dp))
            LinearProgressIndicator(
                progress = { progress },
                color = customColors.recoveryBlue ?: EnergyOrange,
                trackColor = colors.outline,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(6.dp)
                    .clip(RoundedCornerShape(3.dp))
            )
        }
    }
}


@Composable
fun MacroRow(label: String, eaten: Int, limit: Int, unit: String, color: Color) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors
    val fraction = if (limit > 0) eaten.toFloat() / limit else 0f

    Column(modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
        Row(
            horizontalArrangement = Arrangement.SpaceBetween,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(label, color = customColors.primaryText, style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.SemiBold)
            Text("$eaten / $limit $unit", color = customColors.mutedText, style = MaterialTheme.typography.bodySmall)
        }
        Spacer(Modifier.height(4.dp))
        LinearProgressIndicator(
            progress = { fraction.coerceAtMost(1f) },
            color = color,
            trackColor = colors.outline,
            modifier = Modifier
                .fillMaxWidth()
                .height(6.dp)
                .clip(RoundedCornerShape(3.dp))
        )
    }
}

@Composable
fun SweatPaymentStatusCard(state: NutritionUiState.Content, onClear: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    Surface(
        color = customColors.orangeLight,
        shape = RoundedCornerShape(16.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, EnergyOrange),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("🔥", fontSize = 24.sp, modifier = Modifier.padding(end = 8.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text("Nhiệm vụ bù đắp (Sweat Payment)", fontWeight = FontWeight.Bold, color = customColors.primaryText)
                    Text(
                        "Cộng thêm ${state.sweatExtraSets} hiệp ${state.sweatExerciseName} vào buổi tập.",
                        style = MaterialTheme.typography.bodySmall,
                        color = customColors.mutedText
                    )
                }
                Text(
                    "Xóa",
                    color = colors.error,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier
                        .clickable { onClear() }
                        .padding(4.dp)
                )
            }
        }
    }
}

@Composable
fun ScanningCard() {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    Surface(
        color = colors.surfaceVariant,
        shape = RoundedCornerShape(16.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            CircularProgressIndicator(color = EnergyOrange)
            Spacer(Modifier.height(14.dp))
            Text("Đang phân tích món ăn bằng Gemini AI...", fontWeight = FontWeight.Bold, color = customColors.primaryText)
            Text("Dịch vụ chạy offline kết nối server", color = customColors.mutedText, style = MaterialTheme.typography.bodySmall)
        }
    }
}
