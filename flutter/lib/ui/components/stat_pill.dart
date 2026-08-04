import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'gym_card.dart';

class StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Widget? icon;
  final Color? valueColor;

  const StatPill({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GymCard(
        variant: GymCardVariant.flat,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(height: 8),
            ],
            Text(
              value,
              style: GymTypography.displayLarge.copyWith(
                color: valueColor ?? (isDark ? AppColors.white : AppColors.navy),
                fontSize: 24, // Optimized font size for small cards
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: isDark ? GymTypography.bodySmall.mutedDark : GymTypography.bodySmall.muted,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
