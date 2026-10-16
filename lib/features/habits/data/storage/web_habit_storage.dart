import 'package:shared_preferences/shared_preferences.dart';

import '../../../themes/data/models/app_payload_model.dart';
import 'habit_storage.dart';

/// Key-value storage interface allowing dependency injection and in-memory test mocks.
abstract interface class WebKeyValueStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

/// Default web storage adapter backed by [SharedPreferences] (browser local storage).
class SharedPreferencesWebStore implements WebKeyValueStore {
  const SharedPreferencesWebStore();

  @override
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}

/// In-memory storage adapter for unit testing web storage behavior.
class InMemoryWebStore implements WebKeyValueStore {
  final Map<String, String> _memory = {};

  @override
  Future<String?> getString(String key) async => _memory[key];

  @override
  Future<void> setString(String key, String value) async {
    _memory[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _memory.remove(key);
  }
}

/// Platform storage implementation for Web environments.
/// Employs atomic staging keys and rolling snapshot backups (`backup_1.json`,
/// `backup_2.json`, `backup_3.json`) backed by browser local storage.
class WebHabitStorage implements HabitStorage {
  static const String primaryKey = 'habit_tracker_payload';
  static const String backup1Key = 'backup_1.json';
  static const String backup2Key = 'backup_2.json';
  static const String backup3Key = 'backup_3.json';
  static const String stagingKey = 'habit_tracker_payload_tmp';

  final WebKeyValueStore _store;

  WebHabitStorage([WebKeyValueStore? store])
      : _store = store ?? const SharedPreferencesWebStore();

  static const String corruptCopyKey = 'habit_tracker_payload_corrupt';

  @override
  Future<AppPayloadModel?> loadPayload() async {
    var foundData = false;
    Object? lastError;

    final primaryValue = await _store.getString(primaryKey);
    if (primaryValue != null && primaryValue.trim().isNotEmpty) {
      foundData = true;
      try {
        return AppPayloadModel.fromRawJson(primaryValue);
      } catch (e) {
        // Corrupted primary payload; attempt recovery
        lastError = e;
      }
    }

    final backupKeys = [backup1Key, backup2Key, backup3Key];
    for (final key in backupKeys) {
      final value = await _store.getString(key);
      if (value == null || value.trim().isEmpty) continue;
      foundData = true;
      try {
        final payload = AppPayloadModel.fromRawJson(value);
        await _preserveCorruptPrimary(primaryValue);
        await _store.setString(primaryKey, value);
        return payload;
      } catch (e) {
        // Continue scanning older backups
        lastError = e;
      }
    }

    if (foundData) {
      await _preserveCorruptPrimary(primaryValue);
      throw CorruptPayloadException(lastError);
    }
    return null;
  }

  /// Keeps one copy of an unreadable primary record so it is never lost to
  /// backup rotation. An existing copy is not overwritten.
  Future<void> _preserveCorruptPrimary(String? primaryValue) async {
    if (primaryValue == null || primaryValue.trim().isEmpty) return;
    if (await _store.getString(corruptCopyKey) != null) return;
    await _store.setString(corruptCopyKey, primaryValue);
  }

  @override
  Future<void> savePayload(AppPayloadModel payload) async {
    final serialized = payload.toRawJson(pretty: false);

    await _store.setString(stagingKey, serialized);

    final staged = await _store.getString(stagingKey);
    if (staged == null || staged.isEmpty) {
      throw StateError('Staged payload could not be verified in web storage');
    }

    final currentPrimary = await _store.getString(primaryKey);
    if (currentPrimary != null && currentPrimary.isNotEmpty) {
      final backup2 = await _store.getString(backup2Key);
      if (backup2 != null) {
        await _store.setString(backup3Key, backup2);
      }

      final backup1 = await _store.getString(backup1Key);
      if (backup1 != null) {
        await _store.setString(backup2Key, backup1);
      }

      await _store.setString(backup1Key, currentPrimary);
    }

    await _store.setString(primaryKey, staged);
    await _store.remove(stagingKey);
  }

  @override
  Future<List<String>> listBackups() async {
    final backupKeys = [backup1Key, backup2Key, backup3Key];
    final existing = <String>[];

    for (final key in backupKeys) {
      final val = await _store.getString(key);
      if (val != null && val.isNotEmpty) {
        existing.add(key);
      }
    }

    return existing;
  }

  @override
  Future<AppPayloadModel?> restoreBackup(String backupName) async {
    final value = await _store.getString(backupName);
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final payload = AppPayloadModel.fromRawJson(value);
    await _store.setString(primaryKey, value);
    return payload;
  }

  @override
  Future<void> clear() async {
    await _store.remove(primaryKey);
    await _store.remove(backup1Key);
    await _store.remove(backup2Key);
    await _store.remove(backup3Key);
    await _store.remove(stagingKey);
  }
}

HabitStorage createPlatformHabitStorage() => WebHabitStorage();
