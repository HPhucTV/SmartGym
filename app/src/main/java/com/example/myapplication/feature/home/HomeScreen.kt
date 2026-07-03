package com.example.myapplication.feature.home

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

internal object HomePalette {
    val background = Color(0xFFFFFFFF)
    val navy = Color(0xFF14213D)
    val orange = Color(0xFFF97316)
    val green = Color(0xFF22C55E)
    val supportingSurface = Color(0xFFF3F4F6)
    val border = Color(0xFFE5E7EB)
    val mutedText = Color(0xFF64748B)
}

@Composable
fun HomeScreen(
    state: HomeUiState,
    onNavigateToWorkouts: () -> Unit,
    modifier: Modifier = Modifier,
    onNavigateToNutrition: () -> Unit = {},
    onNavigateToCheckIn: () -> Unit = {},
    onNavigateToRecommendations: () -> Unit = {},
    onNavigateToAchievements: () -> Unit = {},
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp, vertical = 18.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        HomeHeader(epochDay = state.epochDay)

        // Daily Motivation Quote
        if (state.dailyQuote.isNotEmpty()) {
            MotivationCard(quote = state.dailyQuote)
        }

        WorkoutHero(state = state, onClick = onNavigateToWorkouts)
        StatusRow(state = state)

        Text(
            text = "TIẾP THEO CHO BẠN",
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 1.2.sp,
        )
        DashboardActionCard(
            tag = "home-nutrition-action",
            eyebrow = "DINH DƯỠNG HÔM NAY",
            title = nutritionTitle(state),
            supporting = nutritionSupporting(state),
            accent = HomePalette.green,
            onClick = onNavigateToNutrition,
        )
        DashboardActionCard(
            tag = "home-checkin-action",
            eyebrow = "PHẢN HỒI HẰNG TUẦN",
            title = "Check-in cơ thể",
            supporting = "Ghi cân nặng, năng lượng và khả năng phục hồi",
            accent = HomePalette.navy,
            onClick = onNavigateToCheckIn,
        )
        DashboardActionCard(
            tag = "home-recommendations-action",
            eyebrow = "CÁ NHÂN HÓA",
            title = "Đề xuất dành cho bạn",
            supporting = "Xem điều chỉnh dựa trên lịch sử và check-in gần nhất",
            accent = HomePalette.orange,
            onClick = onNavigateToRecommendations,
        )
        DashboardActionCard(
            tag = "home-achievements-action",
            eyebrow = "THÀNH TỰU",
            title = "Huy hiệu của bạn 🏆",
            supporting = "Xem các thành tựu đã mở khóa và thử thách mới",
            accent = Color(0xFFEAB308),
            onClick = onNavigateToAchievements,
        )
        Spacer(Modifier.height(4.dp))
    }
}

@Composable
private fun HomeHeader(epochDay: Long) {
    val date = LocalDate.ofEpochDay(epochDay)
    val vietnamese = Locale.forLanguageTag("vi-VN")
    val formatter = DateTimeFormatter.ofPattern("EEEE, d 'tháng' M", vietnamese)
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(42.dp)
                .background(HomePalette.navy, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Text("S", color = Color.White, fontWeight = FontWeight.Black, fontSize = 18.sp)
        }
        Spacer(Modifier.width(12.dp))
        Column {
            Text(
                text = "SMARTGYM",
                color = MaterialTheme.colorScheme.onBackground,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Black,
            )
            Text(
                text = formatter.format(date).replaceFirstChar { it.uppercase(vietnamese) },
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                style = MaterialTheme.typography.bodyMedium,
            )
        }
    }
}

