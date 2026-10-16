import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final isDesktop = MediaQuery.of(context).size.width >= 768.0;

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
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24.0 : 16.w.clamp(14.0, 20.0),
        vertical: 10.h,
      ),
      children: [
        // Header
        Text(
          'ANALYTICS & INSIGHTS',
          style: context.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 11.sp.clamp(10.0, 12.0),
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
            SizedBox(width: 10.w.clamp(8.0, 14.0)),
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
          padding: EdgeInsets.all(14.r.clamp(12.0, 18.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 18.sp.clamp(16.0, 20.0),
                    color: primaryAccent,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Consistency Heatmap',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                      fontSize: 14.sp.clamp(13.0, 16.0),
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
          padding: EdgeInsets.all(14.r.clamp(12.0, 18.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HABIT PERFORMANCE BREAKDOWN',
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  fontSize: 11.sp.clamp(10.0, 12.0),
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
                  final completions = habit.checkIns.values.where((v) => v).length;
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
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
                              fontSize: 13.sp.clamp(12.0, 14.0),
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
      padding: EdgeInsets.all(12.r.clamp(10.0, 16.0)),
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
                  fontSize: 10.sp.clamp(9.0, 11.0),
                  color: context.textMutedColor,
                ),
              ),
              Icon(
                icon,
                size: 16.sp.clamp(14.0, 18.0),
                color: accentColor,
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 20.sp.clamp(16.0, 24.0),
              color: context.textPrimaryColor,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.textMutedColor,
              fontSize: 11.sp.clamp(10.0, 12.0),
            ),
          ),
        ],
      ),
    );
  }
}
