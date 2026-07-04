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
import androidx.compose.animation.core.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.myapplication.ui.theme.EnergyOrange
import com.example.myapplication.ui.theme.SuccessGreen
import com.example.myapplication.ui.theme.customColors
import com.example.myapplication.core.nutrition.NutritionDay
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardType
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import androidx.compose.ui.platform.LocalLifecycleOwner
import java.util.concurrent.Executors
import android.annotation.SuppressLint
import com.example.myapplication.core.nutrition.MealTemplate

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NutritionScreen(
    state: NutritionUiState,
    onBack: () -> Unit,
    onScan: (Bitmap) -> Unit,
    onScanBarcode: (String) -> Unit = {},
    onAccept: () -> Unit,
    onDiscard: () -> Unit,
    onUpdateResult: (String, Int, Int, Int, Int) -> Unit,
    onClearSweat: () -> Unit,
    onReset: () -> Unit,
    onStartManual: () -> Unit = {},
    onDraftName: (String) -> Unit = {},
    onDraftCalories: (String) -> Unit = {},
    onDraftProtein: (String) -> Unit = {},
    onDraftCarbs: (String) -> Unit = {},
    onDraftFat: (String) -> Unit = {},
    onDraftSaveAsTemplate: (Boolean) -> Unit = {},
    onApplyTemplate: (Long) -> Unit = {},
    onRequestDeleteTemplate: (Long) -> Unit = {},
    onCancelDeleteTemplate: () -> Unit = {},
    onConfirmDeleteTemplate: () -> Unit = {},
    onStartRenameTemplate: (Long) -> Unit = {},
    onUpdateTemplateName: (String) -> Unit = {},
    onCancelRenameTemplate: () -> Unit = {},
    onConfirmRenameTemplate: () -> Unit = {},
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

    var showBarcodeDialog by remember { mutableStateOf(false) }

    val barcodePermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            showBarcodeDialog = true
        }
    }

    if (showBarcodeDialog) {
        BarcodeScannerDialog(
            onDismiss = { showBarcodeDialog = false },
            onBarcodeScanned = { barcode ->
                onScanBarcode(barcode)
            }
        )
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
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
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
                        } else {
                            // Dual scan actions: Food photo, Barcode scan, or Manual entry
                            Row(
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Button(
                                    onClick = { permissionLauncher.launch(android.Manifest.permission.CAMERA) },
                                    enabled = !state.savingDraft,
                                    colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
                                    shape = RoundedCornerShape(16.dp),
                                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 8.dp),
                                    modifier = Modifier
                                        .weight(1f)
                                        .height(56.dp)
                                ) {
                                    Text("📸 Chụp đĩa ăn", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Color.White, maxLines = 1)
                                }
                                OutlinedButton(
                                    onClick = { barcodePermissionLauncher.launch(android.Manifest.permission.CAMERA) },
                                    enabled = !state.savingDraft,
                                    shape = RoundedCornerShape(16.dp),
                                    border = androidx.compose.foundation.BorderStroke(1.dp, EnergyOrange),
                                    colors = ButtonDefaults.outlinedButtonColors(contentColor = EnergyOrange),
                                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 8.dp),
                                    modifier = Modifier
                                        .weight(1f)
                                        .height(56.dp)
                                ) {
                                    Text("🔍 Mã vạch", fontSize = 13.sp, fontWeight = FontWeight.Bold, maxLines = 1)
                                }
                                OutlinedButton(
                                    onClick = onStartManual,
                                    enabled = !state.savingDraft,
                                    shape = RoundedCornerShape(16.dp),
                                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 8.dp),
                                    modifier = Modifier
                                        .weight(1f)
                                        .height(56.dp)
                                ) {
                                    Text("Nhập tay", fontSize = 13.sp, fontWeight = FontWeight.Bold, maxLines = 1)
                                }
                            }
                        }

                        state.scanError?.let { error ->
                            Text(error, color = colors.error, textAlign = TextAlign.Center, style = MaterialTheme.typography.bodySmall)
                        }

                        Spacer(Modifier.height(16.dp))

                        Text(
                            "Bữa ăn đã lưu",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = customColors.primaryText,
                            modifier = Modifier.fillMaxWidth(),
                        )
                        if (state.mealTemplates.isEmpty()) {
                            Text(
                                "Chưa có mẫu. Nhập một món và chọn lưu làm mẫu để dùng lại.",
                                color = customColors.mutedText,
                                modifier = Modifier.fillMaxWidth(),
                            )
                        } else {
                            state.mealTemplates.forEach { template ->
                                MealTemplateCard(
                                    template = template,
                                    enabled = !state.savingDraft,
                                    onApply = { onApplyTemplate(template.id) },
                                    onRename = { onStartRenameTemplate(template.id) },
                                    onDelete = { onRequestDeleteTemplate(template.id) },
                                )
                            }
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

                        Spacer(Modifier.height(24.dp))

                        // Title
                        Text(
                            text = "Lịch sử dinh dưỡng 📊",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = customColors.primaryText,
                            modifier = Modifier.fillMaxWidth(),
                            textAlign = TextAlign.Start
                        )

                        if (state.history.isEmpty()) {
                            Surface(
                                color = colors.surfaceVariant,
                                shape = RoundedCornerShape(16.dp),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text(
                                    text = "Chưa có lịch sử dinh dưỡng những ngày trước.",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = customColors.mutedText,
                                    modifier = Modifier.padding(20.dp),
                                    textAlign = TextAlign.Center
                                )
                            }
                        } else {
                            state.history.forEach { day ->
                                HistoryItemCard(day)
                            }
                        }
                    }
                    state.draft?.let { draft ->
                        NutritionDraftDialog(
                            draft = draft,
                            saving = state.savingDraft,
                            onName = onDraftName,
                            onCalories = onDraftCalories,
                            onProtein = onDraftProtein,
                            onCarbs = onDraftCarbs,
                            onFat = onDraftFat,
                            onSaveAsTemplate = onDraftSaveAsTemplate,
                            onAccept = onAccept,
                            onDiscard = onDiscard,
                        )
                    }
                    if (state.pendingDeleteTemplateId != null) {
                        AlertDialog(
                            onDismissRequest = onCancelDeleteTemplate,
                            title = { Text("Xóa bữa ăn đã lưu?") },
                            text = { Text("Lịch sử dinh dưỡng đã ghi sẽ không bị thay đổi.") },
                            dismissButton = { TextButton(onClick = onCancelDeleteTemplate) { Text("Hủy") } },
                            confirmButton = { TextButton(onClick = onConfirmDeleteTemplate) { Text("Xóa") } },
                        )
                    }
                    state.templateNameEdit?.let { edit ->
                        AlertDialog(
                            onDismissRequest = onCancelRenameTemplate,
                            title = { Text("Sửa tên bữa ăn") },
                            text = {
                                Column {
                                    OutlinedTextField(
                                        value = edit.nameVi,
                                        onValueChange = onUpdateTemplateName,
                                        label = { Text("Tên món") },
                                        enabled = !state.savingDraft,
                                    )
                                    edit.error?.let { Text(it, color = colors.error) }
                                }
                            },
                            dismissButton = { TextButton(onClick = onCancelRenameTemplate) { Text("Hủy") } },
                            confirmButton = { TextButton(onClick = onConfirmRenameTemplate) { Text("Lưu") } },
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun NutritionDraftDialog(
    draft: EditableNutritionDraft,
    saving: Boolean,
    onName: (String) -> Unit,
    onCalories: (String) -> Unit,
    onProtein: (String) -> Unit,
    onCarbs: (String) -> Unit,
    onFat: (String) -> Unit,
    onSaveAsTemplate: (Boolean) -> Unit,
    onAccept: () -> Unit,
    onDiscard: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = { if (!saving) onDiscard() },
        title = { Text("Kiểm tra món ăn", fontWeight = FontWeight.Bold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                DraftField("Tên món", draft.nameVi, onName, draft.errors["nameVi"], false, saving)
                DraftField("Calo", draft.caloriesText, onCalories, draft.errors["calories"], true, saving)
                DraftField("Đạm (g)", draft.proteinText, onProtein, draft.errors["protein"], true, saving)
                DraftField("Tinh bột (g)", draft.carbsText, onCarbs, draft.errors["carbs"], true, saving)
                DraftField("Chất béo (g)", draft.fatText, onFat, draft.errors["fat"], true, saving)
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Checkbox(
                        checked = draft.saveAsTemplate,
                        onCheckedChange = onSaveAsTemplate,
                        enabled = !saving,
                    )
                    Text("Lưu làm bữa ăn mẫu")
                }
                draft.errors["submit"]?.let { Text(it, color = MaterialTheme.colorScheme.error) }
                if (saving) LinearProgressIndicator(Modifier.fillMaxWidth())
            }
        },
        dismissButton = { TextButton(onClick = onDiscard, enabled = !saving) { Text("Hủy") } },
        confirmButton = { TextButton(onClick = onAccept, enabled = !saving) { Text("Thêm") } },
    )
}

