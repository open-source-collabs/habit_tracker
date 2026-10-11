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

    final habits = ref.watch(habitListProvider).value ?? const [];
    final selectedDate = ref.watch(selectedDateProvider);

    const weekLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thr', 'Fri', 'Sat'];

    // Calculate completions for the current week (Sun..Sat)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Sunday of the week
    final sunday = today.subtract(Duration(days: today.weekday % 7));

    final weekData = List.generate(7, (i) {
      final day = sunday.add(Duration(days: i));
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

    final avgRate = weekData.map((e) => e.rate).reduce((a, b) => a + b) / 7;
    final avgPercent = (avgRate * 100).round();

    return Container(
      padding: EdgeInsets.all(20.r.clamp(16.0, 24.0)),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(24.r.clamp(16.0, 24.0)),
        border: Border.all(color: context.cardBorderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 10.r,
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
                    fontSize: 18.sp.clamp(16.0, 20.0),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
              SizedBox(width: 8.w.clamp(6.0, 10.0)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w.clamp(8.0, 12.0),
                  vertical: 4.h.clamp(3.0, 6.0),
                ),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? context.surfaceElevatedColor
                      : context.cardBorderColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Avg. $avgPercent%',
                  style: context.textTheme.labelSmall?.copyWith(
                    fontSize: 11.sp.clamp(10.0, 12.0),
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h.clamp(16.0, 28.0)),

          // Bar Chart
          SizedBox(
            height: 120.h.clamp(100.0, 130.0),
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
                            horizontal: 6.w.clamp(4.0, 8.0),
                            vertical: 2.h.clamp(2.0, 4.0),
                          ),
                          decoration: BoxDecoration(
                            color: primaryAccent,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '${(bar.rate * 100).round()}%',
                            style: TextStyle(
                              fontSize: 9.sp.clamp(8.0, 11.0),
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h.clamp(2.0, 6.0)),
                      ],
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        width: 28.w.clamp(18.0, 30.0),
                        height: (70.h * heightFactor).clamp(16.0, 90.0),
                        decoration: BoxDecoration(
                          color: isHighlight
                              ? primaryAccent
                              : (context.isDarkMode
                                    ? context.surfaceElevatedColor
                                    : context.cardBorderColor.withValues(
                                        alpha: 0.7,
                                      )),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      SizedBox(height: 8.h.clamp(4.0, 10.0)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w.clamp(2.0, 6.0),
                          vertical: 2.h.clamp(1.0, 4.0),
                        ),
                        decoration: BoxDecoration(
                          color: isHighlight
                              ? primaryAccent.withValues(alpha: 0.15)
                              : AppColors.transparent,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          bar.label,
                          style: context.textTheme.labelSmall?.copyWith(
                            fontSize: 11.sp.clamp(9.0, 12.0),
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
