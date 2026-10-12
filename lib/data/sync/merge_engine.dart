import 'dart:math' as math;

import '../../features/habits/data/models/habit_model.dart';
import '../../features/themes/data/models/app_payload_model.dart';
import '../../features/themes/data/models/dynamic_theme_model.dart';

/// Serverless, conflict-free synchronization engine that merges dynamic
/// user-created themes, custom habits, and check-in history across devices.
class MergeEngine {
  const MergeEngine._();

  /// Functional wrapper for [mergePayloads].
  static AppPayloadModel merge({
    required AppPayloadModel local,
    required AppPayloadModel incoming,
  }) {
    return mergePayloads(local: local, incoming: incoming);
  }
}

/// Merges two [AppPayloadModel] containers conflict-free:
/// 1. Habit Merge: Union habit records by UUID. Check-ins merge additively
///    ({...local.checkIns, ...remote.checkIns}). Conflicting habit metadata
///    resolves via latest [lastModifiedAt].
/// 2. Dynamic Theme Merge: Union [userThemes] lists by theme [id]. If edited
///    on two devices, the newest [lastModifiedAt] wins.
/// 3. Never lose user data during offline merges across devices.
AppPayloadModel mergePayloads({
  required AppPayloadModel local,
  required AppPayloadModel incoming,
}) {
  // 1. Merge habits and check-in history
  final mergedHabits = _mergeHabits(local.habits, incoming.habits);

  // 2. Merge user-created and built-in themes
  final mergedThemes = _mergeThemes(local.userThemes, incoming.userThemes);

  // 3. Resolve active theme
  final bool incomingIsNewer =
      incoming.lastModifiedAt.isAfter(local.lastModifiedAt);
  final candidateActiveThemeId =
      incomingIsNewer ? incoming.activeThemeId : local.activeThemeId;
  final resolvedActiveThemeId =
      mergedThemes.any((t) => t.id == candidateActiveThemeId)
          ? candidateActiveThemeId
          : (mergedThemes.any((t) => t.id == local.activeThemeId)
              ? local.activeThemeId
              : (mergedThemes.isNotEmpty
                  ? mergedThemes.first.id
                  : UserThemeModel.nordicSerenity.id));

  // 4. Resolve metadata
  final latestTimestamp =
      incomingIsNewer ? incoming.lastModifiedAt : local.lastModifiedAt;
  final mergedVersion = math.max(local.version, incoming.version);
  final mergedLastModifiedBy =
      incomingIsNewer ? incoming.lastModifiedBy : local.lastModifiedBy;

  return AppPayloadModel(
    version: mergedVersion,
    lastModifiedBy: mergedLastModifiedBy,
    lastModifiedAt: latestTimestamp,
    activeThemeId: resolvedActiveThemeId,
    userThemes: mergedThemes,
    habits: mergedHabits,
  );
}

/// Merges two lists of habits additively:
/// - Union by habit UUID
/// - Additive check-in union: every day marked as completed on either device is preserved
/// - Metadata conflicts (title, routine, emoji, frequency, etc.) resolve via latest [lastModifiedAt]
List<HabitModel> _mergeHabits(
  List<HabitModel> localHabits,
  List<HabitModel> incomingHabits,
) {
  final localMap = {for (final h in localHabits) h.id: h};
  final incomingMap = {for (final h in incomingHabits) h.id: h};

  // Preserve local order, then append incoming unique habits
  final allIds = <String>[
    ...localHabits.map((h) => h.id),
    ...incomingHabits.map((h) => h.id).where((id) => !localMap.containsKey(id)),
  ];

  final merged = <HabitModel>[];

  for (final id in allIds) {
    final localHabit = localMap[id];
    final incomingHabit = incomingMap[id];

    if (localHabit != null && incomingHabit == null) {
      // Habit exists only locally: preserve
      merged.add(localHabit);
    } else if (localHabit == null && incomingHabit != null) {
      // Habit exists only incoming: preserve
      merged.add(incomingHabit);
    } else if (localHabit != null && incomingHabit != null) {
      // Habit exists on both devices: resolve conflict
      // A. Additive check-in union:
      final mergedCheckIns = <String, bool>{};
      final allDates = {
        ...localHabit.checkIns.keys,
        ...incomingHabit.checkIns.keys,
      };
      for (final date in allDates) {
        if (localHabit.checkIns[date] == true ||
            incomingHabit.checkIns[date] == true) {
          mergedCheckIns[date] = true;
        }
      }

      // B. Metadata conflict resolution via latest lastModifiedAt (or createdAt)
      final localTime = localHabit.lastModifiedAt ?? localHabit.createdAt;
      final incomingTime =
          incomingHabit.lastModifiedAt ?? incomingHabit.createdAt;

      final HabitModel baseHabit;
      final DateTime resolvedModifiedAt;
      if (incomingTime.isAfter(localTime)) {
        baseHabit = incomingHabit;
        resolvedModifiedAt = incomingTime;
      } else {
        baseHabit = localHabit;
        resolvedModifiedAt = localTime;
      }

      merged.add(
        baseHabit.copyWith(
          checkIns: mergedCheckIns,
          lastModifiedAt: resolvedModifiedAt,
        ),
      );
    }
  }

  return merged;
}

/// Merges user-created and built-in themes:
/// - Union by theme ID
/// - Built-in presets are preserved
/// - Conflicting custom theme edits resolve via latest [lastModifiedAt]
List<UserThemeModel> _mergeThemes(
  List<UserThemeModel> localThemes,
  List<UserThemeModel> incomingThemes,
) {
  final localMap = {for (final t in localThemes) t.id: t};
  final incomingMap = {for (final t in incomingThemes) t.id: t};

  // Preserve local order, then append incoming unique themes
  final allIds = <String>[
    ...localThemes.map((t) => t.id),
    ...incomingThemes.map((t) => t.id).where((id) => !localMap.containsKey(id)),
  ];

  final merged = <UserThemeModel>[];

  for (final id in allIds) {
    final localTheme = localMap[id];
    final incomingTheme = incomingMap[id];

    if (localTheme != null && incomingTheme == null) {
      merged.add(localTheme);
    } else if (localTheme == null && incomingTheme != null) {
      merged.add(incomingTheme);
    } else if (localTheme != null && incomingTheme != null) {
      if (localTheme.isBuiltIn && incomingTheme.isBuiltIn) {
        merged.add(localTheme);
      } else {
        // Custom theme edited on multiple devices: newest lastModifiedAt wins
        final localTime = localTheme.lastModifiedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final incomingTime = incomingTheme.lastModifiedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

        if (incomingTime.isAfter(localTime)) {
          merged.add(incomingTheme);
        } else {
          merged.add(localTheme);
        }
      }
    }
  }

  return merged;
}
