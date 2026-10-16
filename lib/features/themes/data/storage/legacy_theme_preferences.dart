import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dynamic_theme_model.dart';

/// Themes stored by builds before themes moved into the app payload.
@immutable
class LegacyThemeData {
  final List<UserThemeModel> customThemes;
  final String? activeThemeId;

  const LegacyThemeData({required this.customThemes, this.activeThemeId});
}

/// Reads and removes the pre-payload SharedPreferences theme keys.
/// Used once, to migrate existing installs; nothing writes these keys now.
class LegacyThemePreferences {
  static const String customThemesKey = 'habit_tracker_custom_themes_v1';
  static const String activeThemeKey = 'habit_tracker_active_theme_v1';

  const LegacyThemePreferences();

  /// Returns the legacy data, or `null` if none was ever stored.
  Future<LegacyThemeData?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final rawThemes = prefs.getString(customThemesKey);
    final activeId = prefs.getString(activeThemeKey);
    if (rawThemes == null && activeId == null) return null;

    var customThemes = <UserThemeModel>[];
    if (rawThemes != null && rawThemes.isNotEmpty) {
      try {
        customThemes = (jsonDecode(rawThemes) as List<dynamic>)
            .map((e) => UserThemeModel.fromJson(e as Map<String, dynamic>))
            .where((t) => !t.isBuiltIn)
            .toList();
      } catch (e) {
        debugPrint('LegacyThemePreferences: unreadable custom themes: $e');
      }
    }

    return LegacyThemeData(customThemes: customThemes, activeThemeId: activeId);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(customThemesKey);
    await prefs.remove(activeThemeKey);
  }
}

final legacyThemePreferencesProvider = Provider<LegacyThemePreferences>(
  (ref) => const LegacyThemePreferences(),
);
