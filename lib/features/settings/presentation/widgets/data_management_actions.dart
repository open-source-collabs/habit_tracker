import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../onboarding/presentation/onboarding_gate.dart';
import '../providers/data_management_provider.dart';

/// Lets the user pick one of the on-device rolling backups and restore it.
Future<void> showRestoreBackupSheet(BuildContext context) {
  return showAppBottomSheet<void>(
    context: context,
    builder: (_) => const AppBottomSheet(
      title: 'Restore from backup',
      subtitle: 'Backups are kept automatically on this device.',
      child: _BackupList(),
    ),
  );
}

/// Asks for confirmation, then wipes all local data.
Future<void> confirmAndDeleteAllData(BuildContext context, WidgetRef ref) async {
  final confirmed = await showAppConfirmDialog(
    context: context,
    title: 'Delete all data?',
    message: 'This permanently removes every habit, its history, your custom '
        'themes and the on-device backups, and cancels all reminders. '
        'Copies in your iCloud or Google Drive are not touched — turn off '
        'sync first if you don\'t want them to come back.',
    confirmText: 'Delete everything',
    isDestructive: true,
  );
  if (!confirmed || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(dataManagementProvider).deleteAllData();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('All data deleted from this device.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Starting over: offer the first-run setup again.
    await showOnboardingIfNeeded(ref);
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text("Couldn't delete your data. Please try again."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _BackupList extends ConsumerWidget {
  const _BackupList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backups = ref.watch(availableBackupsProvider);

    return backups.when(
      loading: () => Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const _Message(
        "Backups couldn't be read on this device.",
      ),
      data: (entries) => entries.isEmpty
          ? const _Message(
              'No backups yet. One is made automatically each time you '
              'change something.',
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in entries)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: _BackupTile(entry: entry),
                  ),
              ],
            ),
    );
  }
}

class _BackupTile extends ConsumerWidget {
  final BackupEntry entry;

  const _BackupTile({required this.entry});

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Restore "${entry.label}"?',
      message: 'Your current habits, history and themes on this device are '
          'replaced with this backup.',
      confirmText: 'Restore',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var restored = false;
    try {
      restored = await ref.read(dataManagementProvider).restoreBackup(
            entry.name,
          );
    } catch (_) {
      restored = false;
    }
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          restored
              ? 'Restored "${entry.label}".'
              : "Couldn't restore that backup.",
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      child: AppCard(
        isInteractive: true,
        onTap: () => _restore(context, ref),
        padding: EdgeInsets.all(14.r),
        child: Row(
          children: [
            Icon(Icons.history_rounded, color: context.primaryAccent),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  if (entry.description.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      entry.description,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.restore_rounded, color: context.textMutedColor),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;

  const _Message(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Text(
        text,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.textSecondaryColor,
        ),
      ),
    );
  }
}
