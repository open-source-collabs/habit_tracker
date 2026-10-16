import 'dart:math' as math;

import '../../habits/data/models/habit_model.dart';
import '../../themes/data/models/app_payload_model.dart';
import '../../themes/data/models/dynamic_theme_model.dart';

/// Merges two copies of the app payload (e.g. this device's and the copy in
/// the user's cloud) into one that both devices can adopt.
///
/// Properties the sync design relies on (all covered by tests):
/// - **Commutative and idempotent** in content: merging A into B or B into A
///   yields the same habits, themes, and tombstones; merging twice changes
///   nothing.
/// - **Per-day check-ins**: each day resolves independently by its change
///   time (`checkInChangedAt`), so a check on one device and an un-check on
///   another resolve to whichever happened last. Days without a recorded time
///   (data from before schema v2) count as earliest; if neither side has a
///   time, a check on either side wins, so legacy history is never lost.
/// - **Deletions propagate**: a tombstone removes a habit or theme unless it
///   was modified after the deletion (a later edit elsewhere keeps it).
/// - **Metadata** (title, frequency, colors, …) resolves to the newest
///   `lastModifiedAt`.
abstract final class MergeEngine {
  static AppPayloadModel merge({
    required AppPayloadModel local,
    required AppPayloadModel incoming,
  }) => mergePayloads(local: local, incoming: incoming);
}

AppPayloadModel mergePayloads({
  required AppPayloadModel local,
  required AppPayloadModel incoming,
}) {
  final deletedHabits = _mergeTombstones(
    local.deletedHabits,
    incoming.deletedHabits,
  );
  final deletedThemes = _mergeTombstones(
    local.deletedThemes,
    incoming.deletedThemes,
  );

  final habits =
      _mergeById<HabitModel>(
            local.habits,
            incoming.habits,
            id: (h) => h.id,
            resolve: _mergeHabit,
          )
          .where(
            (h) => !_isDeleted(
              deletedHabits[h.id],
              h.lastModifiedAt ?? h.createdAt,
            ),
          )
          .toList();

  final themes =
      _mergeById<UserThemeModel>(
            local.userThemes,
            incoming.userThemes,
            id: (t) => t.id,
            resolve: _mergeTheme,
          )
          .where(
            (t) =>
                t.isBuiltIn ||
                !_isDeleted(
                  deletedThemes[t.id],
                  t.lastModifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                ),
          )
          .toList();

  final incomingIsNewer = incoming.lastModifiedAt.isAfter(local.lastModifiedAt);
  final newer = incomingIsNewer ? incoming : local;
  final older = incomingIsNewer ? local : incoming;

  // Active theme: the newer payload's choice, if that theme still exists.
  final themeIds = {
    ...themes.map((t) => t.id),
    ...UserThemeModel.builtInPresets.map((t) => t.id),
  };
  final activeThemeId =
      [
        newer.activeThemeId,
        older.activeThemeId,
      ].where(themeIds.contains).firstOrNull ??
      UserThemeModel.defaultTheme.id;

  return AppPayloadModel(
    version: math.max(local.version, incoming.version),
    lastModifiedBy: newer.lastModifiedBy,
    lastModifiedAt: newer.lastModifiedAt,
    activeThemeId: activeThemeId,
    userThemes: themes,
    habits: habits,
    displayName: newer.displayName.isNotEmpty
        ? newer.displayName
        : older.displayName,
    deletedHabits: deletedHabits,
    deletedThemes: deletedThemes,
  );
}

/// Deleted at or after its last modification → stays deleted.
bool _isDeleted(DateTime? deletedAt, DateTime lastModified) =>
    deletedAt != null && !deletedAt.isBefore(lastModified);

Map<String, DateTime> _mergeTombstones(
  Map<String, DateTime> a,
  Map<String, DateTime> b,
) {
  final merged = Map<String, DateTime>.from(a);
  for (final entry in b.entries) {
    final existing = merged[entry.key];
    if (existing == null || entry.value.isAfter(existing)) {
      merged[entry.key] = entry.value;
    }
  }
  return merged;
}

/// Union by id, keeping local order and appending incoming-only items.
List<T> _mergeById<T>(
  List<T> local,
  List<T> incoming, {
  required String Function(T) id,
  required T Function(T local, T incoming) resolve,
}) {
  final incomingById = {for (final item in incoming) id(item): item};
  final localIds = local.map(id).toSet();
  return [
    for (final item in local)
      incomingById.containsKey(id(item))
          ? resolve(item, incomingById[id(item)] as T)
          : item,
    for (final item in incoming)
      if (!localIds.contains(id(item))) item,
  ];
}

HabitModel _mergeHabit(HabitModel local, HabitModel incoming) {
  final localTime = local.lastModifiedAt ?? local.createdAt;
  final incomingTime = incoming.lastModifiedAt ?? incoming.createdAt;
  // Ties go to the lexicographically larger id-stable side so the result
  // doesn't depend on which device performs the merge.
  final base =
      incomingTime.isAfter(localTime) ||
          (incomingTime == localTime &&
              incoming.toJson().toString().compareTo(
                    local.toJson().toString(),
                  ) >
                  0)
      ? incoming
      : local;

  final checkIns = <String, bool>{};
  final changedAt = <String, int>{};
  final days = {
    ...local.checkIns.keys,
    ...incoming.checkIns.keys,
    ...local.checkInChangedAt.keys,
    ...incoming.checkInChangedAt.keys,
  };

  for (final day in days) {
    final localDone = local.checkIns[day] == true;
    final incomingDone = incoming.checkIns[day] == true;
    final localAt = local.checkInChangedAt[day];
    final incomingAt = incoming.checkInChangedAt[day];

    final bool done;
    if (localAt == null && incomingAt == null) {
      done = localDone || incomingDone;
    } else if (localAt == null) {
      done = incomingDone;
    } else if (incomingAt == null) {
      done = localDone;
    } else if (localAt == incomingAt) {
      done = localDone || incomingDone;
    } else {
      done = localAt > incomingAt ? localDone : incomingDone;
    }

    if (done) checkIns[day] = true;
    final latest = [localAt, incomingAt].whereType<int>().fold<int?>(
      null,
      (max, t) => max == null || t > max ? t : max,
    );
    if (latest != null) changedAt[day] = latest;
  }

  return base.copyWith(
    checkIns: checkIns,
    checkInChangedAt: changedAt,
    lastModifiedAt: localTime.isAfter(incomingTime) ? localTime : incomingTime,
  );
}

UserThemeModel _mergeTheme(UserThemeModel local, UserThemeModel incoming) {
  if (local.isBuiltIn && incoming.isBuiltIn) return local;
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  final localTime = local.lastModifiedAt ?? epoch;
  final incomingTime = incoming.lastModifiedAt ?? epoch;
  return incomingTime.isAfter(localTime) ? incoming : local;
}
