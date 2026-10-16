import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_settings_model.dart';

/// Provider for [NotificationStorage].
final notificationStorageProvider = Provider<NotificationStorage>((ref) {
  return NotificationStorage();
});

/// Persistence repository for notification preferences using [SharedPreferences].
class NotificationStorage {
  static const String _kStorageKey = 'habit_tracker_notification_settings_v1';

  /// Loads persisted settings or returns default configuration.
  Future<NotificationSettingsModel> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_kStorageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        return NotificationSettingsModel.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('NotificationStorage: Error loading settings: $e');
    }
    return const NotificationSettingsModel();
  }

  /// Persists updated [settings] asynchronously.
  Future<bool> saveSettings(NotificationSettingsModel settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(settings.toJson());
      return await prefs.setString(_kStorageKey, jsonStr);
    } catch (e) {
      debugPrint('NotificationStorage: Error saving settings: $e');
      return false;
    }
  }
}
