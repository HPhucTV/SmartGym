import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class GymBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GymBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      const _BottomNavItem(
        label: "Hôm nay",
        activeIcon: Icons.today_rounded,
        inactiveIcon: Icons.today_outlined,
      ),
      const _BottomNavItem(
        label: "Tiến độ",
        activeIcon: Icons.insights_rounded,
        inactiveIcon: Icons.insights_outlined,
      ),
      const _BottomNavItem(
        label: "Dinh dưỡng",
        activeIcon: Icons.restaurant_menu_rounded,
        inactiveIcon: Icons.restaurant_menu_outlined,
      ),
      const _BottomNavItem(
        label: "Cài đặt",
        activeIcon: Icons.settings_rounded,
        inactiveIcon: Icons.settings_outlined,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.borderGray,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.inactiveIcon,
                        color: isSelected
                            ? AppColors.energyOrange
                            : (isDark ? AppColors.darkMutedText : AppColors.mutedText),
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: GymTypography.labelSmall.copyWith(
                          color: isSelected
                              ? AppColors.energyOrange
                              : (isDark ? AppColors.darkMutedText : AppColors.mutedText),
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.energyOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 6),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const _BottomNavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}
