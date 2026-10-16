import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/app_data_repository.dart';
import '../../../../core/theme/theme_factory.dart';
import '../../data/models/dynamic_theme_model.dart';
import '../../data/storage/legacy_theme_preferences.dart';

/// Immutable state containing the themes catalogue and currently active theme.
@immutable
class UserThemeState {
  final List<UserThemeModel> allThemes;
  final String activeThemeId;

  const UserThemeState({
    required this.allThemes,
    required this.activeThemeId,
  });

  /// Built-in presets followed by [customThemes], with [activeThemeId]
  /// falling back to the default theme when it no longer exists.
  factory UserThemeState.resolve({
    required Iterable<UserThemeModel> customThemes,
    required String activeThemeId,
  }) {
    final presets = UserThemeModel.builtInPresets;
    final presetIds = presets.map((t) => t.id).toSet();
    final allThemes = [
      ...presets,
      ...customThemes.where((t) => !t.isBuiltIn && !presetIds.contains(t.id)),
    ];
    return UserThemeState(
      allThemes: allThemes,
      activeThemeId: allThemes.any((t) => t.id == activeThemeId)
          ? activeThemeId
          : UserThemeModel.defaultTheme.id,
    );
  }

  /// The currently active theme model
  UserThemeModel get activeTheme {
    return allThemes.firstWhere(
      (theme) => theme.id == activeThemeId,
      orElse: () => allThemes.isNotEmpty
          ? allThemes.first
          : UserThemeModel.defaultTheme,
    );
  }

  /// Themes created or edited by the user.
  List<UserThemeModel> get customThemes =>
      allThemes.where((t) => !t.isBuiltIn).toList();

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
///
/// Themes persist in the app payload via [AppDataRepository]. The first frame
/// uses the default theme; stored themes are applied once loading completes.
class ThemeNotifier extends Notifier<UserThemeState> {
  late Future<void> _hydration;
  late AppDataRepository _repository;
  bool _disposed = false;

  @override
  UserThemeState build() {
    // Dependencies are captured synchronously: async work must not touch
    // `ref` after this notifier may have been disposed.
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    _repository = ref.watch(appDataRepositoryProvider);
    _hydration = _hydrate(ref.read(legacyThemePreferencesProvider));
    return UserThemeState.resolve(
      customThemes: const [],
      activeThemeId: UserThemeModel.defaultTheme.id,
    );
  }

  Future<void> _hydrate(LegacyThemePreferences legacyPrefs) async {
    final AppDataSnapshot snapshot;
    try {
      snapshot = await _repository.load();
    } catch (e) {
      // Stored data is unreadable; keep defaults. The habits feature surfaces
      // the error and owns recovery.
      debugPrint('ThemeNotifier: could not load stored themes: $e');
      return;
    }

    var customThemes = snapshot.payload.userThemes;
    var activeThemeId = snapshot.payload.activeThemeId;

    LegacyThemeData? legacy;
    try {
      legacy = await legacyPrefs.read();
    } catch (e) {
      debugPrint('ThemeNotifier: could not read legacy theme prefs: $e');
    }

    if (legacy != null) {
      customThemes = _mergeLegacyThemes(customThemes, legacy.customThemes);
      activeThemeId = legacy.activeThemeId ?? activeThemeId;
    }

    if (_disposed) return;
    state = UserThemeState.resolve(
      customThemes: customThemes,
      activeThemeId: activeThemeId,
    );

    if (legacy != null) {
      final persisted = await _persist();
      if (persisted) {
        try {
          await legacyPrefs.clear();
        } catch (e) {
          debugPrint('ThemeNotifier: could not clear legacy theme prefs: $e');
        }
      }
    }
  }

