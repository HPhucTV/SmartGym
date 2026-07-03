package com.example.myapplication.feature.today

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.myapplication.ui.theme.EnergyOrange
import com.example.myapplication.ui.theme.customColors
import kotlinx.coroutines.delay

@OptIn(ExperimentalAnimationApi::class)
@Composable
fun RestTimerSection(
    initialSeconds: Int,
    onFinished: () -> Unit,
    onClose: () -> Unit,
) {
    var secondsLeft by remember(initialSeconds) { mutableIntStateOf(initialSeconds) }

    LaunchedEffect(initialSeconds) {
        secondsLeft = initialSeconds
    }

    LaunchedEffect(secondsLeft) {
        if (secondsLeft > 0) {
            delay(1000)
            secondsLeft -= 1
        } else {
            onFinished()
        }
    }

    // Breathing loop: Inhale 4s -> Hold 2s -> Exhale 4s (Total 10s cycle)
    var breathCycleTime by remember { mutableIntStateOf(0) }
    LaunchedEffect(secondsLeft) {
        while (secondsLeft > 0) {
            delay(1000)
            breathCycleTime = (breathCycleTime + 1) % 10
        }
    }

    val (breathText, breathScale) = remember(breathCycleTime) {
        when {
            breathCycleTime < 4 -> {
                // Inhale: 0s to 3s -> progress from 0.5 to 1.0
                val progress = (breathCycleTime + 1) / 4f
                Pair("Hít vào... 👃", 0.5f + (progress * 0.5f))
            }
            breathCycleTime < 6 -> {
                // Hold: 4s to 5s -> stay at 1.0
                Pair("Giữ thở... 🛑", 1.0f)
            }
            else -> {
                // Exhale: 6s to 9s -> progress from 1.0 down to 0.5
                val progress = (breathCycleTime - 5) / 4f
                Pair("Thở ra... 💨", 1.0f - (progress * 0.5f))
            }
        }
    }

    val animatedScale by androidx.compose.animation.core.animateFloatAsState(
        targetValue = breathScale,
        animationSpec = androidx.compose.animation.core.tween(durationMillis = 1000, easing = androidx.compose.animation.core.LinearEasing),
        label = "breathScale"
    )

    Surface(
        color = MaterialTheme.colorScheme.customColors.recoveryBlueBg,
        shape = RoundedCornerShape(20.dp),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 4.dp, vertical = 8.dp)
            .border(2.dp, MaterialTheme.colorScheme.customColors.recoveryBlue, RoundedCornerShape(20.dp)),
        shadowElevation = 6.dp,
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        "⏱️",
                        fontSize = 24.sp,
                        modifier = Modifier.padding(end = 12.dp)
                    )
                    Column {
                        Text(
                            "Thời gian nghỉ",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.customColors.primaryText.copy(alpha = 0.7f)
                        )
                        AnimatedContent(
                            targetState = secondsLeft,
                            transitionSpec = {
                                slideInVertically { height -> height } + fadeIn() togetherWith
                                        slideOutVertically { height -> -height } + fadeOut()
                            },
                            label = "timerText"
                        ) { seconds ->
                            Text(
                                "$seconds giây",
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.customColors.recoveryBlue
                            )
                        }
                    }
                }

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    // +10s Button
                    OutlinedButton(
                        onClick = { secondsLeft += 10 },
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = MaterialTheme.colorScheme.customColors.recoveryBlue
                        ),
                        modifier = Modifier.height(40.dp)
                    ) {
                        Text("+10s", fontWeight = FontWeight.Bold)
                    }

                    // Skip Button
                    Button(
                        onClick = onClose,
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.customColors.recoveryBlue,
                            contentColor = Color.White
                        ),
                        modifier = Modifier.height(40.dp)
                    ) {
                        Text("Bỏ qua", fontWeight = FontWeight.Bold)
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))
            HorizontalDivider(color = MaterialTheme.colorScheme.outline, thickness = 1.dp)
            Spacer(modifier = Modifier.height(12.dp))

            // Breathing Guide Animation Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center
            ) {
                // Circle Canvas
                Box(
                    modifier = Modifier.size(56.dp),
                    contentAlignment = Alignment.Center
                ) {
                    androidx.compose.foundation.Canvas(modifier = Modifier.fillMaxSize()) {
                        drawCircle(
                            color = Color(0xFFF97316).copy(alpha = 0.15f),
                            radius = (size.minDimension / 2) * animatedScale
                        )
                        drawCircle(
                            color = Color(0xFFF97316),
                            radius = (size.minDimension / 4) * animatedScale
                        )
                    }
                }
                Spacer(modifier = Modifier.width(16.dp))
                Column {
                    Text(
                        text = "NHỊP THỞ PHỤC HỒI",
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFFF97316),
                        letterSpacing = 1.sp
                    )
                    Text(
                        text = breathText,
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.customColors.primaryText
                    )
                }
            }
        }
    }
}
