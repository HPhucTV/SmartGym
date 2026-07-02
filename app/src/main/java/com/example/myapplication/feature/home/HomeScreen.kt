package com.example.myapplication.feature.home

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.style.TextAlign

// Colors matching the dark premium mockup
private val DarkBg = Color(0xFF070B19)
private val CardBg = Color(0xFF0F172A)
private val NeonGreen = Color(0xFF22C55E)
private val MutedText = Color(0xFF94A3B8)

@Composable
fun HomeScreen(
    state: HomeUiState,
    onNavigateToWorkouts: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DarkBg)
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        // App title header
        Row(
            modifier = Modifier.fillMaxWidth().padding(vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(24.dp)
                    .background(Color(0xFF3B82F6), shape = RoundedCornerShape(6.dp)),
                contentAlignment = Alignment.Center
            ) {
                Text("S", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 14.sp)
            }
            Spacer(Modifier.width(10.dp))
            Text(
                text = "SmartGym",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }

        // Layout with two main side-by-side components or stacked row
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalAlignment = Alignment.Top
        ) {
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Today's Workout Summary Card
                WorkoutSummaryCard(
                    minutes = state.durationMinutes,
                    type = state.workoutType,
                    sets = state.completedSets,
                    total = state.totalSets,
                    onClick = onNavigateToWorkouts
                )

                // Weekly Progress Card
                WeeklyProgressCard(
                    weeklyProgress = state.weeklyProgress
                )
            }

            Column(
                modifier = Modifier.width(130.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Calories Burned Circular Progress (Workout active burn)
                CaloriesCircle(
                    title = "Đốt cháy",
                    current = state.caloriesBurned,
                    target = state.caloriesBurnedTarget,
                    glowColor = Color(0xFFF97316) // orange
                )

                // Calories Consumed Circular Progress (Nutrition food logged today)
                CaloriesCircle(
                    title = "Hấp thụ",
                    current = state.caloriesConsumed,
                    target = state.caloriesTarget,
                    glowColor = NeonGreen // green
                )

                // 14-day Streak Badge
                StreakBadge(
                    days = state.streakDays
                )
            }
        }
    }
}

@Composable
private fun WorkoutSummaryCard(
    minutes: Int,
    type: String,
    sets: Int,
    total: Int,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(CardBg, shape = RoundedCornerShape(16.dp))
            .border(1.dp, Color(0x333B82F6), shape = RoundedCornerShape(16.dp))
            .clickable { onClick() }
    ) {
        // Left accent neon border
        Box(
            modifier = Modifier
                .align(Alignment.CenterStart)
                .width(4.dp)
                .height(40.dp)
                .background(NeonGreen, shape = RoundedCornerShape(topEnd = 4.dp, bottomEnd = 4.dp))
        )

        Column(
            modifier = Modifier.padding(start = 16.dp, top = 16.dp, end = 16.dp, bottom = 16.dp)
        ) {
            Text(
                text = "Tóm tắt buổi tập hôm nay",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                color = Color.White
            )
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "$minutes phút",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = "· $type · $sets/$total bài đã xong",
                    style = MaterialTheme.typography.bodySmall,
                    color = MutedText
                )
            }
        }
    }
}

@Composable
private fun CaloriesCircle(
    title: String,
    current: Int,
    target: Int,
    glowColor: Color,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .size(130.dp)
            .background(CardBg, shape = CircleShape)
            .border(1.dp, Color(0x11FFFFFF), shape = CircleShape),
        contentAlignment = Alignment.Center
    ) {
        val progress = if (target > 0) (current.toFloat() / target).coerceIn(0f, 1f) else 0f
        
        // Custom neon-glowing circular progress using canvas
        Canvas(modifier = Modifier.size(112.dp)) {
            val strokeWidth = 8.dp.toPx()

            // Background track
            drawCircle(
                color = Color(0xFF1E293B),
                style = Stroke(width = strokeWidth)
            )

            // Neon glow outer blur
            drawArc(
                color = glowColor.copy(alpha = 0.15f),
                startAngle = -90f,
                sweepAngle = 360f * progress,
                useCenter = false,
                style = Stroke(width = strokeWidth + 4.dp.toPx(), cap = StrokeCap.Round)
            )

            // Main glowing arc
            drawArc(
                color = glowColor,
                startAngle = -90f,
                sweepAngle = 360f * progress,
                useCenter = false,
                style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
            )
        }

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.labelSmall,
                color = MutedText,
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = "$current",
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
            Text(
                text = "/ $target kcal",
                fontSize = 9.sp,
                color = MutedText
            )
        }
    }
}

@Composable
private fun WeeklyProgressCard(
    weeklyProgress: List<Int>
) {
    val labels = listOf("T2", "T3", "T4", "T5", "T6", "T7", "CN")
    val maxVal = weeklyProgress.maxOrNull()?.coerceAtLeast(1) ?: 60

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(CardBg, shape = RoundedCornerShape(16.dp))
            .border(1.dp, Color(0x11FFFFFF), shape = RoundedCornerShape(16.dp))
            .padding(16.dp)
    ) {
        Text(
            text = "Tiến độ tuần này",
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.SemiBold,
            color = Color.White
        )
        Spacer(modifier = Modifier.height(20.dp))

        Row(
            modifier = Modifier.fillMaxWidth().height(100.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.Bottom
        ) {
            weeklyProgress.forEachIndexed { index, minutes ->
                val ratio = (minutes.toFloat() / maxVal).coerceIn(0.1f, 1f)
                val isHighlighted = index in listOf(3, 4) // Highlight T5 and T6 (Thu & Fri) like mockup

                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Bottom,
                    modifier = Modifier.weight(1f)
                ) {
                    Box(
                        modifier = Modifier
                            .width(14.dp)
                            .fillMaxHeight(ratio)
                            .background(
                                color = if (isHighlighted) NeonGreen else Color(0xFF3B82F6),
                                shape = RoundedCornerShape(topStart = 4.dp, topEnd = 4.dp)
                            )
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = labels[index],
                        fontSize = 9.sp,
                        fontWeight = FontWeight.Medium,
                        color = if (isHighlighted) NeonGreen else MutedText
                    )
                }
            }
        }
    }
}

@Composable
private fun StreakBadge(
    days: Int
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(CardBg, shape = RoundedCornerShape(12.dp))
            .border(1.dp, Color(0x333B82F6), shape = RoundedCornerShape(12.dp))
            .padding(vertical = 12.dp, horizontal = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center
    ) {
        Text(
            text = "🔥",
            fontSize = 16.sp
        )
        Spacer(modifier = Modifier.width(6.dp))
        Text(
            text = "Chuỗi $days ngày",
            color = Color.White,
            fontWeight = FontWeight.Bold,
            fontSize = 12.sp
        )
    }
}
