package com.example.myapplication.feature.today

import android.content.Context
import android.content.Intent
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.myapplication.core.achievement.AchievementType
import com.example.myapplication.core.feedback.WorkoutDifficulty
import com.example.myapplication.ui.theme.EnergyOrange
import com.example.myapplication.ui.theme.customColors

@Composable
fun ExerciseSubstitutionDialog(
    state: ExerciseSubstitutionUi,
    onApply: (String) -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Thay ${state.currentNameVi}", fontWeight = FontWeight.Bold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                state.candidates.forEach { candidate ->
                    OutlinedButton(
                        onClick = { onApply(candidate.exerciseId) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("substitute-${candidate.exerciseId}"),
                        shape = RoundedCornerShape(12.dp),
                    ) {
                        Column(Modifier.fillMaxWidth()) {
                            Text(
                                if (candidate.restoresOriginal) "${candidate.nameVi} · Bài gốc" else candidate.nameVi,
                                fontWeight = FontWeight.Bold,
                            )
                            Text(
                                candidate.equipment.joinToString { it.name.lowercase().replace('_', ' ') },
                                style = MaterialTheme.typography.bodySmall,
                            )
                            candidate.instructionsVi.firstOrNull()?.let {
                                Text(it, style = MaterialTheme.typography.bodySmall)
                            }
                        }
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("Đóng") } },
        shape = RoundedCornerShape(20.dp),
        containerColor = MaterialTheme.colorScheme.surface,
    )
}

@Composable
fun WorkoutFeedbackDialog(
    feedback: PendingWorkoutFeedback,
    onDifficultySelected: (WorkoutDifficulty) -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = { if (!feedback.saving) onDismiss() },
        title = {
            Text(
                text = "Buổi tập vừa rồi thế nào?",
                color = MaterialTheme.colorScheme.customColors.primaryText,
                fontWeight = FontWeight.Bold,
            )
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    text = "Phản hồi này giúp điều chỉnh các buổi sau mà không cần ghi tạ hay số lần tập.",
                    color = MaterialTheme.colorScheme.customColors.mutedText,
                )
                listOf(
                    WorkoutDifficulty.EASY to "Quá nhẹ",
                    WorkoutDifficulty.RIGHT to "Vừa sức",
                    WorkoutDifficulty.HARD to "Quá nặng",
                ).forEach { (difficulty, label) ->
                    OutlinedButton(
                        onClick = { onDifficultySelected(difficulty) },
                        enabled = !feedback.saving,
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("feedback-${difficulty.name.lowercase()}"),
                        shape = RoundedCornerShape(12.dp),
                    ) {
                        Text(label)
                    }
                }
                if (feedback.saving) {
                    LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
                }
                feedback.error?.let { message ->
                    Text(message, color = MaterialTheme.colorScheme.error)
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss, enabled = !feedback.saving) {
                Text("Để sau")
            }
        },
        shape = RoundedCornerShape(20.dp),
        containerColor = MaterialTheme.colorScheme.surface,
    )
}

@Composable
fun AchievementUnlockDialog(
    badges: List<AchievementType>,
    workoutTitle: String,
    completedExercises: Int,
    totalExercises: Int,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedButton(
                    onClick = {
                        shareWorkoutSummary(
                            context = context,
                            workoutTitle = workoutTitle,
                            completed = completedExercises,
                            total = totalExercises,
                            achievements = badges,
                        )
                    },
                    shape = RoundedCornerShape(12.dp),
                    border = BorderStroke(1.dp, EnergyOrange),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = EnergyOrange),
                ) {
                    Text("Chia sẻ 🔗", fontWeight = FontWeight.Bold)
                }
                Button(
                    onClick = onDismiss,
                    modifier = Modifier.testTag("celebration-dismiss"),
                    colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
                    shape = RoundedCornerShape(12.dp),
                ) {
                    Text("Đóng 🌟", fontWeight = FontWeight.Bold)
                }
            }
        },
        title = {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text("🏆 THÀNH TỰU MỚI!", color = EnergyOrange, fontWeight = FontWeight.Black, fontSize = 22.sp)
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Chúc mừng bạn đã mở khóa huy hiệu mới!",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.customColors.mutedText,
                    textAlign = TextAlign.Center,
                )
            }
        },
        text = {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.fillMaxWidth(),
            ) {
                badges.forEach { badge ->
                    Surface(
                        color = MaterialTheme.colorScheme.surfaceVariant,
                        shape = RoundedCornerShape(16.dp),
                        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 6.dp),
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(16.dp),
                        ) {
                            Text(badge.icon, fontSize = 42.sp)
                            Spacer(modifier = Modifier.width(16.dp))
                            Column {
                                Text(
                                    badge.titleVi,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.customColors.primaryText,
                                    fontSize = 16.sp,
                                )
                                Text(
                                    badge.descriptionVi,
                                    color = MaterialTheme.colorScheme.customColors.mutedText,
                                    fontSize = 13.sp,
                                )
                            }
                        }
                    }
                }
            }
        },
        shape = RoundedCornerShape(24.dp),
        containerColor = MaterialTheme.colorScheme.surface,
    )
}

internal fun shareWorkoutSummary(
    context: Context,
    workoutTitle: String,
    completed: Int,
    total: Int,
    achievements: List<AchievementType>,
) {
    val shareText = buildWorkoutShareText(workoutTitle, completed, total, achievements)

    val sendIntent = Intent().apply {
        action = Intent.ACTION_SEND
        putExtra(Intent.EXTRA_TEXT, shareText)
        type = "text/plain"
    }
    val shareIntent = Intent.createChooser(sendIntent, "Chia sẻ kết quả tập")
    context.startActivity(shareIntent)
}
