import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class GymAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const GymAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      title: Text(
        title,
        style: isDark ? GymTypography.titleLarge.white : GymTypography.titleLarge.navy,
      ),
      leading: onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: AppColors.energyOrange,
              onPressed: onBack,
              iconSize: 20,
            )
          : null,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: actions,
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
