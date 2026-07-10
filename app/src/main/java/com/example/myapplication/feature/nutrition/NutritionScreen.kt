package com.example.myapplication.feature.nutrition

import android.graphics.Bitmap
import androidx.core.content.FileProvider
import android.net.Uri
import java.io.File
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
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
import com.example.myapplication.core.nutrition.MealTemplate
import com.example.myapplication.data.local.LoggedFoodEntity
import com.example.myapplication.data.local.FoodCatalogEntity

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NutritionScreen(
    state: NutritionUiState,
    onBack: () -> Unit,
    onScan: (Bitmap) -> Unit,
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
    val context = androidx.compose.ui.platform.LocalContext.current

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

    var photoFile by remember { mutableStateOf<File?>(null) }
    var photoUri by remember { mutableStateOf<Uri?>(null) }

    val cameraLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.TakePicture()
    ) { success ->
        if (success) {
            val uri = photoUri
            val file = photoFile
            if (uri != null && file != null) {
                val bitmap = loadResizedBitmapFromFile(context, file, uri)
                if (bitmap != null) {
                    onScan(bitmap)
                }
            }
        }
    }

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            try {
                val file = File.createTempFile("captured_food_", ".jpg", context.cacheDir)
                photoFile = file
                val uri = FileProvider.getUriForFile(
                    context,
                    "${context.packageName}.fileprovider",
                    file
                )
                photoUri = uri
                cameraLauncher.launch(uri)
            } catch (e: Exception) {
                android.util.Log.e("NutritionScreen", "Failed to create temp file or launch camera", e)
            }
        }
    }

    androidx.compose.runtime.LaunchedEffect(state, (state as? NutritionUiState.Content)?.importSuccess) {
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
                    IconButton(onClick = onBack) {
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
                        // 1. Calorie progress ring
                        CalorieCard(state)

                        // 1.2 Water progress
                        WaterCard(state, onAddWater)

                        // 2. Sweat Payment status card
                        if (state.sweatActive) {
                            SweatPaymentStatusCard(state, onClearSweat)
                        }

                        // 3. Scan result popup card (if scanning or result available)
                        if (state.scanning) {
                            ScanningCard()
                        } else {
                            // Food photo or Manual entry
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

                        // Grouped eaten foods list
                        Text(
                            "Bữa ăn hôm nay 🍽️",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = customColors.primaryText,
                            modifier = Modifier.fillMaxWidth()
                        )

                        if (state.loggedFoods.isNotEmpty()) {
                            val totalCal = state.loggedFoods.sumOf { it.calories }
                            val totalP = state.loggedFoods.sumOf { it.proteinGrams }
                            val totalC = state.loggedFoods.sumOf { it.carbsGrams }
                            val totalF = state.loggedFoods.sumOf { it.fatGrams }
                            Surface(
                                color = colors.surfaceVariant.copy(alpha = 0.5f),
                                shape = RoundedCornerShape(12.dp),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Column(
                                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                                    verticalArrangement = Arrangement.spacedBy(4.dp)
                                ) {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text(
                                            text = "Tổng dinh dưỡng đã nạp:",
                                            style = MaterialTheme.typography.bodyMedium,
                                            fontWeight = FontWeight.Bold,
                                            color = customColors.primaryText
                                        )
                                        Text(
                                            text = "$totalCal kcal",
                                            style = MaterialTheme.typography.bodyLarge,
                                            fontWeight = FontWeight.Bold,
                                            color = EnergyOrange
                                        )
                                    }
                                    Text(
                                        text = "P: ${totalP}g   •   C: ${totalC}g   •   F: ${totalF}g",
                                        style = MaterialTheme.typography.bodyMedium,
                                        fontWeight = FontWeight.SemiBold,
                                        color = customColors.mutedText
                                    )
                                }
                            }
                        }

                        // Copy yesterday meals button
                        OutlinedButton(
                            onClick = onCopyYesterdayMeals,
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("🕒 Sao chép tất cả bữa ăn từ hôm qua", fontWeight = FontWeight.Bold, color = EnergyOrange)
                        }

                        if (state.loggedFoods.isEmpty()) {
                            Surface(
                                color = colors.surfaceVariant,
                                shape = RoundedCornerShape(16.dp),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text(
                                    "Chưa ghi nhận món ăn nào hôm nay.",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = customColors.mutedText,
                                    modifier = Modifier.padding(16.dp),
                                    textAlign = TextAlign.Center
                                )
                            }
                        } else {
                            val mealNames = mapOf(
                                "BREAKFAST" to "Bữa sáng 🍳",
                                "LUNCH" to "Bữa trưa ☀️",
                                "DINNER" to "Bữa tối 🌙",
                                "SNACK" to "Bữa phụ 🍎"
                            )
                            val mealTimes = listOf("BREAKFAST", "LUNCH", "DINNER", "SNACK")
                            Column(
                                modifier = Modifier.fillMaxWidth(),
                                verticalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                mealTimes.forEach { time ->
                                    val foodsInMeal = state.loggedFoods.filter { it.mealTime.uppercase() == time }
                                    if (foodsInMeal.isNotEmpty()) {
                                        val totalCal = foodsInMeal.sumOf { it.calories }
                                        val totalP = foodsInMeal.sumOf { it.proteinGrams }
                                        val totalC = foodsInMeal.sumOf { it.carbsGrams }
                                        val totalF = foodsInMeal.sumOf { it.fatGrams }
                                        
                                        Surface(
                                            color = colors.surfaceVariant,
                                            shape = RoundedCornerShape(16.dp),
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Column(modifier = Modifier.padding(12.dp)) {
                                                Row(
                                                    modifier = Modifier.fillMaxWidth(),
                                                    horizontalArrangement = Arrangement.SpaceBetween,
                                                    verticalAlignment = Alignment.CenterVertically
                                                ) {
                                                    Text(
                                                        text = mealNames[time] ?: time,
                                                        fontWeight = FontWeight.Bold,
                                                        color = customColors.primaryText,
                                                        style = MaterialTheme.typography.bodyLarge
                                                    )
                                                    Text(
                                                        text = "$totalCal kcal  |  P: ${totalP}g  C: ${totalC}g  F: ${totalF}g",
                                                        style = MaterialTheme.typography.bodySmall,
                                                        color = customColors.mutedText,
                                                        fontWeight = FontWeight.SemiBold
                                                    )
                                                }
                                                Spacer(Modifier.height(8.dp))
                                                foodsInMeal.forEach { logged ->
                                                    Row(
                                                        modifier = Modifier
                                                            .fillMaxWidth()
                                                            .padding(vertical = 4.dp),
                                                        horizontalArrangement = Arrangement.SpaceBetween,
                                                        verticalAlignment = Alignment.CenterVertically
                                                    ) {
                                                        Column(modifier = Modifier.weight(1f)) {
                                                            Text(
                                                                logged.name,
                                                                style = MaterialTheme.typography.bodyMedium,
                                                                color = customColors.primaryText,
                                                                fontWeight = FontWeight.SemiBold
                                                            )
                                                            Text(
                                                                "${logged.grams.toInt()}g  •  ${logged.calories} kcal  |  P: ${logged.proteinGrams}g  C: ${logged.carbsGrams}g  F: ${logged.fatGrams}g",
                                                                style = MaterialTheme.typography.bodySmall,
                                                                color = customColors.mutedText
                                                            )
                                                        }
                                                        IconButton(
                                                            onClick = { onDeleteLoggedFood(logged.id) },
                                                            modifier = Modifier.size(24.dp)
                                                        ) {
                                                            Text("❌", fontSize = 12.sp)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Cart / Giỏ chọn món Section
                        if (state.cart.isNotEmpty()) {
                            Surface(
                                color = colors.primaryContainer,
                                border = androidx.compose.foundation.BorderStroke(1.dp, colors.primary),
                                shape = RoundedCornerShape(16.dp),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Column(modifier = Modifier.padding(16.dp)) {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text(
                                            "Giỏ món ăn (${state.cart.size} món) 🛒",
                                            fontWeight = FontWeight.Bold,
                                            style = MaterialTheme.typography.titleMedium,
                                            color = colors.onPrimaryContainer
                                        )
                                        TextButton(onClick = onClearCart) {
                                            Text("Xóa giỏ", color = colors.error, fontWeight = FontWeight.Bold)
                                        }
                                    }
                                    Spacer(Modifier.height(8.dp))
                                    state.cart.forEach { cartItem ->
                                        Row(
                                            modifier = Modifier
                                                .fillMaxWidth()
                                                .padding(vertical = 4.dp),
                                            horizontalArrangement = Arrangement.SpaceBetween,
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            val mealNameVi = when(cartItem.mealTime.uppercase()) {
                                                "BREAKFAST" -> "Sáng"
                                                "LUNCH" -> "Trưa"
                                                "DINNER" -> "Tối"
                                                else -> "Phụ"
                                            }
                                            Column(modifier = Modifier.weight(1f)) {
                                                Text(
                                                    cartItem.food.name,
                                                    style = MaterialTheme.typography.bodyMedium,
                                                    fontWeight = FontWeight.Bold,
                                                    color = colors.onPrimaryContainer
                                                )
                                                Text(
                                                    "Bữa: $mealNameVi  •  ${cartItem.grams.toInt()}g",
                                                    style = MaterialTheme.typography.bodySmall,
                                                    color = colors.onPrimaryContainer.copy(alpha = 0.8f)
                                                )
                                            }
                                            Row(verticalAlignment = Alignment.CenterVertically) {
                                                IconButton(onClick = { onRemoveFromCart(cartItem.food.id, cartItem.mealTime) }) {
                                                    Text("🗑️", fontSize = 16.sp)
                                                }
                                            }
                                        }
                                    }
                                    Spacer(Modifier.height(12.dp))
                                    Button(
                                        onClick = onConfirmEatCart,
                                        colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
                                        shape = RoundedCornerShape(12.dp),
                                        modifier = Modifier.fillMaxWidth()
                                    ) {
                                        Text("Xác nhận đã ăn ✔️", color = Color.White, fontWeight = FontWeight.Bold)
                                    }
                                }
                            }
                        }

                        Spacer(Modifier.height(16.dp))

                        // Tra cứu & Nhập thực phẩm section
                        Text(
                            "Tra cứu & Nhập thực phẩm 📁",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = customColors.primaryText,
                            modifier = Modifier.fillMaxWidth(),
                        )

                        var selectedTab by remember { mutableStateOf(0) }
                        var expandedFoodId by remember { mutableStateOf<Long?>(null) }
                        var inputGrams by remember { mutableStateOf(100f) }
                        var inputMealTime by remember { mutableStateOf(defaultMealTime()) }

                        if (state.foodCatalogCount == 0) {
                            Surface(
                                color = colors.surfaceVariant,
                                shape = RoundedCornerShape(16.dp),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Column(
                                    modifier = Modifier.padding(16.dp),
                                    horizontalAlignment = Alignment.CenterHorizontally
                                ) {
                                    Text(
                                        text = "Hướng dẫn tự thêm thực phẩm 📝",
                                        style = MaterialTheme.typography.titleSmall,
                                        fontWeight = FontWeight.Bold,
                                        color = customColors.primaryText,
                                        modifier = Modifier.padding(bottom = 8.dp)
                                    )
                                    Text(
                                        text = "1. Nhấp \"Tải file mẫu Excel\" bên dưới để lưu tệp thuc_pham_mau.xlsx về điện thoại.\n" +
                                                "2. Mở tệp vừa tải và điền tên món ăn, calo, đạm, tinh bột, béo theo cấu trúc.\n" +
                                                "3. Nhấp \"Nhập thực phẩm\" và chọn tệp Excel vừa điền để tra cứu nhanh.",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = customColors.mutedText,
                                        textAlign = TextAlign.Start,
                                        modifier = Modifier.fillMaxWidth()
                                    )
                                    Spacer(Modifier.height(16.dp))
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        OutlinedButton(
                                            onClick = { createTemplateLauncher.launch("thuc_pham_mau.xlsx") },
                                            shape = RoundedCornerShape(12.dp),
                                            modifier = Modifier.weight(1f).height(42.dp),
                                            colors = ButtonDefaults.outlinedButtonColors(contentColor = EnergyOrange),
                                            border = androidx.compose.foundation.BorderStroke(1.dp, EnergyOrange),
                                            contentPadding = PaddingValues(horizontal = 4.dp)
                                        ) {
                                            Text("Tải file mẫu Excel", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                                        }
                                        Button(
                                            onClick = { csvImportLauncher.launch("*/*") },
                                            colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
                                            shape = RoundedCornerShape(12.dp),
                                            modifier = Modifier.weight(1f).height(42.dp),
                                            contentPadding = PaddingValues(horizontal = 4.dp)
                                        ) {
                                            Text("Nhập thực phẩm", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 12.sp)
                                        }
                                    }
                                }
                            }
                        } else {
                            Column(
                                modifier = Modifier.fillMaxWidth(),
                                verticalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Text(
                                        "Đã nhập ${state.foodCatalogCount} món thực phẩm",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = customColors.mutedText
                                    )
                                    Row(
                                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text(
                                            "Tải Excel hiện tại",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = colors.primary,
                                            fontWeight = FontWeight.Bold,
                                            modifier = Modifier.clickable { exportCatalogLauncher.launch("danh_sach_thuc_pham.xlsx") }
                                        )
                                        Text(
                                            "Đặt lại danh mục",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = colors.error,
                                            fontWeight = FontWeight.Bold,
                                            modifier = Modifier.clickable { onClearCatalog() }
                                        )
                                    }
                                }

                                // Custom Tab Row
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(12.dp))
                                        .background(colors.surfaceVariant),
                                    horizontalArrangement = Arrangement.SpaceEvenly
                                ) {
                                    val tabs = listOf("Danh mục 📁", "Yêu thích ⭐", "Gần đây 🕒")
                                    tabs.forEachIndexed { index, title ->
                                        val isSelected = selectedTab == index
                                        Box(
                                            modifier = Modifier
                                                .weight(1f)
                                                .clickable {
                                                    selectedTab = index
                                                    expandedFoodId = null
                                                }
                                                .background(if (isSelected) EnergyOrange else Color.Transparent)
                                                .padding(vertical = 12.dp),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Text(
                                                text = title,
                                                color = if (isSelected) Color.White else customColors.primaryText,
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 13.sp
                                            )
                                        }
                                    }
                                }

                                OutlinedTextField(
                                    value = state.searchQuery,
                                    onValueChange = onSearchCatalog,
                                    label = { Text("Tìm kiếm thực phẩm...") },
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = RoundedCornerShape(12.dp),
                                    singleLine = true
                                )

                                val displayedFoods = when(selectedTab) {
                                    0 -> state.foodCatalogItems
                                    1 -> state.favorites.filter { it.name.contains(state.searchQuery, ignoreCase = true) }
                                    else -> state.recentFoods.filter { it.name.contains(state.searchQuery, ignoreCase = true) }
                                }

                                if (displayedFoods.isEmpty()) {
                                    Text(
                                        "Không có thực phẩm nào.",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = customColors.mutedText,
                                        modifier = Modifier.padding(vertical = 8.dp)
                                    )
                                } else {
                                    displayedFoods.take(10).forEach { food ->
                                        Surface(
                                            color = colors.surfaceVariant,
                                            shape = RoundedCornerShape(12.dp),
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Column(modifier = Modifier.padding(12.dp)) {
                                                Row(
                                                    modifier = Modifier.fillMaxWidth(),
                                                    horizontalArrangement = Arrangement.SpaceBetween,
                                                    verticalAlignment = Alignment.CenterVertically
                                                ) {
                                                    Column(modifier = Modifier.weight(1f)) {
                                                        Text(
                                                            food.name,
                                                            fontWeight = FontWeight.Bold,
                                                            color = customColors.primaryText
                                                        )
                                                        Text(
                                                            "${food.caloriesPerServing.toInt()} kcal / ${food.gramsPerServing.toInt()}g  |  P: ${food.proteinPerServing.toInt()}g  C: ${food.carbsPerServing.toInt()}g  F: ${food.fatPerServing.toInt()}g",
                                                            style = MaterialTheme.typography.bodySmall,
                                                            color = customColors.mutedText
                                                        )
                                                    }
                                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                                        IconButton(onClick = { onToggleFavoriteCatalog(food.id, !food.isFavorite) }) {
                                                            Text(if (food.isFavorite) "⭐" else "☆", fontSize = 18.sp, color = EnergyOrange)
                                                        }
                                                        Spacer(Modifier.width(4.dp))
                                                        if (selectedTab == 1) {
                                                            IconButton(
                                                                onClick = {
                                                                    onAddFoodFromCatalog(food, food.gramsPerServing)
                                                                    android.widget.Toast.makeText(
                                                                        context,
                                                                        "Đã ăn 1 khẩu phần ${food.name} ⚡",
                                                                        android.widget.Toast.LENGTH_SHORT
                                                                    ).show()
                                                                },
                                                                modifier = Modifier.size(32.dp)
                                                            ) {
                                                                Text("⚡", fontSize = 18.sp)
                                                            }
                                                            Spacer(Modifier.width(4.dp))
                                                        }
                                                        Button(
                                                            onClick = {
                                                                if (expandedFoodId == food.id) {
                                                                    expandedFoodId = null
                                                                } else {
                                                                    expandedFoodId = food.id
                                                                    inputGrams = food.gramsPerServing.toFloat()
                                                                    inputMealTime = defaultMealTime()
                                                                }
                                                            },
                                                            colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
                                                            shape = RoundedCornerShape(8.dp),
                                                            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp)
                                                        ) {
                                                            Text(if (expandedFoodId == food.id) "Đóng" else "+ Chọn", fontSize = 12.sp, color = Color.White)
                                                        }
                                                    }
                                                }

                                                if (expandedFoodId == food.id) {
                                                    Spacer(Modifier.height(8.dp))
                                                    Box(
                                                        modifier = Modifier
                                                            .fillMaxWidth()
                                                            .height(1.dp)
                                                            .background(colors.outline.copy(alpha = 0.3f))
                                                    )
                                                    Spacer(Modifier.height(8.dp))

                                                    Text("Chọn bữa ăn:", style = MaterialTheme.typography.labelSmall, color = customColors.mutedText)
                                                    Row(
                                                        modifier = Modifier.fillMaxWidth(),
                                                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                                                    ) {
                                                        val times = listOf("BREAKFAST" to "Sáng", "LUNCH" to "Trưa", "DINNER" to "Tối", "SNACK" to "Phụ")
                                                        times.forEach { (timeVal, timeLabel) ->
                                                            val isSelected = inputMealTime == timeVal
                                                            if (isSelected) {
                                                                Button(
                                                                    onClick = { inputMealTime = timeVal },
                                                                    colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
                                                                    shape = RoundedCornerShape(8.dp),
                                                                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                                                                    modifier = Modifier.height(32.dp)
                                                                ) {
                                                                    Text(timeLabel, fontSize = 11.sp, color = Color.White, fontWeight = FontWeight.Bold)
                                                                }
                                                            } else {
                                                                OutlinedButton(
                                                                    onClick = { inputMealTime = timeVal },
                                                                    shape = RoundedCornerShape(8.dp),
                                                                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                                                                    modifier = Modifier.height(32.dp)
                                                                ) {
                                                                    Text(timeLabel, fontSize = 11.sp, color = customColors.primaryText)
                                                                }
                                                            }
                                                        }
                                                    }

                                                    Spacer(Modifier.height(8.dp))

                                                    Row(
                                                        modifier = Modifier.fillMaxWidth(),
                                                        horizontalArrangement = Arrangement.SpaceBetween,
                                                        verticalAlignment = Alignment.CenterVertically
                                                    ) {
                                                        Text("Khối lượng:", style = MaterialTheme.typography.labelSmall, color = customColors.mutedText)
                                                        Text("${inputGrams.toInt()}g", fontWeight = FontWeight.Bold, color = EnergyOrange, fontSize = 14.sp)
                                                    }
                                                    Slider(
                                                        value = inputGrams,
                                                        onValueChange = { inputGrams = it },
                                                        valueRange = 10f..1000f,
                                                        steps = 99,
                                                        colors = SliderDefaults.colors(
                                                            activeTrackColor = EnergyOrange,
                                                            thumbColor = EnergyOrange
                                                        )
                                                    )

                                                    Spacer(Modifier.height(4.dp))

                                                    Row(
                                                        modifier = Modifier.fillMaxWidth(),
                                                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                                                    ) {
                                                        val quickGrams = listOf(50, 100, 150, 200, 300, 500)
                                                        quickGrams.forEach { grams ->
                                                            val isSelected = inputGrams.toInt() == grams
                                                            OutlinedButton(
                                                                onClick = { inputGrams = grams.toFloat() },
                                                                shape = RoundedCornerShape(8.dp),
                                                                colors = ButtonDefaults.outlinedButtonColors(
                                                                    containerColor = if (isSelected) EnergyOrange else Color.Transparent,
                                                                    contentColor = if (isSelected) Color.White else customColors.primaryText
                                                                ),
                                                                border = androidx.compose.foundation.BorderStroke(
                                                                    1.dp,
                                                                    if (isSelected) EnergyOrange else colors.outline.copy(alpha = 0.5f)
                                                                ),
                                                                contentPadding = PaddingValues(horizontal = 4.dp, vertical = 2.dp),
                                                                modifier = Modifier
                                                                    .weight(1f)
                                                                    .height(32.dp)
                                                            ) {
                                                                Text("${grams}g", fontSize = 10.sp, fontWeight = FontWeight.Bold, maxLines = 1)
                                                            }
                                                        }
                                                    }

                                                    Spacer(Modifier.height(8.dp))

                                                    Row(
                                                        modifier = Modifier.fillMaxWidth(),
                                                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                                                    ) {
                                                        OutlinedButton(
                                                            onClick = {
                                                                onAddToCart(food, inputGrams.toDouble(), inputMealTime)
                                                                expandedFoodId = null
                                                            },
                                                            shape = RoundedCornerShape(8.dp),
                                                            modifier = Modifier.weight(1f)
                                                        ) {
                                                            Text("+ Giỏ hàng 🛒", fontSize = 12.sp)
                                                        }

                                                        Button(
                                                            onClick = {
                                                                onAddFoodFromCatalog(food, inputGrams.toDouble())
                                                                expandedFoodId = null
                                                            },
                                                            colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
                                                            shape = RoundedCornerShape(8.dp),
                                                            modifier = Modifier.weight(1f)
                                                        ) {
                                                            Text("Ăn ngay ✔️", fontSize = 12.sp, color = Color.White)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Button(
                                    onClick = { csvImportLauncher.launch("*/*") },
                                    colors = ButtonDefaults.buttonColors(containerColor = colors.secondaryContainer),
                                    shape = RoundedCornerShape(12.dp),
                                    modifier = Modifier.align(Alignment.CenterHorizontally)
                                ) {
                                    Text("Cập nhật / Nhập thêm CSV/Excel", color = colors.onSecondaryContainer, fontWeight = FontWeight.Bold)
                                }
                            }
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
                    if (state.scanResult != null && state.draft == null) {
                        val scanRes = state.scanResult!!
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
                                    
                                    val recommendations = scanRes.recommendations.take(3)
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
                                                    contentPadding = PaddingValues(vertical = 4.dp)
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
    onFiber: (String) -> Unit,
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
                DraftField("Chất xơ (g)", draft.fiberText, onFiber, draft.errors["fiber"], true, saving)
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
                keyboardType = androidx.compose.ui.text.input.KeyboardType.Decimal,
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
private fun WaterCard(state: NutritionUiState.Content, onAddWater: (Int) -> Unit) {
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
                val targetForScore = day.target ?: com.example.myapplication.core.nutrition.NutritionTarget(
                    basalCalories = 2000,
                    maintenanceCalories = 2000,
                    calories = 2000,
                    proteinGrams = 125,
                    carbsGrams = 250,
                    fatGrams = 55,
                    audit = com.example.myapplication.core.nutrition.NutritionTargetAudit(2000.0, 2000.0, 2000.0, 125.0, 250.0, 55.0)
                )
                val scoreResult = com.example.myapplication.core.nutrition.NutritionScoreCalculator.calculateScore(
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

private fun loadResizedBitmapFromFile(
    context: android.content.Context,
    file: java.io.File,
    uri: android.net.Uri,
    maxDimension: Int = 1080
): android.graphics.Bitmap? {
    return try {
        val options = android.graphics.BitmapFactory.Options().apply {
            inJustDecodeBounds = true
        }
        context.contentResolver.openInputStream(uri)?.use { input ->
            android.graphics.BitmapFactory.decodeStream(input, null, options)
        }

        val srcWidth = options.outWidth
        val srcHeight = options.outHeight

        var inSampleSize = 1
        if (srcWidth > maxDimension || srcHeight > maxDimension) {
            val halfWidth = srcWidth / 2
            val halfHeight = srcHeight / 2
            while ((halfWidth / inSampleSize) >= maxDimension && (halfHeight / inSampleSize) >= maxDimension) {
                inSampleSize *= 2
            }
        }

        val decodeOptions = android.graphics.BitmapFactory.Options().apply {
            inSampleSize = inSampleSize
        }
        val sampledBitmap = context.contentResolver.openInputStream(uri)?.use { input ->
            android.graphics.BitmapFactory.decodeStream(input, null, decodeOptions)
        } ?: return null

        val scaledBitmap = if (sampledBitmap.width > maxDimension || sampledBitmap.height > maxDimension) {
            val ratio = sampledBitmap.width.toFloat() / sampledBitmap.height.toFloat()
            val targetWidth: Int
            val targetHeight: Int
            if (sampledBitmap.width > sampledBitmap.height) {
                targetWidth = maxDimension
                targetHeight = (maxDimension / ratio).toInt()
            } else {
                targetHeight = maxDimension
                targetWidth = (maxDimension * ratio).toInt()
            }
            android.graphics.Bitmap.createScaledBitmap(sampledBitmap, targetWidth, targetHeight, true).also {
                if (it != sampledBitmap) {
                    sampledBitmap.recycle()
                }
            }
        } else {
            sampledBitmap
        }

        val exifInterface = android.media.ExifInterface(file.absolutePath)
        val orientation = exifInterface.getAttributeInt(
            android.media.ExifInterface.TAG_ORIENTATION,
            android.media.ExifInterface.ORIENTATION_NORMAL
        )
        val rotationDegrees = when (orientation) {
            android.media.ExifInterface.ORIENTATION_ROTATE_90 -> 90
            android.media.ExifInterface.ORIENTATION_ROTATE_180 -> 180
            android.media.ExifInterface.ORIENTATION_ROTATE_270 -> 270
            else -> 0
        }

        if (rotationDegrees != 0) {
            val matrix = android.graphics.Matrix().apply { postRotate(rotationDegrees.toFloat()) }
            val rotatedBitmap = android.graphics.Bitmap.createBitmap(
                scaledBitmap, 0, 0, scaledBitmap.width, scaledBitmap.height, matrix, true
            )
            if (rotatedBitmap != scaledBitmap) {
                scaledBitmap.recycle()
            }
            rotatedBitmap
        } else {
            scaledBitmap
        }
    } catch (e: Exception) {
        android.util.Log.e("loadResizedBitmapFromFile", "Error decoding or resizing image", e)
        null
    }
}

private fun defaultMealTime(): String {
    val hour = java.time.LocalTime.now().hour
    return when {
        hour < 10 -> "BREAKFAST"
        hour < 14 -> "LUNCH"
        hour < 17 -> "SNACK"
        else -> "DINNER"
    }
}

private fun getFileName(context: android.content.Context, uri: Uri): String? {
    var result: String? = null
    if (uri.scheme == "content") {
        val cursor = context.contentResolver.query(uri, null, null, null, null)
        try {
            if (cursor != null && cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                if (nameIndex != -1) {
                    result = cursor.getString(nameIndex)
                }
            }
        } finally {
            cursor?.close()
        }
    }
    if (result == null) {
        result = uri.path
        val cut = result?.lastIndexOf('/')
        if (cut != null && cut != -1) {
            result = result.substring(cut + 1)
        }
    }
    return result
}


