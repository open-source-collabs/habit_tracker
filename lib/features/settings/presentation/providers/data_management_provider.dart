import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/notification_service.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../themes/presentation/providers/theme_provider.dart';
import 'profile_provider.dart';

/// One restorable rolling backup, with a human-readable label.
class BackupEntry {
  final String name;
  final String label;
  final String description;

  const BackupEntry({
    required this.name,
    required this.label,
    required this.description,
  });
}

/// Restorable backups on this device, newest first.
final availableBackupsProvider =
    FutureProvider.autoDispose<List<BackupEntry>>((ref) async {
  final names = await ref.watch(appDataRepositoryProvider).listBackups();
  return [for (final name in names) DataManagement.describeBackup(name)];
});

final dataManagementProvider = Provider<DataManagement>(DataManagement.new);

/// Restore-from-backup and delete-everything actions for Settings.
class DataManagement {
  DataManagement(this._ref);

  final Ref _ref;

  static BackupEntry describeBackup(String name) => switch (name) {
        'backup_1.json' => BackupEntry(
            name: name,
            label: 'Latest save',
            description: 'Your data as of the most recent change.',
          ),
        'backup_2.json' => BackupEntry(
            name: name,
            label: 'Previous day',
            description: 'How your data looked at the end of the last day '
                'before today that you used the app.',
          ),
        'backup_3.json' => BackupEntry(
            name: name,
            label: 'Two days back',
            description: 'The day before that.',
          ),
        _ => BackupEntry(name: name, label: name, description: ''),
      };

  /// Replaces current data with backup [name]. Returns `false` when it no
  /// longer exists.
  Future<bool> restoreBackup(String name) async {
    final restored =
        await _ref.read(appDataRepositoryProvider).restoreBackup(name);
    if (restored) _reload();
    return restored;
  }

  /// Wipes habits, themes, profile and backups from this device and cancels
  /// every scheduled notification.
  Future<void> deleteAllData() async {
    await _ref.read(appDataRepositoryProvider).deleteAllData();
    await _ref.read(notificationServiceProvider).cancelAll();
    _reload();
  }

  void _reload() {
    _ref.invalidate(habitListProvider);
    _ref.invalidate(themeProvider);
    _ref.invalidate(displayNameProvider);
    _ref.invalidate(availableBackupsProvider);
    final habits =
        _ref.read(appDataRepositoryProvider).current?.habits ?? const [];
    unawaited(_ref.read(notificationServiceProvider).rescheduleAll(habits));
  }
}