@Composable
private fun DraftField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    error: String?,
    numeric: Boolean,
    saving: Boolean,
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(label) },
        isError = error != null,
        supportingText = error?.let { message -> { Text(message) } },
        keyboardOptions = if (numeric) {
            androidx.compose.foundation.text.KeyboardOptions(
                keyboardType = androidx.compose.ui.text.input.KeyboardType.Number,
            )
        } else androidx.compose.foundation.text.KeyboardOptions.Default,
        enabled = !saving,
        singleLine = true,
        modifier = Modifier.fillMaxWidth(),
    )
}

@Composable
private fun MealTemplateCard(
    template: MealTemplate,
    enabled: Boolean,
    onApply: () -> Unit,
    onRename: () -> Unit,
    onDelete: () -> Unit,
) {
    Surface(
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = RoundedCornerShape(14.dp),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(template.nameVi, fontWeight = FontWeight.Bold)
            Text(
                "${template.nutrients.calories} kcal · ${template.nutrients.proteinGrams}g đạm · " +
                    "${template.nutrients.carbsGrams}g carb · ${template.nutrients.fatGrams}g béo",
                style = MaterialTheme.typography.bodySmall,
            )
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Button(
                    onClick = onApply,
                    enabled = enabled,
                    modifier = Modifier.testTag("meal-template-apply-${template.id}"),
                ) { Text("Thêm") }
                TextButton(onClick = onRename, enabled = enabled) { Text("Sửa tên") }
                TextButton(onClick = onDelete, enabled = enabled) { Text("Xóa") }
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
    onUpdateResult: (String, Int, Int, Int, Int) -> Unit,
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
            
            if (result.confidence < 0.80 || result.needsUserConfirmation) {
                val warningText = if (result.needsUserConfirmation) {
                    "⚠️ Món ăn tự nấu/ước lượng từ ảnh: Vui lòng kiểm tra và chỉnh lại số liệu cho khớp khẩu phần thực tế."
                } else {
                    "⚠️ Độ tin cậy thấp: Vui lòng kiểm tra kỹ các thông số Calo và Macros."
                }
                Surface(
                    color = colors.errorContainer,
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = warningText,
                        style = MaterialTheme.typography.bodySmall,
                        color = colors.onErrorContainer,
                        modifier = Modifier.padding(12.dp)
                    )
                }
            }

            OutlinedTextField(
                value = result.dishName,
                onValueChange = { onUpdateResult(it, result.totalCalories, result.proteinGrams, result.carbsGrams, result.fatGrams) },
                label = { Text("Tên món ăn") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = EnergyOrange,
                    focusedLabelColor = EnergyOrange
                )
            )

            var selectedPortion by remember { mutableStateOf("Vừa") }
            val originalCalories = remember(result.dishName) { result.totalCalories }
            val originalProtein = remember(result.dishName) { result.proteinGrams }
            val originalCarbs = remember(result.dishName) { result.carbsGrams }
            val originalFat = remember(result.dishName) { result.fatGrams }

            Text("Khẩu phần nhanh:", fontWeight = FontWeight.Bold, color = customColors.primaryText)
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                val portions = listOf(
                    Triple("Nhỏ (0.7x)", 0.7, "Nhỏ"),
                    Triple("Vừa (1.0x)", 1.0, "Vừa"),
                    Triple("Lớn (1.3x)", 1.3, "Lớn")
                )
                portions.forEach { (label, multiplier, portionName) ->
                    val isSelected = selectedPortion == portionName
                    Button(
                        onClick = {
                            selectedPortion = portionName
                            val newCal = Math.round(originalCalories * multiplier).toInt()
                            val newProtein = Math.round(originalProtein * multiplier).toInt()
                            val newCarbs = Math.round(originalCarbs * multiplier).toInt()
                            val newFat = Math.round(originalFat * multiplier).toInt()
                            onUpdateResult(result.dishName, newCal, newProtein, newCarbs, newFat)
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = if (isSelected) EnergyOrange else colors.surface,
                            contentColor = if (isSelected) Color.White else customColors.primaryText
                        ),
                        border = androidx.compose.foundation.BorderStroke(1.dp, if (isSelected) EnergyOrange else colors.outline),
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier.weight(1f),
                        contentPadding = PaddingValues(horizontal = 4.dp, vertical = 8.dp)
                    ) {
                        Text(label, style = MaterialTheme.typography.bodySmall, maxLines = 1)
                    }
                }
            }

            HorizontalDivider(color = colors.outline)

            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                OutlinedTextField(
                    value = if (result.totalCalories == 0) "" else result.totalCalories.toString(),
                    onValueChange = { newValue ->
                        val cal = newValue.toIntOrNull() ?: 0
                        onUpdateResult(result.dishName, cal, result.proteinGrams, result.carbsGrams, result.fatGrams)
                    },
                    label = { Text("🔥 Calo") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = EnergyOrange,
                        focusedLabelColor = EnergyOrange
                    )
                )
                OutlinedTextField(
                    value = if (result.proteinGrams == 0) "" else result.proteinGrams.toString(),
                    onValueChange = { newValue ->
                        val protein = newValue.toIntOrNull() ?: 0
                        onUpdateResult(result.dishName, result.totalCalories, protein, result.carbsGrams, result.fatGrams)
                    },
                    label = { Text("💪 Đạm (g)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = EnergyOrange,
                        focusedLabelColor = EnergyOrange
                    )
                )
            }

            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                OutlinedTextField(
                    value = if (result.carbsGrams == 0) "" else result.carbsGrams.toString(),
                    onValueChange = { newValue ->
                        val carbs = newValue.toIntOrNull() ?: 0
                        onUpdateResult(result.dishName, result.totalCalories, result.proteinGrams, carbs, result.fatGrams)
                    },
                    label = { Text("🍚 Tinh bột (g)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = EnergyOrange,
                        focusedLabelColor = EnergyOrange
                    )
                )
                OutlinedTextField(
                    value = if (result.fatGrams == 0) "" else result.fatGrams.toString(),
                    onValueChange = { newValue ->
                        val fat = newValue.toIntOrNull() ?: 0
                        onUpdateResult(result.dishName, result.totalCalories, result.proteinGrams, result.carbsGrams, fat)
                    },
                    label = { Text("🥑 Chất béo (g)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = EnergyOrange,
                        focusedLabelColor = EnergyOrange
                    )
                )
            }

            HorizontalDivider(color = colors.outline)

            Text("Lời khuyên dinh dưỡng:", fontWeight = FontWeight.Bold, color = customColors.primaryText)
            Text(result.advice, color = customColors.primaryText, style = MaterialTheme.typography.bodyMedium)

            if (!result.calculationProcess.isNullOrEmpty()) {
                Surface(
                    color = colors.surface,
                    shape = RoundedCornerShape(12.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, colors.outlineVariant),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(
                            "🧮 Cơ chế & Phép tính của AI:",
                            fontWeight = FontWeight.Bold,
                            color = EnergyOrange,
                            style = MaterialTheme.typography.bodySmall
                        )
                        Text(
                            result.calculationProcess,
                            style = MaterialTheme.typography.bodySmall,
                            color = customColors.primaryText
                        )
                    }
                }
            }

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

