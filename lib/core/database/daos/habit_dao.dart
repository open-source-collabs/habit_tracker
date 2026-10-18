import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../../../features/habits/data/models/habit_model.dart';
import '../database_schema.dart';

/// Data Access Object for habits and their daily check-in histories.
class HabitDao {
  const HabitDao();

  /// Retrieves all persisted habits and their complete check-in histories.
  Future<List<HabitModel>> getAllHabits(
    DatabaseExecutor executor, {
    bool includeArchived = true,
  }) async {
    final habitsQuery = includeArchived
        ? 'SELECT * FROM ${DatabaseSchema.tableHabits} ORDER BY ${DatabaseSchema.colHabitCreatedAt} ASC'
        : 'SELECT * FROM ${DatabaseSchema.tableHabits} WHERE ${DatabaseSchema.colHabitIsArchived} = 0 ORDER BY ${DatabaseSchema.colHabitCreatedAt} ASC';

    final habitRows = await executor.rawQuery(habitsQuery);
    if (habitRows.isEmpty) return const [];

    // Query all check-ins in one efficient query
    final checkInRows = await executor.rawQuery(
      'SELECT * FROM ${DatabaseSchema.tableCheckIns} ORDER BY ${DatabaseSchema.colCheckInDate} ASC',
    );

    // Group check-ins and timestamps by habitId
    final checkInsByHabit = <String, Map<String, bool>>{};
    final checkInChangedAtByHabit = <String, Map<String, int>>{};

    for (final row in checkInRows) {
      final habitId = row[DatabaseSchema.colCheckInHabitId] as String;
      final date = row[DatabaseSchema.colCheckInDate] as String;
      final completed = (row[DatabaseSchema.colCheckInCompleted] as int) == 1;
      final changedAt = row[DatabaseSchema.colCheckInChangedAt] as int;

      (checkInsByHabit[habitId] ??= {})[date] = completed;
      (checkInChangedAtByHabit[habitId] ??= {})[date] = changedAt;
    }

    return habitRows.map((row) {
      final id = row[DatabaseSchema.colHabitId] as String;
      final frequencyTypeStr =
          row[DatabaseSchema.colHabitFrequencyType] as String? ?? 'daily';
      final frequencyType = HabitFrequencyType.values.firstWhere(
        (e) => e.name == frequencyTypeStr,
        orElse: () => HabitFrequencyType.daily,
      );

      final daysOfWeekJson =
          row[DatabaseSchema.colHabitDaysOfWeek] as String? ?? '[]';
      final List<int> daysOfWeek = (jsonDecode(daysOfWeekJson) as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList();

      final targetTimesPerWeek =
          row[DatabaseSchema.colHabitTargetTimesPerWeek] as int? ?? 1;

      final frequency = HabitFrequency(
        type: frequencyType,
        daysOfWeek: daysOfWeek,
        targetTimesPerWeek: targetTimesPerWeek,
      );

      final createdAtStr = row[DatabaseSchema.colHabitCreatedAt] as String;
      final lastModifiedAtStr =
          row[DatabaseSchema.colHabitLastModifiedAt] as String?;

      return HabitModel(
        id: id,
        title: row[DatabaseSchema.colHabitTitle] as String,
        subtitle: row[DatabaseSchema.colHabitSubtitle] as String? ?? '',
        frequency: frequency,
        routineGroup:
            row[DatabaseSchema.colHabitRoutineGroup] as String? ?? 'General',
        accentIndex: row[DatabaseSchema.colHabitAccentIndex] as int? ?? 0,
        createdAt: DateTime.parse(createdAtStr),
        isArchived: (row[DatabaseSchema.colHabitIsArchived] as int? ?? 0) == 1,
        checkIns: checkInsByHabit[id] ?? const {},
        checkInChangedAt: checkInChangedAtByHabit[id] ?? const {},
        emoji: row[DatabaseSchema.colHabitEmoji] as String?,
        customColorValue: row[DatabaseSchema.colHabitCustomColorValue] as int?,
        iconCode: row[DatabaseSchema.colHabitIconCode] as String?,
        reminderTime: row[DatabaseSchema.colHabitReminderTime] as String?,
        lastModifiedAt: lastModifiedAtStr != null
            ? DateTime.tryParse(lastModifiedAtStr)
            : null,
      );
    }).toList();
  }

  /// Transactionally reconciles the entire habit list, updating, adding, or removing entries.
  Future<void> syncHabits(
    DatabaseExecutor executor,
    List<HabitModel> habits,
  ) async {
    final existingRows = await executor.query(
      DatabaseSchema.tableHabits,
      columns: [DatabaseSchema.colHabitId],
    );
    final existingIds = existingRows
        .map((r) => r[DatabaseSchema.colHabitId] as String)
        .toSet();

    final currentIds = habits.map((h) => h.id).toSet();
    final idsToDelete = existingIds.difference(currentIds);

    for (final id in idsToDelete) {
      await deleteHabit(executor, id);
    }

    for (final habit in habits) {
      await upsertHabit(executor, habit);
    }
  }

  /// Upserts a habit and all of its check-ins.
  Future<void> upsertHabit(DatabaseExecutor executor, HabitModel habit) async {
    await executor.insert(
      DatabaseSchema.tableHabits,
      {
        DatabaseSchema.colHabitId: habit.id,
        DatabaseSchema.colHabitTitle: habit.title,
        DatabaseSchema.colHabitSubtitle: habit.subtitle,
        DatabaseSchema.colHabitFrequencyType: habit.frequency.type.name,
        DatabaseSchema.colHabitDaysOfWeek:
            jsonEncode(habit.frequency.daysOfWeek),
        DatabaseSchema.colHabitTargetTimesPerWeek:
            habit.frequency.targetTimesPerWeek,
        DatabaseSchema.colHabitRoutineGroup: habit.routineGroup,
        DatabaseSchema.colHabitAccentIndex: habit.accentIndex,
        DatabaseSchema.colHabitCreatedAt: habit.createdAt.toIso8601String(),
        DatabaseSchema.colHabitIsArchived: habit.isArchived ? 1 : 0,
        DatabaseSchema.colHabitEmoji: habit.emoji,
        DatabaseSchema.colHabitCustomColorValue: habit.customColorValue,
        DatabaseSchema.colHabitIconCode: habit.iconCode,
        DatabaseSchema.colHabitReminderTime: habit.reminderTime,
        DatabaseSchema.colHabitLastModifiedAt:
            habit.lastModifiedAt?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Synchronize check-ins for this habit
    if (habit.checkIns.isNotEmpty || habit.checkInChangedAt.isNotEmpty) {
      final allDates = {
        ...habit.checkIns.keys,
        ...habit.checkInChangedAt.keys,
      };

      for (final date in allDates) {
        final completed = habit.checkIns[date] ?? false;
        final changedAt = habit.checkInChangedAt[date] ?? 0;

        await executor.insert(
          DatabaseSchema.tableCheckIns,
          {
            DatabaseSchema.colCheckInHabitId: habit.id,
            DatabaseSchema.colCheckInDate: date,
            DatabaseSchema.colCheckInCompleted: completed ? 1 : 0,
            DatabaseSchema.colCheckInChangedAt: changedAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  /// Deletes a habit by [id]. Check-ins cascade delete via foreign key constraint.
  Future<void> deleteHabit(DatabaseExecutor executor, String id) async {
    await executor.delete(
      DatabaseSchema.tableHabits,
      where: '${DatabaseSchema.colHabitId} = ?',
      whereArgs: [id],
    );
  }

  /// Toggles or updates a single day's check-in status directly in SQLite.
  Future<void> setCheckIn(
    DatabaseExecutor executor, {
    required String habitId,
    required String date,
    required bool completed,
    required int changedAtMs,
  }) async {
    await executor.insert(
      DatabaseSchema.tableCheckIns,
      {
        DatabaseSchema.colCheckInHabitId: habitId,
        DatabaseSchema.colCheckInDate: date,
        DatabaseSchema.colCheckInCompleted: completed ? 1 : 0,
        DatabaseSchema.colCheckInChangedAt: changedAtMs,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Truncates habits and check-ins.
  Future<void> clear(DatabaseExecutor executor) async {
    await executor.delete(DatabaseSchema.tableCheckIns);
    await executor.delete(DatabaseSchema.tableHabits);
  }
}
