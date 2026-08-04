import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class GymLinearProgress extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final bool showPercentage;

  const GymLinearProgress({
    super.key,
    required this.value,
    this.height = 8.0,
    this.color,
    this.backgroundColor,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressColor = color ?? AppColors.successGreen;
    final bg = backgroundColor ?? (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceGray);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPercentage) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${(value * 100).toInt()}%",
                style: GymTypography.titleSmall.semibold.copyWith(
                  color: isDark ? AppColors.white : AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: value.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, val, child) {
              return SizedBox(
                height: height,
                width: double.infinity,
                child: LinearProgressIndicator(
                  value: val,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  backgroundColor: bg,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class GymCircularProgress extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;
  final Widget? centerWidget;

  const GymCircularProgress({
    super.key,
    required this.value,
    this.size = 80.0,
    this.strokeWidth = 8.0,
    this.color,
    this.backgroundColor,
    this.centerWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressColor = color ?? AppColors.energyOrange;
    final bg = backgroundColor ?? (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceGray);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: value.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, val, child) {
              return SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: val,
                  strokeWidth: strokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  backgroundColor: bg,
                  strokeCap: StrokeCap.round,
                ),
              );
            },
          ),
          if (centerWidget != null) centerWidget!,
          if (centerWidget == null)
            Text(
              "${(value * 100).toInt()}%",
              style: GymTypography.titleMedium.semibold.copyWith(
                color: isDark ? AppColors.white : AppColors.navy,
                fontSize: size * 0.22,
              ),
            ),
        ],
      ),
    );
  }
}
