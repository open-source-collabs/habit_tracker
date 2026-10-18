import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../../../features/notifications/data/models/notification_settings_model.dart';
import '../database_schema.dart';

/// Data Access Object for notification preferences and alert history.
class NotificationDao {
  const NotificationDao();

  /// Loads persisted settings or returns default configuration.
  Future<NotificationSettingsModel> loadSettings(DatabaseExecutor executor) async {
    final rows = await executor.query(
      DatabaseSchema.tableNotificationSettings,
      where: '${DatabaseSchema.colNotificationId} = 1',
    );

    if (rows.isNotEmpty) {
      final jsonStr =
          rows.first[DatabaseSchema.colNotificationSettingsJson] as String;
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      return NotificationSettingsModel.fromJson(decoded);
    }

    return const NotificationSettingsModel();
  }

  /// Persists updated [settings] asynchronously into SQLite.
  Future<void> saveSettings(
    DatabaseExecutor executor,
    NotificationSettingsModel settings,
  ) async {
    final jsonStr = json.encode(settings.toJson());
    await executor.insert(
      DatabaseSchema.tableNotificationSettings,
      {
        DatabaseSchema.colNotificationId: 1,
        DatabaseSchema.colNotificationSettingsJson: jsonStr,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Clears stored notification settings.
  Future<void> clear(DatabaseExecutor executor) async {
    await executor.delete(DatabaseSchema.tableNotificationSettings);
  }
}
