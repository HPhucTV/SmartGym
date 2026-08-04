import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/program/program_phase_planner.dart';
import '../../core/model/catalog_models.dart';
import '../../ui/theme/colors.dart';
import '../../ui/theme/theme.dart';
import '../../ui/theme/spacing.dart';
import '../../ui/theme/typography.dart';
import '../../ui/components/gym_card.dart';
import '../../ui/components/gym_button.dart';
import '../../ui/components/gym_progress_indicator.dart';
import 'today_ui_state.dart';
import 'today_view_model.dart';
import 'widgets/exercise_card.dart';
import 'widgets/exercise_substitution_dialog.dart';
import 'widgets/workout_feedback_dialog.dart';
import 'widgets/achievement_unlock_dialog.dart';
import 'widgets/rest_timer_section.dart';
import '../../ui/components/confetti_celebration.dart';

class TodayScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToCatalog;
  final VoidCallback onNavigateToNutrition;

  const TodayScreen({
    super.key,
    required this.onNavigateToCatalog,
    required this.onNavigateToNutrition,
  });

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  int _timerInitialSeconds = 0;
  bool _timerVisible = false;

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(todayNotifierProvider);
    final celebration = ref.watch(celebrationProvider);
    final pendingFeedback = ref.watch(pendingFeedbackProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBg
          : AppColors.white,
      body: Stack(
        children: [
          // Main Content
          _buildMainContent(uiState),

          // Confetti / Celebration Layer
          if (celebration.showConfetti) ...[
            ConfettiCelebration(
              isActive: true,
              onFinished: () {
                if (celebration.unlockedAchievements.isEmpty) {
                  ref.read(todayNotifierProvider.notifier).dismissCelebration();
                }
              },
            ),
            if (celebration.unlockedAchievements.isEmpty)
              _buildSimpleCelebrationBanner(celebration)
            else
              _buildAchievementCelebrationDialog(celebration),
          ],

          // Feedback Dialogue
          if (pendingFeedback != null) _buildFeedbackDialog(pendingFeedback),
        ],
      ),
    );
  }

  Widget _buildMainContent(TodayUiState state) {
    switch (state) {
      case TodayUiStateLoading():
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.energyOrange),
          ),
        );
      case TodayUiStateGoalComplete():
        return const GoalCompleteScreen();
      case TodayUiStateRecovery():
        return RecoveryScreen(
          state: state,
          onRefreshCoachTip: () =>
              ref.read(todayNotifierProvider.notifier).refreshCoachTip(),
        );
      case TodayUiStateError():
        return ErrorScreen(
          state: state,
          onRetry: () => ref.read(todayNotifierProvider.notifier).retry(),
        );
      case TodayUiStateWorkout():
        return _buildWorkoutContent(state);
    }
  }

  Widget _buildWorkoutContent(TodayUiStateWorkout state) {
    final customColors = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final musclesInWorkout =
        state.rows.map((r) => r.primaryMuscleGroup).toSet().toList();

    return Stack(
      children: [
        Positioned.fill(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: GymSpacing.screenHorizontal,
                right: GymSpacing.screenHorizontal,
                top: GymSpacing.screenVertical,
                bottom: 120.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Actions Bar (Tra cứu & Dinh dưỡng)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tập luyện",
                        style: isDark ? GymTypography.displayMedium.white : GymTypography.displayMedium.navy,
                      ),
                      GymButton.text(
                        text: "Tra cứu 📚",
                        onPressed: widget.onNavigateToCatalog,
                      ),
                    ],
                  ),
                  GymGap.md,

                  // Header Card
                  _TodayHeaderCard(
                    state: state,
                  ),
                  GymGap.lg,

                  // Time Budget Choices
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Thời lượng buổi tập",
                        style: GymTypography.titleSmall.copyWith(
                          color: isDark ? AppColors.white : AppColors.navy,
                        ),
                      ),
                      GymGap.sm,
                      Row(
                        children: state.timeBudgetChoices.map((minutes) {
                          final isSelected =
                              state.selectedTimeBudgetMinutes == minutes;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ChoiceChip(
                                showCheckmark: false,
                                label: Center(
                                  child: Text(
                                    minutes != null ? "$minutes phút" : "Đầy đủ",
                                    style: GymTypography.labelSmall.copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? AppColors.darkText : AppColors.navy),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: state.canChangeTimeBudget
                                    ? (_) => ref
                                        .read(todayNotifierProvider.notifier)
                                        .applyTimeBudget(minutes)
                                    : null,
                                selectedColor: AppColors.energyOrange,
                                backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceGray,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: BorderSide.none,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (state.omittedExerciseCount > 0) ...[
                        GymGap.xs,
                        Text(
                          "${state.omittedExerciseCount} bài phụ được lược bớt",
                          style: GymTypography.bodySmall.muted,
                        ),
                      ]
                    ],
                  ),
                  GymGap.lg,

                  // Sore Muscles Toggles
                  if (musclesInWorkout.isNotEmpty) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hôm nay bạn mỏi nhóm cơ nào? (Tập nhẹ giảm 50% hiệp 💡)",
                          style: GymTypography.titleSmall.copyWith(
                            color: isDark ? AppColors.white : AppColors.navy,
                          ),
                        ),
                        GymGap.sm,
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: musclesInWorkout.map((muscle) {
                            final isSelected =
                                state.soreMuscles.contains(muscle.name);
                            return FilterChip(
                              showCheckmark: false,
                              selected: isSelected,
                              label: Text(
                                _muscleLabelVi(muscle),
                                style: GymTypography.labelSmall.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? AppColors.darkText : AppColors.navy),
                                ),
                              ),
                              onSelected: (_) => ref
                                  .read(todayNotifierProvider.notifier)
                                  .toggleSoreMuscle(muscle.name),
                              selectedColor: AppColors.energyOrange,
                              backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceGray,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: BorderSide.none,
                            );
                          }).toList(),
                        )
                      ],
                    ),
                    GymGap.lg,
                  ],

                  // Warmup Card
                  if (state.warmUp != null) ...[
                    AdvisoryMovementBlockCard(
                      sectionLabel: "Khởi động",
                      block: state.warmUp!,
                    ),
                    GymGap.md,
                  ],

                  // AI Coach Tip
                  if (state.coachTip != null) ...[
                    AICoachTipCard(
                      tip: state.coachTip,
                      isRefreshing: state.isRefreshingCoach,
                      onRefresh: () => ref
                          .read(todayNotifierProvider.notifier)
                          .refreshCoachTip(),
                    ),
                    GymGap.md,
                  ],

                  // Section title for exercises
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "DANH SÁCH BÀI TẬP",
                      style: GymTypography.labelLarge.muted,
                    ),
                  ),

                  // Exercises list
                  ...state.rows.map((row) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: ExerciseCard(
                        sessionId: state.sessionId,
                        row: row,
                        enabled: !state.isCompleting &&
                            !state.pendingOrderIndices.contains(row.orderIndex),
                        onCheckedChange: (checked) {
                          ref
                              .read(todayNotifierProvider.notifier)
                              .setChecked(row.orderIndex, checked);
                          if (checked && row.restSeconds > 0) {
                            setState(() {
                              _timerInitialSeconds = row.restSeconds;
                              _timerVisible = true;
                            });
                          }
                        },
                        onSubstitute: () => ref
                            .read(todayNotifierProvider.notifier)
                            .requestSubstitution(row.orderIndex),
                      ),
                    );
                  }),

                  // Cooldown Card
                  if (state.coolDown != null) ...[
                    GymGap.md,
                    AdvisoryMovementBlockCard(
                      sectionLabel: "Thả lỏng",
                      block: state.coolDown!,
                    ),
                  ],

                  // Interaction errors
                  if (state.interactionError != null) ...[
                    GymGap.md,
                    Text(
                      state.interactionError!,
                      style: GymTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],

                  // Complete Button Section
                  GymGap.xxl,
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _getCompleteStatusText(state),
                          style: GymTypography.bodyMedium.copyWith(
                            color: (state.total - state.checkedCount == 0)
                                ? AppColors.successGreen
                                : customColors.mutedText,
                            fontWeight: (state.total - state.checkedCount == 0)
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        GymGap.sm,
                        GymButton.primary(
                          text: state.isCompleting ? "Đang hoàn thành…" : "Hoàn thành buổi tập ✓",
                          onPressed: (state.canComplete && !state.isCompleting)
                              ? () => ref
                                  .read(todayNotifierProvider.notifier)
                                  .completeWorkout()
                              : null,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),

        // Floating Rest Timer
        if (_timerVisible && _timerInitialSeconds > 0)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: RestTimerSection(
                initialSeconds: _timerInitialSeconds,
                onFinished: () {
                  setState(() {
                    _timerVisible = false;
                  });
                },
                onClose: () {
                  setState(() {
                    _timerVisible = false;
                  });
                },
              ),
            ),
          ),

        // Substitution Dialog Overlay
        if (state.substitution != null)
          _buildSubstitutionDialog(state.substitution!),
      ],
    );
  }

  String _getCompleteStatusText(TodayUiStateWorkout state) {
    final remaining = state.total - state.checkedCount;
    if (state.isCompleting) return "Đang lưu kết quả...";
    if (remaining == 0) return "Sẵn sàng hoàn thành! ✓";
    if (remaining == 1) return "Còn 1 bài nữa";
    return "Còn $remaining bài nữa";
  }

  String _muscleLabelVi(MuscleGroup muscle) {
    switch (muscle) {
      case MuscleGroup.chest:
        return "Ngực";
      case MuscleGroup.back:
        return "Lưng";
      case MuscleGroup.shoulders:
        return "Vai";
      case MuscleGroup.biceps:
        return "Tay trước";
      case MuscleGroup.triceps:
        return "Tay sau";
      case MuscleGroup.core:
        return "Cơ bụng";
      case MuscleGroup.quads:
        return "Đùi trước";
      case MuscleGroup.hamstrings:
        return "Đùi sau";
      case MuscleGroup.glutes:
        return "Mông";
      case MuscleGroup.calves:
        return "Bắp chân";
      case MuscleGroup.fullBody:
        return "Toàn thân";
      case MuscleGroup.cardio:
        return "Tim mạch";
      case MuscleGroup.mobility:
        return "Linh hoạt";
    }
  }

  Widget _buildSubstitutionDialog(ExerciseSubstitutionUi substitution) {
    return Positioned.fill(
      child: Container(
        color: Colors.black45,
        alignment: Alignment.center,
        child: ExerciseSubstitutionDialog(
          state: substitution,
          onApply: (replacementId) {
            ref
                .read(todayNotifierProvider.notifier)
                .applySubstitution(replacementId);
          },
          onDismiss: () =>
              ref.read(todayNotifierProvider.notifier).dismissSubstitution(),
        ),
      ),
    );
  }

  Widget _buildFeedbackDialog(PendingWorkoutFeedback feedback) {
    return Positioned.fill(
      child: Container(
        color: Colors.black45,
        alignment: Alignment.center,
        child: WorkoutFeedbackDialog(
          feedback: feedback,
          onDifficultySelected: (difficulty) {
            ref
                .read(todayNotifierProvider.notifier)
                .submitDifficulty(difficulty);
          },
          onDismiss: () =>
              ref.read(todayNotifierProvider.notifier).dismissFeedback(),
        ),
      ),
    );
  }

  Widget _buildSimpleCelebrationBanner(CelebrationState celebration) {
    return Positioned(
      top: 40,
      left: 20,
      right: 20,
      child: SafeArea(
        child: Material(
          color: AppColors.successGreen,
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "Tuyệt vời! Bạn đã hoàn thành buổi tập hôm nay! 💪🎉",
                  textAlign: TextAlign.center,
                  style: GymTypography.titleMedium.white.bold,
                ),
                GymGap.md,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        shareWorkoutSummary(
                          context: context,
                          workoutTitle: celebration.workoutTitle,
                          completed: celebration.completedExercises,
                          total: celebration.totalExercises,
                          achievements: const [],
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Chia sẻ 🔗",
                        style: GymTypography.titleSmall.white.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(todayNotifierProvider.notifier)
                          .dismissCelebration(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.successGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Đóng",
                        style: GymTypography.titleSmall.green.bold,
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCelebrationDialog(CelebrationState celebration) {
    return Positioned.fill(
      child: Container(
        color: Colors.black45,
        alignment: Alignment.center,
        child: AchievementUnlockDialog(
          badges: celebration.unlockedAchievements,
          workoutTitle: celebration.workoutTitle,
          completedExercises: celebration.completedExercises,
          totalExercises: celebration.totalExercises,
          onDismiss: () =>
              ref.read(todayNotifierProvider.notifier).dismissCelebration(),
        ),
      ),
    );
  }
}

class GoalCompleteScreen extends StatelessWidget {
  const GoalCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customColors = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🏆", style: TextStyle(fontSize: 72)),
            GymGap.lg,
            Text(
              "Hoàn thành mục tiêu!",
              style: GymTypography.displayMedium.copyWith(
                color: customColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            GymGap.sm,
            Text(
              "Bạn đã hoàn thành tất cả buổi tập trong chương trình. Tuyệt vời! 🎉",
              textAlign: TextAlign.center,
              style: GymTypography.bodyLarge.copyWith(
                color: customColors.mutedText,
              ),
            ),
            GymGap.xl,
            GymCard(
              variant: GymCardVariant.flat,
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.greenLight,
              child: Text(
                "Hãy vào Cài đặt để tạo mục tiêu mới!",
                textAlign: TextAlign.center,
                style: GymTypography.titleMedium.bold.copyWith(
                  color: isDark ? AppColors.white : AppColors.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final TodayUiStateError state;
  final VoidCallback onRetry;

  const ErrorScreen({
    super.key,
    required this.state,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = context.customColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("⚠️", style: TextStyle(fontSize: 56)),
            GymGap.md,
            Text(
              "Đã có lỗi",
              style: GymTypography.displayMedium.copyWith(
                color: customColors.primaryText,
              ),
            ),
            GymGap.sm,
            Text(
              state.message,
              style: GymTypography.bodyMedium.muted,
              textAlign: TextAlign.center,
            ),
            if (state.canRetry) ...[
              GymGap.lg,
              GymButton.primary(
                text: "Thử lại",
                onPressed: onRetry,
                fullWidth: false,
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class RecoveryScreen extends StatelessWidget {
  final TodayUiStateRecovery state;
  final VoidCallback onRefreshCoachTip;

  const RecoveryScreen({
    super.key,
    required this.state,
    required this.onRefreshCoachTip,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final emoji = state.kind == RecoveryKind.fullRest ? "🧘" : "🚶";
    final title = state.kind == RecoveryKind.fullRest
        ? "Nghỉ ngơi hoàn toàn"
        : "Phục hồi nhẹ";
    final supporting = state.kind == RecoveryKind.fullRest
        ? "Hôm nay hãy nghỉ ngơi để cơ thể phục hồi."
        : "Bạn có thể đi bộ hoặc vận động nhẹ nhàng.";

    final date = DateTime.fromMillisecondsSinceEpoch(
        state.nextDueEpochDay * 24 * 60 * 60 * 1000);
    final dateStr = DateFormat("dd/MM/yyyy").format(date);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            GymGap.lg,
            Text(
              title,
              style: GymTypography.displayMedium.copyWith(
                color: customColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            GymGap.sm,
            Text(
              supporting,
              textAlign: TextAlign.center,
              style: GymTypography.bodyLarge.copyWith(
                color: customColors.mutedText,
              ),
            ),
            GymGap.xl,

            // Next Workout Card
            GymCard(
              variant: GymCardVariant.flat,
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.recoveryBlueBg,
              child: Row(
                children: [
                  const Text("📅", style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Buổi tập tiếp theo",
                          style: GymTypography.titleSmall.copyWith(
                            color: customColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: GymTypography.titleLarge.copyWith(
                            color: AppColors.recoveryBlue,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            GymGap.lg,

            // AI Coach Tip
            if (state.coachTip != null)
              AICoachTipCard(
                tip: state.coachTip,
                isRefreshing: state.isRefreshingCoach,
                onRefresh: onRefreshCoachTip,
              ),
          ],
        ),
      ),
    );
  }
}

class AICoachTipCard extends StatelessWidget {
  final String? tip;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const AICoachTipCard({
    super.key,
    required this.tip,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (tip == null || tip!.isEmpty) return const SizedBox.shrink();
    final customColors = context.customColors;

    return GymCard(
      variant: GymCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("🤖", style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    "Trợ lý AI Coach",
                    style: GymTypography.titleMedium.bold.copyWith(
                      color: customColors.primaryText,
                    ),
                  ),
                ],
              ),
              if (isRefreshing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.energyOrange),
                  ),
                )
              else
                GestureDetector(
                  onTap: onRefresh,
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Text(
                      "Cập nhật 🔄",
                      style: TextStyle(
                        color: AppColors.energyOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
            ],
          ),
          GymGap.sm,
          Text(
            tip!,
            style: GymTypography.bodyMedium.copyWith(
              color: customColors.primaryText,
              height: 1.4,
            ),
          )
        ],
      ),
    );
  }
}

class AdvisoryMovementBlockCard extends StatefulWidget {
  final String sectionLabel;
  final AdvisoryMovementBlockUi block;

  const AdvisoryMovementBlockCard({
    super.key,
    required this.sectionLabel,
    required this.block,
  });

  @override
  State<AdvisoryMovementBlockCard> createState() =>
      _AdvisoryMovementBlockCardState();
}

class _AdvisoryMovementBlockCardState extends State<AdvisoryMovementBlockCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final customColors = context.customColors;

    return GymCard(
      variant: GymCardVariant.flat,
      onTap: () {
        setState(() {
          _expanded = !_expanded;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.sectionLabel.toUpperCase(),
                      style: GymTypography.labelSmall.orange.bold,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.block.titleVi,
                      style: GymTypography.titleMedium.bold.copyWith(
                        color: customColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${widget.block.estimatedMinutes} phút · Không tính vào tiến độ",
                      style: GymTypography.bodySmall.muted,
                    )
                  ],
                ),
              ),
              Icon(
                _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: AppColors.energyOrange,
              )
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GymGap.md,
                      ...List.generate(widget.block.stepsVi.length,
                          (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${index + 1}. ",
                                style: GymTypography.bodyMedium.orange.bold,
                              ),
                              Expanded(
                                child: Text(
                                  widget.block.stepsVi[index],
                                  style: GymTypography.bodyMedium.copyWith(
                                    color: customColors.primaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                    ],
                  )
                : const SizedBox.shrink(),
          )
        ],
      ),
    );
  }
}

class _TodayHeaderCard extends StatelessWidget {
  final TodayUiStateWorkout state;

  const _TodayHeaderCard({
    required this.state,
  });

  String _phaseLabelVi(ProgramPhase phase) {
    switch (phase) {
      case ProgramPhase.foundation:
        return "Giai đoạn làm quen";
      case ProgramPhase.build:
        return "Giai đoạn phát triển";
      case ProgramPhase.consolidate:
        return "Giai đoạn củng cố";
      case ProgramPhase.deload:
        return "Giai đoạn giảm tải";
    }
  }

  @override
  Widget build(BuildContext context) {
    final customColors = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final progress = state.total > 0 ? state.checkedCount / state.total : 0.0;

    return GymCard(
      variant: GymCardVariant.flat,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _phaseLabelVi(state.phase).toUpperCase(),
                  style: GymTypography.labelSmall.orange.bold,
                ),
                const SizedBox(height: 4),
                Text(
                  state.titleVi,
                  style: GymTypography.titleLarge.bold.copyWith(
                    color: customColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${state.focusVi} · ${state.estimatedMinutes} phút",
                  style: GymTypography.bodyMedium.muted,
                ),
                GymGap.sm,
                Text(
                  "${state.checkedCount}/${state.total} bài đã xong",
                  style: GymTypography.titleSmall.green.bold,
                )
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Circular progress ring
          GymCircularProgress(
            value: progress,
            size: 80,
            strokeWidth: 8,
            color: progress >= 1.0 ? AppColors.successGreen : AppColors.energyOrange,
            backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceGray,
          )
        ],
      ),
    );
  }
}

