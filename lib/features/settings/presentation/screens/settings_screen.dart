import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_links.dart';
import '../../../../core/data/app_data_repository.dart';
import '../../../../core/routes/app_navigator.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_error_log.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../notifications/presentation/widgets/notification_settings_card.dart';
import '../providers/profile_provider.dart';
import '../widgets/about_links.dart';
import '../widgets/data_management_actions.dart';

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
                icon: Icons.archive_rounded,
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
              SizedBox(height: 10.h),
              _SettingsTile(
                icon: Icons.history_rounded,
                title: 'Restore from backup',
                subtitle:
                    'Go back to your latest save or how things looked on a '
                    'previous day.',
                onTap: () => showRestoreBackupSheet(context),
              ),
              SizedBox(height: 10.h),
              _SettingsTile(
                icon: Icons.delete_forever_rounded,
                iconColor: context.colorScheme.error,
                title: 'Delete all data',
                subtitle: 'Permanently remove everything from this device.',
                onTap: () => confirmAndDeleteAllData(context, ref),
              ),
              SizedBox(height: 20.h),
              const _SectionLabel('PRIVACY'),
              AppCard(
                padding: EdgeInsets.all(16.r),
                child: const _PrivacySummary(),
              ),
              SizedBox(height: 10.h),
              _SettingsTile(
                icon: Icons.policy_rounded,
                title: 'Privacy policy',
                subtitle: 'Exactly what is stored, where, and how to delete it.',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.privacyPolicy),
              ),
              SizedBox(height: 20.h),
              const _SectionLabel('ABOUT'),
              const _AboutSection(),
              SizedBox(height: 24.h),
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
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
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
            Icon(icon, color: iconColor ?? context.primaryAccent),
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
            Icon(Icons.lock_rounded, color: context.primaryAccent),
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

class _AboutSection extends ConsumerWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).valueOrNull ?? '';
    final storeListing = AppLinks.storeListing(defaultTargetPlatform);
    final feedback = AppLinks.feedbackEmail;

    final tiles = <Widget>[
      _SettingsTile(
        icon: Icons.info_rounded,
        title: 'Track Free',
        subtitle: version.isEmpty ? 'Habit tracker' : 'Version $version',
      ),
      if (storeListing != null)
        _SettingsTile(
          icon: Icons.star_rounded,
          title: 'Rate Track Free',
          subtitle: 'A quick review helps others find the app.',
          onTap: () => openExternalLink(context, storeListing),
        ),
      if (feedback != null)
        _SettingsTile(
          icon: Icons.mail_rounded,
          title: 'Send feedback',
          subtitle: 'Report a problem or suggest an idea.',
          onTap: () => openExternalLink(context, feedback),
        ),
      _SettingsTile(
        icon: Icons.bug_report_rounded,
        title: 'Copy diagnostics',
        subtitle: 'Recent errors on this device, to paste into a bug report. '
            'Contains no habit data.',
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          await Clipboard.setData(
            ClipboardData(text: AppErrorLog.export(appVersion: version)),
          );
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Diagnostics copied.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
      _SettingsTile(
        icon: Icons.description_rounded,
        title: 'Open-source licenses',
        subtitle: 'Fonts and libraries Track Free is built with.',
        onTap: () => showLicensePage(
          context: context,
          applicationName: 'Track Free',
          applicationVersion: version,
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) SizedBox(height: 10.h),
          tiles[i],
        ],
      ],
    );
  }
}
