package com.example.myapplication.feature.today

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Checkbox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.example.myapplication.ui.theme.*

@Composable
fun ExerciseCard(
    row: WorkoutRowUi,
    enabled: Boolean,
    onCheckedChange: (Boolean) -> Unit,
) {
    var expanded by remember(row.orderIndex) { mutableStateOf(false) }
    Column(
        Modifier.fillMaxWidth().background(SurfaceGray, RoundedCornerShape(16.dp))
            .border(1.dp, BorderGray, RoundedCornerShape(16.dp)).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(row.nameVi, style = MaterialTheme.typography.titleMedium, color = Navy)
                Text("${row.prescriptionText} · nghỉ ${row.restSeconds} giây", color = MutedText)
            }
            if (row.checked) Text("✓", color = SuccessGreen,
                modifier = Modifier.semantics { contentDescription = "Đã hoàn thành ${row.nameVi}" })
            Checkbox(
                checked = row.checked,
                onCheckedChange = onCheckedChange,
                enabled = enabled,
                modifier = Modifier.semantics { contentDescription = "Đánh dấu ${row.nameVi} hoàn thành" },
            )
        }
        Text(
            if (expanded) "Ẩn hướng dẫn" else "Xem hướng dẫn",
            color = EnergyOrange,
            modifier = Modifier.fillMaxWidth().clickable(enabled = enabled) { expanded = !expanded }
                .semantics { contentDescription = if (expanded) "Đóng hướng dẫn ${row.nameVi}" else "Mở hướng dẫn ${row.nameVi}" }
                .padding(vertical = 10.dp),
        )
        if (expanded) row.instructionsVi.forEachIndexed { index, instruction ->
            Text("${index + 1}. $instruction", color = Navy)
        }
    }
}
