package com.example.myapplication.feature.nutrition

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.example.myapplication.core.nutrition.NutritionDay
import com.example.myapplication.core.nutrition.NutritionScoreCalculator
import com.example.myapplication.core.nutrition.NutritionTarget
import com.example.myapplication.core.nutrition.NutritionTargetAudit
import com.example.myapplication.data.local.FoodCatalogEntity
import com.example.myapplication.ui.theme.EnergyOrange
import com.example.myapplication.ui.theme.SuccessGreen
import com.example.myapplication.ui.theme.customColors
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NutritionScreen(
    state: NutritionUiState,
    onBack: () -> Unit,
    onScan: (android.graphics.Bitmap) -> Unit,
    onScanBarcode: (String) -> Unit = {},
    onAccept: () -> Unit,
    onDiscard: () -> Unit,
    onUpdateResult: (String, Int, Int, Int, Int) -> Unit,
    onClearSweat: () -> Unit,
    onReset: () -> Unit,
    onAddWater: (Int) -> Unit = {},
    onStartManual: () -> Unit = {},
    onDraftName: (String) -> Unit = {},
    onDraftCalories: (String) -> Unit = {},
    onDraftProtein: (String) -> Unit = {},
    onDraftCarbs: (String) -> Unit = {},
    onDraftFat: (String) -> Unit = {},
    onDraftFiber: (String) -> Unit = {},
    onDraftSaveAsTemplate: (Boolean) -> Unit = {},
    onApplyTemplate: (Long) -> Unit = {},
    onRequestDeleteTemplate: (Long) -> Unit = {},
    onCancelDeleteTemplate: () -> Unit = {},
    onConfirmDeleteTemplate: () -> Unit = {},
    onStartRenameTemplate: (Long) -> Unit = {},
    onUpdateTemplateName: (String) -> Unit = {},
    onCancelRenameTemplate: () -> Unit = {},
    onConfirmRenameTemplate: () -> Unit = {},
    onImportFile: (String, ByteArray) -> Unit = { _, _ -> },
    onExportCatalog: (Uri) -> Unit = {},
    onSearchCatalog: (String) -> Unit = {},
    onClearCatalog: () -> Unit = {},
    onAddFoodFromCatalog: (FoodCatalogEntity, Double) -> Unit = { _, _ -> },
    onAddToCart: (FoodCatalogEntity, Double, String) -> Unit = { _, _, _ -> },
    onRemoveFromCart: (Long, String) -> Unit = { _, _ -> },
    onUpdateCartGrams: (Long, String, Double) -> Unit = { _, _, _ -> },
    onClearCart: () -> Unit = {},
    onConfirmEatCart: () -> Unit = {},
    onToggleFavoriteCatalog: (Long, Boolean) -> Unit = { _, _ -> },
    onDeleteLoggedFood: (Long) -> Unit = {},
    onCopyYesterdayMeals: () -> Unit = {},
    onSelectScanRecommendation: (ScanRecommendation) -> Unit = {},
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors
    val context = LocalContext.current

    val csvImportLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        if (uri != null) {
            try {
                val fileName = getFileName(context, uri) ?: "file.csv"
                context.contentResolver.openInputStream(uri)?.use { stream ->
                    val bytes = stream.readBytes()
                    onImportFile(fileName, bytes)
                }
            } catch (e: Exception) {
                android.util.Log.e("NutritionScreen", "Failed to read file", e)
            }
        }
    }

    val createTemplateLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.CreateDocument("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    ) { uri: Uri? ->
        if (uri != null) {
            try {
                context.contentResolver.openOutputStream(uri)?.use { outputStream ->
                    context.assets.open("catalog/thuc_pham_mau.xlsx").use { inputStream ->
                        inputStream.copyTo(outputStream)
                    }
                }
                android.widget.Toast.makeText(context, "Đã tải tệp thuc_pham_mau.xlsx thành công!", android.widget.Toast.LENGTH_LONG).show()
            } catch (e: Exception) {
                android.util.Log.e("NutritionScreen", "Failed to save template file", e)
                android.widget.Toast.makeText(context, "Lỗi khi tải tệp mẫu: ${e.localizedMessage}", android.widget.Toast.LENGTH_LONG).show()
            }
        }
    }

    val exportCatalogLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.CreateDocument("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    ) { uri: Uri? ->
        if (uri != null) {
            onExportCatalog(uri)
        }
    }

    var showBarcodeScanner by remember { mutableStateOf(false) }

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            showBarcodeScanner = true
        }
    }

    LaunchedEffect(state, (state as? NutritionUiState.Content)?.importSuccess) {
        if (state is NutritionUiState.Content) {
            if (state.importSuccess == true) {
                if (state.importWarnings.isNotEmpty()) {
                    android.widget.Toast.makeText(
                        context,
                        "Nhập thành công nhưng có ${state.importWarnings.size} cảnh báo:\n" +
                                state.importWarnings.take(3).joinToString("\n") +
                                (if (state.importWarnings.size > 3) "\n..." else ""),
                        android.widget.Toast.LENGTH_LONG
                    ).show()
                } else {
                    android.widget.Toast.makeText(context, "Nhập danh mục thực phẩm thành công!", android.widget.Toast.LENGTH_SHORT).show()
                }
            } else if (state.importSuccess == false) {
                android.widget.Toast.makeText(
                    context,
                    state.importErrorMessage ?: "Lỗi nhập danh mục thực phẩm.",
                    android.widget.Toast.LENGTH_LONG
                ).show()
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Theo dõi Dinh dưỡng 🥗", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    TextButton(onClick = onBack) {
                        Text("◀", color = EnergyOrange, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = colors.background,
                    titleContentColor = customColors.primaryText,
                    navigationIconContentColor = customColors.primaryText
                ),
                windowInsets = WindowInsets(0, 0, 0, 0)
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
                        CalorieCard(state)
                        WaterCard(state, onAddWater)

                        if (state.sweatActive) {
                            SweatPaymentStatusCard(state, onClearSweat)
                        }

                        if (state.scanning) {
                            ScanningCard()
                        } else {
                            ScanEntryRow(
                                enabled = !state.savingDraft,
                                onScanBarcode = {
                                    val hasCameraPermission = ContextCompat.checkSelfPermission(context, android.Manifest.permission.CAMERA) == android.content.pm.PackageManager.PERMISSION_GRANTED
                                    if (hasCameraPermission) {
                                        showBarcodeScanner = true
                                    } else {
                                        permissionLauncher.launch(android.Manifest.permission.CAMERA)
                                    }
                                },
                                onStartManual = onStartManual,
                            )
                        }

                        state.scanError?.let { error ->
                            Text(error, color = colors.error, textAlign = TextAlign.Center, style = MaterialTheme.typography.bodySmall)
                        }

                        Spacer(Modifier.height(16.dp))

                        LoggedMealsSection(
                            state = state,
                            onCopyYesterdayMeals = onCopyYesterdayMeals,
                            onDeleteLoggedFood = onDeleteLoggedFood,
                        )

                        NutritionCartSection(
                            state = state,
                            onClearCart = onClearCart,
                            onRemoveFromCart = onRemoveFromCart,
                            onConfirmEatCart = onConfirmEatCart,
                        )

                        Spacer(Modifier.height(16.dp))

                        FoodCatalogSection(
                            state = state,
                            onSearchCatalog = onSearchCatalog,
                            onClearCatalog = onClearCatalog,
                            onAddFoodFromCatalog = onAddFoodFromCatalog,
                            onAddToCart = onAddToCart,
                            onToggleFavoriteCatalog = onToggleFavoriteCatalog,
                            csvImportLauncher = csvImportLauncher,
                            createTemplateLauncher = createTemplateLauncher,
                            exportCatalogLauncher = exportCatalogLauncher,
                        )

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

                        Text(
                            "Đặt lại calo hôm nay",
                            color = colors.error,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier
                                .clickable { onReset() }
                                .padding(8.dp)
                        )

                        Spacer(Modifier.height(24.dp))

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

                    if (state.scanResult != null && state.draft == null) {
                        ScanRecommendationsDialog(
                            scanResult = state.scanResult,
                            onDiscard = onDiscard,
                            onSelectScanRecommendation = onSelectScanRecommendation,
                        )
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
                            onFiber = onDraftFiber,
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
            if (showBarcodeScanner) {
                BarcodeScannerView(
                    onBarcodeDetected = { barcode ->
                        showBarcodeScanner = false
                        onScanBarcode(barcode)
                    },
                    onClose = {
                        showBarcodeScanner = false
                    }
                )
            }
        }
    }
}

/**
 * The scan/manual entry button row shown when not actively scanning.
 */
@Composable
private fun ScanEntryRow(
    enabled: Boolean,
    onScanBarcode: () -> Unit,
    onStartManual: () -> Unit,
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Button(
            onClick = onScanBarcode,
            enabled = enabled,
            colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
            shape = RoundedCornerShape(16.dp),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 8.dp, vertical = 8.dp),
            modifier = Modifier
                .weight(1f)
                .height(56.dp)
        ) {
            Text("📸 Quét mã vạch", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Color.White, maxLines = 1)
        }
        OutlinedButton(
            onClick = onStartManual,
            enabled = enabled,
            shape = RoundedCornerShape(16.dp),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 8.dp, vertical = 8.dp),
            modifier = Modifier
                .weight(1f)
                .height(56.dp)
        ) {
            Text("Nhập tay", fontSize = 13.sp, fontWeight = FontWeight.Bold, maxLines = 1)
        }
    }
}