@Composable
private fun HistoryItemCard(day: NutritionDay) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    val targetCalories = day.target?.calories ?: 2000
    val caloriesEaten = day.consumed.calories
    val progress = if (targetCalories > 0) caloriesEaten.toFloat() / targetCalories else 0f
    val isOverLimit = caloriesEaten > targetCalories

    val localDate = java.time.LocalDate.ofEpochDay(day.epochDay)
    val vietnamese = java.util.Locale.forLanguageTag("vi-VN")
    val formatter = java.time.format.DateTimeFormatter.ofPattern("EEEE, dd/MM", vietnamese)

    val today = java.time.LocalDate.now().toEpochDay()
    val dateText = when (day.epochDay) {
        today - 1 -> "Hôm qua"
        else -> localDate.format(formatter).replaceFirstChar {
            if (it.isLowerCase()) it.titlecase(vietnamese) else it.toString()
        }
    }

    Surface(
        color = colors.surfaceVariant,
        shape = RoundedCornerShape(16.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = dateText,
                        fontWeight = FontWeight.Bold,
                        color = customColors.primaryText,
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Spacer(Modifier.height(4.dp))
                    Text(
                        text = "Đạm: ${day.consumed.proteinGrams}g  •  Tinh bột: ${day.consumed.carbsGrams}g  •  Béo: ${day.consumed.fatGrams}g",
                        style = MaterialTheme.typography.bodySmall,
                        color = customColors.mutedText
                    )
                }

                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = "$caloriesEaten / $targetCalories kcal",
                        fontWeight = FontWeight.Bold,
                        color = if (isOverLimit) colors.error else SuccessGreen,
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Spacer(Modifier.height(4.dp))
                    Text(
                        text = "${(progress * 100).toInt()}% mục tiêu",
                        style = MaterialTheme.typography.labelSmall,
                        color = customColors.mutedText
                    )
                }
            }

            Spacer(Modifier.height(10.dp))
            LinearProgressIndicator(
                progress = { progress.coerceAtMost(1f) },
                color = if (isOverLimit) colors.error else SuccessGreen,
                trackColor = colors.outline,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(6.dp)
                    .clip(RoundedCornerShape(3.dp))
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BarcodeScannerDialog(
    onDismiss: () -> Unit,
    onBarcodeScanned: (String) -> Unit
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors
    var manualBarcode by remember { mutableStateOf("") }
    
    val infiniteTransition = rememberInfiniteTransition()
    val laserYPercent by infiniteTransition.animateFloat(
        initialValue = 0.05f,
        targetValue = 0.95f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1500, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        )
    )

    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Đóng", color = colors.error)
            }
        },
        title = {
            Text("Quét mã vạch sản phẩm 🔍", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = EnergyOrange)
        },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    "Đang quét bằng Camera (Chạy Offline)...",
                    style = MaterialTheme.typography.bodySmall,
                    color = customColors.mutedText
                )
                
                Box(
                    modifier = Modifier
                        .size(width = 240.dp, height = 120.dp)
                        .background(Color.Black.copy(alpha = 0.05f), RoundedCornerShape(12.dp))
                        .border(2.dp, EnergyOrange, RoundedCornerShape(12.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    BarcodeCameraPreview(
                        modifier = Modifier.fillMaxSize().clip(RoundedCornerShape(12.dp)),
                        onBarcodeScanned = { barcode ->
                            onBarcodeScanned(barcode)
                            onDismiss()
                        }
                    )
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(2.dp)
                            .background(Color.Red)
                            .align(Alignment.TopCenter)
                            .offset(y = (140 * laserYPercent).dp)
                    )
                }

                Text(
                    "Chọn nhanh sản phẩm mẫu hoặc tự nhập số mã vạch:",
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Bold,
                    color = customColors.primaryText,
                    textAlign = TextAlign.Start,
                    modifier = Modifier.fillMaxWidth()
                )

                val mocks = listOf(
                    "8934563138073" to "Snack Toonies Chef 57g",
                    "8936011773005" to "Sữa TH True Milk 180ml",
                    "8934563128906" to "Mì Hảo Hảo Chua Cay"
                )
                
                mocks.forEach { (code, name) ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                onBarcodeScanned(code)
                                onDismiss()
                            },
                        shape = RoundedCornerShape(8.dp),
                        border = androidx.compose.foundation.BorderStroke(1.dp, colors.outlineVariant),
                        colors = CardDefaults.cardColors(containerColor = colors.surface)
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(name, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, color = customColors.primaryText, maxLines = 1)
                                Text(code, style = MaterialTheme.typography.bodySmall, color = customColors.mutedText)
                            }
                            Text("Quét ✓", color = EnergyOrange, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.bodySmall, maxLines = 1)
                        }
                    }
                }

                HorizontalDivider(color = colors.outlineVariant)

                OutlinedTextField(
                    value = manualBarcode,
                    onValueChange = { manualBarcode = it },
                    label = { Text("Tự nhập mã vạch thủ công") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = EnergyOrange,
                        focusedLabelColor = EnergyOrange
                    ),
                    trailingIcon = {
                        if (manualBarcode.isNotEmpty()) {
                            TextButton(
                                onClick = {
                                    onBarcodeScanned(manualBarcode)
                                    onDismiss()
                                }
                            ) {
                                Text("Nhập", color = EnergyOrange, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                )
            }
        }
    )
}

