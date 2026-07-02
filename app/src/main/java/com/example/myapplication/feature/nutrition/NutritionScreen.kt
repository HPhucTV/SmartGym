package com.example.myapplication.feature.nutrition

import android.graphics.Bitmap
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.myapplication.ui.theme.EnergyOrange
import com.example.myapplication.ui.theme.SuccessGreen
import com.example.myapplication.ui.theme.customColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NutritionScreen(
    state: NutritionUiState,
    onBack: () -> Unit,
    onScan: (Bitmap) -> Unit,
    onAccept: () -> Unit,
    onDiscard: () -> Unit,
    onClearSweat: () -> Unit,
    onReset: () -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    val cameraLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.TakePicturePreview()
    ) { bitmap ->
        if (bitmap != null) {
            onScan(bitmap)
        }
    }

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            cameraLauncher.launch(null)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Theo dõi Dinh dưỡng 🥗", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    TextButton(onClick = onBack) {
                        Text("◀", color = EnergyOrange, fontSize = 20.sp)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = colors.background,
                    titleContentColor = customColors.primaryText,
                    navigationIconContentColor = customColors.primaryText
                )
            )
        },
        containerColor = colors.background
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when (state) {
                NutritionUiState.Loading -> Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = EnergyOrange)
                }
                is NutritionUiState.Content -> {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState())
                            .padding(20.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        // 1. Calorie progress ring
                        CalorieCard(state)

                        // 2. Sweat Payment status card
                        if (state.sweatActive) {
                            SweatPaymentStatusCard(state, onClearSweat)
                        }

                        // 3. Scan result popup card (if scanning or result available)
                        if (state.scanning) {
                            ScanningCard()
                        } else if (state.scanResult != null) {
                            ScanResultCard(state.scanResult, onAccept, onDiscard)
                        } else {
                            // Primary scan action button
                            Button(
                                onClick = { permissionLauncher.launch(android.Manifest.permission.CAMERA) },
                                colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
                                shape = RoundedCornerShape(16.dp),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(56.dp)
                            ) {
                                Text("📸 Quét đĩa ăn nhanh", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.White)
                            }
                        }

                        state.scanError?.let { error ->
                            Text(error, color = colors.error, textAlign = TextAlign.Center, style = MaterialTheme.typography.bodySmall)
                        }

                        Spacer(Modifier.height(16.dp))

                        // Reset button
                        Text(
                            "Đặt lại calo hôm nay",
                            color = colors.error,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier
                                .clickable { onReset() }
                                .padding(8.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun CalorieCard(state: NutritionUiState.Content) {
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
            Text("Ngân sách calo hôm nay", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = customColors.primaryText)
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
            MacroRow("Đạm (Protein)", state.proteinEaten, (state.calorieLimit * 0.3 / 4).toInt(), "g", SuccessGreen)
            MacroRow("Tinh bột (Carbs)", state.carbsEaten, (state.calorieLimit * 0.5 / 4).toInt(), "g", EnergyOrange)
            MacroRow("Chất béo (Fat)", state.fatEaten, (state.calorieLimit * 0.2 / 9).toInt(), "g", customColors.recoveryBlue)
        }
    }
}

@Composable
private fun MacroRow(label: String, eaten: Int, limit: Int, unit: String, color: Color) {
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
private fun SweatPaymentStatusCard(state: NutritionUiState.Content, onClear: () -> Unit) {
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
private fun ScanningCard() {
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

@Composable
private fun ScanResultCard(
    result: ScanResult,
    onAccept: () -> Unit,
    onDiscard: () -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    Surface(
        color = colors.surfaceVariant,
        shape = RoundedCornerShape(16.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, colors.outline),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("Kết quả quét món ăn 📸", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = EnergyOrange)
            Text(result.dishName, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = customColors.primaryText)

            HorizontalDivider(color = colors.outline)

            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                NutrientTag("🔥 Calo", "${result.totalCalories} kcal", modifier = Modifier.weight(1f))
                NutrientTag("💪 Đạm", "${result.proteinGrams}g", modifier = Modifier.weight(1f))
                NutrientTag("🍚 Tinh bột", "${result.carbsGrams}g", modifier = Modifier.weight(1f))
                NutrientTag("🥑 Béo", "${result.fatGrams}g", modifier = Modifier.weight(1f))
            }

            HorizontalDivider(color = colors.outline)

            Text("Lời khuyên dinh dưỡng:", fontWeight = FontWeight.Bold, color = customColors.primaryText)
            Text(result.advice, color = customColors.primaryText, style = MaterialTheme.typography.bodyMedium)

            result.sweatPayment?.let { proposal ->
                Surface(
                    color = customColors.orangeLight,
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(12.dp)) {
                        Text(
                            "💦 Bài tập bù đề xuất (Sweat Payment):",
                            fontWeight = FontWeight.Bold,
                            color = EnergyOrange,
                            style = MaterialTheme.typography.bodySmall
                        )
                        Text(
                            "Cần tập thêm ${proposal.extraSets} hiệp [${proposal.exerciseName}] để giữ cân bằng.",
                            style = MaterialTheme.typography.bodySmall,
                            color = customColors.primaryText
                        )
                    }
                }
            }

            Spacer(Modifier.height(10.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedButton(
                    onClick = onDiscard,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = colors.error)
                ) {
                    Text("Hủy bỏ")
                }
                Button(
                    onClick = onAccept,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = SuccessGreen)
                ) {
                    Text("Xác nhận ăn", color = Color.White)
                }
            }
        }
    }
}

@Composable
private fun NutrientTag(label: String, value: String, modifier: Modifier = Modifier) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors
    Surface(
        color = colors.background,
        shape = RoundedCornerShape(12.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, colors.outline),
        modifier = modifier
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(vertical = 8.dp)
        ) {
            Text(label, style = MaterialTheme.typography.labelSmall, color = customColors.mutedText, maxLines = 1)
            Spacer(Modifier.height(4.dp))
            Text(value, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold, color = customColors.primaryText, maxLines = 1)
        }
    }
}
