package com.example.myapplication.feature.today

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.myapplication.core.model.MuscleGroup
import com.example.myapplication.ui.theme.*

@Composable
fun ExerciseCard(
    sessionId: Long,
    row: WorkoutRowUi,
    enabled: Boolean,
    onCheckedChange: (Boolean) -> Unit,
) {
    var expanded by rememberSaveable(sessionId, row.orderIndex, row.exerciseId) { mutableStateOf(false) }

    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    val borderColor by animateColorAsState(
        targetValue = if (row.checked) customColors.checkedCardBorder else colors.outline,
        label = "cardBorder",
    )
    val bgColor by animateColorAsState(
        targetValue = if (row.checked) customColors.greenLight else colors.surfaceVariant,
        label = "cardBg",
    )

    Column(
        Modifier
            .fillMaxWidth()
            .animateContentSize()
            .background(bgColor, RoundedCornerShape(16.dp))
            .border(1.dp, borderColor, RoundedCornerShape(16.dp))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            // Exercise number badge
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(if (row.checked) SuccessGreen else EnergyOrange),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    if (row.checked) "✓" else "${row.orderIndex + 1}",
                    color = Color.White,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp,
                )
            }
            Spacer(Modifier.width(12.dp))

            Column(Modifier.weight(1f)) {
                Text(
                    row.nameVi,
                    style = MaterialTheme.typography.titleMedium,
                    color = customColors.primaryText,
                    fontWeight = FontWeight.SemiBold,
                    textDecoration = if (row.checked) TextDecoration.LineThrough else TextDecoration.None,
                )
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Text(
                        muscleEmoji(row.primaryMuscle),
                        fontSize = 14.sp,
                    )
                    Text(
                        "${row.prescriptionText} · nghỉ ${row.restSeconds}s",
                        color = customColors.mutedText,
                        style = MaterialTheme.typography.bodySmall,
                    )
                }
            }

            Checkbox(
                checked = row.checked,
                onCheckedChange = onCheckedChange,
                enabled = enabled,
                colors = CheckboxDefaults.colors(
                    checkedColor = SuccessGreen,
                    uncheckedColor = colors.outline,
                ),
                modifier = Modifier
                    .testTag("exercise-checkbox-${row.orderIndex}")
                    .semantics { contentDescription = "Đánh dấu ${row.nameVi} hoàn thành" },
            )
        }

        // Expandable instructions
        Text(
            if (expanded) "Ẩn hướng dẫn ▲" else "Xem hướng dẫn ▼",
            color = EnergyOrange,
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 48.dp)
                .testTag("exercise-expand-${row.orderIndex}")
                .clickable(enabled = enabled) { expanded = !expanded }
                .semantics {
                    contentDescription = if (expanded) "Đóng hướng dẫn ${row.nameVi}" else "Mở hướng dẫn ${row.nameVi}"
                }
                .padding(vertical = 6.dp),
        )

        if (expanded) {
            Column(
                Modifier
                    .fillMaxWidth()
                    .background(colors.surface, RoundedCornerShape(12.dp))
                    .padding(14.dp)
                    .testTag("exercise-instructions-${row.orderIndex}"),
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                row.instructionsVi.forEachIndexed { index, instruction ->
                    Row {
                        Text(
                            "${index + 1}.",
                            color = EnergyOrange,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.width(24.dp),
                        )
                        Text(instruction, color = customColors.primaryText, style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
        }
    }
}

private fun muscleEmoji(muscle: MuscleGroup): String = when (muscle) {
    MuscleGroup.CHEST -> "🫁"
    MuscleGroup.BACK -> "🔙"
    MuscleGroup.SHOULDERS -> "💪"
    MuscleGroup.BICEPS -> "💪"
    MuscleGroup.TRICEPS -> "💪"
    MuscleGroup.CORE -> "🎯"
    MuscleGroup.QUADS -> "🦵"
    MuscleGroup.HAMSTRINGS -> "🦵"
    MuscleGroup.GLUTES -> "🍑"
    MuscleGroup.CALVES -> "🦶"
    MuscleGroup.FULL_BODY -> "🏋️"
    MuscleGroup.CARDIO -> "❤️"
    MuscleGroup.MOBILITY -> "🧘"
}
