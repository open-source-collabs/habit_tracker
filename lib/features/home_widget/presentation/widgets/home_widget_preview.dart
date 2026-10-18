import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_font_sizes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../habits/presentation/providers/habit_provider.dart';

/// In-app replica of the Android "Today's progress" widget, filled with the
/// user's real numbers for today, so they see exactly what they'll get.
class HomeWidgetPreview extends ConsumerWidget {
  const HomeWidgetPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(currentDayProvider);
    final habits = ref.watch(habitListProvider).valueOrNull ?? const [];
    final scheduled = habits
        .where((h) => !h.isArchived && h.frequency.isScheduledFor(today))
        .toList();
    final done = scheduled.where((h) => h.isCompletedOn(today)).length;
    final total = scheduled.length;
    final ratio = total == 0 ? 0.0 : done / total;
    var streak = 0;
    for (final h in habits.where((h) => !h.isArchived)) {
      final s = h.calculateCurrentStreak(asOf: today);
      if (s > streak) streak = s;
    }
    final next = scheduled.where((h) => !h.isCompletedOn(today)).firstOrNull;
    final footer = total == 0
        ? 'No habits scheduled today'
        : next == null
            ? 'All done today! 🎉'
            : 'Next: ${next.emoji ?? ''} ${next.title}'.replaceAll('  ', ' ');

    final secondary = context.textTheme.bodySmall?.copyWith(
      color: context.textSecondaryColor,
    );

    return Semantics(
      label: 'Widget preview: $done of $total habits done today',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
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
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Image.asset(AppAssets.appLogo, width: 20.r, height: 20.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Today',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
                Text(AppDateFormat.shortDay(today), style: secondary),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$done / $total',
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: context.textPrimaryColor,
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(child: Text('done', style: secondary)),
                Text(
                  '${(ratio * 100).round()}%',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.primaryAccent,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6.h,
                backgroundColor: context.cardBorderColor,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.brandGreen),
              ),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    footer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: secondary,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.pastelSurface(
                      AppColors.mangoSunrise,
                      isDark: context.isDarkMode,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '🔥 $streak',
                    style: context.textTheme.labelSmall?.copyWith(
                      fontSize: AppFontSizes.labelSmall,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
