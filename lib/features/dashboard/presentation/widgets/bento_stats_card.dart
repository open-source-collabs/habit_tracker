import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../habits/presentation/providers/habit_provider.dart';

/// Bento Stats Card showing daily completion progress, streaks, and completion rate.
class BentoStatsCard extends ConsumerWidget {
  const BentoStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dailyHabitStatsProvider);
    final primaryAccent = context.primaryAccent;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'PROGRESS OVERVIEW',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    fontSize: 11.sp.clamp(10.0, 13.0),
                    color: context.textMutedColor,
                  ),
                ),
              ),
              SizedBox(width: 8.w.clamp(4.0, 10.0)),
              Text(
                '${stats.completedCount}/${stats.totalScheduled} Complete',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp.clamp(11.0, 14.0),
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: stats.totalScheduled > 0 ? stats.completionRate : 0.0,
              minHeight: 8.h.clamp(6.0, 10.0),
              backgroundColor: context.cardBorderColor.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
            ),
          ),
          if (stats.longestActiveStreak > 0) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 15.sp,
                  color: primaryAccent,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    'Best streak: ${stats.longestActiveStreak} days in a row',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11.sp,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
