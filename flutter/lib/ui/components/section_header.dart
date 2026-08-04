import 'package:flutter/material.dart';
import '../theme/typography.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onActionPressed;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (subtitle != null) ...[
                  Text(
                    subtitle!.toUpperCase(),
                    style: (isDark
                            ? GymTypography.labelLarge.mutedDark
                            : GymTypography.labelLarge.muted)
                        .copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  title,
                  style: isDark ? GymTypography.titleLarge.white : GymTypography.titleLarge.navy,
                ),
              ],
            ),
          ),
          if (actionText != null && onActionPressed != null)
            GestureDetector(
              onTap: onActionPressed,
              child: Text(
                actionText!,
                style: GymTypography.titleSmall.orange.semibold,
              ),
            ),
        ],
      ),
    );
  }
}
