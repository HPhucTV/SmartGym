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

    Surface(
        color = MaterialTheme.colorScheme.customColors.recoveryBlueBg,
        shape = RoundedCornerShape(20.dp),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 4.dp, vertical = 8.dp)
            .border(2.dp, MaterialTheme.colorScheme.customColors.recoveryBlue, RoundedCornerShape(20.dp)),
        shadowElevation = 6.dp,
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
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
    }
}
