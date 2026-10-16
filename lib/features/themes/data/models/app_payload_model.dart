import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../habits/data/models/habit_model.dart';
import 'dynamic_theme_model.dart';

/// Root JSON container persisting the application state, custom themes,
/// and dynamic habit tracking entities.
///
/// Schema history:
/// - v1: habits, themes, active theme, display name.
/// - v2: deletion tombstones ([deletedHabits], [deletedThemes]) and per-day
///   check-in change times (`HabitModel.checkInChangedAt`), so deletions and
///   un-checks propagate through sync instead of being resurrected by it.
@immutable
class AppPayloadModel {
  /// Schema version written by this build. Bump it when the JSON shape
  /// changes and register a step in [_migrations] that upgrades the previous
  /// version's JSON.
  static const int currentSchemaVersion = 2;

  /// Upgrade steps keyed by the version they upgrade *from*:
  /// `_migrations[n]` turns version-n JSON into version-(n+1) JSON.
  static final Map<int, Map<String, dynamic> Function(Map<String, dynamic>)>
      _migrations = {
    // v1 → v2: v1 had no tombstones; start with none. Check-ins without a
    // change time are treated as "checked at an unknown, earliest time".
    1: (json) => {
          ...json,
          'deletedHabits': json['deletedHabits'] ?? <String, dynamic>{},
          'deletedThemes': json['deletedThemes'] ?? <String, dynamic>{},
        },
  };

  final int version;
  final String lastModifiedBy;
  final DateTime lastModifiedAt;
  final String activeThemeId;
  final List<UserThemeModel> userThemes;
  final List<HabitModel> habits;

  /// Name used to greet the user; empty when not set.
  final String displayName;

  /// Ids of deleted habits and when they were deleted. Lets sync remove a
  /// habit on other devices instead of restoring it from their copy.
  final Map<String, DateTime> deletedHabits;

  /// Ids of deleted custom themes and when they were deleted.
  final Map<String, DateTime> deletedThemes;

  const AppPayloadModel({
    required this.version,
    required this.lastModifiedBy,
    required this.lastModifiedAt,
    required this.activeThemeId,
    required this.userThemes,
    required this.habits,
    this.displayName = '',
    this.deletedHabits = const {},
    this.deletedThemes = const {},
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
    String? displayName,
    Map<String, DateTime>? deletedHabits,
    Map<String, DateTime>? deletedThemes,
  }) {
    return AppPayloadModel(
      displayName: displayName ?? this.displayName,
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
      deletedHabits: deletedHabits != null
          ? Map.unmodifiable(deletedHabits)
          : this.deletedHabits,
      deletedThemes: deletedThemes != null
          ? Map.unmodifiable(deletedThemes)
          : this.deletedThemes,
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
      if (displayName.isNotEmpty) 'displayName': displayName,
      'deletedHabits': _encodeTimes(deletedHabits),
      'deletedThemes': _encodeTimes(deletedThemes),
    };
  }

  static Map<String, String> _encodeTimes(Map<String, DateTime> times) => {
        for (final e in times.entries) e.key: e.value.toUtc().toIso8601String(),
      };

  static Map<String, DateTime> _decodeTimes(Object? raw) {
    if (raw is! Map) return const {};
    final result = <String, DateTime>{};
    for (final entry in raw.entries) {
      final parsed = entry.value is String
          ? DateTime.tryParse(entry.value as String)
          : null;
      if (parsed != null) result[entry.key as String] = parsed;
    }
    return result;
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
      displayName: json['displayName'] as String? ?? '',
      deletedHabits: _decodeTimes(json['deletedHabits']),
      deletedThemes: _decodeTimes(json['deletedThemes']),
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
          displayName == other.displayName &&
          listEquals(userThemes, other.userThemes) &&
          listEquals(habits, other.habits) &&
          _sameInstants(deletedHabits, other.deletedHabits) &&
          _sameInstants(deletedThemes, other.deletedThemes);

  /// Compares by instant: a local and a UTC [DateTime] for the same moment
  /// aren't `==`, but a tombstone read back from JSON (UTC) must equal the
  /// one created locally.
  static bool _sameInstants(Map<String, DateTime> a, Map<String, DateTime> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null || !other.isAtSameMomentAs(entry.value)) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        version,
        lastModifiedBy,
        activeThemeId,
        displayName,
        Object.hashAll(userThemes),
        Object.hashAll(habits),
        Object.hashAllUnordered(
          deletedHabits.entries.map(
            (e) => Object.hash(e.key, e.value.microsecondsSinceEpoch),
          ),
        ),
        Object.hashAllUnordered(
          deletedThemes.entries.map(
            (e) => Object.hash(e.key, e.value.microsecondsSinceEpoch),
          ),
        ),
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
