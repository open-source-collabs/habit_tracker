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

  SqfliteHabitStorage({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  @override
  Future<AppPayloadModel?> loadPayload() async {
    try {
      final db = await _database.database;
      final meta = await _database.metadataDao.getAllMetadata(db);
      final habits = await _database.habitDao.getAllHabits(db);

      // True first run: no metadata and no habits exist
      if (meta.isEmpty && habits.isEmpty) {
        return null;
      }

      final themes = await _database.themeDao.getAllThemes(db);
      final deletedHabits =
          await _database.metadataDao.getTombstones(db, 'habit');
      final deletedThemes =
          await _database.metadataDao.getTombstones(db, 'theme');

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

      final activeThemeId = meta[DatabaseSchema.metaKeyActiveThemeId] ??
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
    } catch (e) {
      throw CorruptPayloadException(e);
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
        DatabaseSchema.metaKeyLastModifiedAt:
            payload.lastModifiedAt.toIso8601String(),
        DatabaseSchema.metaKeyActiveThemeId: payload.activeThemeId,
        if (payload.displayName.isNotEmpty)
          DatabaseSchema.metaKeyDisplayName: payload.displayName,
      });
    });
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
  }
}

/// Factory function creating [SqfliteHabitStorage].
HabitStorage createPlatformHabitStorage() => SqfliteHabitStorage();
