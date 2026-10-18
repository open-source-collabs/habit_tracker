import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_font_sizes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/calendar_days.dart';
import '../../../habits/presentation/providers/habit_provider.dart';

/// "Consistency score" weekly bar chart directly inspired by Reference Image 1.
class ConsistencyChart extends ConsumerWidget {
  const ConsistencyChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryAccent = context.primaryAccent;

    final habits = ref.watch(habitListProvider).valueOrNull ?? const [];
    final selectedDate = ref.watch(selectedDateProvider);

    // Monday-start, matching the weekly streak logic in HabitModel.
    const weekLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final today = ref.watch(currentDayProvider);
    // Show the week containing the selected date.
    final monday = CalendarDays.mondayOf(selectedDate);

    final weekData = List.generate(7, (i) {
      final day = DateTime(monday.year, monday.month, monday.day + i);
      final scheduled = habits
          .where((h) => !h.isArchived && h.frequency.isScheduledFor(day))
          .toList();
      final done = scheduled.where((h) => h.isCompletedOn(day)).length;
      final rate = scheduled.isNotEmpty ? done / scheduled.length : 0.0;
      return (
        date: day,
        label: weekLabels[i],
        rate: rate,
        isToday:
            day.year == today.year &&
            day.month == today.month &&
            day.day == today.day,
        isSelected:
            day.year == selectedDate.year &&
            day.month == selectedDate.month &&
            day.day == selectedDate.day,
      );
    });

    // Future days haven't happened yet, so they don't count against the score.
    final elapsedDays = weekData.where((e) => !e.date.isAfter(today));
    final avgRate = elapsedDays.isEmpty
        ? 0.0
        : elapsedDays.map((e) => e.rate).reduce((a, b) => a + b) /
              elapsedDays.length;
    final avgPercent = (avgRate * 100).round();

    return Container(
      padding: EdgeInsets.all(14.r),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Consistency score',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontSize: AppFontSizes.titleMedium,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? context.surfaceElevatedColor
                      : context.cardBorderColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  'Avg. $avgPercent%',
                  style: context.textTheme.labelSmall?.copyWith(
                    fontSize: AppFontSizes.micro,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Bar Chart: grows with large text instead of overflowing.
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: 78.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekData.map((bar) {
                final heightFactor = (bar.rate.clamp(0.15, 1.0));
                final isHighlight = bar.isToday || bar.isSelected;

                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isHighlight) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 1.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: primaryAccent,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            '${(bar.rate * 100).round()}%',
                            style: context.textTheme.labelSmall?.copyWith(
                              fontSize: AppFontSizes.nano,
                              fontWeight: FontWeight.w800,
                              color: context.onPrimaryColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 3.h),
                      ],
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        width: 22.w,
                        height: math.max(12.w, 44.w * heightFactor),
                        decoration: BoxDecoration(
                          color: isHighlight
                              ? primaryAccent
                              : (context.isDarkMode
                                    ? context.surfaceElevatedColor
                                    : context.cardBorderColor.withValues(
                                        alpha: 0.7,
                                      )),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: isHighlight
                              ? primaryAccent.withValues(alpha: 0.15)
                              : AppColors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          bar.label,
                          style: context.textTheme.labelSmall?.copyWith(
                            fontSize: AppFontSizes.micro,
                            fontWeight: isHighlight
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isHighlight
                                ? primaryAccent
                                : context.textMutedColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
