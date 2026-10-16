import 'package:flutter/foundation.dart';

/// Frequency types supported by the habit tracking engine.
enum HabitFrequencyType {
  daily,
  specificWeekdays,
  timesPerWeek,
}

/// Immutable frequency configuration for a habit.
@immutable
class HabitFrequency {
  final HabitFrequencyType type;

  /// Weekdays (1 = Monday, ..., 7 = Sunday) for [HabitFrequencyType.specificWeekdays].
  final List<int> daysOfWeek;

  /// Target completion count per week for [HabitFrequencyType.timesPerWeek].
  final int targetTimesPerWeek;

  const HabitFrequency({
    required this.type,
    this.daysOfWeek = const [],
    this.targetTimesPerWeek = 1,
  });

  const HabitFrequency.daily()
      : type = HabitFrequencyType.daily,
        daysOfWeek = const [],
        targetTimesPerWeek = 7;

  const HabitFrequency.specificWeekdays(this.daysOfWeek, [this.targetTimesPerWeek = 0])
      : type = HabitFrequencyType.specificWeekdays;

  const HabitFrequency.timesPerWeek(this.targetTimesPerWeek)
      : type = HabitFrequencyType.timesPerWeek,
        daysOfWeek = const [];

  /// Checks if this habit is scheduled to be performed on a given [date].
  bool isScheduledFor(DateTime date) {
    switch (type) {
      case HabitFrequencyType.daily:
        return true;
      case HabitFrequencyType.specificWeekdays:
        return daysOfWeek.contains(date.weekday);
      case HabitFrequencyType.timesPerWeek:
        return true;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'daysOfWeek': daysOfWeek,
      'targetTimesPerWeek': targetTimesPerWeek,
    };
  }

  factory HabitFrequency.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'daily';
    final type = HabitFrequencyType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => HabitFrequencyType.daily,
    );

    final rawDays = json['daysOfWeek'] as List<dynamic>?;
    final days = rawDays?.map((e) => (e as num).toInt()).toList() ?? const [];
    final target = (json['targetTimesPerWeek'] as num?)?.toInt() ?? 1;

    return HabitFrequency(
      type: type,
      daysOfWeek: days,
      targetTimesPerWeek: target,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitFrequency &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          listEquals(daysOfWeek, other.daysOfWeek) &&
          targetTimesPerWeek == other.targetTimesPerWeek;

  @override
  int get hashCode => Object.hash(
        type,
        Object.hashAll(daysOfWeek),
        targetTimesPerWeek,
      );
}

/// Dynamic habit model supporting flexible frequencies, custom groupings,
/// date-keyed check-ins, custom emojis, and streak calculations.
@immutable
class HabitModel {
  final String id;
  final String title;
  final String subtitle;
  final HabitFrequency frequency;
  final String routineGroup;
  final int accentIndex;
  final DateTime createdAt;
  final bool isArchived;

  /// Date-keyed completion map: "YYYY-MM-DD" -> true
  final Map<String, bool> checkIns;

  /// Optional custom emoji or visual glyph.
  final String? emoji;

  /// Optional custom color 32-bit ARGB value (overrides [accentIndex] if provided).
  final int? customColorValue;

  /// Optional Material Icon identifier (e.g. 'fitness_center', 'water_drop').
  final String? iconCode;

  /// Optional scheduled daily reminder time string (e.g. '08:30').
  final String? reminderTime;

  /// Audit timestamp for the latest check-in or property modification.
  final DateTime? lastModifiedAt;

