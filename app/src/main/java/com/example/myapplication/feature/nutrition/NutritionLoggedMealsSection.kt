package com.example.myapplication.feature.nutrition

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.myapplication.ui.theme.EnergyOrange
import com.example.myapplication.ui.theme.customColors

/**
 * Renders the "Bữa ăn hôm nay" section: daily nutrition totals, copy-yesterday button,
 * and the grouped meal list (BREAKFAST / LUNCH / DINNER / SNACK) with delete actions.
 */
@Composable
fun LoggedMealsSection(
    state: NutritionUiState.Content,
    onCopyYesterdayMeals: () -> Unit,
    onDeleteLoggedFood: (Long) -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

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
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
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
}
