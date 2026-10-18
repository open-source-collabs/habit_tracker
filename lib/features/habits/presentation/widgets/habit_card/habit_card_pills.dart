import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_font_sizes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../data/models/habit_model.dart';
import '../../providers/habit_provider.dart';
import '../habit_extensions.dart';

/// The row of micro-pills under a habit's title: routine, frequency and
/// current streak (when > 0). Purely informational, so it stays compact.
class HabitCardPills extends StatelessWidget {
  final HabitModel habit;
  final int currentStreak;
  final Color accentColor;

  const HabitCardPills({
    super.key,
    required this.habit,
    required this.currentStreak,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final neutralFill = context.isDarkMode
        ? context.surfaceElevatedColor
        : context.cardBorderColor.withValues(alpha: 0.4);

    return Wrap(
      spacing: 6.w,
      runSpacing: 4.h,
      children: [
        _HabitCardPill(
          label: habit.routineGroup,
          background: neutralFill,
          foreground: context.textPrimaryColor,
        ),
        _HabitCardPill(
          label: habit.frequency.label,
          background: neutralFill,
          foreground: context.textPrimaryColor,
        ),
        if (currentStreak > 0)
          _HabitCardPill(
            label: '$currentStreak days',
            icon: Icons.local_fire_department_rounded,
            iconSize: AppIconSizes.xs,
            background: accentColor.withValues(alpha: 0.15),
            foreground: accentColor,
            borderColor: accentColor.withValues(alpha: 0.3),
            fontWeight: FontWeight.w800,
          ),
      ],
    );
  }
}

/// One small rounded label, optionally led by an icon.
class _HabitCardPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final double? iconSize;
  final Color? borderColor;
  final FontWeight fontWeight;

  const _HabitCardPill({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.iconSize,
    this.borderColor,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: context.textTheme.labelSmall?.copyWith(
        fontSize: AppFontSizes.micro,
        fontWeight: fontWeight,
        color: foreground,
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: AppSizes.borderWidth),
      ),
      child: icon == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: iconSize ?? AppIconSizes.xs,
                  color: foreground,
                ),
                SizedBox(width: 3.w),
                text,
              ],
            ),
    );
  }
}

/// Shows or hides the habit's heatmap. Lives in the title row next to the
/// actions menu, which is already finger-height, so a full 48dp touch area
/// costs the card no extra height.
class HabitCardHeatmapToggle extends ConsumerWidget {
  final HabitModel habit;
  final Color accentColor;

  const HabitCardHeatmapToggle({
    super.key,
    required this.habit,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = habitHeatmapExpandedProvider(habit.id);
    final showHeatmap = ref.watch(provider);

    return Semantics(
      toggled: showHeatmap,
      child: AppIconButton(
        icon: Icons.calendar_view_week_rounded,
        tooltip: showHeatmap ? 'Hide heatmap' : 'Show heatmap',
        size: 30.r,
        iconSize: AppIconSizes.sm,
        border: false,
        color: showHeatmap ? accentColor : context.textMutedColor,
        backgroundColor: showHeatmap
            ? accentColor.withValues(alpha: 0.15)
            : AppColors.transparent,
        onPressed: () => ref.read(provider.notifier).state = !showHeatmap,
      ),
    );
  }
}