  const HabitModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.frequency,
    this.routineGroup = 'General',
    this.accentIndex = 0,
    required this.createdAt,
    this.isArchived = false,
    this.checkIns = const {},
    this.emoji,
    this.customColorValue,
    this.iconCode,
    this.reminderTime,
    this.lastModifiedAt,
  });

  /// Formats a [DateTime] into standard "YYYY-MM-DD" string key.
  static String formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Parses a "YYYY-MM-DD" key into normalized [DateTime] at 00:00:00.
  static DateTime parseDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Checks if this habit is marked completed on [date].
  bool isCompletedOn(DateTime date) {
    return checkIns[formatDate(date)] == true;
  }

  /// Returns a copy of this habit with completion toggled for [date].
  HabitModel toggleCheckIn(DateTime date) {
    final key = formatDate(date);
    final updated = Map<String, bool>.from(checkIns);
    if (updated[key] == true) {
      updated.remove(key);
    } else {
      updated[key] = true;
    }
    return copyWith(
      checkIns: updated,
      lastModifiedAt: DateTime.now(),
    );
  }

  /// Visual emoji representation with smart fallback derived from routine or title keywords.
  String get displayEmoji {
    if (emoji != null && emoji!.trim().isNotEmpty) return emoji!.trim();
    final lower = '${title.toLowerCase()} ${routineGroup.toLowerCase()}';
    if (lower.contains('sun') || lower.contains('morning') || lower.contains('wake')) return '☀️';
    if (lower.contains('focus') || lower.contains('code') || lower.contains('deep') || lower.contains('sprint')) return '⚡';
    if (lower.contains('water') || lower.contains('hydrat')) return '💧';
    if (lower.contains('journal') || lower.contains('gratitude') || lower.contains('read') || lower.contains('book')) return '📖';
    if (lower.contains('night') || lower.contains('sleep') || lower.contains('evening') || lower.contains('bed')) return '🌙';
    if (lower.contains('gym') || lower.contains('workout') || lower.contains('train') || lower.contains('fitness') || lower.contains('run') || lower.contains('strength')) return '💪';
    if (lower.contains('meditat') || lower.contains('breath') || lower.contains('mind')) return '🧘';
    if (lower.contains('walk') || lower.contains('step')) return '🚶';
    return '🎯';
  }

  /// Current active streak.
  int get currentStreak => calculateCurrentStreak();

  /// Longest historical streak.
  int get longestStreak => calculateLongestStreak();

  /// Calculates current streak as of [asOf] (defaults to DateTime.now()).
  int calculateCurrentStreak({DateTime? asOf}) {
    if (checkIns.isEmpty) return 0;

    final now = asOf ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (frequency.type) {
      case HabitFrequencyType.daily:
        return _calculateDailyCurrentStreak(today);
      case HabitFrequencyType.specificWeekdays:
        return _calculateSpecificWeekdaysCurrentStreak(today);
      case HabitFrequencyType.timesPerWeek:
        return _calculateTimesPerWeekCurrentStreak(today);
    }
  }

  int _calculateDailyCurrentStreak(DateTime today) {
    final isTodayDone = isCompletedOn(today);
    final yesterday = today.subtract(const Duration(days: 1));
    final isYesterdayDone = isCompletedOn(yesterday);

    if (!isTodayDone && !isYesterdayDone) {
      return 0;
    }

    int streak = 0;
    DateTime cursor = isTodayDone ? today : yesterday;

    while (isCompletedOn(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int _calculateSpecificWeekdaysCurrentStreak(DateTime today) {
    final scheduledDays = frequency.daysOfWeek;
    if (scheduledDays.isEmpty) return 0;

    DateTime? cursor;

    if (scheduledDays.contains(today.weekday)) {
      if (isCompletedOn(today)) {
        cursor = today;
      } else {
        cursor = _previousScheduledDay(today, scheduledDays);
        if (cursor == null || !isCompletedOn(cursor)) {
          return 0;
        }
      }
    } else {
      cursor = _previousScheduledDay(today, scheduledDays);
      if (cursor == null || !isCompletedOn(cursor)) {
        return 0;
      }
    }

    int streak = 0;
    while (cursor != null && isCompletedOn(cursor)) {
      streak++;
      cursor = _previousScheduledDay(cursor, scheduledDays);
    }

    return streak;
  }

  DateTime? _previousScheduledDay(DateTime from, List<int> scheduledDays) {
    DateTime cursor = from.subtract(const Duration(days: 1));
    for (int i = 0; i < 14; i++) {
      if (scheduledDays.contains(cursor.weekday)) {
        return cursor;
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return null;
  }

  int _calculateTimesPerWeekCurrentStreak(DateTime today) {
    final target = frequency.targetTimesPerWeek;
    if (target <= 0) return 0;

    final currentMonday = today.subtract(Duration(days: today.weekday - 1));
    final currentWeekCount = _checkInsInWeek(currentMonday);

    DateTime checkMonday;
    int streak = 0;

    if (currentWeekCount >= target) {
      streak++;
      checkMonday = currentMonday.subtract(const Duration(days: 7));
    } else {
      final prevMonday = currentMonday.subtract(const Duration(days: 7));
      if (_checkInsInWeek(prevMonday) >= target) {
        checkMonday = prevMonday;
      } else {
        return 0;
      }
    }

    while (_checkInsInWeek(checkMonday) >= target) {
      streak++;
      checkMonday = checkMonday.subtract(const Duration(days: 7));
    }

    return streak;
  }

  int _checkInsInWeek(DateTime monday) {
    int count = 0;
    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      if (isCompletedOn(day)) {
        count++;
      }
    }
    return count;
  }

  /// Calculates longest historical streak across all recorded check-ins.
  int calculateLongestStreak() {
    final completedDates = checkIns.entries
        .where((e) => e.value == true)
        .map((e) => parseDate(e.key))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    if (completedDates.isEmpty) return 0;

    switch (frequency.type) {
      case HabitFrequencyType.daily:
        return _calculateDailyLongestStreak(completedDates);
      case HabitFrequencyType.specificWeekdays:
        return _calculateSpecificWeekdaysLongestStreak(completedDates);
      case HabitFrequencyType.timesPerWeek:
        return _calculateTimesPerWeekLongestStreak(completedDates);
    }
  }

  int _calculateDailyLongestStreak(List<DateTime> completedDates) {
    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < completedDates.length; i++) {
      final prev = completedDates[i - 1];
      final curr = completedDates[i];
      final diff = curr.difference(prev).inDays;

      if (diff == 1) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else if (diff == 0) {
        continue;
      } else {
        currentStreak = 1;
      }
    }

    return maxStreak;
  }

  int _calculateSpecificWeekdaysLongestStreak(List<DateTime> completedDates) {
    final scheduledDays = frequency.daysOfWeek;
    if (scheduledDays.isEmpty) return 0;

    final start = completedDates.first;
    final end = completedDates.last;

    int maxStreak = 0;
    int currentStreak = 0;
    DateTime cursor = start;

    while (!cursor.isAfter(end)) {
      if (scheduledDays.contains(cursor.weekday)) {
        if (isCompletedOn(cursor)) {
          currentStreak++;
          if (currentStreak > maxStreak) {
            maxStreak = currentStreak;
          }
        } else {
          currentStreak = 0;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return maxStreak;
  }

  int _calculateTimesPerWeekLongestStreak(List<DateTime> completedDates) {
    final target = frequency.targetTimesPerWeek;
    if (target <= 0) return 0;

    final first = completedDates.first;
    final last = completedDates.last;

    final startMonday = first.subtract(Duration(days: first.weekday - 1));
    final endMonday = last.subtract(Duration(days: last.weekday - 1));

    int maxStreak = 0;
    int currentStreak = 0;
    DateTime cursorMonday = startMonday;

    while (!cursorMonday.isAfter(endMonday)) {
      if (_checkInsInWeek(cursorMonday) >= target) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
      cursorMonday = cursorMonday.add(const Duration(days: 7));
    }

    return maxStreak;
  }

  HabitModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    HabitFrequency? frequency,
    String? routineGroup,
    int? accentIndex,
    DateTime? createdAt,
    bool? isArchived,
    Map<String, bool>? checkIns,
    String? emoji,
    int? customColorValue,
    String? iconCode,
    String? reminderTime,
    DateTime? lastModifiedAt,
    bool clearEmoji = false,
    bool clearCustomColor = false,
    bool clearIconCode = false,
    bool clearReminderTime = false,
  }) {
    return HabitModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      frequency: frequency ?? this.frequency,
      routineGroup: routineGroup ?? this.routineGroup,
      accentIndex: accentIndex ?? this.accentIndex,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
      checkIns: checkIns != null
          ? Map.unmodifiable(checkIns)
          : this.checkIns,
      emoji: clearEmoji ? null : (emoji ?? this.emoji),
      customColorValue:
          clearCustomColor ? null : (customColorValue ?? this.customColorValue),
      iconCode: clearIconCode ? null : (iconCode ?? this.iconCode),
      reminderTime:
          clearReminderTime ? null : (reminderTime ?? this.reminderTime),
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'frequency': frequency.toJson(),
      'routineGroup': routineGroup,
      'accentIndex': accentIndex,
      'createdAt': createdAt.toIso8601String(),
      'isArchived': isArchived,
      'checkIns': checkIns,
      if (emoji != null) 'emoji': emoji,
      if (customColorValue != null) 'customColorValue': customColorValue,
      if (iconCode != null) 'iconCode': iconCode,
      if (reminderTime != null) 'reminderTime': reminderTime,
      if (lastModifiedAt != null) 'lastModifiedAt': lastModifiedAt!.toIso8601String(),
    };
  }

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    final rawCheckIns = json['checkIns'] as Map<String, dynamic>?;
    final checkInsMap = <String, bool>{};
    if (rawCheckIns != null) {
      for (final entry in rawCheckIns.entries) {
        checkInsMap[entry.key] = entry.value == true;
      }
    }

    return HabitModel(
      id: json['id'] as String? ?? 'habit_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      frequency: json['frequency'] != null
          ? HabitFrequency.fromJson(json['frequency'] as Map<String, dynamic>)
          : const HabitFrequency.daily(),
      routineGroup: json['routineGroup'] as String? ?? 'General',
      accentIndex: (json['accentIndex'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isArchived: json['isArchived'] as bool? ?? false,
      checkIns: checkInsMap,
      emoji: json['emoji'] as String?,
      customColorValue: (json['customColorValue'] as num?)?.toInt(),
      iconCode: json['iconCode'] as String?,
      reminderTime: json['reminderTime'] as String?,
      lastModifiedAt: json['lastModifiedAt'] != null
          ? DateTime.parse(json['lastModifiedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          subtitle == other.subtitle &&
          frequency == other.frequency &&
          routineGroup == other.routineGroup &&
          accentIndex == other.accentIndex &&
          createdAt == other.createdAt &&
          isArchived == other.isArchived &&
          emoji == other.emoji &&
          customColorValue == other.customColorValue &&
          iconCode == other.iconCode &&
          reminderTime == other.reminderTime &&
          mapEquals(checkIns, other.checkIns);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        subtitle,
        frequency,
        routineGroup,
        accentIndex,
        createdAt,
        isArchived,
        emoji,
        customColorValue,
        iconCode,
        reminderTime,
        // Order-independent so equal maps (see mapEquals in ==) always hash
        // the same regardless of insertion order.
        Object.hashAllUnordered(
          checkIns.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );
}
