import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

enum GymButtonType { primary, secondary, text }

class GymButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final GymButtonType type;
  final bool isLoading;
  final bool fullWidth;
  final Widget? icon;

  const GymButton({
    super.key,
    required this.text,
    this.onPressed,
    required this.type,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
  });

  factory GymButton.primary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool fullWidth = true,
    Widget? icon,
  }) {
    return GymButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: GymButtonType.primary,
      isLoading: isLoading,
      fullWidth: fullWidth,
      icon: icon,
    );
  }

  factory GymButton.secondary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool fullWidth = true,
    Widget? icon,
  }) {
    return GymButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: GymButtonType.secondary,
      isLoading: isLoading,
      fullWidth: fullWidth,
      icon: icon,
    );
  }

  factory GymButton.text({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool fullWidth = false,
    Widget? icon,
  }) {
    return GymButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: GymButtonType.text,
      isLoading: isLoading,
      fullWidth: fullWidth,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final bool isEnabled = onPressed != null && !isLoading;

    Widget buttonContent;
    if (isLoading) {
      buttonContent = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else {
      buttonContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 8),
          ],
          Text(text),
        ],
      );
    }

    Widget btn;
    switch (type) {
      case GymButtonType.primary:
        btn = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: theme.elevatedButtonTheme.style,
          child: buttonContent,
        );
        break;
      case GymButtonType.secondary:
        btn = OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? AppColors.darkText : AppColors.navy,
            side: BorderSide(
              color: isEnabled
                  ? (isDark ? AppColors.darkBorder : AppColors.navy)
                  : (isDark ? AppColors.darkBorder.withOpacity(0.3) : AppColors.navy.withOpacity(0.3)),
              width: 1.5,
            ),
            textStyle: isDark ? GymTypography.titleMedium.white : GymTypography.titleMedium.navy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
          child: buttonContent,
        );
        break;
      case GymButtonType.text:
        btn = TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.energyOrange,
            textStyle: GymTypography.titleMedium.orange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
          child: buttonContent,
        );
        break;
    }

    if (fullWidth && type != GymButtonType.text) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: btn,
      );
    }

    return type == GymButtonType.text ? btn : SizedBox(height: 52, child: btn);
  }
}
