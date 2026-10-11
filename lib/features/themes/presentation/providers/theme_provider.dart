import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/theme_factory.dart';
import '../../data/models/dynamic_theme_model.dart';

/// Immutable state containing the themes catalogue and currently active theme.
@immutable
class UserThemeState {
  final List<UserThemeModel> allThemes;
  final String activeThemeId;

  const UserThemeState({
    required this.allThemes,
    required this.activeThemeId,
  });

  /// The currently active theme model
  UserThemeModel get activeTheme {
    return allThemes.firstWhere(
      (theme) => theme.id == activeThemeId,
      orElse: () => allThemes.isNotEmpty
          ? allThemes.first
          : UserThemeModel.nordicSerenity,
    );
  }

  /// ThemeData compiled dynamically from the active theme model
  ThemeData get themeData => ThemeFactory.createTheme(activeTheme);

  UserThemeState copyWith({
    List<UserThemeModel>? allThemes,
    String? activeThemeId,
  }) {
    return UserThemeState(
      allThemes: allThemes ?? this.allThemes,
      activeThemeId: activeThemeId ?? this.activeThemeId,
    );
  }
}

/// Riverpod Notifier managing theme customization, persistence, and switching.
class ThemeNotifier extends Notifier<UserThemeState> {
  static const String _prefsKeyCustomThemes = 'habit_tracker_custom_themes_v1';
  static const String _prefsKeyActiveTheme = 'habit_tracker_active_theme_v1';

  @override
  UserThemeState build() {
    final initialState = UserThemeState(
      allThemes: UserThemeModel.builtInPresets,
      activeThemeId: UserThemeModel.obsidianTwilight.id,
    );

    _loadFromPreferences();

    return initialState;
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJsonString = prefs.getString(_prefsKeyCustomThemes);
      final savedActiveId = prefs.getString(_prefsKeyActiveTheme);

      List<UserThemeModel> customThemes = [];
      if (savedJsonString != null && savedJsonString.isNotEmpty) {
        final decoded = jsonDecode(savedJsonString) as List<dynamic>;
        customThemes = decoded
            .map((e) => UserThemeModel.fromJson(e as Map<String, dynamic>))
            .where((t) => !t.isBuiltIn)
            .toList();
      }

      final mergedThemes = [
        ...UserThemeModel.builtInPresets,
        ...customThemes,
      ];

      final resolvedActiveId = savedActiveId != null &&
              mergedThemes.any((t) => t.id == savedActiveId)
          ? savedActiveId
          : UserThemeModel.nordicSerenity.id;

      state = state.copyWith(
        allThemes: mergedThemes,
        activeThemeId: resolvedActiveId,
      );
    } catch (_) {}
  }

  /// Sets the active theme and immediately persists the preference
  Future<void> setActiveTheme(String id) async {
    if (!state.allThemes.any((t) => t.id == id)) return;

    state = state.copyWith(activeThemeId: id);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyActiveTheme, id);
    } catch (_) {}
  }

  /// Saves a custom theme (insert or update), activates it, and persists to local storage
  Future<void> saveCustomTheme(UserThemeModel theme) async {
    final existingIndex = state.allThemes.indexWhere((t) => t.id == theme.id);
    List<UserThemeModel> updatedList;

    if (existingIndex >= 0) {
      updatedList = List<UserThemeModel>.from(state.allThemes);
      updatedList[existingIndex] = theme;
    } else {
      updatedList = [...state.allThemes, theme];
    }

    state = state.copyWith(
      allThemes: updatedList,
      activeThemeId: theme.id,
    );

    await _persistCustomThemes(updatedList);
    await setActiveTheme(theme.id);
  }

  /// Clones an existing theme as a new custom theme and sets it active
  Future<UserThemeModel> duplicateTheme(UserThemeModel source) async {
    final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final duplicated = source.copyWith(
      id: newId,
      name: '${source.name} (Copy)',
      isBuiltIn: false,
    );

    await saveCustomTheme(duplicated);
    return duplicated;
  }

  /// Deletes a custom theme (built-ins are protected)
  Future<void> deleteTheme(String id) async {
    final target = state.allThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => UserThemeModel.nordicSerenity,
    );

    if (target.isBuiltIn) return;

    final updatedList = state.allThemes.where((t) => t.id != id).toList();

    final newActiveId = state.activeThemeId == id
        ? UserThemeModel.nordicSerenity.id
        : state.activeThemeId;

    state = state.copyWith(
      allThemes: updatedList,
      activeThemeId: newActiveId,
    );

    await _persistCustomThemes(updatedList);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyActiveTheme, newActiveId);
    } catch (_) {}
  }

  Future<void> _persistCustomThemes(List<UserThemeModel> themes) async {
    try {
      final customThemes = themes.where((t) => !t.isBuiltIn).toList();
      final jsonString = jsonEncode(customThemes.map((t) => t.toJson()).toList());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyCustomThemes, jsonString);
    } catch (_) {}
  }
}

/// Global provider for the theme system
final themeProvider =
    NotifierProvider<ThemeNotifier, UserThemeState>(ThemeNotifier.new);
