import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/services/notification_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/haptics.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../data/models/habit_model.dart';
import '../../providers/habit_creator_form_provider.dart';
import 'habit_creator_accent.dart';

/// Reminder alarm toggle and daily time picker.
class HabitCreatorReminderSection extends ConsumerWidget {
  final HabitModel? initialHabit;

  const HabitCreatorReminderSection({super.key, required this.initialHabit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(habitCreatorFormProvider(initialHabit));
    final formNotifier = ref.read(
      habitCreatorFormProvider(initialHabit).notifier,
    );
    final activeColor = resolveHabitCreatorAccent(context, formState);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.cardBorderColor,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    size: AppIconSizes.lg,
                    color: formState.reminderEnabled
                        ? activeColor
                        : context.textMutedColor,
                  ),
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reminder Alarm',
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      Text(
                        'Native offline notifications',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.textMutedColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AppSwitch(
                value: formState.reminderEnabled,
                activeColor: activeColor,
                semanticLabel: 'Reminder Alarm',
                onChanged: (val) {
                  formNotifier.setReminderEnabled(val);
                  // Ask at the moment it matters, not on first launch.
                  if (val) {
                    ref.read(notificationServiceProvider).requestPermission();
                  }
                },
              ),
            ],
          ),
          if (formState.reminderEnabled) ...[
            Divider(color: context.cardBorderColor, height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily alarm time:',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
                _ReminderTimeChip(
                  time: formState.reminderTime,
                  activeColor: activeColor,
                  onPicked: formNotifier.setReminderTime,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReminderTimeChip extends StatelessWidget {
  final TimeOfDay time;
  final Color activeColor;
  final ValueChanged<TimeOfDay> onPicked;

  const _ReminderTimeChip({
    required this.time,
    required this.activeColor,
    required this.onPicked,
  });

  Future<void> _pickTime(BuildContext context) async {
    AppHaptics.mediumImpact();
    final picked = await showTimePicker(
      context: context,
      initialTime: time,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: activeColor,
              onPrimary: AppColors.white,
              surface: context.cardBackgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickTime(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.pastelSurface(
            activeColor,
            isDark: context.isDarkMode,
            opacity: 0.22,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: activeColor, width: AppSizes.borderWidth),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: AppIconSizes.sm,
              color: activeColor,
            ),
            SizedBox(width: 6.w),
            Text(
              time.format(context),
              style: context.textTheme.labelLarge?.copyWith(
                color: activeColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
