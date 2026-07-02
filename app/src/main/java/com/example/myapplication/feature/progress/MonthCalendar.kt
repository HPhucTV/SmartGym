package com.example.myapplication.feature.progress

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.myapplication.ui.theme.*
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter

internal val CompletedDayBackgroundColor = SuccessGreen
internal val CompletedDayContentColor = Color(0xFF0F172A) // High contrast dark color on green background

@Composable
fun MonthCalendar(
    selectedMonth: YearMonth,
    markedEpochDays: Set<Long>,
    canNavigatePrevious: Boolean,
    canNavigateNext: Boolean,
    onPreviousMonth: () -> Unit,
    onNextMonth: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    Column(modifier = modifier) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            FilledTonalButton(
                onClick = onPreviousMonth,
                enabled = canNavigatePrevious,
                colors = ButtonDefaults.filledTonalButtonColors(
                    containerColor = colors.surfaceVariant,
                    contentColor = customColors.primaryText
                ),
                modifier = Modifier.sizeIn(minWidth = 48.dp, minHeight = 48.dp)
                    .semantics { contentDescription = "Tháng trước" },
                contentPadding = PaddingValues(0.dp),
            ) { Text("‹", style = MaterialTheme.typography.headlineSmall) }
            Text(
                "Tháng ${selectedMonth.monthValue}, ${selectedMonth.year}",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = customColors.primaryText,
            )
            FilledTonalButton(
                onClick = onNextMonth,
                enabled = canNavigateNext,
                colors = ButtonDefaults.filledTonalButtonColors(
                    containerColor = colors.surfaceVariant,
                    contentColor = customColors.primaryText
                ),
                modifier = Modifier.sizeIn(minWidth = 48.dp, minHeight = 48.dp)
                    .semantics { contentDescription = "Tháng sau" },
                contentPadding = PaddingValues(0.dp),
            ) { Text("›", style = MaterialTheme.typography.headlineSmall) }
        }
        Spacer(Modifier.height(12.dp))
        Row(Modifier.fillMaxWidth()) {
            listOf("T2", "T3", "T4", "T5", "T6", "T7", "CN").forEach { label ->
                Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
                    Text(label, color = customColors.mutedText, style = MaterialTheme.typography.labelMedium)
                }
            }
        }
        Spacer(Modifier.height(6.dp))
        val leading = selectedMonth.atDay(1).dayOfWeek.value - 1
        val cells = leading + selectedMonth.lengthOfMonth()
        val rows = (cells + 6) / 7
        repeat(rows) { row ->
            Row(Modifier.fillMaxWidth()) {
                repeat(7) { column ->
                    val index = row * 7 + column
                    val dayNumber = index - leading + 1
                    if (dayNumber !in 1..selectedMonth.lengthOfMonth()) {
                        Box(Modifier.weight(1f).height(48.dp).testTag("calendar-blank-$index"))
                    } else {
                        CalendarDay(selectedMonth.atDay(dayNumber), selectedMonth.atDay(dayNumber).toEpochDay() in markedEpochDays,
                            Modifier.weight(1f))
                    }
                }
            }
        }
    }
}

@Composable
private fun CalendarDay(date: LocalDate, completed: Boolean, modifier: Modifier = Modifier) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    val formatted = date.format(DateTimeFormatter.ofPattern("dd/MM/yyyy"))
    val description = if (completed) "Đã hoàn thành ngày $formatted" else "Ngày $formatted"
    Box(
        modifier = modifier.height(48.dp).semantics(mergeDescendants = true) { contentDescription = description },
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier.size(38.dp).clip(CircleShape)
                .background(if (completed) CompletedDayBackgroundColor else Color.Transparent),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                date.dayOfMonth.toString(),
                color = if (completed) CompletedDayContentColor else customColors.primaryText,
                fontWeight = FontWeight.SemiBold
            )
            if (completed) {
                Text("✓", color = CompletedDayContentColor, style = MaterialTheme.typography.labelSmall,
                    modifier = Modifier.align(Alignment.BottomEnd).padding(2.dp))
            }
        }
    }
}
