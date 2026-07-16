package com.example.myapplication.feature.nutrition

import android.widget.Toast
import androidx.activity.compose.ManagedActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
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
import com.example.myapplication.data.local.FoodCatalogEntity
import com.example.myapplication.ui.theme.EnergyOrange
import com.example.myapplication.ui.theme.customColors

/**
 * Renders the "Tra cứu & Nhập thực phẩm" section. When the catalog is empty it shows an
 * import guide; otherwise it shows the catalog tabs (Danh mục / Yêu thích / Gần đây),
 * search field, and expandable food cards with portion/meal pickers.
 */
@Composable
fun FoodCatalogSection(
    state: NutritionUiState.Content,
    onSearchCatalog: (String) -> Unit,
    onClearCatalog: () -> Unit,
    onAddFoodFromCatalog: (FoodCatalogEntity, Double) -> Unit,
    onAddToCart: (FoodCatalogEntity, Double, String) -> Unit,
    onToggleFavoriteCatalog: (Long, Boolean) -> Unit,
    csvImportLauncher: ManagedActivityResultLauncher<String, *>,
    createTemplateLauncher: ManagedActivityResultLauncher<String, *>,
    exportCatalogLauncher: ManagedActivityResultLauncher<String, *>,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors
    val context = LocalContext.current

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
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(
                "Đã nhập ${state.foodCatalogCount} món thực phẩm",
                style = MaterialTheme.typography.bodySmall,
                color = customColors.mutedText,
                modifier = Modifier.padding(bottom = 2.dp)
            )
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
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

            val displayedFoods = when (selectedTab) {
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
                                                Toast.makeText(
                                                    context,
                                                    "Đã ăn 1 khẩu phần ${food.name} ⚡",
                                                    Toast.LENGTH_SHORT
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
}
