package com.example.myapplication.feature.progress

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.myapplication.ui.theme.customColors
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.format.TextStyle
import java.util.Locale

@Composable
fun ContributionGraphCard(
    markedEpochDays: Set<Long>,
    modifier: Modifier = Modifier,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    Surface(
        color = colors.surface,
        shape = RoundedCornerShape(16.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, colors.outline),
        modifier = modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Tần suất tập luyện (18 tuần)",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = customColors.primaryText
            )
            Spacer(modifier = Modifier.height(12.dp))

            Row(verticalAlignment = Alignment.CenterVertically) {
                // Day Labels on the Left
                Column(
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                    modifier = Modifier.padding(end = 8.dp)
                ) {
                    // Show labels for T2, T4, T6 (Mon, Wed, Fri)
                    Text("T2", fontSize = 9.sp, color = customColors.mutedText, fontWeight = FontWeight.Bold)
                    Box(modifier = Modifier.height(10.dp)) // spacer matching Box size
                    Text("T4", fontSize = 9.sp, color = customColors.mutedText, fontWeight = FontWeight.Bold)
                    Box(modifier = Modifier.height(10.dp))
                    Text("T6", fontSize = 9.sp, color = customColors.mutedText, fontWeight = FontWeight.Bold)
                    Box(modifier = Modifier.height(10.dp))
                    Text("CN", fontSize = 9.sp, color = customColors.mutedText, fontWeight = FontWeight.Bold)
                }

                // Grid scrollable horizontally
                val today = remember { LocalDate.now() }
                val startDay = remember {
                    val date = today.minusWeeks(18)
                    // Back up to the Monday of that week
                    date.minusDays((date.dayOfWeek.value - 1).toLong())
                }

                Row(
                    modifier = Modifier.horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    for (w in 0..18) {
                        Column(
                            verticalArrangement = Arrangement.spacedBy(4.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            // Month label at the top of the column if it's the start of a month or first column
                            val firstDayOfWeek = startDay.plusWeeks(w.toLong())
                            val showMonthLabel = w == 0 || firstDayOfWeek.dayOfMonth <= 7
                            val monthLabel = if (showMonthLabel) {
                                firstDayOfWeek.month.getDisplayName(TextStyle.SHORT, Locale.forLanguageTag("vi"))
                            } else ""

                            Text(
                                text = monthLabel,
                                fontSize = 8.sp,
                                fontWeight = FontWeight.Bold,
                                color = customColors.mutedText,
                                modifier = Modifier.height(12.dp),
                                maxLines = 1
                            )

                            // 7 days of the week (Monday to Sunday)
                            for (d in 0..6) {
                                val date = firstDayOfWeek.plusDays(d.toLong())
                                val isFuture = date.isAfter(today)
                                val epochDay = date.toEpochDay()
                                val isCompleted = epochDay in markedEpochDays

                                val cellColor = when {
                                    isFuture -> Color.Transparent
                                    isCompleted -> Color(0xFF22C55E) // Green for workouts
                                    else -> colors.outline.copy(alpha = 0.5f) // Gray for rest
                                }

                                Box(
                                    modifier = Modifier
                                        .size(10.dp)
                                        .background(
                                            color = cellColor,
                                            shape = RoundedCornerShape(2.dp)
                                        )
                                )
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))
            // Legend
            Row(
                horizontalArrangement = Arrangement.End,
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Ít", fontSize = 10.sp, color = customColors.mutedText)
                Spacer(modifier = Modifier.width(4.dp))
                Box(
                    modifier = Modifier
                        .size(10.dp)
                        .background(colors.outline.copy(alpha = 0.5f), RoundedCornerShape(2.dp))
                )
                Spacer(modifier = Modifier.width(4.dp))
                Box(
                    modifier = Modifier
                        .size(10.dp)
                        .background(Color(0xFF22C55E), RoundedCornerShape(2.dp))
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text("Nhiều", fontSize = 10.sp, color = customColors.mutedText)
            }
        }
    }
}
