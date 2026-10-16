import 'package:flutter/foundation.dart';

import '../../features/habits/data/models/habit_model.dart';

/// One recurring notification: daily when [weekday] is null, otherwise weekly
/// on that weekday (1 = Monday … 7 = Sunday).
@immutable
class ReminderSlot {
  final int id;
  final int? weekday;
  final int hour;
  final int minute;

  const ReminderSlot({
    required this.id,
    required this.weekday,
    required this.hour,
    required this.minute,
  });

  @override
  bool operator ==(Object other) =>
      other is ReminderSlot &&
      other.id == id &&
      other.weekday == weekday &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(id, weekday, hour, minute);

  @override
  String toString() => 'ReminderSlot(id: $id, weekday: $weekday, '
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')})';
}

/// Pure planning of habit reminders, independent of the notification plugin.
///
/// Each habit owns a block of 8 consecutive notification ids: offset 0 for a
/// daily reminder and offsets 1–7 for weekday-specific ones. Ids derive from
/// a stable FNV-1a hash of the habit id, so they survive restarts (unlike
/// `String.hashCode`) and can always be cancelled.
abstract final class ReminderSchedule {
  /// Ids below this are reserved for app-level notifications (digests, tests).
  static const int reservedIdCeiling = 0x100000;

  static const int _slotsPerHabit = 8;

  /// First id of [habitId]'s block. Always ≥ [reservedIdCeiling] and the
  /// whole block fits in a signed 32-bit int (Android's notification id).
  static int baseId(String habitId) {
    const maxBlocks = (0x80000000 - reservedIdCeiling) ~/ _slotsPerHabit;
    final block = fnv1a32(habitId) % maxBlocks;
    return reservedIdCeiling + block * _slotsPerHabit;
  }

  /// Every id [habitId] could be scheduled under (for cancellation).
  static List<int> allIds(String habitId) {
    final base = baseId(habitId);
    return [for (var i = 0; i < _slotsPerHabit; i++) base + i];
  }

  /// The notifications [habit] should have right now. Empty when it has no
  /// valid reminder time or is archived.
  static List<ReminderSlot> slotsFor(HabitModel habit) {
    final time = parseTime(habit.reminderTime);
    if (time == null || habit.isArchived) return const [];

    final base = baseId(habit.id);
    final frequency = habit.frequency;
    final weekdays = frequency.type == HabitFrequencyType.specificWeekdays
        ? (frequency.daysOfWeek.where((d) => d >= 1 && d <= 7).toSet().toList()
          ..sort())
        : const <int>[];

    // Daily and times-per-week habits can be done any day, so remind daily.
    if (weekdays.isEmpty || weekdays.length == 7) {
      return [
        ReminderSlot(id: base, weekday: null, hour: time.hour, minute: time.minute),
      ];
    }
    return [
      for (final day in weekdays)
        ReminderSlot(
          id: base + day,
          weekday: day,
          hour: time.hour,
          minute: time.minute,
        ),
    ];
  }

  /// Parses "HH:mm"; returns null for anything invalid.
  static ({int hour, int minute})? parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return (hour: hour, minute: minute);
  }

  /// Next occurrence of [hour]:[minute] (on [weekday], if given) strictly
  /// after [now], in [now]'s own time zone.
  static DateTime nextOccurrence(
    DateTime now, {
    required int hour,
    required int minute,
    int? weekday,
  }) {
    var candidate = DateTime(now.year, now.month, now.day, hour, minute);
    if (weekday != null) {
      final daysAhead = (weekday - candidate.weekday) % 7;
      candidate = DateTime(
        candidate.year,
        candidate.month,
        candidate.day + daysAhead,
        hour,
        minute,
      );
    }
    if (!candidate.isAfter(now)) {
      candidate = DateTime(
        candidate.year,
        candidate.month,
        candidate.day + (weekday != null ? 7 : 1),
        hour,
        minute,
      );
    }
    return candidate;
  }

  /// 32-bit FNV-1a. The multiply by the FNV prime (2^24 + 403) is split so
  /// every intermediate stays below 2^53 and the result is identical on the
  /// VM and on the web.
  @visibleForTesting
  static int fnv1a32(String input) {
    const twoPow32 = 0x100000000;
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash = (hash ^ unit) % twoPow32;
      hash = ((hash % 256) * 0x1000000 + hash * 403) % twoPow32;
    }
    return hash;
  }
}
