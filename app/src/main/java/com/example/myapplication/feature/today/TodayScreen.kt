package com.example.myapplication.feature.today

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.myapplication.core.feedback.WorkoutDifficulty
import com.example.myapplication.ui.theme.EnergyOrange
import com.example.myapplication.ui.theme.SuccessGreen

@Composable
fun TodayScreen(
    state: TodayUiState,
    onCheckedChange: (Int, Boolean) -> Unit,
    onComplete: () -> Unit,
    onRetry: () -> Unit,
    onNavigateToCatalog: () -> Unit = {},
    onNavigateToNutrition: () -> Unit = {},
    onRefreshCoachTip: () -> Unit = {},
    celebrationState: CelebrationState = CelebrationState(),
    onDismissCelebration: () -> Unit = {},
    pendingFeedback: PendingWorkoutFeedback? = null,
    onDifficultySelected: (WorkoutDifficulty) -> Unit = {},
    onDismissFeedback: () -> Unit = {},
    onRequestSubstitution: (Int) -> Unit = {},
    onApplySubstitution: (String) -> Unit = {},
    onDismissSubstitution: () -> Unit = {},
    onApplyTimeBudget: (Int?) -> Unit = {},
    onToggleSoreMuscle: (String) -> Unit = {},
) {
    val colors = MaterialTheme.colorScheme

    Box(modifier = Modifier.fillMaxSize().background(colors.background)) {
        when (state) {
            TodayUiState.Loading -> Box(
                Modifier.fillMaxSize().testTag("today-loading"),
                contentAlignment = Alignment.Center,
            ) {
                CircularProgressIndicator(color = EnergyOrange, modifier = Modifier.semantics { contentDescription = "Đang tải bài tập" })
            }
            TodayUiState.GoalComplete -> GoalCompleteScreen()
            is TodayUiState.Recovery -> RecoveryScreen(state, onRefreshCoachTip)
            is TodayUiState.Error -> ErrorScreen(state, onRetry)
            is TodayUiState.Workout -> WorkoutContent(
                state = state,
                onCheckedChange = onCheckedChange,
                onComplete = onComplete,
                onNavigateToCatalog = onNavigateToCatalog,
                onNavigateToNutrition = onNavigateToNutrition,
                onRefreshCoachTip = onRefreshCoachTip,
                onRequestSubstitution = onRequestSubstitution,
                onApplyTimeBudget = onApplyTimeBudget,
                onToggleSoreMuscle = onToggleSoreMuscle,
            )
        }

        // Celebration Layer
        if (celebrationState.showConfetti) {
            com.example.myapplication.core.ui.ConfettiCelebration(
                isActive = true,
                onFinished = {
                    if (celebrationState.unlockedAchievements.isEmpty()) {
                        onDismissCelebration()
                    }
                }
            )

            // Simple celebratory banner at top if no achievements, or full dialog if achievements are unlocked
            if (celebrationState.unlockedAchievements.isEmpty()) {
                Surface(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 40.dp, start = 20.dp, end = 20.dp),
                    color = SuccessGreen,
                    shape = RoundedCornerShape(16.dp),
                    shadowElevation = 4.dp
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            "Tuyệt vời! Bạn đã hoàn thành buổi tập hôm nay! 💪🎉",
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                            textAlign = androidx.compose.ui.text.style.TextAlign.Center
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            val context = androidx.compose.ui.platform.LocalContext.current
                            OutlinedButton(
                                onClick = {
                                    shareWorkoutSummary(
                                        context = context,
                                        workoutTitle = celebrationState.workoutTitle,
                                        completed = celebrationState.completedExercises,
                                        total = celebrationState.totalExercises,
                                        achievements = emptyList()
                                    )
                                },
                                shape = RoundedCornerShape(12.dp),
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color.White),
                                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.White)
                            ) {
                                Text("Chia sẻ 🔗", fontWeight = FontWeight.Bold)
                            }
                            Button(
                                onClick = onDismissCelebration,
                                modifier = Modifier.testTag("celebration-dismiss"),
                                shape = RoundedCornerShape(12.dp),
                                colors = ButtonDefaults.buttonColors(containerColor = Color.White, contentColor = SuccessGreen)
                            ) {
                                Text("Đóng", fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            } else {
                // Achievement unlock dialog
                AchievementUnlockDialog(
                    badges = celebrationState.unlockedAchievements,
                    workoutTitle = celebrationState.workoutTitle,
                    completedExercises = celebrationState.completedExercises,
                    totalExercises = celebrationState.totalExercises,
                    onDismiss = onDismissCelebration
                )
            }
        }

        pendingFeedback?.let { feedback ->
            WorkoutFeedbackDialog(
                feedback = feedback,
                onDifficultySelected = onDifficultySelected,
                onDismiss = onDismissFeedback,
            )
        }

        (state as? TodayUiState.Workout)?.substitution?.let { substitution ->
            ExerciseSubstitutionDialog(
                state = substitution,
                onApply = onApplySubstitution,
                onDismiss = onDismissSubstitution,
            )
        }
    }
}