@Composable
fun BarcodeCameraPreview(
    modifier: Modifier = Modifier,
    onBarcodeScanned: (String) -> Unit
) {
    val context = androidx.compose.ui.platform.LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val cameraProviderFuture = remember { ProcessCameraProvider.getInstance(context) }
    val executor = remember { java.util.concurrent.Executors.newSingleThreadExecutor() }

    AndroidView(
        factory = { ctx ->
            val previewView = PreviewView(ctx).apply {
                scaleType = PreviewView.ScaleType.FILL_CENTER
            }

            cameraProviderFuture.addListener({
                val cameraProvider = cameraProviderFuture.get()
                val preview = Preview.Builder().build().also {
                    it.surfaceProvider = previewView.surfaceProvider
                }

                val imageAnalysis = ImageAnalysis.Builder()
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .build()
                    .also {
                        it.setAnalyzer(executor, BarcodeAnalyzer { barcode ->
                            previewView.post {
                                onBarcodeScanned(barcode)
                            }
                        })
                    }

                val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

                try {
                    cameraProvider.unbindAll()
                    cameraProvider.bindToLifecycle(
                        lifecycleOwner,
                        cameraSelector,
                        preview,
                        imageAnalysis
                    )
                } catch (e: Exception) {
                    android.util.Log.e("BarcodeCameraPreview", "Camera binding failed", e)
                }
            }, ContextCompat.getMainExecutor(context))

            previewView
        },
        modifier = modifier
    )
}

@SuppressLint("UnsafeOptInUsageError")
private class BarcodeAnalyzer(
    private val onBarcodeScanned: (String) -> Unit
) : ImageAnalysis.Analyzer {
    private val scanner = BarcodeScanning.getClient(
        BarcodeScannerOptions.Builder()
            .setBarcodeFormats(Barcode.FORMAT_ALL_FORMATS)
            .build()
    )

    private var isCooldown = false
    private var lastScanTime = 0L

    override fun analyze(imageProxy: ImageProxy) {
        val mediaImage = imageProxy.image
        if (mediaImage != null) {
            val now = System.currentTimeMillis()
            if (isCooldown && now - lastScanTime < 3000) {
                imageProxy.close()
                return
            }
            
            val image = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
            scanner.process(image)
                .addOnSuccessListener { barcodes ->
                    val barcode = barcodes.firstOrNull()?.rawValue
                    if (barcode != null) {
                        isCooldown = true
                        lastScanTime = now
                        onBarcodeScanned(barcode)
                    }
                }
                .addOnFailureListener {
                    // Ignore errors
                }
                .addOnCompleteListener {
                    imageProxy.close()
                }
        } else {
            imageProxy.close()
        }
    }
}
