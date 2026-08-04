import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/model/catalog_models.dart';
import '../../core/progress/progress_calculator.dart';
import '../../core/progress/goal_forecast_calculator.dart';
import '../../core/progress/weekly_insight_engine.dart';
import '../../data/local/database.dart';
import '../../data/providers/data_providers.dart';
import '../../ui/theme/colors.dart';
import '../../ui/theme/theme.dart';
import 'progress_ui_state.dart';
import 'progress_view_model.dart';

class ProgressScreen extends ConsumerWidget {
  final VoidCallback onNavigateToCatalog;
  final VoidCallback onNavigateToRoadmap;

  const ProgressScreen({
    super.key,
    required this.onNavigateToCatalog,
    required this.onNavigateToRoadmap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(progressUiStateProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBg
          : AppColors.white,
      body: SafeArea(
        child: uiState is ProgressUiStateLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.energyOrange),
                ),
              )
            : _buildContent(context, ref, uiState),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, ProgressUiState state) {
    final customColors = context.customColors;

    final selectedMonth = state is ProgressUiStateContent
        ? state.selectedMonth
        : (state as ProgressUiStateNoActiveGoal).selectedMonth;

    final markedEpochDays = state is ProgressUiStateContent
        ? state.markedEpochDays
        : (state as ProgressUiStateNoActiveGoal).markedEpochDays;

    final completedInMonth = state is ProgressUiStateContent
        ? state.completedInMonth
        : (state as ProgressUiStateNoActiveGoal).completedInMonth;

    final canNavigatePrevious = state is ProgressUiStateContent
        ? state.canNavigatePrevious
        : (state as ProgressUiStateNoActiveGoal).canNavigatePrevious;

    final canNavigateNext = state is ProgressUiStateContent
        ? state.canNavigateNext
        : (state as ProgressUiStateNoActiveGoal).canNavigateNext;

    final weeklyStats = state is ProgressUiStateContent
        ? state.weeklyStats
        : (state as ProgressUiStateNoActiveGoal).weeklyStats;

    final muscleStats = state is ProgressUiStateContent
        ? state.muscleStats
        : (state as ProgressUiStateNoActiveGoal).muscleStats;

    final weightHistory = state is ProgressUiStateContent
        ? state.weightHistory
        : (state as ProgressUiStateNoActiveGoal).weightHistory;

    final weightFilter = state is ProgressUiStateContent
        ? state.weightFilter
        : (state as ProgressUiStateNoActiveGoal).weightFilter;

    final allCompletedDates = state is ProgressUiStateContent
        ? state.allCompletedDates
        : (state as ProgressUiStateNoActiveGoal).allCompletedDates;

    final targetPerWeek =
        state is ProgressUiStateContent ? state.targetPerWeek : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Expanded(
                child: Text(
                  "Tiến độ tập luyện",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: customColors.primaryText,
                      ),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: onNavigateToRoadmap,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.energyOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                AppColors.energyOrange.withValues(alpha: 0.3)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: const Row(
                        children: [
                          Text("🗺️", style: TextStyle(fontSize: 12)),
                          SizedBox(width: 4),
                          Text(
                            "Lộ trình",
                            style: TextStyle(
                              color: AppColors.energyOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onNavigateToCatalog,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.energyOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                AppColors.energyOrange.withValues(alpha: 0.3)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: const Row(
                        children: [
                          Text("📚", style: TextStyle(fontSize: 12)),
                          SizedBox(width: 4),
                          Text(
                            "Tra cứu",
                            style: TextStyle(
                              color: AppColors.energyOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 18),

          // Goal summary card (if goal active)
          if (state is ProgressUiStateContent) ...[
            _SummaryCard(state: state),
            const SizedBox(height: 18),
          ],

          // Weekly insights card (if active & not empty)
          if (state is ProgressUiStateContent &&
              state.weeklyInsights.isNotEmpty) ...[
            _WeeklyInsightsCard(insights: state.weeklyInsights),
            const SizedBox(height: 18),
          ],

          // Forecast card (if active)
          if (state is ProgressUiStateContent) ...[
            _GoalForecastCard(state: state),
            const SizedBox(height: 18),
          ],

          // Weight history card
          _WeightHistoryChartCard(
            weightHistory: weightHistory,
            currentFilter: weightFilter,
            onFilterSelected: (filter) {
              ref.read(progressWeightFilterProvider.notifier).set(filter);
            },
          ),
          const SizedBox(height: 18),

          // Completion stats card (Weekly completion count & Muscle stats)
          _ProgressChartsSection(
            weeklyStats: weeklyStats,
            targetPerWeek: targetPerWeek,
            muscleStats: muscleStats,
          ),
          const SizedBox(height: 18),

          // Contribution graph
          _ContributionGraphCard(markedEpochDays: allCompletedDates),
          const SizedBox(height: 18),

          // Monthly Calendar Card
          _CalendarCard(
            selectedMonth: selectedMonth,
            markedEpochDays: markedEpochDays,
            completedInMonth: completedInMonth,
            canNavigatePrevious: canNavigatePrevious,
            canNavigateNext: canNavigateNext,
            onPreviousMonth: () {
              ref
                  .read(progressSelectedMonthProvider.notifier)
                  .update((m) => m.plusMonths(-1));
            },
            onNextMonth: () {
              ref
                  .read(progressSelectedMonthProvider.notifier)
                  .update((m) => m.plusMonths(1));
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ProgressUiStateContent state;

  const _SummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final customColors = context.customColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Đang thực hiện mục tiêu",
                style: TextStyle(
                  color: customColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "${state.percentage}%",
                style: const TextStyle(
                  color: AppColors.energyOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: state.percentage / 100,
            backgroundColor: colors.outline.withValues(alpha: 0.3),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.energyOrange),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Đã tập",
                      style: TextStyle(
                          color: customColors.mutedText, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${state.completedActive}/${state.totalActive} buổi",
                      style: TextStyle(
                        color: customColors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
              ),
              Container(
                  width: 1,
                  height: 40,
                  color: colors.outline.withValues(alpha: 0.3)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Chuỗi tuần",
                      style: TextStyle(
                          color: customColors.mutedText, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${state.weeklyStreak} tuần 🔥",
                      style: const TextStyle(
                        color: AppColors.energyOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

class _WeeklyInsightsCard extends StatelessWidget {
  final List<WeeklyInsight> insights;

  const _WeeklyInsightsCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final customColors = context.customColors;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Nhận xét tuần",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: customColors.primaryText,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: insights.map((insight) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2.0),
                      child: Text("•",
                          style: TextStyle(
                              color: AppColors.energyOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight.messageVi,
                        style: TextStyle(
                            color: customColors.primaryText, fontSize: 14),
                      ),
                    )
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            "Phân tích từ lịch tập và phản hồi đã lưu trên thiết bị.",
            style: TextStyle(color: customColors.mutedText, fontSize: 10),
          )
        ],
      ),
    );
  }
}

class _GoalForecastCard extends StatelessWidget {
  final ProgressUiStateContent state;

  const _GoalForecastCard({required this.state});

  String _formatForecastDate(int epochDay) {
    final date = DateTime.fromMillisecondsSinceEpoch(
        epochDay * 24 * 60 * 60 * 1000,
        isUtc: true);
    return DateFormat("dd/MM/yyyy").format(date);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final customColors = context.customColors;

    String title = "";
    String detail = "";

    final forecast = state.goalForecast;
    if (forecast is GoalForecastInsufficientData) {
      title = "Chưa đủ dữ liệu dự báo";
      detail = "Cần ít nhất 2 buổi hoàn thành trong 2 tuần trọn vẹn.";
    } else if (forecast is GoalForecastComplete) {
      title = "Đã hoàn thành mục tiêu";
      detail = "Toàn bộ buổi trong chương trình đã hoàn tất.";
    } else if (forecast is GoalForecastOnTrack) {
      title = "Đang đúng tiến độ";
      detail =
          "Dự kiến hoàn thành ${_formatForecastDate(forecast.projectedEpochDay)}.";
    } else if (forecast is GoalForecastAtRisk) {
      title = "Có nguy cơ chậm tiến độ";
      detail =
          "Dự kiến ${_formatForecastDate(forecast.projectedEpochDay)}, đang chậm ${forecast.sessionsBehind} buổi.";
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dự báo hoàn thành",
            style: TextStyle(
              color: AppColors.energyOrange,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: customColors.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: TextStyle(color: customColors.primaryText, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            "Dựa trên ${state.forecastCompletedSessions} buổi trong ${state.forecastElapsedWeeks} tuần.",
            style: TextStyle(color: customColors.mutedText, fontSize: 10),
          ),
          Text(
            "Đây là ước tính lịch tập, không phải dự đoán cân nặng, y khoa hay vóc dáng.",
            style: TextStyle(color: customColors.mutedText, fontSize: 10),
          )
        ],
      ),
    );
  }
}

class _ProgressChartsSection extends StatelessWidget {
  final List<WeeklyCompletedStats> weeklyStats;
  final int targetPerWeek;
  final List<MuscleCompletedStats> muscleStats;

  const _ProgressChartsSection({
    required this.weeklyStats,
    required this.targetPerWeek,
    required this.muscleStats,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (weeklyStats.isNotEmpty) ...[
          _WeeklyCompletionChartCard(
            weeklyStats: weeklyStats,
            targetPerWeek: targetPerWeek,
          ),
          const SizedBox(height: 18),
        ],
        if (muscleStats.isNotEmpty)
          _MuscleFocusStatsCard(muscleStats: muscleStats),
      ],
    );
  }
}

class _WeeklyCompletionChartCard extends StatelessWidget {
  final List<WeeklyCompletedStats> weeklyStats;
  final int targetPerWeek;

  const _WeeklyCompletionChartCard({
    required this.weeklyStats,
    required this.targetPerWeek,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final customColors = context.customColors;

    final maxVal =
        (weeklyStats.map((s) => s.count).toList() + [4, targetPerWeek])
            .reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tần suất tập luyện hàng tuần",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: customColors.primaryText,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          // Custom bar chart
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: _WeeklyBarChartPainter(
                stats: weeklyStats,
                target: targetPerWeek,
                maxVal: maxVal,
                labelColor: customColors.mutedText,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: weeklyStats.map((stat) {
              return Expanded(
                child: Text(
                  stat.weekLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: customColors.mutedText,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 16, height: 3, color: AppColors.energyOrange),
              const SizedBox(width: 8),
              Text(
                "Mục tiêu hàng tuần ($targetPerWeek buổi)",
                style: TextStyle(color: customColors.mutedText, fontSize: 11),
              )
            ],
          )
        ],
      ),
    );
  }
}

class _WeeklyBarChartPainter extends CustomPainter {
  final List<WeeklyCompletedStats> stats;
  final int target;
  final int maxVal;
  final Color labelColor;

  _WeeklyBarChartPainter({
    required this.stats,
    required this.target,
    required this.maxVal,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Draw Target line (dashed style)
    final targetY = height - (target.toDouble() / maxVal) * height;
    final targetPaint = Paint()
      ..color = AppColors.energyOrange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 6.0;
    double startX = 0;
    while (startX < width) {
      canvas.drawLine(
        Offset(startX, targetY),
        Offset(startX + dashWidth, targetY),
        targetPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Draw bars
    final barCount = stats.length;
    if (barCount == 0) return;

    final spaceBetween = width / (barCount * 2 + 1);
    final barWidth = spaceBetween;

    final barPaint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < barCount; i++) {
      final stat = stats[i];
      final barHeight = (stat.count.toDouble() / maxVal) * height;
      final left = spaceBetween + i * (barWidth + spaceBetween);
      final top = height - barHeight;

      barPaint.color = stat.count >= target
          ? AppColors.successGreen
          : AppColors.energyOrange.withValues(alpha: 0.8);

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(
            left, top, barWidth, barHeight.clamp(4.0, double.infinity)),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      canvas.drawRRect(rect, barPaint);

      // Draw values on top of bars
      final textPainter = TextPainter(
        text: TextSpan(
          text: stat.count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          left + (barWidth - textPainter.width) / 2,
          (top + 4).clamp(0.0, height - textPainter.height - 4),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.stats != stats ||
        oldDelegate.target != target ||
        oldDelegate.maxVal != maxVal ||
        oldDelegate.labelColor != labelColor;
  }
}

class _MuscleFocusStatsCard extends StatelessWidget {
  final List<MuscleCompletedStats> muscleStats;

  const _MuscleFocusStatsCard({required this.muscleStats});

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

  String _muscleEmoji(MuscleGroup muscle) {
    switch (muscle) {
      case MuscleGroup.chest:
        return "🫁";
      case MuscleGroup.back:
        return "🔙";
      case MuscleGroup.shoulders:
      case MuscleGroup.biceps:
      case MuscleGroup.triceps:
        return "💪";
      case MuscleGroup.core:
        return "🎯";
      case MuscleGroup.quads:
      case MuscleGroup.hamstrings:
        return "🦵";
      case MuscleGroup.glutes:
        return "🍑";
      case MuscleGroup.calves:
        return "🦶";
      case MuscleGroup.fullBody:
        return "🏋️";
      case MuscleGroup.cardio:
        return "❤️";
      case MuscleGroup.mobility:
        return "🧘";
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final customColors = context.customColors;

    final maxCount = muscleStats.isNotEmpty
        ? muscleStats.map((s) => s.count).reduce((a, b) => a > b ? a : b)
        : 1;
    final topMuscles = muscleStats.take(5).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Nhóm cơ tác động nhiều nhất",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: customColors.primaryText,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          Column(
            children: topMuscles.map((stat) {
              final progress = stat.count / maxCount;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${_muscleEmoji(stat.muscleGroup)} ${_muscleLabelVi(stat.muscleGroup)}",
                          style: TextStyle(
                            color: customColors.primaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "${stat.count} hiệp",
                          style: TextStyle(
                              color: customColors.mutedText, fontSize: 12),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      color: AppColors.energyOrange,
                      backgroundColor: colors.outline.withValues(alpha: 0.3),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    )
                  ],
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }
}

class _WeightHistoryChartCard extends StatelessWidget {
  final List<WeightMeasurement> weightHistory;
  final WeightFilter currentFilter;
  final ValueChanged<WeightFilter> onFilterSelected;

  const _WeightHistoryChartCard({
    required this.weightHistory,
    required this.currentFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final customColors = context.customColors;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Xu hướng cân nặng ⚖️",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: customColors.primaryText,
                  fontSize: 16,
                ),
              ),

              // Filter selector
              Row(
                children: WeightFilter.values.map((filter) {
                  final active = filter == currentFilter;
                  final label = filter == WeightFilter.last7Days
                      ? "7N"
                      : filter == WeightFilter.last30Days
                          ? "30N"
                          : "90N";
                  return GestureDetector(
                    onTap: () => onFilterSelected(filter),
                    child: Container(
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.energyOrange
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: active ? Colors.white : customColors.mutedText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              )
            ],
          ),
          const SizedBox(height: 16),
          if (weightHistory.length < 2)
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Center(
                child: Text(
                  weightHistory.isEmpty
                      ? "Hãy ghi nhận cân nặng trong phần Cài đặt\nhoặc Check-in hàng tuần."
                      : "Đã ghi nhận ${weightHistory.first.weightKg} kg.\nCần ít nhất 2 ngày đo khác nhau để vẽ biểu đồ.",
                  style: TextStyle(color: customColors.mutedText, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            SizedBox(
              height: 160,
              width: double.infinity,
              child: CustomPaint(
                painter: _WeightLineChartPainter(
                  history: weightHistory,
                  textColor: customColors.primaryText,
                  dateColor: customColors.mutedText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeightLineChartPainter extends CustomPainter {
  final List<WeightMeasurement> history;
  final Color textColor;
  final Color dateColor;

  _WeightLineChartPainter({
    required this.history,
    required this.textColor,
    required this.dateColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final weights = history.map((e) => e.weightKg).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final weightRange = maxWeight - minWeight;

    final yMin = minWeight - math.max(1.0, weightRange * 0.1);
    final yMax = maxWeight + math.max(1.0, weightRange * 0.1);
    final yRange = (yMax - yMin).clamp(0.1, double.infinity);

    final minDay = history.first.epochDay;
    final maxDay = history.last.epochDay;
    final dayRange = (maxDay - minDay).clamp(1, double.infinity).toInt();

    const paddingX = 40.0;
    const paddingY = 20.0;
    final chartWidth = width - paddingX * 2;
    final chartHeight = height - paddingY * 2;

    final points = history.map((measurement) {
      final xFraction =
          dayRange == 0 ? 0.5 : (measurement.epochDay - minDay) / dayRange;
      final yFraction = (measurement.weightKg - yMin) / yRange;
      final x = paddingX + xFraction * chartWidth;
      final y = paddingY + (1.0 - yFraction) * chartHeight;
      return Offset(x, y);
    }).toList();

    // 1. Draw Average dotted line
    final avgWeight = weights.reduce((a, b) => a + b) / weights.length;
    final avgYFraction = (avgWeight - yMin) / yRange;
    final avgY = paddingY + (1.0 - avgYFraction) * chartHeight;

    final gridPaint = Paint()
      ..color = dateColor.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 6.0;
    double startX = paddingX;
    while (startX < width - paddingX) {
      canvas.drawLine(
        Offset(startX, avgY),
        Offset(startX + dashWidth, avgY),
        gridPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // 2. Draw line path connecting points
    final linePaint = Paint()
      ..color = AppColors.energyOrange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }

    // 3. Draw dots and labels
    final dotFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final dotStrokePaint = Paint()
      ..color = AppColors.energyOrange
      ..style = PaintingStyle.fill;

    for (var i = 0; i < points.length; i++) {
      final pt = points[i];
      final measurement = history[i];

      // Outer orange circle
      canvas.drawCircle(pt, 5.0, dotStrokePaint);
      // Inner white circle
      canvas.drawCircle(pt, 2.0, dotFillPaint);

      // Draw weight value text (above dot)
      final weightTextPainter = TextPainter(
        text: TextSpan(
          text: measurement.weightKg.toStringAsFixed(1),
          style: TextStyle(
            color: textColor,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      weightTextPainter.paint(
        canvas,
        Offset(pt.dx - weightTextPainter.width / 2,
            pt.dy - 8.0 - weightTextPainter.height),
      );

      // Draw date label (below dot)
      final date = DateTime.fromMillisecondsSinceEpoch(
          measurement.epochDay * 24 * 60 * 60 * 1000,
          isUtc: true);
      final dateStr = DateFormat("dd/MM").format(date);

      final dateTextPainter = TextPainter(
        text: TextSpan(
          text: dateStr,
          style: TextStyle(
            color: dateColor,
            fontSize: 8,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      dateTextPainter.paint(
        canvas,
        Offset(pt.dx - dateTextPainter.width / 2, pt.dy + 12.0),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeightLineChartPainter oldDelegate) {
    return oldDelegate.history != history ||
        oldDelegate.textColor != textColor ||
        oldDelegate.dateColor != dateColor;
  }
}

class _ContributionGraphCard extends StatelessWidget {
  final Set<int> markedEpochDays;

  const _ContributionGraphCard({required this.markedEpochDays});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final customColors = context.customColors;

    final todayDay = currentLocalEpochDay();
    final todayDate = DateTime.fromMillisecondsSinceEpoch(
        todayDay * 24 * 60 * 60 * 1000,
        isUtc: true);

    // Monday of 18 weeks ago
    final startWeekDate = todayDate.subtract(Duration(days: 18 * 7));
    final startMonday =
        startWeekDate.subtract(Duration(days: startWeekDate.weekday - 1));

    // Controller for automatic alignment to the right side (most recent weeks)
    final scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tần suất tập luyện (18 tuần)",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: customColors.primaryText,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day label column T2, T4, T6, CN
              Column(
                children: [
                  const SizedBox(height: 18),
                  _dayLabel("T2", customColors.mutedText),
                  const SizedBox(height: 12),
                  _dayLabel("T4", customColors.mutedText),
                  const SizedBox(height: 12),
                  _dayLabel("T6", customColors.mutedText),
                  const SizedBox(height: 12),
                  _dayLabel("CN", customColors.mutedText),
                ],
              ),
              const SizedBox(width: 8),

              // Scrollable grid
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month labels row
                      Row(
                        children: List.generate(19, (w) {
                          final firstDayOfWeek =
                              startMonday.add(Duration(days: w * 7));
                          final showLabel = w == 0 || firstDayOfWeek.day <= 7;
                          final monthLabel =
                              showLabel ? "Thg ${firstDayOfWeek.month}" : "";
                          return Container(
                            width: 10,
                            margin: const EdgeInsets.only(right: 4),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              monthLabel,
                              style: TextStyle(
                                  fontSize: 8,
                                  color: customColors.mutedText,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              softWrap: false,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 4),

                      // Grid blocks
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(19, (w) {
                          final firstDayOfWeek =
                              startMonday.add(Duration(days: w * 7));
                          return Container(
                            margin: const EdgeInsets.only(right: 4),
                            child: Column(
                              children: List.generate(7, (d) {
                                final date =
                                    firstDayOfWeek.add(Duration(days: d));
                                final isFuture = date.isAfter(DateTime.now());
                                final epochDay = date.millisecondsSinceEpoch ~/
                                    (24 * 60 * 60 * 1000);
                                final isCompleted =
                                    markedEpochDays.contains(epochDay);

                                Color cellColor =
                                    colors.outline.withValues(alpha: 0.3);
                                if (isFuture) {
                                  cellColor = Colors.transparent;
                                } else if (isCompleted) {
                                  cellColor = AppColors.successGreen;
                                }

                                return Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    color: cellColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("Ít",
                  style:
                      TextStyle(fontSize: 10, color: customColors.mutedText)),
              const SizedBox(width: 4),
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: colors.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: AppColors.successGreen,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text("Nhiều",
                  style:
                      TextStyle(fontSize: 10, color: customColors.mutedText)),
            ],
          )
        ],
      ),
    );
  }

  Widget _dayLabel(String text, Color color) {
    return SizedBox(
      height: 10,
      child: Text(
        text,
        style:
            TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final YearMonth selectedMonth;
  final Set<int> markedEpochDays;
  final int completedInMonth;
  final bool canNavigatePrevious;
  final bool canNavigateNext;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const _CalendarCard({
    required this.selectedMonth,
    required this.markedEpochDays,
    required this.completedInMonth,
    required this.canNavigatePrevious,
    required this.canNavigateNext,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final customColors = context.customColors;

    final firstDayOfMonth =
        DateTime(selectedMonth.year, selectedMonth.month, 1);
    // adjust weekday representation: Monday = 0, Sunday = 6
    final leadingEmptyDays = firstDayOfMonth.weekday - 1;
    final totalDays = _daysInMonth(selectedMonth.year, selectedMonth.month);
    final calendarCells = leadingEmptyDays + totalDays;
    final rows = (calendarCells + 6) ~/ 7;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: canNavigatePrevious ? onPreviousMonth : null,
                icon: const Text("‹",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.energyOrange)),
              ),
              Text(
                "Tháng ${selectedMonth.month}, ${selectedMonth.year}",
                style: TextStyle(
                  color: customColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                onPressed: canNavigateNext ? onNextMonth : null,
                icon: const Text("›",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.energyOrange)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: ["T2", "T3", "T4", "T5", "T6", "T7", "CN"].map((day) {
              return Expanded(
                child: Text(
                  day,
                  style: TextStyle(
                      color: customColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Column(
            children: List.generate(rows, (row) {
              return Row(
                children: List.generate(7, (column) {
                  final index = row * 7 + column;
                  final dayNumber = index - leadingEmptyDays + 1;
                  if (dayNumber < 1 || dayNumber > totalDays) {
                    return const Expanded(child: SizedBox(height: 40));
                  } else {
                    final dayDate = DateTime(
                        selectedMonth.year, selectedMonth.month, dayNumber);
                    final epochDay =
                        dayDate.millisecondsSinceEpoch ~/ (24 * 60 * 60 * 1000);
                    final isCompleted = markedEpochDays.contains(epochDay);

                    return Expanded(
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.all(2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.successGreen
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              dayNumber.toString(),
                              style: TextStyle(
                                color: isCompleted
                                    ? Colors.white
                                    : customColors.primaryText,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (isCompleted)
                              const Positioned(
                                bottom: 2,
                                child: Text(
                                  "✓",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                          ],
                        ),
                      ),
                    );
                  }
                }),
              );
            }),
          )
        ],
      ),
    );
  }
}
