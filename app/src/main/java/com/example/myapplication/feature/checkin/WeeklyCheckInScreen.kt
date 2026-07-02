package com.example.myapplication.feature.checkin

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.myapplication.ui.theme.EnergyOrange
import com.example.myapplication.ui.theme.customColors

@Composable
fun WeeklyCheckInScreen(
    state: WeeklyCheckInUiState,
    onWeightChanged: (String) -> Unit,
    onEnergyChanged: (Int) -> Unit,
    onHungerChanged: (Int) -> Unit,
    onRecoveryChanged: (Int) -> Unit,
    onSleepQualityChanged: (Int) -> Unit,
    onNoteChanged: (String) -> Unit,
    onSubmit: () -> Unit,
    onBack: () -> Unit,
    onNavigateToProfile: () -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
    ) {
        when (state) {
            WeeklyCheckInUiState.Loading -> Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = EnergyOrange)
            }
            WeeklyCheckInUiState.NoProfile -> NoProfileContent(
                onNavigateToProfile = onNavigateToProfile,
                onBack = onBack
            )
            is WeeklyCheckInUiState.Input -> CheckInContent(
                state = state,
                onWeightChanged = onWeightChanged,
                onEnergyChanged = onEnergyChanged,
                onHungerChanged = onHungerChanged,
                onRecoveryChanged = onRecoveryChanged,
                onSleepQualityChanged = onSleepQualityChanged,
                onNoteChanged = onNoteChanged,
                onSubmit = onSubmit,
                onBack = onBack
            )
        }
    }
}

@Composable
private fun NoProfileContent(
    onNavigateToProfile: () -> Unit,
    onBack: () -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text("👤", fontSize = 64.sp)
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            "Yêu cầu Hồ sơ cá nhân",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = customColors.primaryText,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(12.dp))
        Text(
            "Bạn cần thiết lập hồ sơ cá nhân và đồng ý cá nhân hóa trước khi tiến hành Check-in tuần.",
            style = MaterialTheme.typography.bodyLarge,
            color = customColors.mutedText,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(28.dp))
        Button(
            onClick = onNavigateToProfile,
            modifier = Modifier.fillMaxWidth().height(48.dp),
            colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
            shape = RoundedCornerShape(12.dp)
        ) {
            Text("ĐI TỚI HỒ SƠ", fontWeight = FontWeight.Bold)
        }
        Spacer(modifier = Modifier.height(8.dp))
        TextButton(
            onClick = onBack,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Quay lại", color = customColors.mutedText)
        }
    }
}

@Composable
private fun CheckInContent(
    state: WeeklyCheckInUiState.Input,
    onWeightChanged: (String) -> Unit,
    onEnergyChanged: (Int) -> Unit,
    onHungerChanged: (Int) -> Unit,
    onRecoveryChanged: (Int) -> Unit,
    onSleepQualityChanged: (Int) -> Unit,
    onNoteChanged: (String) -> Unit,
    onSubmit: () -> Unit,
    onBack: () -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors
    val scrollState = rememberScrollState()

    if (state.success) {
        AlertDialog(
            onDismissRequest = { /* stay */ },
            title = { Text("Thành công") },
            text = { Text("Check-in tuần đã được lưu thành công!") },
            confirmButton = {
                Button(
                    onClick = onBack,
                    colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange)
                ) {
                    Text("Đồng ý")
                }
            }
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(scrollState)
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        // Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                "Quay lại ⬅",
                color = EnergyOrange,
                fontWeight = FontWeight.Bold,
                modifier = Modifier
                    .clickable { onBack() }
                    .padding(vertical = 8.dp)
            )
            Spacer(modifier = Modifier.width(16.dp))
            Text(
                "CHECK-IN TUẦN",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = customColors.primaryText
            )
        }

        // Weight Input Card
        Card(
            colors = CardDefaults.cardColors(containerColor = colors.surfaceVariant),
            shape = RoundedCornerShape(16.dp),
            border = BorderStroke(1.dp, colors.outline)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    "Cân nặng tuần này",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = customColors.primaryText
                )
                OutlinedTextField(
                    value = state.weightKgStr,
                    onValueChange = onWeightChanged,
                    label = { Text("Cân nặng thực tế") },
                    trailingIcon = { Text("kg ") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = EnergyOrange,
                        focusedLabelColor = EnergyOrange
                    )
                )
            }
        }

        // Wellness Questions Card
        Card(
            colors = CardDefaults.cardColors(containerColor = colors.surfaceVariant),
            shape = RoundedCornerShape(16.dp),
            border = BorderStroke(1.dp, colors.outline)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(20.dp)
            ) {
                Text(
                    "Đánh giá thể trạng (Thang điểm 1 - 5)",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = customColors.primaryText
                )

                ScaleSelector(
                    label = "⚡ Mức năng lượng",
                    value = state.energy,
                    onValueSelected = onEnergyChanged
                )

                ScaleSelector(
                    label = "🍕 Mức thèm ăn",
                    value = state.hunger,
                    onValueSelected = onHungerChanged
                )

                ScaleSelector(
                    label = "🧘 Khả năng phục hồi",
                    value = state.recovery,
                    onValueSelected = onRecoveryChanged
                )

                ScaleSelector(
                    label = "😴 Chất lượng giấc ngủ",
                    value = state.sleepQuality,
                    onValueSelected = onSleepQualityChanged
                )
            }
        }

        // Notes Card
        Card(
            colors = CardDefaults.cardColors(containerColor = colors.surfaceVariant),
            shape = RoundedCornerShape(16.dp),
            border = BorderStroke(1.dp, colors.outline)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    "Ghi chú bổ sung",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = customColors.primaryText
                )
                OutlinedTextField(
                    value = state.note,
                    onValueChange = onNoteChanged,
                    label = { Text("Ghi chú cá nhân (tùy chọn)") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(100.dp),
                    maxLines = 4,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = EnergyOrange,
                        focusedLabelColor = EnergyOrange
                    )
                )
            }
        }

        // Validation Errors
        if (state.validationErrors.isNotEmpty()) {
            Surface(
                color = colors.errorContainer,
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    state.validationErrors.forEach { err ->
                        Text(
                            "- $err",
                            color = colors.onErrorContainer,
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }
            }
        }

        // Submit Error
        state.error?.let { err ->
            Text(
                text = err,
                color = colors.error,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center
            )
        }

        // Submit Button
        Button(
            onClick = onSubmit,
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp)
                .testTag("checkin-submit-button"),
            colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
            shape = RoundedCornerShape(12.dp),
            enabled = !state.isSubmitting
        ) {
            if (state.isSubmitting) {
                CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
            } else {
                Text(
                    "LƯU CHECK-IN",
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp
                )
            }
        }
    }
}

@Composable
private fun ScaleSelector(
    label: String,
    value: Int,
    onValueSelected: (Int) -> Unit
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors
    Column {
        Text(
            label,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Bold,
            color = customColors.primaryText
        )
        Spacer(modifier = Modifier.height(6.dp))
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            (1..5).forEach { num ->
                val selected = value == num
                Surface(
                    modifier = Modifier
                        .weight(1f)
                        .height(48.dp)
                        .clickable { onValueSelected(num) },
                    shape = RoundedCornerShape(8.dp),
                    border = BorderStroke(1.dp, if (selected) EnergyOrange else colors.outline),
                    color = if (selected) customColors.orangeLight else colors.background
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(
                            num.toString(),
                            fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal,
                            color = if (selected) EnergyOrange else customColors.primaryText
                        )
                    }
                }
            }
        }
    }
}
