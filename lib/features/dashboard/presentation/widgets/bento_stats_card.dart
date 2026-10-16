import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_font_sizes.dart';
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
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(18.r),
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
                    fontSize: AppFontSizes.micro,
                    color: context.textMutedColor,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '${stats.completedCount}/${stats.totalScheduled} Complete',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: AppFontSizes.labelSmall,
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: LinearProgressIndicator(
              value: stats.totalScheduled > 0 ? stats.completionRate : 0.0,
              minHeight: 6.w,
              backgroundColor: context.cardBorderColor.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
            ),
          ),
          if (stats.longestActiveStreak > 0) ...[
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: AppIconSizes.xs,
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
                      fontSize: AppFontSizes.micro,
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
