import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/home_widget_provider.dart';
import 'add_home_widget_action.dart';

/// One-time dashboard suggestion to add the home-screen widget. Hides itself
/// unless [showHomeWidgetTipProvider] says it's relevant; gone for good after
/// "Add" or ✕.
class HomeWidgetTipCard extends ConsumerWidget {
  const HomeWidgetTipCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(showHomeWidgetTipProvider)) return const SizedBox.shrink();
    final accent = context.primaryAccent;
    final dismissed = ref.read(homeWidgetTipDismissedProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: AppCard(
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 4.w, 12.h),
        backgroundColor: AppColors.pastelSurface(
          accent,
          isDark: context.isDarkMode,
        ),
        borderColor: accent.withValues(alpha: 0.35),
        child: Row(
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.widgets_rounded,
                size: AppIconSizes.lg,
                color: accent,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add a home screen widget',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "Today's progress, one glance away.",
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            AppButton(
              text: 'Add',
              size: AppButtonSize.sm,
              onPressed: () async {
                await dismissed.dismiss();
                if (context.mounted) await addHomeWidget(context, ref);
              },
            ),
            AppIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Dismiss',
              size: 32.r,
              iconSize: AppIconSizes.sm,
              border: false,
              backgroundColor: AppColors.transparent,
              color: context.textMutedColor,
              onPressed: dismissed.dismiss,
            ),
          ],
        ),
      ),
    );
  }
}
