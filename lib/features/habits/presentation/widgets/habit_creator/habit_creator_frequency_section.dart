import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/haptics.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../data/models/habit_model.dart';
import '../../providers/habit_creator_form_provider.dart';
import 'habit_creator_accent.dart';

/// Frequency mode selector (Every Day / Specific Days / Times per Week)
/// with the matching sub-configurator underneath.
class HabitCreatorFrequencySection extends ConsumerWidget {
  final HabitModel? initialHabit;

  const HabitCreatorFrequencySection({super.key, required this.initialHabit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(habitCreatorFormProvider(initialHabit));
    final formNotifier = ref.read(
      habitCreatorFormProvider(initialHabit).notifier,
    );
    final activeColor = resolveHabitCreatorAccent(context, formState);

    Widget pill(String title, HabitFrequencyType type) {
      return Expanded(
        child: _FrequencyModePill(
          title: title,
          isSelected: formState.frequencyType == type,
          activeColor: activeColor,
          onTap: () {
            AppHaptics.selectionClick();
            formNotifier.setFrequencyType(type);
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FREQUENCY CONFIGURATOR',
          style: AppTextStyles.labelSmall(context),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            pill('Every Day', HabitFrequencyType.daily),
            SizedBox(width: 8.w),
            pill('Specific Days', HabitFrequencyType.specificWeekdays),
            SizedBox(width: 8.w),
            pill('Times / Week', HabitFrequencyType.timesPerWeek),
          ],
        ),
        SizedBox(height: 12.h),
        if (formState.frequencyType == HabitFrequencyType.specificWeekdays)
          _WeekdaysSelector(
            selectedDays: formState.selectedDaysOfWeek,
            activeColor: activeColor,
            notifier: formNotifier,
          )
        else if (formState.frequencyType == HabitFrequencyType.timesPerWeek)
          _TimesPerWeekStepper(
            target: formState.targetTimesPerWeek,
            activeColor: activeColor,
            notifier: formNotifier,
          ),
      ],
    );
  }
}

class _FrequencyModePill extends StatelessWidget {
  final String title;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _FrequencyModePill({
    required this.title,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.pastelSurface(
                  activeColor,
                  isDark: context.isDarkMode,
                  opacity: 0.22,
                )
              : context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? activeColor : context.cardBorderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                title,
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : context.textSecondaryColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdaysSelector extends StatelessWidget {
  final List<int> selectedDays;
  final Color activeColor;
  final HabitCreatorFormNotifier notifier;

  const _WeekdaysSelector({
    required this.selectedDays,
    required this.activeColor,
    required this.notifier,
  });

  static const List<(int, String)> _dayLabels = [
    (1, 'Mon'),
    (2, 'Tue'),
    (3, 'Wed'),
    (4, 'Thu'),
    (5, 'Fri'),
    (6, 'Sat'),
    (7, 'Sun'),
  ];

  @override
  Widget build(BuildContext context) {
    final presetStyle = context.textTheme.labelSmall?.copyWith(
      color: activeColor,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select active days:',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.textMutedColor,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    AppHaptics.selectionClick();
                    notifier.setSelectedDaysOfWeek([1, 2, 3, 4, 5]);
                  },
                  child: Text('Weekdays', style: presetStyle),
                ),
                SizedBox(width: 10.w),
                GestureDetector(
                  onTap: () {
                    AppHaptics.selectionClick();
                    notifier.setSelectedDaysOfWeek([6, 7]);
                  },
                  child: Text('Weekends', style: presetStyle),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: _dayLabels.map((d) {
            final (val, name) = d;
            final isDaySelected = selectedDays.contains(val);

            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: GestureDetector(
                  onTap: () {
                    AppHaptics.selectionClick();
                    notifier.toggleDayOfWeek(val);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isDaySelected
                          ? activeColor
                          : context.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isDaySelected
                            ? activeColor
                            : context.cardBorderColor,
                        width: AppSizes.borderWidth,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        name,
                        style: context.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDaySelected
                              ? habitCreatorOnColor(activeColor)
                              : context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TimesPerWeekStepper extends StatelessWidget {
  final int target;
  final Color activeColor;
  final HabitCreatorFormNotifier notifier;

  const _TimesPerWeekStepper({
    required this.target,
    required this.activeColor,
    required this.notifier,
  });

  Widget _stepButton(
    BuildContext context, {
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    // AppIconButton fires its own selection haptic on tap.
    return AppIconButton(
      icon: icon,
      onPressed: enabled ? onPressed : null,
      color: enabled
          ? activeColor
          : context.textMutedColor.withValues(alpha: 0.38),
      iconSize: AppIconSizes.xl,
      size: AppSizes.minTapTarget,
      backgroundColor: AppColors.transparent,
      border: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: context.cardBorderColor,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Target frequency:',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              _stepButton(
                context,
                icon: Icons.remove_circle_rounded,
                enabled: target > 1,
                onPressed: notifier.decrementTargetTimesPerWeek,
              ),
              Container(
                constraints: BoxConstraints(minWidth: 44.w),
                child: Center(
                  child: Text(
                    '$target × / wk',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: activeColor,
                    ),
                  ),
                ),
              ),
              _stepButton(
                context,
                icon: Icons.add_circle_rounded,
                enabled: target < 6,
                onPressed: notifier.incrementTargetTimesPerWeek,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
