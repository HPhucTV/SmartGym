package com.example.myapplication.feature.nutrition

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.myapplication.ui.theme.EnergyOrange

/**
 * Renders the food cart ("Giỏ món ăn") section: list of selected foods grouped by meal,
 * clear-cart action, and confirm-eaten button. Shown only when the cart is non-empty.
 */
@Composable
fun NutritionCartSection(
    state: NutritionUiState.Content,
    onClearCart: () -> Unit,
    onRemoveFromCart: (Long, String) -> Unit,
    onConfirmEatCart: () -> Unit,
) {
    if (state.cart.isEmpty()) return

    val colors = MaterialTheme.colorScheme

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
                    val mealNameVi = when (cartItem.mealTime.uppercase()) {
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
