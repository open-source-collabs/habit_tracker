import 'package:sqflite/sqflite.dart';

import '../../../features/themes/data/models/app_payload_model.dart';
import '../database_schema.dart';

/// Data Access Object for rolling backup snapshots in SQLite.
class BackupDao {
  static const String backup1FileName = 'backup_1.json';
  static const String backup2FileName = 'backup_2.json';
  static const String backup3FileName = 'backup_3.json';

  const BackupDao();

  /// Keeps `backup_1` as a copy of the latest save and `backup_2`/`backup_3`
  /// as the last state of the two previous days the app was used.
  ///
  /// Rotation happens only on the first save of a new day, so a burst of
  /// edits can't push yesterday's data out of the backups.
  Future<void> rotateAndSaveBackup(
    DatabaseExecutor executor,
    AppPayloadModel payload, {
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final latest = await _getBackupRow(executor, backup1FileName);
    final latestAt = _createdAt(latest);

    if (latest != null &&
        (latestAt == null || !_sameDay(latestAt, timestamp))) {
      final previous = await _getBackupRow(executor, backup2FileName);
      if (previous != null) {
        await _copyRow(executor, previous, backup3FileName);
      }
      await _copyRow(executor, latest, backup2FileName);
    }

    await executor.insert(DatabaseSchema.tableBackups, {
      DatabaseSchema.colBackupName: backup1FileName,
      DatabaseSchema.colBackupPayloadJson: payload.toRawJson(),
      DatabaseSchema.colBackupCreatedAt: timestamp.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static bool _sameDay(DateTime a, DateTime b) {
    final x = a.toLocal();
    final y = b.toLocal();
    return x.year == y.year && x.month == y.month && x.day == y.day;
  }

  static DateTime? _createdAt(Map<String, Object?>? row) => DateTime.tryParse(
    row?[DatabaseSchema.colBackupCreatedAt] as String? ?? '',
  );

  /// Copies [row] under [name], keeping its original creation time.
  Future<void> _copyRow(
    DatabaseExecutor executor,
    Map<String, Object?> row,
    String name,
  ) => executor.insert(DatabaseSchema.tableBackups, {
    DatabaseSchema.colBackupName: name,
    DatabaseSchema.colBackupPayloadJson:
        row[DatabaseSchema.colBackupPayloadJson],
    DatabaseSchema.colBackupCreatedAt: row[DatabaseSchema.colBackupCreatedAt],
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<Map<String, Object?>?> _getBackupRow(
    DatabaseExecutor executor,
    String name,
  ) async {
    final rows = await executor.query(
      DatabaseSchema.tableBackups,
      where: '${DatabaseSchema.colBackupName} = ?',
      whereArgs: [name],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<String?> _getBackupRecord(
    DatabaseExecutor executor,
    String name,
  ) async {
    final row = await _getBackupRow(executor, name);
    return row?[DatabaseSchema.colBackupPayloadJson] as String?;
  }

  /// When backup [name] was saved, or `null` if it doesn't exist.
  Future<DateTime?> backupCreatedAt(
    DatabaseExecutor executor,
    String name,
  ) async => _createdAt(await _getBackupRow(executor, name));

  /// Lists all available backup names.
  Future<List<String>> listBackups(DatabaseExecutor executor) async {
    final backupNames = [backup1FileName, backup2FileName, backup3FileName];
    final existing = <String>[];

    for (final name in backupNames) {
      final rows = await executor.query(
        DatabaseSchema.tableBackups,
        where: '${DatabaseSchema.colBackupName} = ?',
        whereArgs: [name],
      );
      if (rows.isNotEmpty) {
        existing.add(name);
      }
    }

    return existing;
  }

  /// Restores a backup payload by name.
  Future<AppPayloadModel?> restoreBackup(
    DatabaseExecutor executor,
    String backupName,
  ) async {
    final jsonStr = await _getBackupRecord(executor, backupName);
    if (jsonStr == null || jsonStr.trim().isEmpty) return null;
    return AppPayloadModel.fromRawJson(jsonStr);
  }

  /// Clears stored backups.
  Future<void> clear(DatabaseExecutor executor) async {
    await executor.delete(DatabaseSchema.tableBackups);
  }
}
