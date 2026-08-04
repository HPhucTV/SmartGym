import 'package:flutter/material.dart';
import '../../../core/model/catalog_models.dart';
import '../../../ui/components/exercise_3d_dialog.dart';
import '../today_ui_state.dart';
import '../../../ui/theme/colors.dart';
import '../../../ui/theme/theme.dart';
import '../../../ui/theme/spacing.dart';
import '../../../ui/theme/radius.dart';
import '../../../ui/theme/typography.dart';
import '../../../ui/components/gym_card.dart';
import '../../../ui/components/gym_checkbox.dart';

class ExerciseCard extends StatefulWidget {
  final int sessionId;
  final WorkoutRowUi row;
  final bool enabled;
  final ValueChanged<bool> onCheckedChange;
  final VoidCallback onSubstitute;

  const ExerciseCard({
    super.key,
    required this.sessionId,
    required this.row,
    required this.enabled,
    required this.onCheckedChange,
    required this.onSubstitute,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  bool _expanded = false;

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
    final customColors = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = widget.row.isChecked
        ? (isDark ? AppColors.darkGreenLight : AppColors.greenLight)
        : (isDark ? AppColors.darkSurface : AppColors.white);

    return GymCard(
      variant: widget.row.isChecked
          ? GymCardVariant.flat
          : GymCardVariant.outlined,
      backgroundColor: bgColor,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Exercise Number/Checkmark Badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.row.isChecked
                      ? AppColors.successGreen
                      : AppColors.energyOrange,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.row.isChecked ? "✓" : "${widget.row.orderIndex + 1}",
                  style: GymTypography.titleMedium.white.bold,
                ),
              ),
              const SizedBox(width: 12),

              // Title and Focus Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.row.nameVi,
                            style: GymTypography.titleMedium.bold.copyWith(
                              color: customColors.primaryText,
                              decoration: widget.row.isChecked
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                        if (widget.row.isLightWorkout) ...[
                          const SizedBox(width: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.energyOrange.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Text(
                              "Tập nhẹ",
                              style: GymTypography.labelSmall.orange.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _muscleEmoji(widget.row.primaryMuscleGroup),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "${widget.row.prescriptionText} · nghỉ ${widget.row.restSeconds}s",
                            style: isDark
                                ? GymTypography.bodySmall.mutedDark
                                : GymTypography.bodySmall.muted,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Circular Checkbox Toggle
              GymCheckbox(
                value: widget.row.isChecked,
                onChanged: widget.enabled
                    ? (val) => widget.onCheckedChange(val)
                    : null,
              ),
            ],
          ),

          // Instructions Trigger Link
          InkWell(
            onTap: widget.enabled
                ? () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Text(
                    _expanded ? "Ẩn hướng dẫn ▲" : "Xem hướng dẫn ▼",
                    style: GymTypography.labelSmall.orange.bold,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Instruction Sheet
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.surfaceGray,
                          borderRadius: GymRadius.mdBorder,
                        ),
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Step-by-Step Instructions
                            ...List.generate(widget.row.instructionsVi.length, (
                              index,
                            ) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${index + 1}.",
                                      style:
                                          GymTypography.bodyMedium.orange.bold,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        widget.row.instructionsVi[index],
                                        style: GymTypography.bodyMedium
                                            .copyWith(
                                              color: customColors.primaryText,
                                              height: 1.4,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            if (widget.row.animationId != null) ...[
                              GymGap.md,
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Exercise3DDialog.show(
                                      context: context,
                                      animationId: widget.row.animationId!,
                                      exerciseName: widget.row.nameVi,
                                      instructions: widget.row.instructionsVi,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.energyOrange,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    "Xem chuyển động 3D",
                                    style: GymTypography.titleSmall.white.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // Exercise Substitution Triggers
          if (!widget.row.isChecked) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.enabled ? widget.onSubstitute : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "Thay bài",
                  style: GymTypography.labelSmall.orange.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset expand state if workout session or exercise ID changed
    if (oldWidget.row.exerciseId != widget.row.exerciseId ||
        oldWidget.sessionId != widget.sessionId) {
      setState(() {
        _expanded = false;
      });
    }
  }
}
