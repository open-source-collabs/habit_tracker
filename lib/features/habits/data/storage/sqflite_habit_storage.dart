import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_schema.dart';
import '../../../themes/data/models/app_payload_model.dart';
import '../../../themes/data/models/dynamic_theme_model.dart';
import 'habit_storage.dart';

/// Platform storage implementation backed by SQLite (`sqflite`).
///
/// Persists habits, check-ins, custom themes, deletion tombstones, and app metadata
/// in normalized SQL tables with foreign key cascades, WAL mode, and ACID transactions.
class SqfliteHabitStorage implements HabitStorage {
  final AppDatabase _database;
  final Future<File?> Function() _mirrorFileResolver;

  /// File name of the copy of the latest save kept outside the database, so
  /// data survives even if the database file itself is damaged.
  static const String mirrorFileName = 'track_free_latest_backup.json';

  /// [mirrorFile] overrides where that copy lives (tests); by default it goes
  /// in the app support directory. When no location is available, the copy
  /// is skipped.
  SqfliteHabitStorage({AppDatabase? database, File? mirrorFile})
    : _database = database ?? AppDatabase.instance,
      _mirrorFileResolver = mirrorFile != null
          ? (() async => mirrorFile)
          : (database == null ? _defaultMirrorFile : (() async => null));

  static Future<File?> _defaultMirrorFile() async {
    try {
      final dir = await getApplicationSupportDirectory();
      return File(p.join(dir.path, mirrorFileName));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AppPayloadModel?> loadPayload() async {
    try {
      return await _loadFromTables();
    } catch (e) {
      final recovered = await _loadNewestReadableBackup();
      if (recovered != null) {
        debugPrint(
          'SqfliteHabitStorage: recovered data from a backup '
          'after: $e',
        );
        return recovered;
      }
      throw CorruptPayloadException(e);
    }
  }

  Future<AppPayloadModel?> _loadFromTables() async {
    final db = await _database.database;
    final meta = await _database.metadataDao.getAllMetadata(db);
    final habits = await _database.habitDao.getAllHabits(db);

    if (meta.isEmpty && habits.isEmpty) {
      // Older data exists but couldn't be migrated: not a first run.
      if (_database.legacyMigrationFailed) {
        throw StateError('Legacy data could not be migrated');
      }
      return null;
    }

    final themes = await _database.themeDao.getAllThemes(db);
    final deletedHabits = await _database.metadataDao.getTombstones(
      db,
      'habit',
    );
    final deletedThemes = await _database.metadataDao.getTombstones(
      db,
      'theme',
    );

    final versionStr = meta[DatabaseSchema.metaKeySchemaVersion];
    final version = versionStr != null
        ? (int.tryParse(versionStr) ?? AppPayloadModel.currentSchemaVersion)
        : AppPayloadModel.currentSchemaVersion;

    final lastModifiedBy =
        meta[DatabaseSchema.metaKeyLastModifiedBy] ?? 'local_device';
    final lastModifiedAtStr = meta[DatabaseSchema.metaKeyLastModifiedAt];
    final lastModifiedAt = lastModifiedAtStr != null
        ? (DateTime.tryParse(lastModifiedAtStr) ?? DateTime.now())
        : DateTime.now();

    final activeThemeId =
        meta[DatabaseSchema.metaKeyActiveThemeId] ??
        UserThemeModel.defaultTheme.id;
    final displayName = meta[DatabaseSchema.metaKeyDisplayName] ?? '';

    return AppPayloadModel(
      version: version,
      lastModifiedBy: lastModifiedBy,
      lastModifiedAt: lastModifiedAt,
      activeThemeId: activeThemeId,
      userThemes: themes.isNotEmpty ? themes : UserThemeModel.builtInPresets,
      habits: habits,
      displayName: displayName,
      deletedHabits: deletedHabits,
      deletedThemes: deletedThemes,
    );
  }

  /// The newest backup that parses: in-database snapshots first, then the
  /// mirror file outside the database.
  Future<AppPayloadModel?> _loadNewestReadableBackup() async {
    try {
      final db = await _database.database;
      for (final name in await _database.backupDao.listBackups(db)) {
        try {
          final payload = await _database.backupDao.restoreBackup(db, name);
          if (payload != null) return payload;
        } catch (_) {}
      }
    } catch (_) {
      // Database unusable; fall through to the mirror file.
    }
    try {
      final file = await _mirrorFileResolver();
      if (file != null && await file.exists()) {
        return AppPayloadModel.fromRawJson(await file.readAsString());
      }
    } catch (_) {}
    return null;
  }

  /// Atomically replaces the mirror file (write to a temp file, then rename)
  /// so a crash mid-write never leaves a truncated copy.
  Future<void> _writeMirror(AppPayloadModel payload) async {
    try {
      final file = await _mirrorFileResolver();
      if (file == null) return;
      await file.parent.create(recursive: true);
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(payload.toRawJson(), flush: true);
      await temp.rename(file.path);
    } catch (e) {
      debugPrint('SqfliteHabitStorage: mirror backup not written: $e');
    }
  }

  @override
  Future<void> savePayload(AppPayloadModel payload) async {
    final db = await _database.database;

    await db.transaction((txn) async {
      // 1. Maintain rolling snapshots
      await _database.backupDao.rotateAndSaveBackup(txn, payload);

      // 2. Persist habits & check-ins
      await _database.habitDao.syncHabits(txn, payload.habits);

      // 3. Persist themes
      await _database.themeDao.syncThemes(txn, payload.userThemes);

      // 4. Persist tombstones
      await _database.metadataDao.syncTombstones(
        txn,
        'habit',
        payload.deletedHabits,
      );
      await _database.metadataDao.syncTombstones(
        txn,
        'theme',
        payload.deletedThemes,
      );

      // 5. Persist metadata
      await _database.metadataDao.setAllMetadata(txn, {
        DatabaseSchema.metaKeySchemaVersion: payload.version.toString(),
        DatabaseSchema.metaKeyLastModifiedBy: payload.lastModifiedBy,
        DatabaseSchema.metaKeyLastModifiedAt: payload.lastModifiedAt
            .toIso8601String(),
        DatabaseSchema.metaKeyActiveThemeId: payload.activeThemeId,
        if (payload.displayName.isNotEmpty)
          DatabaseSchema.metaKeyDisplayName: payload.displayName,
      });
    });
    await _writeMirror(payload);
  }

  @override
  Future<List<String>> listBackups() async {
    final db = await _database.database;
    return await _database.backupDao.listBackups(db);
  }

  @override
  Future<AppPayloadModel?> restoreBackup(String backupName) async {
    final db = await _database.database;
    final payload = await _database.backupDao.restoreBackup(db, backupName);
    if (payload != null) {
      await savePayload(payload);
    }
    return payload;
  }

  @override
  Future<void> clear() async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await _database.habitDao.clear(txn);
      await _database.themeDao.clear(txn);
      await _database.metadataDao.clear(txn);
      await _database.backupDao.clear(txn);
    });
    try {
      final file = await _mirrorFileResolver();
      if (file != null && await file.exists()) await file.delete();
    } catch (_) {}
  }
}

/// Factory function creating [SqfliteHabitStorage].
HabitStorage createPlatformHabitStorage() => SqfliteHabitStorage();
