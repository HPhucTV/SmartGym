import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/theme/colors.dart';
import '../../ui/theme/theme.dart';
import '../../ui/theme/spacing.dart';
import '../../ui/theme/typography.dart';
import '../../ui/components/gym_card.dart';
import '../../ui/components/gym_button.dart';
import '../../ui/components/stat_pill.dart';
import '../../ui/components/section_header.dart';
import '../../ui/components/gym_progress_indicator.dart';
import 'home_ui_state.dart';
import 'home_view_model.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback onNavigateToWorkouts;
  final VoidCallback onNavigateToNutrition;
  final VoidCallback onNavigateToCheckIn;
  final VoidCallback onNavigateToRecommendations;
  final VoidCallback onNavigateToAchievements;
  final VoidCallback onNavigateToRoadmap;

  const HomeScreen({
    super.key,
    required this.onNavigateToWorkouts,
    required this.onNavigateToNutrition,
    required this.onNavigateToCheckIn,
    required this.onNavigateToRecommendations,
    required this.onNavigateToAchievements,
    required this.onNavigateToRoadmap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiStateAsync = ref.watch(homeUiStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.white,
      body: uiStateAsync.when(
        data: (state) => _buildContent(context, state),
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.energyOrange),
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(GymSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("⚠️", style: TextStyle(fontSize: 40)),
                GymGap.md,
                Text(
                  "Đã xảy ra lỗi khi tải dữ liệu",
                  style: GymTypography.titleMedium.bold.copyWith(
                    color: context.customColors.primaryText,
                  ),
                ),
                GymGap.xs,
                Text(
                  error.toString(),
                  style: GymTypography.bodySmall.muted,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeUiState state) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: GymSpacing.screenHorizontal,
          vertical: GymSpacing.screenVertical,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, state.epochDay),
            GymGap.lg,

            // Workout Hero Card (Navy theme)
            _buildWorkoutHero(context, state),
            GymGap.lg,

            // Status Metric Pills Row
            _buildStatusRow(context, state),
            GymGap.xl,

            // Quick Actions Grid (2x2 Grid)
            const SectionHeader(
              title: "Tiếp theo cho bạn",
              subtitle: "Lối tắt nhanh",
            ),
            GymGap.sm,
            _buildQuickActionsGrid(context, state),
            GymGap.xl,

            // Daily Motivation Quote
            if (state.dailyQuote.isNotEmpty) ...[
              _buildMotivationCard(context, state.dailyQuote),
              GymGap.lg,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int epochDay) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = DateTime.fromMillisecondsSinceEpoch(epochDay * 24 * 60 * 60 * 1000);

    final weekdays = {
      DateTime.monday: 'thứ hai',
      DateTime.tuesday: 'thứ ba',
      DateTime.wednesday: 'thứ tư',
      DateTime.thursday: 'thứ năm',
      DateTime.friday: 'thứ sáu',
      DateTime.saturday: 'thứ bảy',
      DateTime.sunday: 'chủ nhật',
    };
    final weekday = weekdays[date.weekday] ?? '';
    String formattedDate = "$weekday, ngày ${date.day} tháng ${date.month}";
    if (formattedDate.isNotEmpty) {
      formattedDate = formattedDate[0].toUpperCase() + formattedDate.substring(1);
    }

    final hour = DateTime.now().hour;
    String greeting = "Chào ngày mới!";
    if (hour >= 5 && hour < 12) {
      greeting = "Chào buổi sáng, bạn! 👋";
    } else if (hour >= 12 && hour < 18) {
      greeting = "Chào buổi chiều, bạn! 👋";
    } else {
      greeting = "Chào buổi tối, bạn! 👋";
    }

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.navy,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            "S",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GymTypography.titleMedium.bold.copyWith(
                  color: isDark ? AppColors.white : AppColors.navy,
                ),
              ),
              Text(
                formattedDate,
                style: isDark ? GymTypography.bodySmall.mutedDark : GymTypography.bodySmall.muted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationCard(BuildContext context, String quote) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GymCard(
      variant: GymCardVariant.flat,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceGray.withOpacity(0.5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "✨  ĐỘNG LỰC HẰNG NGÀY  ✨",
                style: GymTypography.labelSmall.orange.bold,
              ),
            ],
          ),
          GymGap.sm,
          Text(
            "“$quote”",
            style: (isDark ? GymTypography.bodyMedium.mutedDark : GymTypography.bodyMedium.muted).copyWith(
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutHero(BuildContext context, HomeUiState state) {
    final hasWorkout = state.workoutTitle != null;
    final progress = state.totalExercises > 0
        ? state.completedExercises / state.totalExercises
        : 0.0;

    return GymCard(
      variant: GymCardVariant.flat,
      backgroundColor: AppColors.navy,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "BUỔI TẬP HÔM NAY",
            style: GymTypography.labelLarge.orange,
          ),
          GymGap.sm,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.workoutTitle ?? "Chưa có buổi tập hiện tại",
                      style: GymTypography.displayMedium.white,
                    ),
                    if (hasWorkout) ...[
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (state.workoutFocus != null) state.workoutFocus,
                          if (state.durationMinutes != null) "${state.durationMinutes} phút"
                        ].join("  •  "),
                        style: GymTypography.bodyMedium.copyWith(color: const Color(0xFFCBD5E1)),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasWorkout && state.totalExercises > 0) ...[
                const SizedBox(width: 16),
                GymCircularProgress(
                  value: progress,
                  size: 54,
                  strokeWidth: 5,
                  color: AppColors.successGreen,
                  backgroundColor: const Color(0xFF243047),
                  centerWidget: Text(
                    "${state.completedExercises}/${state.totalExercises}",
                    style: GymTypography.labelSmall.white.bold,
                  ),
                ),
              ],
            ],
          ),
          if (!hasWorkout) ...[
            GymGap.sm,
            const Text(
              "Kế hoạch sẽ xuất hiện khi có buổi tập đang hoạt động.",
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
            ),
          ],
          GymGap.xl,
          GymButton.primary(
            text: state.completedExercises > 0 ? "TIẾP TỤC TẬP  ➤" : "BẮT ĐẦU TẬP  ➤",
            onPressed: hasWorkout ? onNavigateToWorkouts : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, HomeUiState state) {
    final nutritionPct = state.caloriesTarget != null
        ? "${((state.caloriesConsumed * 100) / state.caloriesTarget!.clamp(1, 999999)).round().clamp(0, 999)}%"
        : "—";

    return Row(
      children: [
        StatPill(
          value: state.completedThisWeek.toString(),
          label: "Buổi tuần này",
          icon: const Icon(Icons.calendar_today_rounded, color: AppColors.recoveryBlue, size: 20),
          valueColor: AppColors.recoveryBlue,
        ),
        const SizedBox(width: 10),
        StatPill(
          value: state.streakDays.toString(),
          label: "Ngày liên tiếp",
          icon: const Icon(Icons.local_fire_department_rounded, color: AppColors.energyOrange, size: 20),
          valueColor: AppColors.energyOrange,
        ),
        const SizedBox(width: 10),
        StatPill(
          value: nutritionPct,
          label: "Dinh dưỡng",
          icon: const Icon(Icons.restaurant_rounded, color: AppColors.successGreen, size: 20),
          valueColor: AppColors.successGreen,
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, HomeUiState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      _QuickActionItem(
        title: "Dinh dưỡng",
        subtitle: state.caloriesTarget != null
            ? "${state.caloriesConsumed}/${state.caloriesTarget} kcal"
            : "Ghi chép ăn uống",
        emoji: "🍎",
        color: AppColors.successGreen,
        onTap: onNavigateToNutrition,
      ),
      _QuickActionItem(
        title: "Check-in tuần",
        subtitle: "Cân nặng & Phục hồi",
        emoji: "📋",
        color: AppColors.recoveryBlue,
        onTap: onNavigateToCheckIn,
      ),
      _QuickActionItem(
        title: "Lộ trình tập",
        subtitle: "Tiến trình chương trình",
        emoji: "🗺️",
        color: AppColors.navy,
        onTap: onNavigateToRoadmap,
      ),
      _QuickActionItem(
        title: "Đề xuất",
        subtitle: "Cá nhân hóa cho bạn",
        emoji: "🎯",
        color: AppColors.energyOrange,
        onTap: onNavigateToRecommendations,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GymCard(
          variant: GymCardVariant.outlined,
          onTap: item.onTap,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceGray,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.mutedText,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GymTypography.titleSmall.copyWith(
                      color: isDark ? AppColors.white : AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: GymTypography.bodySmall.muted.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionItem {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.onTap,
  });
}
