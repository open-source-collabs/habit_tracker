import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../features/notifications/data/models/notification_settings_model.dart';
import '../../features/themes/data/models/app_payload_model.dart';
import 'daos/backup_dao.dart';
import 'daos/habit_dao.dart';
import 'daos/metadata_dao.dart';
import 'daos/notification_dao.dart';
import 'daos/theme_dao.dart';
import 'database_schema.dart';

/// Central database service managing SQLite connection, transactions, and DAOs.
class AppDatabase {
  static final AppDatabase instance = AppDatabase();

  final Database? _injectedDatabase;
  final String? customPath;
  final File? legacyJsonFile;

  Database? _db;
  Future<Database>? _openFuture;

  AppDatabase({
    Database? db,
    this.customPath,
    this.legacyJsonFile,
  }) : _injectedDatabase = db;

  /// Initializes the FFI database factory on desktop (Windows, Linux, macOS)
  /// and unit test environments.
  static Future<void> initializePlatform() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      if (databaseFactory != databaseFactoryFfi) {
        databaseFactory = databaseFactoryFfi;
      }
    }
  }

  /// Returns the active or initialized [Database] connection.
  Future<Database> get database async {
    if (_injectedDatabase != null) return _injectedDatabase;
    if (_db != null && _db!.isOpen) return _db!;
    return _openFuture ??= _initDatabase();
  }

  Future<Database> _initDatabase() async {
    // Ensure platform factory is set on desktop/tests
    await initializePlatform();

    final String dbPath;
    if (customPath != null) {
      dbPath = customPath!;
    } else {
      final databasesPath = await getDatabasesPath();
      dbPath = p.join(databasesPath, DatabaseSchema.databaseName);
    }

    final db = await openDatabase(
      dbPath,
      version: DatabaseSchema.version,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );

    _db = db;
    _openFuture = null;

    // Check and run legacy migration if opening for the first time
    await _migrateFromLegacyStorageIfNeeded(db);

    return db;
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
    // In-memory or temporary databases do not support WAL mode
    try {
      await db.execute('PRAGMA journal_mode = WAL;');
    } catch (_) {
      // Graceful fallback in environments where WAL is not supported (e.g. in-memory test DB)
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute(DatabaseSchema.createHabitsTable);
    await db.execute(DatabaseSchema.createCheckInsTable);
    await db.execute(DatabaseSchema.createUserThemesTable);
    await db.execute(DatabaseSchema.createAppMetadataTable);
    await db.execute(DatabaseSchema.createTombstonesTable);
    await db.execute(DatabaseSchema.createNotificationSettingsTable);
    await db.execute(DatabaseSchema.createBackupsTable);

    for (final indexSql in DatabaseSchema.createIndexes) {
      await db.execute(indexSql);
    }
  }

  /// Migrates legacy file-based JSON (`app_data.json`) and legacy `SharedPreferences`
  /// into SQLite relational tables.
  Future<void> _migrateFromLegacyStorageIfNeeded(Database db) async {
    try {
      final meta = await metadataDao.getAllMetadata(db);
      if (meta.containsKey(DatabaseSchema.metaKeySchemaVersion)) {
        // Already initialized with SQLite schema
        return;
      }

      // Check for legacy JSON payload
      final legacyFile = await _findLegacyJsonFile();
      if (legacyFile != null && await legacyFile.exists()) {
        final content = await legacyFile.readAsString();
        if (content.trim().isNotEmpty) {
          final payload = AppPayloadModel.fromRawJson(content);

          await db.transaction((txn) async {
            // Save habits and check-ins
            await habitDao.syncHabits(txn, payload.habits);

            // Save user themes
            await themeDao.syncThemes(txn, payload.userThemes);

            // Save tombstones
            await metadataDao.syncTombstones(
              txn,
              'habit',
              payload.deletedHabits,
            );
            await metadataDao.syncTombstones(
              txn,
              'theme',
              payload.deletedThemes,
            );

            // Save metadata
            await metadataDao.setAllMetadata(txn, {
              DatabaseSchema.metaKeySchemaVersion: payload.version.toString(),
              DatabaseSchema.metaKeyLastModifiedBy: payload.lastModifiedBy,
              DatabaseSchema.metaKeyLastModifiedAt:
                  payload.lastModifiedAt.toIso8601String(),
              DatabaseSchema.metaKeyActiveThemeId: payload.activeThemeId,
              if (payload.displayName.isNotEmpty)
                DatabaseSchema.metaKeyDisplayName: payload.displayName,
            });
          });

          // Backup legacy file as migrated
          try {
            final migratedCopy =
                File('${legacyFile.parent.path}/app_data.migrated.json');
            if (!await migratedCopy.exists()) {
              await legacyFile.copy(migratedCopy.path);
            }
          } catch (_) {}
        }
      }

      // Check for legacy SharedPreferences notifications
      try {
        final prefs = await SharedPreferences.getInstance();
        final notifJson =
            prefs.getString('habit_tracker_notification_settings_v1');
        if (notifJson != null && notifJson.isNotEmpty) {
          final decoded = json.decode(notifJson) as Map<String, dynamic>;
          final settings = NotificationSettingsModel.fromJson(decoded);
          await notificationDao.saveSettings(db, settings);
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('AppDatabase: Error running legacy migration: $e');
    }
  }

  Future<File?> _findLegacyJsonFile() async {
    if (legacyJsonFile != null) return legacyJsonFile;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final target = File('${docDir.path}/habit_tracker_data/app_data.json');
      if (await target.exists()) return target;
    } catch (_) {}

    try {
      String basePath = './habit_tracker_data';
      if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'] ??
            Platform.environment['USERPROFILE'];
        if (appData != null) basePath = '$appData/HabitTracker';
      } else if (Platform.isLinux || Platform.isMacOS) {
        final home = Platform.environment['HOME'];
        if (home != null) basePath = '$home/.habit_tracker';
      }
      final file = File('$basePath/app_data.json');
      if (await file.exists()) return file;
    } catch (_) {}

    return null;
  }

  /// Closes database connection.
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
    _openFuture = null;
  }

  // --- DAO Accessors ---
  HabitDao get habitDao => const HabitDao();
  ThemeDao get themeDao => const ThemeDao();
  MetadataDao get metadataDao => const MetadataDao();
  NotificationDao get notificationDao => const NotificationDao();
  BackupDao get backupDao => const BackupDao();
}