  /// Legacy prefs were the live source of truth, so their themes win on id
  /// clashes. Older builds could save an edited preset under the preset's own
  /// id; those are re-keyed so they survive alongside the preset.
  static List<UserThemeModel> _mergeLegacyThemes(
    List<UserThemeModel> payloadThemes,
    List<UserThemeModel> legacyThemes,
  ) {
    final presetIds = UserThemeModel.builtInPresets.map((t) => t.id).toSet();
    final byId = <String, UserThemeModel>{
      for (final t in payloadThemes.where((t) => !t.isBuiltIn)) t.id: t,
    };
    for (final theme in legacyThemes) {
      final rekeyed = presetIds.contains(theme.id)
          ? theme.copyWith(id: '${theme.id}_custom', isBuiltIn: false)
          : theme;
      byId[rekeyed.id] = rekeyed;
    }
    return byId.values.toList();
  }

  /// Sets the active theme and persists the preference.
  Future<void> setActiveTheme(String id) async {
    await _hydration;
    if (!state.allThemes.any((t) => t.id == id)) return;

    state = state.copyWith(activeThemeId: id);
    await _persist();
  }

  /// Saves a custom theme (insert or update), activates it, and persists it.
  ///
  /// Built-in presets are never overwritten: saving an edited preset creates
  /// a new custom theme. Returns the theme as stored.
  Future<UserThemeModel> saveCustomTheme(UserThemeModel theme) async {
    await _hydration;
    final isPresetId =
        UserThemeModel.builtInPresets.any((preset) => preset.id == theme.id);
    final saved = theme.copyWith(
      id: isPresetId ? _newCustomThemeId() : theme.id,
      isBuiltIn: false,
      lastModifiedAt: DateTime.now(),
    );

    final existingIndex = state.allThemes.indexWhere((t) => t.id == saved.id);
    final updatedList = List<UserThemeModel>.from(state.allThemes);
    if (existingIndex >= 0) {
      updatedList[existingIndex] = saved;
    } else {
      updatedList.add(saved);
    }

    state = state.copyWith(allThemes: updatedList, activeThemeId: saved.id);
    await _persist();
    return saved;
  }

  /// Clones an existing theme as a new custom theme and sets it active
  Future<UserThemeModel> duplicateTheme(UserThemeModel source) {
    return saveCustomTheme(
      source.copyWith(
        id: _newCustomThemeId(),
        name: '${source.name} (Copy)',
        isBuiltIn: false,
      ),
    );
  }

  /// Deletes a custom theme (built-ins are protected)
  Future<void> deleteTheme(String id) async {
    await _hydration;
    final target = state.allThemes.where((t) => t.id == id).firstOrNull;
    if (target == null || target.isBuiltIn) return;

    state = UserThemeState.resolve(
      customThemes: state.customThemes.where((t) => t.id != id),
      activeThemeId: state.activeThemeId == id
          ? UserThemeModel.defaultTheme.id
          : state.activeThemeId,
    );
    await _persist();
  }

  /// Restores themes and active theme from an imported payload.
  Future<void> restoreThemes({
    required List<UserThemeModel> themes,
    required String activeThemeId,
  }) async {
    await _hydration;
    state = UserThemeState.resolve(
      customThemes: themes,
      activeThemeId: activeThemeId,
    );
    await _persist();
  }

  /// Writes the custom themes and active id into the app payload.
  /// Returns whether the write succeeded.
  Future<bool> _persist() async {
    final customThemes = state.customThemes;
    final activeThemeId = state.activeThemeId;
    try {
      await _repository.update(
            (payload) => payload.copyWith(
              userThemes: customThemes,
              activeThemeId: activeThemeId,
            ),
          );
      return true;
    } catch (e) {
      debugPrint('ThemeNotifier: failed to persist themes: $e');
      return false;
    }
  }

  static String _newCustomThemeId() =>
      'custom_${DateTime.now().microsecondsSinceEpoch}';
}

/// Global provider for the theme system
final themeProvider =
    NotifierProvider<ThemeNotifier, UserThemeState>(ThemeNotifier.new);
