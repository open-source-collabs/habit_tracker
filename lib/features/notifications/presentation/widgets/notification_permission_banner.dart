import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/notification_provider.dart';

/// Bento banner indicating notification permission health and providing 1-tap activation.
class NotificationPermissionBanner extends ConsumerWidget {
  const NotificationPermissionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(notificationPermissionStatusProvider);
    final isGranted = permissionAsync.value ?? true;

    final primaryAccent = context.primaryAccent;
    final cardBg = context.cardBackgroundColor;
    final border = context.cardBorderColor;
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;

    if (isGranted) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14.w.clamp(12.0, 16.0),
          vertical: 10.h.clamp(8.0, 12.0),
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16.r.clamp(12.0, 18.0)),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: primaryAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: primaryAccent,
                size: 16.sp.clamp(14.0, 18.0),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Alarms & notifications active on this device',
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp.clamp(11.0, 13.0),
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.r.clamp(14.0, 18.0)),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.r.clamp(16.0, 22.0)),
        border: Border.all(
          color: primaryAccent.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryAccent.withValues(alpha: 0.12),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: primaryAccent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: primaryAccent,
                  size: 20.sp.clamp(18.0, 22.0),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications Are Disabled',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.sp.clamp(14.0, 17.0),
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Enable notifications to receive daily habit alarms and keep your streak safe.',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 12.sp.clamp(11.0, 13.0),
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          AppButton(
            text: 'Enable Notifications',
            leadingIcon: const Icon(Icons.lock_open_rounded),
            variant: AppButtonVariant.primary,
            size: AppButtonSize.sm,
            glow: true,
            onPressed: () {
              ref.read(notificationSettingsProvider.notifier).requestPermission();
            },
          ),
        ],
      ),
    );
  }
}
