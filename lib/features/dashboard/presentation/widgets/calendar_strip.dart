import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../habits/presentation/providers/habit_provider.dart';

/// 7-day horizontal interactive calendar strip inspired by Reference Image 1 & 2.
class CalendarStrip extends ConsumerWidget {
  final VoidCallback? onAddTap;

  const CalendarStrip({super.key, this.onAddTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final primaryAccent = context.primaryAccent;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Compute the 7-day window centered or ending on today
    final days = List.generate(7, (i) {
      return today.subtract(Duration(days: 3 - i));
    });

    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w.clamp(12.0, 18.0),
        vertical: 14.h.clamp(10.0, 16.0),
      ),
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

            return GestureDetector(
              onTap: () {
                AppHaptics.selectionClick();
                ref.read(selectedDateProvider.notifier).state = date;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 38.w.clamp(32.0, 42.0),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryAccent
                      : (isToday
                            ? primaryAccent.withValues(alpha: 0.12)
                            : AppColors.transparent),
                  borderRadius: BorderRadius.circular(16.r),
                  border: isToday && !isSelected
                      ? Border.all(
                          color: primaryAccent.withValues(alpha: 0.4),
                          width: 1.2,
                        )
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: context.textTheme.labelSmall?.copyWith(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? context.onPrimaryColor
                            : context.textMutedColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${date.day}',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontSize: 14.sp,
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
            );
          }),
          if (onAddTap != null)
            GestureDetector(
              onTap: () {
                AppHaptics.lightImpact();
                onAddTap!();
              },
              child: Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: primaryAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: primaryAccent,
                  size: 20.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
