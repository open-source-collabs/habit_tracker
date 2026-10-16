import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_font_sizes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../themes/presentation/providers/theme_provider.dart';
import '../../../data/models/habit_model.dart';
import '../../providers/habit_creator_form_provider.dart';
import '../habit_extensions.dart';
import 'habit_creator_accent.dart';

/// Header row: live avatar preview, title/subtitle and close button.
class HabitCreatorHeader extends ConsumerWidget {
  final HabitModel? initialHabit;

  const HabitCreatorHeader({super.key, required this.initialHabit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTheme = ref.watch(themeProvider).activeTheme;
    final formState = ref.watch(habitCreatorFormProvider(initialHabit));
    final activeColor = resolveHabitCreatorAccent(context, formState);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 14.w, 10.h),
      child: Row(
        children: [
          // Visual Avatar Preview
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: AppColors.pastelSurface(
                activeColor,
                isDark: context.isDarkMode,
                opacity: 0.22,
              ),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: activeColor.withValues(alpha: 0.6),
                width: AppSizes.borderWidthFocused,
              ),
            ),
            child: Center(
              child: formState.isEmojiSelected
                  ? Text(
                      formState.selectedEmoji,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontSize: AppFontSizes.headlineLarge,
                      ),
                    )
                  : Icon(
                      HabitIconRegistry.getIcon(formState.selectedIconCode) ??
                          Icons.star_rounded,
                      color: activeColor,
                      size: AppIconSizes.xl,
                    ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  initialHabit != null ? 'Edit Habit' : 'New Habit',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontFamily: activeTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Configure identity, frequency & alarms',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: Icons.close_rounded,
            onPressed: () => Navigator.of(context).pop(),
            color: context.textMutedColor,
            iconSize: AppIconSizes.lg,
            size: AppSizes.minTapTarget,
            backgroundColor: AppColors.transparent,
            border: false,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}
