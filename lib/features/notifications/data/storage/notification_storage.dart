import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/database/app_database.dart';
import '../models/notification_settings_model.dart';

/// Provider for [NotificationStorage].
final notificationStorageProvider = Provider<NotificationStorage>((ref) {
  return NotificationStorage();
});

/// Persistence repository for notification preferences backed by SQLite
/// with transparent legacy [SharedPreferences] migration and web support.
class NotificationStorage {
  static const String _kStorageKey = 'habit_tracker_notification_settings_v1';
  final AppDatabase _database;

  NotificationStorage({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  /// Loads persisted settings from SQLite or falls back to defaults.
  Future<NotificationSettingsModel> loadSettings() async {
    if (!kIsWeb) {
      try {
        final db = await _database.database;
        final settings = await _database.notificationDao.loadSettings(db);
        // If settings were found in DB, return them
        final rows = await db.rawQuery(
          'SELECT COUNT(*) as count FROM notification_settings',
        );
        final count = (rows.first['count'] as int?) ?? 0;
        if (count > 0) {
          return settings;
        }
      } catch (e) {
        debugPrint('NotificationStorage: Error loading from SQLite: $e');
      }
    }

    // Check legacy SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_kStorageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        final legacySettings = NotificationSettingsModel.fromJson(decoded);
        if (!kIsWeb) {
          try {
            final db = await _database.database;
            await _database.notificationDao.saveSettings(db, legacySettings);
          } catch (_) {}
        }
        return legacySettings;
      }
    } catch (e) {
      debugPrint('NotificationStorage: Error loading settings from prefs: $e');
    }

    return const NotificationSettingsModel();
  }

  /// Persists updated [settings] asynchronously into SQLite.
  Future<bool> saveSettings(NotificationSettingsModel settings) async {
    var success = true;
    if (!kIsWeb) {
      try {
        final db = await _database.database;
        await _database.notificationDao.saveSettings(db, settings);
      } catch (e) {
        debugPrint('NotificationStorage: Error saving to SQLite: $e');
        success = false;
      }
    }

    // Keep SharedPreferences updated as secondary backup / web store
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(settings.toJson());
      await prefs.setString(_kStorageKey, jsonStr);
    } catch (e) {
      debugPrint('NotificationStorage: Error saving to SharedPreferences: $e');
      if (kIsWeb) success = false;
    }

    return success;
  }
}
