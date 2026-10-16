import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../habits/data/models/habit_model.dart';
import 'dynamic_theme_model.dart';

/// Root JSON container persisting the application state, custom themes,
/// and dynamic habit tracking entities.
@immutable
class AppPayloadModel {
  /// Schema version written by this build. Bump it when the JSON shape
  /// changes and register a step in [_migrations] that upgrades the previous
  /// version's JSON.
  static const int currentSchemaVersion = 1;

  /// Upgrade steps keyed by the version they upgrade *from*:
  /// `_migrations[n]` turns version-n JSON into version-(n+1) JSON.
  static final Map<int, Map<String, dynamic> Function(Map<String, dynamic>)>
      _migrations = {};

  final int version;
  final String lastModifiedBy;
  final DateTime lastModifiedAt;
  final String activeThemeId;
  final List<UserThemeModel> userThemes;
  final List<HabitModel> habits;

  const AppPayloadModel({
    required this.version,
    required this.lastModifiedBy,
    required this.lastModifiedAt,
    required this.activeThemeId,
    required this.userThemes,
    required this.habits,
  });

  /// Factory providing default initial state with built-in theme presets.
  factory AppPayloadModel.initial({
    String lastModifiedBy = 'local_device',
    String? activeThemeId,
  }) {
    return AppPayloadModel(
      version: currentSchemaVersion,
      lastModifiedBy: lastModifiedBy,
      lastModifiedAt: DateTime.now(),
      activeThemeId: activeThemeId ?? UserThemeModel.defaultTheme.id,
      userThemes: UserThemeModel.builtInPresets,
      habits: const [],
    );
  }

  AppPayloadModel copyWith({
    int? version,
    String? lastModifiedBy,
    DateTime? lastModifiedAt,
    String? activeThemeId,
    List<UserThemeModel>? userThemes,
    List<HabitModel>? habits,
  }) {
    return AppPayloadModel(
      version: version ?? this.version,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      activeThemeId: activeThemeId ?? this.activeThemeId,
      userThemes: userThemes != null
          ? List.unmodifiable(userThemes)
          : this.userThemes,
      habits: habits != null
          ? List.unmodifiable(habits)
          : this.habits,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'lastModifiedBy': lastModifiedBy,
      'lastModifiedAt': lastModifiedAt.toIso8601String(),
      'activeThemeId': activeThemeId,
      'userThemes': userThemes.map((t) => t.toJson()).toList(),
      'habits': habits.map((h) => h.toJson()).toList(),
    };
  }

  /// Upgrades [json] from its stored schema version to [currentSchemaVersion].
  ///
  /// Throws [UnsupportedPayloadVersionException] for data written by a newer
  /// build, so an older build never silently drops fields it doesn't know.
  static Map<String, dynamic> migrate(Map<String, dynamic> json) {
    var version = (json['version'] as num?)?.toInt() ?? 1;
    if (version > currentSchemaVersion) {
      throw UnsupportedPayloadVersionException(version);
    }

    var migrated = json;
    while (version < currentSchemaVersion) {
      final step = _migrations[version];
      if (step == null) {
        throw StateError('No payload migration registered from v$version');
      }
      migrated = step(migrated);
      version++;
    }
    return {...migrated, 'version': currentSchemaVersion};
  }

  factory AppPayloadModel.fromJson(Map<String, dynamic> rawJson) {
    final json = migrate(rawJson);

    final rawThemes = json['userThemes'] as List<dynamic>? ?? const [];
    final themes = rawThemes
        .map((e) => UserThemeModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawHabits = json['habits'] as List<dynamic>? ?? const [];
    final habits = rawHabits
        .map((e) => HabitModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return AppPayloadModel(
      version: json['version'] as int,
      lastModifiedBy: json['lastModifiedBy'] as String? ?? 'unknown',
      lastModifiedAt: json['lastModifiedAt'] != null
          ? DateTime.parse(json['lastModifiedAt'] as String)
          : DateTime.now(),
      activeThemeId:
          json['activeThemeId'] as String? ?? UserThemeModel.defaultTheme.id,
      userThemes: themes,
      habits: habits,
    );
  }

  /// Serializes to formatted or compact JSON string.
  String toRawJson({bool pretty = false}) {
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(toJson());
    }
    return jsonEncode(toJson());
  }

  /// Deserializes directly from raw JSON string.
  factory AppPayloadModel.fromRawJson(String rawJson) {
    final Map<String, dynamic> decoded =
        jsonDecode(rawJson) as Map<String, dynamic>;
    return AppPayloadModel.fromJson(decoded);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppPayloadModel &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          lastModifiedBy == other.lastModifiedBy &&
          activeThemeId == other.activeThemeId &&
          listEquals(userThemes, other.userThemes) &&
          listEquals(habits, other.habits);

  @override
  int get hashCode => Object.hash(
        version,
        lastModifiedBy,
        activeThemeId,
        Object.hashAll(userThemes),
        Object.hashAll(habits),
      );
}

/// Thrown when stored data was written by a newer build than this one.
class UnsupportedPayloadVersionException implements Exception {
  final int version;

  const UnsupportedPayloadVersionException(this.version);

  @override
  String toString() =>
      'UnsupportedPayloadVersionException: data is schema v$version, '
      'this build supports up to v${AppPayloadModel.currentSchemaVersion}';
}
