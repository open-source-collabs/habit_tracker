import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_font_sizes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../settings/presentation/providers/profile_provider.dart';

/// App bar title: time-of-day greeting (personalised when a display name is
/// set) above today's long date.
class DashboardGreetingHeader extends ConsumerWidget {
  const DashboardGreetingHeader({super.key});

  static String _timeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(displayNameProvider);
    final greeting = displayName.isEmpty
        ? _timeOfDayGreeting()
        : '${_timeOfDayGreeting()}, $displayName';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: AppFontSizes.headlineMedium,
                  letterSpacing: -0.4,
                  color: context.textPrimaryColor,
                ),
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              '👋',
              style: context.textTheme.titleLarge?.copyWith(
                fontSize: AppFontSizes.titleLarge,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          AppDateFormat.longDay(DateTime.now()),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: AppFontSizes.labelMedium,
            color: context.textMutedColor,
          ),
        ),
      ],
    );
  }
}
