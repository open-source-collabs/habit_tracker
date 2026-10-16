import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/data/app_data_repository.dart';
import '../../../../core/routes/app_navigator.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../notifications/presentation/widgets/notification_settings_card.dart';
import '../providers/profile_provider.dart';

/// App settings: profile, archived habits, data & backup, and privacy.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedCount = ref.watch(archivedHabitCountProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.textPrimaryColor,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.pageMaxWidth),
          child: ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              const _SectionLabel('PROFILE'),
              AppCard(
                padding: EdgeInsets.all(16.r),
                child: const _DisplayNameForm(),
              ),
              SizedBox(height: 20.h),
              const _SectionLabel('HABITS'),
              _SettingsTile(
                icon: Icons.archive_outlined,
                title: 'Archived habits',
                subtitle: archivedCount == 0
                    ? 'Archive a habit from its menu to pause it without '
                          'losing its history.'
                    : '$archivedCount paused, history kept',
                onTap: archivedCount == 0
                    ? null
                    : () {
                        ref.read(activeRoutineFilterProvider.notifier).state =
                            kArchivedHabitsFilter;
                        ref.read(selectedDashboardTabProvider.notifier).state =
                            0;
                        Navigator.of(context).pop();
                      },
              ),
              SizedBox(height: 20.h),
              const _SectionLabel('NOTIFICATIONS'),
              const NotificationSettingsCard(),
              SizedBox(height: 20.h),
              const _SectionLabel('DATA & BACKUP'),
              _SettingsTile(
                icon: Icons.import_export_rounded,
                title: 'Export, import & sync',
                subtitle:
                    'Copy your data as JSON, restore a backup, or merge '
                    'from another device.',
                onTap: () => AppNavigator.toDataPortability(context),
              ),
              SizedBox(height: 20.h),
              const _SectionLabel('PRIVACY'),
              AppCard(
                padding: EdgeInsets.all(16.r),
                child: const _PrivacySummary(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
      child: Text(
        text,
        style: context.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: context.textMutedColor,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: enabled,
      child: AppCard(
        isInteractive: enabled,
        onTap: onTap,
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            Icon(icon, color: context.primaryAccent),
            SizedBox(width: 14.w),
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
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled)
              Icon(Icons.chevron_right_rounded, color: context.textMutedColor),
          ],
        ),
      ),
    );
  }
}

class _DisplayNameForm extends ConsumerStatefulWidget {
  const _DisplayNameForm();

  @override
  ConsumerState<_DisplayNameForm> createState() => _DisplayNameFormState();
}

class _DisplayNameFormState extends ConsumerState<_DisplayNameForm> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(displayNameProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(displayNameProvider.notifier)
        .setDisplayName(_controller.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Name saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Keep the field in sync if the stored name loads after this opens.
    ref.listen(displayNameProvider, (previous, next) {
      if (_controller.text == (previous ?? '')) _controller.text = next;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _controller,
          labelText: 'Your name',
          hintText: 'Shown in the greeting',
          maxLength: DisplayNameNotifier.maxLength,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
        ),
        SizedBox(height: 12.h),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            text: 'Save',
            size: AppButtonSize.sm,
            onPressed: _save,
          ),
        ),
      ],
    );
  }
}

class _PrivacySummary extends ConsumerWidget {
  const _PrivacySummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bodyStyle = context.textTheme.bodyMedium?.copyWith(
      color: context.textSecondaryColor,
    );
    final deviceId = ref.watch(deviceIdProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: context.primaryAccent),
            SizedBox(width: 10.w),
            Text(
              'No account. No tracking.',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Text(
          'Your habits are stored on this device. Nothing is sent to us: '
          'there is no server and no analytics. Sync only ever uses your own '
          'iCloud or Google Drive.',
          style: bodyStyle,
        ),
        if (deviceId != null) ...[
          SizedBox(height: 12.h),
          Text(
            'This device: '
            '${deviceId.length > 8 ? deviceId.substring(0, 8) : deviceId}',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.textMutedColor,
            ),
          ),
        ],
      ],
    );
  }
}
