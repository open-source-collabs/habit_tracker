import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../habits/data/models/habit_model.dart';
import 'dynamic_theme_model.dart';

/// Root JSON container persisting the application state, custom themes,
/// and dynamic habit tracking entities.
@immutable
class AppPayloadModel {
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
      version: 1,
      lastModifiedBy: lastModifiedBy,
      lastModifiedAt: DateTime.now(),
      activeThemeId: activeThemeId ?? UserThemeModel.obsidianTwilight.id,
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

  factory AppPayloadModel.fromJson(Map<String, dynamic> json) {
    final rawThemes = json['userThemes'] as List<dynamic>? ?? const [];
    final themes = rawThemes
        .map((e) => UserThemeModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawHabits = json['habits'] as List<dynamic>? ?? const [];
    final habits = rawHabits
        .map((e) => HabitModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return AppPayloadModel(
      version: (json['version'] as num?)?.toInt() ?? 1,
      lastModifiedBy: json['lastModifiedBy'] as String? ?? 'unknown',
      lastModifiedAt: json['lastModifiedAt'] != null
          ? DateTime.parse(json['lastModifiedAt'] as String)
          : DateTime.now(),
      activeThemeId:
          json['activeThemeId'] as String? ?? UserThemeModel.nordicSerenity.id,
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
