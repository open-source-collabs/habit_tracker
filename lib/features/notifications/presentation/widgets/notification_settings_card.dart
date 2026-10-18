import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/notification_provider.dart';
import 'notification_permission_banner.dart';

/// Settings card for on-device reminders: the global switch, permission
/// status, the two daily digests, and a delivery test.
class NotificationSettingsCard extends ConsumerWidget {
  const NotificationSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);
    final settings = settingsAsync.valueOrNull;
    final notifier = ref.read(notificationSettingsProvider.notifier);

    if (settings == null) {
      return AppCard(
        padding: EdgeInsets.all(16.r),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return AppCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SwitchRow(
            icon: Icons.notifications_active_rounded,
            title: 'Reminders',
            subtitle: 'Habit reminders and digests, scheduled on this device.',
            value: settings.masterEnabled,
            onChanged: (enabled) async {
              if (enabled) await notifier.requestPermission();
              await notifier.toggleMaster(enabled);
            },
          ),
          if (settings.masterEnabled) ...[
            SizedBox(height: 12.h),
            const NotificationPermissionBanner(),
            SizedBox(height: 12.h),
            _SwitchRow(
              icon: Icons.wb_sunny_rounded,
              title: 'Morning kickoff',
              subtitle: 'A nudge to plan the day',
              value: settings.morningKickoffEnabled,
              time: settings.morningTime,
              onChanged: (enabled) =>
                  notifier.updateMorningKickoff(enabled: enabled),
              onTimeChanged: (time) => notifier.updateMorningKickoff(time: time),
            ),
            SizedBox(height: 8.h),
            _SwitchRow(
              icon: Icons.nights_stay_rounded,
              title: 'Evening streak saver',
              subtitle: 'A reminder before the day ends',
              value: settings.eveningStreakSaverEnabled,
              time: settings.eveningTime,
              onChanged: (enabled) =>
                  notifier.updateEveningStreakSaver(enabled: enabled),
              onTimeChanged: (time) =>
                  notifier.updateEveningStreakSaver(time: time),
            ),
            SizedBox(height: 8.h),
            _SwitchRow(
              icon: Icons.volume_up_rounded,
              title: 'Sound',
              subtitle: 'Play a sound with reminders',
              value: settings.soundEnabled,
              onChanged: notifier.toggleSound,
            ),
            SizedBox(height: 12.h),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                text: 'Check that reminders reach you',
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                leadingIcon: Icon(Icons.send_rounded, size: AppIconSizes.sm),
                onPressed: notifier.sendTestNotification,
              ),
            ),
          ],
          SizedBox(height: 8.h),
          _SwitchRow(
            icon: Icons.vibration_rounded,
            title: 'Haptic feedback',
            subtitle: 'Subtle vibrations when you tap and check off',
            value: settings.hapticsEnabled,
            onChanged: notifier.toggleHaptics,
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay>? onTimeChanged;

  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.time,
    this.onTimeChanged,
  });

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: time ?? TimeOfDay.now(),
    );
    if (picked != null) onTimeChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: context.primaryAccent, size: AppIconSizes.lg),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
              ),
              Text(
                subtitle,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
        if (time != null && value)
          AppButton(
            text: time!.format(context),
            variant: AppButtonVariant.outline,
            size: AppButtonSize.sm,
            onPressed: () => _pickTime(context),
          ),
        Semantics(
          label: title,
          child: Switch.adaptive(
            value: value,
            activeTrackColor: context.primaryAccent,
            onChanged: (enabled) {
              AppHaptics.selectionClick();
              onChanged(enabled);
            },
          ),
        ),
      ],
    );
  }
}
