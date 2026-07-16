package com.example.myapplication.feature.nutrition

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import com.example.myapplication.core.nutrition.MealTemplate
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ButtonDefaults

@Composable
fun NutritionDraftDialog(
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
fun DraftField(
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
            KeyboardOptions(
                keyboardType = KeyboardType.Decimal,
            )
        } else KeyboardOptions.Default,
        enabled = !saving,
        singleLine = true,
        modifier = Modifier.fillMaxWidth(),
    )
}

@Composable
fun MealTemplateCard(
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
