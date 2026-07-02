package com.example.myapplication.feature.profile

import android.app.DatePickerDialog
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.myapplication.core.profile.ActivityLevel
import com.example.myapplication.core.profile.GoalPace
import com.example.myapplication.core.profile.MetabolicSex
import com.example.myapplication.ui.theme.EnergyOrange
import com.example.myapplication.ui.theme.customColors
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@Composable
fun ProfileScreen(
    state: ProfileUiState,
    onBirthDateChanged: (Long) -> Unit,
    onMetabolicSexChanged: (MetabolicSex) -> Unit,
    onHeightChanged: (String) -> Unit,
    onCurrentWeightChanged: (String) -> Unit,
    onTargetWeightChanged: (String) -> Unit,
    onActivityLevelChanged: (ActivityLevel) -> Unit,
    onGoalPaceChanged: (GoalPace) -> Unit,
    onPersonalizationConsentChanged: (Boolean) -> Unit,
    onCloudAiConsentChanged: (Boolean) -> Unit,
    onSave: () -> Unit,
    onBack: () -> Unit,
    onNavigateToSettings: (() -> Unit)? = null,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
    ) {
        when (state) {
            ProfileUiState.Loading -> Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = EnergyOrange)
            }
            is ProfileUiState.Content -> ProfileContent(
                state = state,
                onBirthDateChanged = onBirthDateChanged,
                onMetabolicSexChanged = onMetabolicSexChanged,
                onHeightChanged = onHeightChanged,
                onCurrentWeightChanged = onCurrentWeightChanged,
                onTargetWeightChanged = onTargetWeightChanged,
                onActivityLevelChanged = onActivityLevelChanged,
                onGoalPaceChanged = onGoalPaceChanged,
                onPersonalizationConsentChanged = onPersonalizationConsentChanged,
                onCloudAiConsentChanged = onCloudAiConsentChanged,
                onSave = onSave,
                onBack = onBack,
                onNavigateToSettings = onNavigateToSettings
            )
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ProfileContent(
    state: ProfileUiState.Content,
    onBirthDateChanged: (Long) -> Unit,
    onMetabolicSexChanged: (MetabolicSex) -> Unit,
    onHeightChanged: (String) -> Unit,
    onCurrentWeightChanged: (String) -> Unit,
    onTargetWeightChanged: (String) -> Unit,
    onActivityLevelChanged: (ActivityLevel) -> Unit,
    onGoalPaceChanged: (GoalPace) -> Unit,
    onPersonalizationConsentChanged: (Boolean) -> Unit,
    onCloudAiConsentChanged: (Boolean) -> Unit,
    onSave: () -> Unit,
    onBack: () -> Unit,
    onNavigateToSettings: (() -> Unit)?,
) {
    val context = LocalContext.current
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors
    val scrollState = rememberScrollState()

    val birthLocalDate = LocalDate.ofEpochDay(state.birthDateEpochDay)
    val formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy")
    val birthDateStr = birthLocalDate.format(formatter)

    val datePickerDialog = remember(context, state.birthDateEpochDay) {
        DatePickerDialog(
            context,
            { _, year, month, dayOfMonth ->
                onBirthDateChanged(LocalDate.of(year, month + 1, dayOfMonth).toEpochDay())
            },
            birthLocalDate.year,
            birthLocalDate.monthValue - 1,
            birthLocalDate.dayOfMonth
        )
    }

    if (state.success) {
        AlertDialog(
            onDismissRequest = { /* stay */ },
            title = { Text("Thành công") },
            text = { Text("Hồ sơ cá nhân và mục tiêu dinh dưỡng đã được cập nhật thành công!") },
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
        // Header Row with optional Settings gear button
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (onNavigateToSettings == null) {
                    Text(
                        "Quay lại ⬅",
                        color = EnergyOrange,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier
                            .clickable { onBack() }
                            .padding(vertical = 8.dp)
                    )
                    Spacer(modifier = Modifier.width(16.dp))
                }
                Text(
                    "HỒ SƠ CÁ NHÂN",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = customColors.primaryText
                )
            }
            if (onNavigateToSettings != null) {
                Text(
                    "⚙️",
                    fontSize = 24.sp,
                    modifier = Modifier
                        .clickable { onNavigateToSettings() }
                        .padding(8.dp)
                )
            }
        }

        // Card containing General Profile Info
        Card(
            colors = CardDefaults.cardColors(containerColor = colors.surfaceVariant),
            shape = RoundedCornerShape(16.dp),
            border = BorderStroke(1.dp, colors.outline)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text(
                    "Thông tin cơ bản",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = customColors.primaryText
                )

                // Birthdate picker
                Column {
                    Text(
                        "Ngày sinh",
                        style = MaterialTheme.typography.bodySmall,
                        color = customColors.mutedText
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Surface(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(56.dp)
                            .clickable { datePickerDialog.show() },
                        shape = RoundedCornerShape(8.dp),
                        border = BorderStroke(1.dp, colors.outline),
                        color = colors.background
                    ) {
                        Box(
                            contentAlignment = Alignment.CenterStart,
                            modifier = Modifier.padding(horizontal = 12.dp)
                        ) {
                            Text(
                                text = birthDateStr,
                                style = MaterialTheme.typography.bodyLarge,
                                color = customColors.primaryText
                            )
                        }
                    }
                }

                // Metabolic Sex selection
                Column {
                    Text(
                        "Giới tính sinh học (để tính mức tiêu hao năng lượng)",
                        style = MaterialTheme.typography.bodySmall,
                        color = customColors.mutedText
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        listOf(
                            MetabolicSex.MALE to "Nam",
                            MetabolicSex.FEMALE to "Nữ"
                        ).forEach { (sex, label) ->
                            val selected = state.metabolicSex == sex
                            Surface(
                                modifier = Modifier
                                    .weight(1f)
                                    .height(48.dp)
                                    .selectable(
                                        selected = selected,
                                        role = Role.RadioButton,
                                        onClick = { onMetabolicSexChanged(sex) }
                                    ),
                                shape = RoundedCornerShape(8.dp),
                                border = BorderStroke(1.dp, if (selected) EnergyOrange else colors.outline),
                                color = if (selected) customColors.orangeLight else colors.background
                            ) {
                                Box(contentAlignment = Alignment.Center) {
                                    Text(
                                        label,
                                        fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal,
                                        color = if (selected) EnergyOrange else customColors.primaryText
                                    )
                                }
                            }
                        }
                    }
                }

                // Height and Weight
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    OutlinedTextField(
                        value = state.heightCmStr,
                        onValueChange = onHeightChanged,
                        label = { Text("Chiều cao") },
                        trailingIcon = { Text("cm ") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        modifier = Modifier.weight(1f),
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = EnergyOrange,
                            focusedLabelColor = EnergyOrange
                        )
                    )

                    OutlinedTextField(
                        value = state.currentWeightKgStr,
                        onValueChange = onCurrentWeightChanged,
                        label = { Text("Cân nặng") },
                        trailingIcon = { Text("kg ") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        modifier = Modifier.weight(1f),
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = EnergyOrange,
                            focusedLabelColor = EnergyOrange
                        )
                    )
                }

                OutlinedTextField(
                    value = state.targetWeightKgStr,
                    onValueChange = onTargetWeightChanged,
                    label = { Text("Cân nặng mục tiêu") },
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

        // Activity Level & Goal Pace
        Card(
            colors = CardDefaults.cardColors(containerColor = colors.surfaceVariant),
            shape = RoundedCornerShape(16.dp),
            border = BorderStroke(1.dp, colors.outline)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text(
                    "Hoạt động & Tốc độ mục tiêu",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = customColors.primaryText
                )

                // Activity level
                Column {
                    Text(
                        "Mức độ hoạt động hằng ngày",
                        style = MaterialTheme.typography.bodySmall,
                        color = customColors.mutedText
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        listOf(
                            ActivityLevel.SEDENTARY to "Ít vận động (Nhân viên văn phòng)",
                            ActivityLevel.LIGHT to "Vận động nhẹ (Luyện tập 1-3 ngày/tuần)",
                            ActivityLevel.MODERATE to "Vận động vừa (Luyện tập 3-5 ngày/tuần)",
                            ActivityLevel.HIGH to "Vận động nhiều (Luyện tập 6-7 ngày/tuần)"
                        ).forEach { (level, label) ->
                            val selected = state.activityLevel == level
                            Surface(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(48.dp)
                                    .selectable(
                                        selected = selected,
                                        role = Role.RadioButton,
                                        onClick = { onActivityLevelChanged(level) }
                                    ),
                                shape = RoundedCornerShape(8.dp),
                                border = BorderStroke(1.dp, if (selected) EnergyOrange else colors.outline),
                                color = if (selected) customColors.orangeLight else colors.background
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    modifier = Modifier.padding(horizontal = 12.dp)
                                ) {
                                    RadioButton(
                                        selected = selected,
                                        onClick = null,
                                        colors = RadioButtonDefaults.colors(selectedColor = EnergyOrange)
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        label,
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = if (selected) EnergyOrange else customColors.primaryText
                                    )
                                }
                            }
                        }
                    }
                }

                // Goal Pace
                Column {
                    Text(
                        "Tốc độ điều chỉnh cân nặng mong muốn",
                        style = MaterialTheme.typography.bodySmall,
                        color = customColors.mutedText
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        listOf(
                            GoalPace.GRADUAL to "Từ từ (Bền vững)",
                            GoalPace.STANDARD to "Tiêu chuẩn (Khuyến nghị)"
                        ).forEach { (pace, label) ->
                            val selected = state.goalPace == pace
                            Surface(
                                modifier = Modifier
                                    .weight(1f)
                                    .height(48.dp)
                                    .selectable(
                                        selected = selected,
                                        role = Role.RadioButton,
                                        onClick = { onGoalPaceChanged(pace) }
                                    ),
                                shape = RoundedCornerShape(8.dp),
                                border = BorderStroke(1.dp, if (selected) EnergyOrange else colors.outline),
                                color = if (selected) customColors.orangeLight else colors.background
                            ) {
                                Box(contentAlignment = Alignment.Center) {
                                    Text(
                                        label,
                                        fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal,
                                        color = if (selected) EnergyOrange else customColors.primaryText,
                                        textAlign = TextAlign.Center,
                                        fontSize = 13.sp
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        // Consents and Rules
        Card(
            colors = CardDefaults.cardColors(containerColor = colors.surfaceVariant),
            shape = RoundedCornerShape(16.dp),
            border = BorderStroke(1.dp, colors.outline)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text(
                    "Quyền riêng tư & Cam kết",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = customColors.primaryText
                )

                // Consent 1: Personalization
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Checkbox(
                        checked = state.personalizationConsent,
                        onCheckedChange = onPersonalizationConsentChanged,
                        colors = CheckboxDefaults.colors(checkedColor = EnergyOrange)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            "Đồng ý cá nhân hóa dinh dưỡng",
                            fontWeight = FontWeight.Bold,
                            color = customColors.primaryText,
                            style = MaterialTheme.typography.bodyMedium
                        )
                        Text(
                            "Cho phép ứng dụng sử dụng các chỉ số cơ thể để tính toán calo & macros mục tiêu ngoại tuyến.",
                            color = customColors.mutedText,
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }

                // Consent 2: Cloud AI Consent
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Checkbox(
                        checked = state.cloudAiConsent,
                        onCheckedChange = onCloudAiConsentChanged,
                        colors = CheckboxDefaults.colors(checkedColor = EnergyOrange)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            "Đồng ý gửi dữ liệu ẩn danh lên AI Coach",
                            fontWeight = FontWeight.Bold,
                            color = customColors.primaryText,
                            style = MaterialTheme.typography.bodyMedium
                        )
                        Text(
                            "Cho phép gửi ẩn danh các chỉ số dinh dưỡng ngày (không bao gồm thông tin cá nhân) để nhận lời khuyên thông minh từ AI.",
                            color = customColors.mutedText,
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            }
        }

        // Display Validation Errors if any
        if (state.validationErrors.isNotEmpty()) {
            Surface(
                color = colors.errorContainer,
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Text(
                        "Vui lòng sửa các lỗi sau:",
                        fontWeight = FontWeight.Bold,
                        color = colors.onErrorContainer,
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Spacer(modifier = Modifier.height(4.dp))
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

        // Display Save Error if any
        state.saveError?.let { err ->
            Text(
                text = err,
                color = colors.error,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center
            )
        }

        // Save Button
        Button(
            onClick = onSave,
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp)
                .testTag("profile-save-button"),
            colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
            shape = RoundedCornerShape(12.dp),
            enabled = !state.isSaving
        ) {
            if (state.isSaving) {
                CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
            } else {
                Text(
                    "LƯU HỒ SƠ",
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp
                )
            }
        }
    }
}
