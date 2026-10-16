import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_font_sizes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../habits/presentation/providers/habit_provider.dart';

/// Placeholder card shown when the selected routine filter has no habits.
class DashboardEmptyState extends StatelessWidget {
  final String activeFilter;

  const DashboardEmptyState({super.key, required this.activeFilter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(32.r),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: context.cardBorderColor,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              '🎯',
              style: context.textTheme.displayLarge?.copyWith(
                fontSize: AppFontSizes.displayLarge,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              activeFilter == kArchivedHabitsFilter
                  ? 'No archived habits'
                  : 'No habits in this routine',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
