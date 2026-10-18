import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/core/database/daos/backup_dao.dart';
import 'package:habit_tracker/core/database/database_schema.dart';
import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/habits/data/storage/sqflite_habit_storage.dart';
import 'package:habit_tracker/features/notifications/data/models/notification_settings_model.dart';
import 'package:habit_tracker/features/themes/data/models/app_payload_model.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SQLite Schema & Core DAOs', () {
    late AppDatabase appDb;
    late Database db;

    setUp(() async {
      appDb = AppDatabase(customPath: inMemoryDatabasePath);
      db = await appDb.database;
    });

    tearDown(() async {
      await appDb.close();
    });

    test('Tables are created properly in SQLite', () async {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table';",
      );
      final tableNames = tables.map((t) => t['name'] as String).toSet();

      expect(tableNames, contains(DatabaseSchema.tableHabits));
      expect(tableNames, contains(DatabaseSchema.tableCheckIns));
      expect(tableNames, contains(DatabaseSchema.tableUserThemes));
      expect(tableNames, contains(DatabaseSchema.tableAppMetadata));
      expect(tableNames, contains(DatabaseSchema.tableTombstones));
      expect(tableNames, contains(DatabaseSchema.tableNotificationSettings));
      expect(tableNames, contains(DatabaseSchema.tableBackups));
    });

    test('HabitDao inserts, queries, and cascade-deletes check-ins', () async {
      final habitDao = appDb.habitDao;
      final testHabit = HabitModel(
        id: 'h_sql_1',
        title: 'Morning Run',
        subtitle: '5km daily',
        frequency: const HabitFrequency.daily(),
        routineGroup: 'Fitness',
        accentIndex: 2,
        createdAt: DateTime(2026, 1, 1),
        checkIns: const {'2026-10-18': true, '2026-10-17': true},
        checkInChangedAt: const {
          '2026-10-18': 1760000000,
          '2026-10-17': 1759000000,
        },
      );

      await habitDao.upsertHabit(db, testHabit);

      final loaded = await habitDao.getAllHabits(db);
      expect(loaded.length, 1);
      expect(loaded.first.id, 'h_sql_1');
      expect(loaded.first.title, 'Morning Run');
      expect(loaded.first.checkIns['2026-10-18'], isTrue);
      expect(loaded.first.checkInChangedAt['2026-10-18'], 1760000000);

      // Verify check_ins table has rows
      final checkInRows = await db.query(DatabaseSchema.tableCheckIns);
      expect(checkInRows.length, 2);

      // Delete habit and verify check-ins cascade delete
      await habitDao.deleteHabit(db, 'h_sql_1');
      final remainingHabits = await habitDao.getAllHabits(db);
      expect(remainingHabits, isEmpty);

      final remainingCheckIns = await db.query(DatabaseSchema.tableCheckIns);
      expect(remainingCheckIns, isEmpty);
    });

    test('ThemeDao persists and deletes custom themes', () async {
      final themeDao = appDb.themeDao;
      const theme = UserThemeModel(
        id: 'theme_cyber',
        name: 'Cyberpunk Neon',
        fontFamily: 'Inter',
        scaffoldBgHex: '#0A0A14',
        cardBgHex: '#121224',
        cardBorderHex: '#00F0FF',
        textPrimaryHex: '#FFFFFF',
        accentPaletteHex: ['#00F0FF', '#FF0055'],
        isBuiltIn: false,
      );

      await themeDao.upsertTheme(db, theme);

      final themes = await themeDao.getAllThemes(db);
      expect(themes.length, 1);
      expect(themes.first.name, 'Cyberpunk Neon');
      expect(themes.first.accentPaletteHex, ['#00F0FF', '#FF0055']);

      await themeDao.deleteTheme(db, 'theme_cyber');
      final afterDelete = await themeDao.getAllThemes(db);
      expect(afterDelete, isEmpty);
    });

    test('NotificationDao saves and loads notification preferences', () async {
      final notifDao = appDb.notificationDao;
      const settings = NotificationSettingsModel(
        masterEnabled: true,
        morningKickoffEnabled: false,
        morningHour: 9,
        morningMinute: 15,
        eveningStreakSaverEnabled: true,
        eveningHour: 21,
        eveningMinute: 45,
        soundEnabled: false,
      );

      await notifDao.saveSettings(db, settings);

      final loaded = await notifDao.loadSettings(db);
      expect(loaded.masterEnabled, isTrue);
      expect(loaded.morningKickoffEnabled, isFalse);
      expect(loaded.morningHour, 9);
      expect(loaded.morningMinute, 15);
      expect(loaded.eveningHour, 21);
      expect(loaded.soundEnabled, isFalse);
    });

    test('BackupDao rotates and restores rolling snapshots', () async {
      final backupDao = appDb.backupDao;
      final p1 = AppPayloadModel.initial(lastModifiedBy: 'device_1');
      final p2 = AppPayloadModel.initial(lastModifiedBy: 'device_2');
      final p3 = AppPayloadModel.initial(lastModifiedBy: 'device_3');

      await backupDao.rotateAndSaveBackup(db, p1);
      var backups = await backupDao.listBackups(db);
      expect(backups, [BackupDao.backup1FileName]);

      await backupDao.rotateAndSaveBackup(db, p2);
      backups = await backupDao.listBackups(db);
      expect(backups, [BackupDao.backup1FileName, BackupDao.backup2FileName]);

      await backupDao.rotateAndSaveBackup(db, p3);
      backups = await backupDao.listBackups(db);
      expect(backups, [
        BackupDao.backup1FileName,
        BackupDao.backup2FileName,
        BackupDao.backup3FileName,
      ]);

      final restoredP3 = await backupDao.restoreBackup(
        db,
        BackupDao.backup1FileName,
      );
      expect(restoredP3?.lastModifiedBy, 'device_3');

      final restoredP2 = await backupDao.restoreBackup(
        db,
        BackupDao.backup2FileName,
      );
      expect(restoredP2?.lastModifiedBy, 'device_2');
    });
  });

  group('SqfliteHabitStorage Integration', () {
    late AppDatabase appDb;
    late SqfliteHabitStorage storage;

    setUp(() {
      appDb = AppDatabase(customPath: inMemoryDatabasePath);
      storage = SqfliteHabitStorage(database: appDb);
    });

    tearDown(() async {
      await appDb.close();
    });

    test('Returns null on first run when database is empty', () async {
      final payload = await storage.loadPayload();
      expect(payload, isNull);
    });

    test('Saves and loads complete AppPayloadModel round-trip', () async {
      final habit = HabitModel(
        id: 'h_rt_1',
        title: 'Meditation',
        subtitle: '10 mins mindfulness',
        frequency: const HabitFrequency.specificWeekdays([1, 3, 5]),
        routineGroup: 'Wellness',
        accentIndex: 3,
        createdAt: DateTime(2026, 1, 1),
        checkIns: const {'2026-10-18': true},
        checkInChangedAt: const {'2026-10-18': 123456789},
        emoji: '🧘',
      );

      final payload = AppPayloadModel(
        version: AppPayloadModel.currentSchemaVersion,
        lastModifiedBy: 'tester',
        lastModifiedAt: DateTime(2026, 10, 18, 12, 0),
        activeThemeId: UserThemeModel.obsidianTwilight.id,
        userThemes: UserThemeModel.builtInPresets,
        habits: [habit],
        displayName: 'Umair',
        deletedHabits: {'deleted_h1': DateTime(2026, 10, 17)},
      );

      await storage.savePayload(payload);

      final loaded = await storage.loadPayload();
      expect(loaded, isNotNull);
      expect(loaded!.lastModifiedBy, 'tester');
      expect(loaded.displayName, 'Umair');
      expect(loaded.habits.length, 1);
      expect(loaded.habits.first.title, 'Meditation');
      expect(loaded.habits.first.emoji, '🧘');
      expect(
        loaded.habits.first.frequency.type,
        HabitFrequencyType.specificWeekdays,
      );
      expect(loaded.habits.first.frequency.daysOfWeek, [1, 3, 5]);
      expect(loaded.habits.first.checkIns['2026-10-18'], isTrue);
      expect(loaded.deletedHabits.containsKey('deleted_h1'), isTrue);
    });

    test('clear wipes data completely', () async {
      final payload = AppPayloadModel.initial(lastModifiedBy: 'device_clear');
      await storage.savePayload(payload);

      final before = await storage.loadPayload();
      expect(before, isNotNull);

      await storage.clear();

      final after = await storage.loadPayload();
      expect(after, isNull);
    });
  });

  group('Legacy Data Migration', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('sqflite_mig_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Migrates existing app_data.json into SQLite on first open', () async {
      // 1. Create legacy JSON file in temp dir
      final legacyDir = Directory('${tempDir.path}/habit_tracker_data');
      legacyDir.createSync(recursive: true);
      final legacyFile = File('${legacyDir.path}/app_data.json');

      final initialPayload = AppPayloadModel(
        version: AppPayloadModel.currentSchemaVersion,
        lastModifiedBy: 'migrated_user',
        lastModifiedAt: DateTime(2026, 10, 15),
        activeThemeId: UserThemeModel.defaultTheme.id,
        userThemes: UserThemeModel.builtInPresets,
        habits: [
          HabitModel(
            id: 'legacy_h1',
            title: 'Read Book',
            frequency: const HabitFrequency.daily(),
            createdAt: DateTime(2026, 1, 1),
            checkIns: const {'2026-10-15': true},
          ),
        ],
        displayName: 'Bookworm',
      );

      legacyFile.writeAsStringSync(initialPayload.toRawJson());

      // 2. Open SQLite database pointing to temp db path and passing legacy file
      final dbPath = '${tempDir.path}/test_migration.db';
      final appDb = AppDatabase(customPath: dbPath, legacyJsonFile: legacyFile);
      final storage = SqfliteHabitStorage(database: appDb);

      // Verify migration occurred
      final loaded = await storage.loadPayload();
      expect(loaded, isNotNull);
      expect(loaded!.lastModifiedBy, 'migrated_user');
      expect(loaded.displayName, 'Bookworm');
      expect(loaded.habits.length, 1);
      expect(loaded.habits.first.id, 'legacy_h1');
      expect(loaded.habits.first.title, 'Read Book');
      expect(loaded.habits.first.checkIns['2026-10-15'], isTrue);

      await appDb.close();
    });
  });
}
