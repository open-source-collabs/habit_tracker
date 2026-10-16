import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';

import '../../../../core/theme/app_theme.dart';
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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Show the week containing the selected date.
    final monday =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

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
      padding: EdgeInsets.all(14.r.clamp(12.0, 18.0)),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20.r.clamp(16.0, 22.0)),
        border: Border.all(color: context.cardBorderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
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
                    fontSize: 16.sp.clamp(15.0, 18.0),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
              SizedBox(width: 8.w.clamp(6.0, 10.0)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w.clamp(6.0, 10.0),
                  vertical: 3.h.clamp(2.0, 5.0),
                ),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? context.surfaceElevatedColor
                      : context.cardBorderColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  'Avg. $avgPercent%',
                  style: context.textTheme.labelSmall?.copyWith(
                    fontSize: 10.sp.clamp(9.0, 11.0),
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h.clamp(8.0, 14.0)),

          // Bar Chart
          SizedBox(
            height: 78.h.clamp(70.0, 86.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekData.map((bar) {
                final heightFactor = (bar.rate.clamp(0.15, 1.0));
                final isHighlight = bar.isToday || bar.isSelected;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isHighlight) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w.clamp(3.0, 7.0),
                            vertical: 1.5.h.clamp(1.0, 3.0),
                          ),
                          decoration: BoxDecoration(
                            color: primaryAccent,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '${(bar.rate * 100).round()}%',
                            style: context.textTheme.labelSmall?.copyWith(
                              fontSize: 8.5.sp.clamp(7.5, 10.0),
                              fontWeight: FontWeight.w800,
                              color: context.onPrimaryColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 3.h.clamp(2.0, 4.0)),
                      ],
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        width: 22.w.clamp(16.0, 26.0),
                        height: (44.h * heightFactor).clamp(12.0, 50.0),
                        decoration: BoxDecoration(
                          color: isHighlight
                              ? primaryAccent
                              : (context.isDarkMode
                                    ? context.surfaceElevatedColor
                                    : context.cardBorderColor.withValues(
                                        alpha: 0.7,
                                      )),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      SizedBox(height: 4.h.clamp(2.0, 6.0)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w.clamp(2.0, 6.0),
                          vertical: 1.5.h.clamp(1.0, 3.0),
                        ),
                        decoration: BoxDecoration(
                          color: isHighlight
                              ? primaryAccent.withValues(alpha: 0.15)
                              : AppColors.transparent,
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        child: Text(
                          bar.label,
                          style: context.textTheme.labelSmall?.copyWith(
                            fontSize: 10.sp.clamp(8.5, 11.0),
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
