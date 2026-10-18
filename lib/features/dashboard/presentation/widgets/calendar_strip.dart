import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_font_sizes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/calendar_days.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/haptics.dart';
import '../../../habits/presentation/providers/habit_provider.dart';

/// 7-day horizontal interactive calendar strip (the past week through today).
class CalendarStrip extends ConsumerWidget {
  final VoidCallback? onAddTap;

  const CalendarStrip({super.key, this.onAddTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final primaryAccent = context.primaryAccent;

    final today = ref.watch(currentDayProvider);

    // The 7 days ending today. Future dates are never offered because they
    // can't be checked off.
    final days = List.generate(7, (i) {
      return CalendarDays.addDays(today, i - 6);
    });

    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: context.cardBorderColor,
          width: AppSizes.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ...days.map((date) {
            final isSelected =
                date.year == selectedDate.year &&
                date.month == selectedDate.month &&
                date.day == selectedDate.day;
            final isToday =
                date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final label = dayLabels[(date.weekday - 1).clamp(0, 6)];

            return Expanded(
              child: Semantics(
                button: true,
                selected: isSelected,
                label:
                    '${AppDateFormat.longDay(date)}${isToday ? ', today' : ''}',
                excludeSemantics: true,
                child: GestureDetector(
                  // The whole column slot is tappable, not just the pill.
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    AppHaptics.selectionClick();
                    ref.read(selectedDateProvider.notifier).state = date;
                  },
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: 34.w,
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryAccent
                            : (isToday
                                  ? primaryAccent.withValues(alpha: 0.12)
                                  : AppColors.transparent),
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        border: isToday && !isSelected
                            ? Border.all(
                                color: primaryAccent.withValues(alpha: 0.4),
                                width: AppSizes.borderWidth,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: context.textTheme.labelSmall?.copyWith(
                              fontSize: AppFontSizes.micro,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? context.onPrimaryColor
                                  : context.textMutedColor,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${date.day}',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontSize: AppFontSizes.caption,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? context.onPrimaryColor
                                  : context.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          if (onAddTap != null)
            Semantics(
              button: true,
              label: 'New habit',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  AppHaptics.lightImpact();
                  onAddTap!();
                },
                child: SizedBox(
                  width: AppSizes.minTapTarget,
                  height: AppSizes.minTapTarget,
                  child: Center(
                    child: Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: BoxDecoration(
                        color: primaryAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: primaryAccent,
                        size: AppIconSizes.md,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