/**
 * Dialog showing AI-detected dish candidates (with confidence) for the user to pick from.
 */
@Composable
private fun ScanRecommendationsDialog(
    scanResult: ScanResult,
    onDiscard: () -> Unit,
    onSelectScanRecommendation: (ScanRecommendation) -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors
    AlertDialog(
        onDismissRequest = onDiscard,
        title = { Text("Gợi ý từ AI 📸", fontWeight = FontWeight.Bold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    "AI phát hiện đĩa ăn của bạn có thể là một trong các món sau. Vui lòng chọn món đúng:",
                    style = MaterialTheme.typography.bodyMedium,
                    color = customColors.primaryText
                )

                val recommendations = scanResult.recommendations.take(3)
                recommendations.forEach { recommendation ->
                    val confidencePercentage = (recommendation.confidence * 100).toInt()
                    val isLowConfidence = recommendation.confidence < 0.70

                    Surface(
                        color = if (isLowConfidence) colors.errorContainer else colors.surfaceVariant,
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(modifier = Modifier.padding(12.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = recommendation.dishName,
                                    fontWeight = FontWeight.Bold,
                                    color = if (isLowConfidence) colors.onErrorContainer else customColors.primaryText,
                                    style = MaterialTheme.typography.bodyLarge,
                                    modifier = Modifier.weight(1f)
                                )
                                Text(
                                    text = "$confidencePercentage% tin cậy",
                                    fontWeight = FontWeight.SemiBold,
                                    color = if (isLowConfidence) colors.error else SuccessGreen,
                                    style = MaterialTheme.typography.bodySmall,
                                    textAlign = TextAlign.End
                                )
                            }
                            Spacer(Modifier.height(4.dp))
                            Text(
                                "${recommendation.calories} kcal | P: ${recommendation.proteinGrams}g C: ${recommendation.carbsGrams}g F: ${recommendation.fatGrams}g",
                                style = MaterialTheme.typography.bodySmall,
                                color = if (isLowConfidence) colors.onErrorContainer.copy(alpha = 0.8f) else customColors.mutedText
                            )
                            if (isLowConfidence) {
                                Spacer(Modifier.height(4.dp))
                                Text(
                                    "⚠️ Độ tin cậy thấp (< 70%). Vui lòng kiểm tra kỹ.",
                                    color = colors.error,
                                    style = MaterialTheme.typography.labelSmall,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                            Spacer(Modifier.height(8.dp))
                            Button(
                                onClick = { onSelectScanRecommendation(recommendation) },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = if (isLowConfidence) colors.error else EnergyOrange
                                ),
                                shape = RoundedCornerShape(8.dp),
                                modifier = Modifier.fillMaxWidth(),
                                contentPadding = androidx.compose.foundation.layout.PaddingValues(vertical = 4.dp)
                            ) {
                                Text("Chọn món này", color = Color.White, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }
        },
        dismissButton = {
            TextButton(onClick = onDiscard) {
                Text("Hủy")
            }
        },
        confirmButton = {}
    )
}

@Composable
private fun HistoryItemCard(day: NutritionDay) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    val targetCalories = day.target?.calories ?: 2000
    val caloriesEaten = day.consumed.calories
    val progress = if (targetCalories > 0) caloriesEaten.toFloat() / targetCalories else 0f
    val isOverLimit = caloriesEaten > targetCalories

    val localDate = LocalDate.ofEpochDay(day.epochDay)
    val vietnamese = Locale.forLanguageTag("vi-VN")
    val formatter = DateTimeFormatter.ofPattern("EEEE, dd/MM", vietnamese)

    val today = LocalDate.now().toEpochDay()
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
                val targetForScore = day.target ?: NutritionTarget(
                    basalCalories = 2000,
                    maintenanceCalories = 2000,
                    calories = 2000,
                    proteinGrams = 125,
                    carbsGrams = 250,
                    fatGrams = 55,
                    audit = NutritionTargetAudit(2000.0, 2000.0, 2000.0, 125.0, 250.0, 55.0)
                )
                val scoreResult = NutritionScoreCalculator.calculateScore(
                    consumed = day.consumed,
                    target = targetForScore,
                    waterIntakeMl = day.waterIntakeMl
                )

                Column(modifier = Modifier.weight(1f)) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Text(
                            text = dateText,
                            fontWeight = FontWeight.Bold,
                            color = customColors.primaryText,
                            style = MaterialTheme.typography.bodyLarge
                        )
                        Surface(
                            color = colors.primaryContainer.copy(alpha = 0.2f),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text(
                                text = "${scoreResult.emoji} ${scoreResult.score}đ",
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold,
                                color = colors.primary
                            )
                        }
                    }
                    Spacer(Modifier.height(4.dp))
                    Text(
                        text = "Đạm: ${day.consumed.proteinGrams}g  •  Tinh bột: ${day.consumed.carbsGrams}g  •  Béo: ${day.consumed.fatGrams}g  •  Xơ: ${day.consumed.fiberGrams}g",
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
