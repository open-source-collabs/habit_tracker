import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_font_sizes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../presentation/widgets/heatmap_grid.dart';
import '../../../habits/presentation/providers/habit_provider.dart';

/// Comprehensive Analytics tab view featuring the 30/60/90-day consistency
/// heatmap, completion ratios, streak metrics, and routine group insights.
class AnalyticsTabView extends ConsumerWidget {
  const AnalyticsTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitListProvider).valueOrNull ?? [];
    final stats = ref.watch(dailyHabitStatsProvider);
    final primaryAccent = context.primaryAccent;
    final secondaryAccent = context.secondaryAccent;
    final isDesktop = context.isDesktop;

    // Aggregate check-ins across all habits
    final combinedCheckIns = <String, bool>{};
    for (final habit in habits) {
      for (final entry in habit.checkIns.entries) {
        if (entry.value) {
          combinedCheckIns[entry.key] = true;
        }
      }
    }

    // Rate for the selected day: completed out of the active habits actually
    // scheduled that day (see dailyHabitStatsProvider).
    final completionPct = (stats.completionRate * 100).round();
    final selectedDate = ref.watch(selectedDateProvider);
    final now = DateTime.now();
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24.w : 16.w,
        vertical: 10.h,
      ),
      children: [
        // Header
        Text(
          'ANALYTICS & INSIGHTS',
          style: context.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: AppFontSizes.labelSmall,
            color: context.textMutedColor,
          ),
        ),
        SizedBox(height: 8.h),

        // High-level Metrics Row
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: isToday ? 'TODAY RATE' : 'DAY RATE',
                value: '$completionPct%',
                subtitle:
                    '${stats.completedCount}/${stats.totalScheduled} done',
                accentColor: primaryAccent,
                icon: Icons.percent_rounded,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _MetricCard(
                title: 'MAX STREAK',
                value: '${stats.longestActiveStreak}d',
                subtitle: 'Active champion',
                accentColor: secondaryAccent,
                icon: Icons.local_fire_department_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        // Consistency Heatmap Card
        AppCard(
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: AppIconSizes.md,
                    color: primaryAccent,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Consistency Heatmap',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                      fontSize: AppFontSizes.titleSmall,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              HeatmapGrid(
                checkIns: combinedCheckIns,
                activeColor: primaryAccent,
                initialRangeDays: 60,
                showRangeSelector: true,
                showHeader: true,
                showWeekdayLabels: true,
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),

        // Habit performance summary
        AppCard(
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HABIT PERFORMANCE BREAKDOWN',
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  fontSize: AppFontSizes.labelSmall,
                  color: context.textMutedColor,
                ),
              ),
              SizedBox(height: 8.h),
              if (habits.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  child: Center(
                    child: Text(
                      'No habits created yet. Tap + to start tracking!',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.textMutedColor,
                      ),
                    ),
                  ),
                )
              else
                ...habits.map((habit) {
                  final completions = habit.checkIns.values
                      .where((v) => v)
                      .length;
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Row(
                      children: [
                        Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: BoxDecoration(
                            color: primaryAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            habit.title,
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.textPrimaryColor,
                              fontSize: AppFontSizes.caption,
                            ),
                          ),
                        ),
                        Text(
                          '$completions check-ins',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.textMutedColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),

        // Safe spacing for floating navbar
        SizedBox(height: 100.h),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  fontSize: AppFontSizes.micro,
                  color: context.textMutedColor,
                ),
              ),
              Icon(icon, size: AppIconSizes.sm, color: accentColor),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: AppFontSizes.headlineMedium,
              color: context.textPrimaryColor,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.textMutedColor,
              fontSize: AppFontSizes.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
