import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';

/// Pill or badge badge rendering categories, routine groups, and frequencies.
class AppBadge extends StatelessWidget {
  final String label;
  final Widget? icon;
  final Color? color;
  final VoidCallback? onTap;
  final bool isOutlined;
  final bool isSelected;

  const AppBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.onTap,
    this.isOutlined = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.primaryAccent;

    final bgColor = isSelected
        ? effectiveColor
        : isOutlined
            ? AppColors.transparent
            : AppColors.pastelSurface(
                effectiveColor,
                isDark: context.isDarkMode,
                opacity: 0.14,
              );

    final textColor = isSelected
        ? AppColors.white
        : isOutlined
            ? effectiveColor
            : effectiveColor;

    final border = isSelected
        ? Border.all(color: effectiveColor, width: 1.2)
        : isOutlined
            ? Border.all(color: effectiveColor.withValues(alpha: 0.5), width: 1.2)
            : Border.all(color: effectiveColor.withValues(alpha: 0.25), width: 1.0);

    Widget badge = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.r),
        border: border,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: effectiveColor.withValues(alpha: 0.35),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h),
                ),
              ]
            : const [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            SizedBox(width: 5.w),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall(
              context,
              color: textColor,
              uppercase: false,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    if (onTap != null) {
      badge = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selectionClick();
          onTap!();
        },
        child: badge,
      );
    }

    return badge;
  }
}

/// Specialized flame streak badge counter.
class AppStreakBadge extends StatelessWidget {
  final int streakCount;
  final Color? color;

  const AppStreakBadge({
    super.key,
    required this.streakCount,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.primaryAccent;

    return AppBadge(
      label: streakCount == 1 ? '1 day streak' : '$streakCount days streak',
      color: accent,
      icon: Icon(
        Icons.local_fire_department_rounded,
        size: 14.sp,
        color: accent,
      ),
    );
  }
}