@Composable
private fun WorkoutHero(state: HomeUiState, onClick: () -> Unit) {
    val hasWorkout = state.workoutTitle != null
    val progress = if (state.totalExercises > 0) {
        state.completedExercises.toFloat() / state.totalExercises
    } else {
        0f
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(HomePalette.navy, RoundedCornerShape(20.dp))
            .border(1.dp, HomePalette.navy, RoundedCornerShape(20.dp))
            .padding(20.dp),
    ) {
        Text(
            text = "BUỔI TẬP HÔM NAY",
            color = HomePalette.orange,
            fontWeight = FontWeight.Bold,
            fontSize = 12.sp,
            letterSpacing = 1.1.sp,
        )
        Spacer(Modifier.height(10.dp))
        Text(
            text = state.workoutTitle ?: "Chưa có buổi tập hiện tại",
            color = Color.White,
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Black,
        )
        if (hasWorkout) {
            Text(
                text = listOfNotNull(state.workoutFocus, state.durationMinutes?.let { "$it phút" }).joinToString("  •  "),
                color = Color(0xFFCBD5E1),
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.padding(top = 4.dp),
            )
            Spacer(Modifier.height(18.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("Tiến độ bài tập", color = Color(0xFFCBD5E1), style = MaterialTheme.typography.bodySmall)
                Text(
                    "${state.completedExercises}/${state.totalExercises}",
                    color = HomePalette.green,
                    fontWeight = FontWeight.Bold,
                )
            }
            Spacer(Modifier.height(8.dp))
            LinearProgressIndicator(
                progress = { progress },
                modifier = Modifier.fillMaxWidth().height(7.dp),
                color = HomePalette.green,
                trackColor = Color(0xFF243047),
            )
        } else {
            Text(
                text = "Kế hoạch sẽ xuất hiện khi có buổi tập đang hoạt động.",
                color = Color(0xFFCBD5E1),
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.padding(top = 8.dp),
            )
        }
        Spacer(Modifier.height(18.dp))
        Button(
            onClick = onClick,
            enabled = hasWorkout,
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 52.dp)
                .testTag("home-workout-action"),
            shape = RoundedCornerShape(14.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = HomePalette.orange,
                contentColor = Color.White,
                disabledContainerColor = Color(0xFF334155),
                disabledContentColor = Color(0xFFCBD5E1),
            ),
        ) {
            Text(
                text = if (state.completedExercises > 0) "TIẾP TỤC BUỔI TẬP" else "BẮT ĐẦU BUỔI TẬP",
                fontWeight = FontWeight.Black,
            )
        }
    }
}

@Composable
private fun StatusRow(state: HomeUiState) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        StatusMetric(
            value = state.completedThisWeek.toString(),
            label = "Buổi tuần này",
            accent = HomePalette.navy,
            modifier = Modifier.weight(1f),
        )
        StatusMetric(
            value = state.streakDays.toString(),
            label = "Ngày liên tiếp",
            accent = HomePalette.green,
            modifier = Modifier.weight(1f),
        )
        StatusMetric(
            value = state.caloriesTarget?.let { "${((state.caloriesConsumed * 100L) / it.coerceAtLeast(1)).coerceAtMost(999)}%" } ?: "—",
            label = "Dinh dưỡng",
            accent = HomePalette.orange,
            modifier = Modifier.weight(1f),
        )
    }
}

@Composable
private fun StatusMetric(value: String, label: String, accent: Color, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .heightIn(min = 94.dp)
            .background(MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(14.dp))
            .border(1.dp, MaterialTheme.colorScheme.outline, RoundedCornerShape(14.dp))
            .padding(horizontal = 10.dp, vertical = 14.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(value, color = accent, fontSize = 24.sp, fontWeight = FontWeight.Black)
        Spacer(Modifier.height(4.dp))
        Text(
            text = label,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            style = MaterialTheme.typography.labelSmall,
            maxLines = 2,
        )
    }
}

@Composable
private fun DashboardActionCard(
    tag: String,
    eyebrow: String,
    title: String,
    supporting: String,
    accent: Color,
    onClick: () -> Unit,
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 96.dp)
            .testTag(tag)
            .clickable(onClick = onClick),
        color = MaterialTheme.colorScheme.surface,
        contentColor = MaterialTheme.colorScheme.onSurface,
        shape = RoundedCornerShape(16.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .size(10.dp)
                    .background(accent, CircleShape),
            )
            Spacer(Modifier.width(14.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(eyebrow, color = accent, fontSize = 10.sp, fontWeight = FontWeight.Bold, letterSpacing = 0.8.sp)
                Text(title, color = MaterialTheme.colorScheme.onSurface, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Text(supporting, color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodySmall)
            }
            Text("›", color = accent, fontSize = 28.sp, fontWeight = FontWeight.Light)
        }
    }
}

private fun nutritionTitle(state: HomeUiState): String = state.caloriesTarget?.let {
    "${state.caloriesConsumed} / $it kcal"
} ?: "${state.caloriesConsumed} kcal đã ghi"

private fun nutritionSupporting(state: HomeUiState): String = if (state.caloriesTarget == null) {
    "Chưa có mục tiêu calories — hoàn thiện hồ sơ để cá nhân hóa"
} else {
    "Mở nhật ký để cập nhật bữa ăn hôm nay"
}

@Composable
private fun MotivationCard(quote: String) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = RoundedCornerShape(16.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("✨", fontSize = 18.sp, modifier = Modifier.padding(end = 6.dp))
                Text(
                    text = "ĐỘNG LỰC HẰNG NGÀY",
                    color = HomePalette.orange,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 1.sp
                )
                Text("✨", fontSize = 18.sp, modifier = Modifier.padding(start = 6.dp))
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "“$quote”",
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                lineHeight = 20.sp
            )
        }
    }
}
