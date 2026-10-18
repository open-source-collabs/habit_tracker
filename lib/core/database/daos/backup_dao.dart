import 'package:sqflite/sqflite.dart';

import '../../../features/themes/data/models/app_payload_model.dart';
import '../database_schema.dart';

/// Data Access Object for rolling backup snapshots in SQLite.
class BackupDao {
  static const String backup1FileName = 'backup_1.json';
  static const String backup2FileName = 'backup_2.json';
  static const String backup3FileName = 'backup_3.json';

  const BackupDao();

  /// Rotates backups (1 -> 2, 2 -> 3) and stores the current [payload] as backup 1.
  Future<void> rotateAndSaveBackup(
    DatabaseExecutor executor,
    AppPayloadModel payload,
  ) async {
    final now = DateTime.now().toIso8601String();

    // Check existing backups
    final b2 = await _getBackupRecord(executor, backup2FileName);
    if (b2 != null) {
      await executor.insert(
        DatabaseSchema.tableBackups,
        {
          DatabaseSchema.colBackupName: backup3FileName,
          DatabaseSchema.colBackupPayloadJson: b2,
          DatabaseSchema.colBackupCreatedAt: now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final b1 = await _getBackupRecord(executor, backup1FileName);
    if (b1 != null) {
      await executor.insert(
        DatabaseSchema.tableBackups,
        {
          DatabaseSchema.colBackupName: backup2FileName,
          DatabaseSchema.colBackupPayloadJson: b1,
          DatabaseSchema.colBackupCreatedAt: now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final jsonString = payload.toRawJson(pretty: true);
    await executor.insert(
      DatabaseSchema.tableBackups,
      {
        DatabaseSchema.colBackupName: backup1FileName,
        DatabaseSchema.colBackupPayloadJson: jsonString,
        DatabaseSchema.colBackupCreatedAt: now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> _getBackupRecord(
    DatabaseExecutor executor,
    String name,
  ) async {
    final rows = await executor.query(
      DatabaseSchema.tableBackups,
      where: '${DatabaseSchema.colBackupName} = ?',
      whereArgs: [name],
    );
    if (rows.isEmpty) return null;
    return rows.first[DatabaseSchema.colBackupPayloadJson] as String?;
  }

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
