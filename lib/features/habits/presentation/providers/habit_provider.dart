import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:habit_tracker/core/widgets_kit/habit_widget_sync_service.dart';
import '../../../../core/data/app_data_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../../themes/presentation/providers/theme_provider.dart';
import '../../data/models/habit_model.dart';

export '../../../../core/data/app_data_repository.dart'
    show appDataRepositoryProvider, habitStorageProvider;

/// Currently selected date for inspecting or checking off habits (defaults to today).
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Filter value showing every active habit.
const String kAllHabitsFilter = 'All';

/// Filter value showing archived (paused) habits instead of active ones.
const String kArchivedHabitsFilter = 'Archived';

/// Active routine category filter: [kAllHabitsFilter], a routine group name,
/// or [kArchivedHabitsFilter].
final activeRoutineFilterProvider =
    StateProvider<String>((ref) => kAllHabitsFilter);

/// Tracks heatmap expansion toggle state per habit ID.
final habitHeatmapExpandedProvider = StateProvider.family<bool, String>((ref, habitId) => false);

/// Notifier managing habit state with 0ms optimistic updates and asynchronous persistence.
///
/// If stored data cannot be read, the state becomes an [AsyncError] and every
/// mutation is ignored until the user retries or explicitly starts fresh, so
/// damaged data is never overwritten.
class HabitListNotifier extends AsyncNotifier<List<HabitModel>> {
  bool _disposed = false;

  @override
  Future<List<HabitModel>> build() async {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    final repository = ref.watch(appDataRepositoryProvider);
    final snapshot = await repository.load();

    var habits = snapshot.payload.habits;
    if (snapshot.isFirstRun) {
      habits = _generateStarterHabits();
      unawaited(_persist(habits));
    } else {
      Future.microtask(() => _syncWidgets(habits));
    }
    return habits;
  }

  /// Re-attempts loading stored data after a failure.
  void retryLoad() {
    ref.invalidate(themeProvider);
    ref.invalidateSelf();
  }

  /// Abandons unreadable stored data and starts with an empty habit list.
  /// Storage keeps a copy of the damaged record.
  Future<void> discardUnreadableData() async {
    await ref.read(appDataRepositoryProvider).discardStoredData();
    retryLoad();
  }

  /// Optimistically toggles habit check-in status for [date] with 0ms latency
  /// and writes to local storage asynchronously in the background.
  /// Dates after today are ignored.
  Future<void> toggleHabit(String habitId, DateTime date) async {
    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    if (day.isAfter(DateTime(now.year, now.month, now.day))) return;

    final currentList = state.valueOrNull;
    if (currentList == null) return;
    final habitIndex = currentList.indexWhere((h) => h.id == habitId);
    if (habitIndex == -1) return;

    final targetHabit = currentList[habitIndex];
    if (targetHabit.isArchived) return;
    final updatedHabit = targetHabit.toggleCheckIn(date);

    final updatedList = List<HabitModel>.from(currentList);
    updatedList[habitIndex] = updatedHabit;

    state = AsyncData(updatedList);
    await _persist(updatedList);
  }

  /// Creates and appends a new dynamic habit with optimistic UI update.
  Future<void> createHabit(HabitModel habit) async {
    final currentList = state.valueOrNull;
    if (currentList == null) return;
    final notifications = ref.read(notificationServiceProvider);
    final updatedHabit = habit.copyWith(lastModifiedAt: DateTime.now());
    final updatedList = [...currentList, updatedHabit];

    state = AsyncData(updatedList);
    unawaited(notifications.syncHabitReminder(updatedHabit));
    await _persist(updatedList);
  }

  /// Updates an existing habit's configuration or frequency.
  Future<void> updateHabit(HabitModel habit) async {
    final currentList = state.valueOrNull;
    if (currentList == null) return;
    final index = currentList.indexWhere((h) => h.id == habit.id);
    if (index == -1) return;

    final notifications = ref.read(notificationServiceProvider);
    final updatedHabit = habit.copyWith(lastModifiedAt: DateTime.now());
    final updatedList = List<HabitModel>.from(currentList);
    updatedList[index] = updatedHabit;

    state = AsyncData(updatedList);
    unawaited(notifications.syncHabitReminder(updatedHabit));
    await _persist(updatedList);
  }

  /// Removes a habit by [habitId], cancels its reminder, and persists.
  ///
  /// Returns the removed habit and its position so the caller can offer undo
  /// via [restoreHabit], or `null` if no such habit exists.
  Future<({HabitModel habit, int index})?> deleteHabit(String habitId) async {
    final currentList = state.valueOrNull;
    if (currentList == null) return null;
    final index = currentList.indexWhere((h) => h.id == habitId);
    if (index == -1) return null;

    final removed = currentList[index];
    final notifications = ref.read(notificationServiceProvider);
    final updatedList = List<HabitModel>.from(currentList)..removeAt(index);

    state = AsyncData(updatedList);
    unawaited(notifications.cancelHabitReminder(habitId));
    // The tombstone makes the deletion reach other devices through sync.
    final deletedAt = DateTime.now();
    await _persist(
      updatedList,
      tombstones: (t) => {...t, habitId: deletedAt},
    );
    return (habit: removed, index: index);
  }

  /// Re-inserts a previously deleted [habit] (e.g. from an undo action) at
  /// [index], restoring its reminder.
  Future<void> restoreHabit(HabitModel habit, {int? index}) async {
    final currentList = state.valueOrNull;
    if (currentList == null || currentList.any((h) => h.id == habit.id)) {
      return;
    }
    final notifications = ref.read(notificationServiceProvider);
    // Restoring counts as a modification after the deletion, so it also wins
    // over the tombstone on devices that already received it.
    final restored = habit.copyWith(lastModifiedAt: DateTime.now());
    final updatedList = List<HabitModel>.from(currentList)
      ..insert(
        (index ?? currentList.length).clamp(0, currentList.length),
        restored,
      );

    state = AsyncData(updatedList);
    unawaited(notifications.syncHabitReminder(restored));
    await _persist(
      updatedList,
      tombstones: (t) => Map.of(t)..remove(habit.id),
    );
  }

  /// Archives (pauses) or unarchives a habit. History is kept; archived
  /// habits can't be checked off, don't count in stats, and have no reminder.
  Future<void> setArchived(String habitId, {required bool archived}) async {
    final currentList = state.valueOrNull;
    if (currentList == null) return;
    final index = currentList.indexWhere((h) => h.id == habitId);
    if (index == -1 || currentList[index].isArchived == archived) return;

    final notifications = ref.read(notificationServiceProvider);
    final updated = currentList[index].copyWith(
      isArchived: archived,
      lastModifiedAt: DateTime.now(),
    );
    final updatedList = List<HabitModel>.from(currentList)..[index] = updated;

    state = AsyncData(updatedList);
    unawaited(notifications.syncHabitReminder(updated));
    await _persist(updatedList);
  }

  /// Restores and persists an imported collection of habits atomically, and
  /// reconciles reminders with it (habits that disappeared lose theirs).
  Future<void> restoreHabits(List<HabitModel> habits) async {
    final notifications = ref.read(notificationServiceProvider);
    state = AsyncData(habits);
    unawaited(notifications.rescheduleAll(habits));
    await _persist(habits);
  }

  /// Writes [habits] (and optionally updated deletion [tombstones]) into the
  /// app payload, then refreshes home screen widgets.
  Future<void> _persist(
    List<HabitModel> habits, {
    Map<String, DateTime> Function(Map<String, DateTime> current)? tombstones,
  }) async {
    final repository = ref.read(appDataRepositoryProvider);
    try {
      await repository.update(
        (payload) => payload.copyWith(
          habits: habits,
          deletedHabits: tombstones?.call(payload.deletedHabits),
        ),
      );
    } catch (e) {
      debugPrint('HabitListNotifier: Failed to persist habits: $e');
      return;
    }
    _syncWidgets(habits);
  }

  /// Pushes habit state to native home screen widgets via widgets_kit.
  void _syncWidgets(List<HabitModel> habits) {
    if (_disposed) return;
    try {
      final syncService = ref.read(habitWidgetSyncServiceProvider);
      unawaited(
        syncService.syncHabits(
          habits: habits,
          activeTheme: ref.read(themeProvider).activeTheme,
        ),
      );
    } catch (e) {
      debugPrint('HabitListNotifier: Error syncing widgets_kit: $e');
    }
  }

  /// Curated default habits showcasing streak calculations and theme accents.
  static List<HabitModel> _generateStarterHabits() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    return [
      HabitModel(
        id: 'habit_sunlight',
        title: 'Morning Sunlight & Breath',
        subtitle: '15 mins outdoors within 1 hour of waking',
        frequency: const HabitFrequency.daily(),
        routineGroup: 'Morning',
        accentIndex: 0,
        createdAt: today.subtract(const Duration(days: 14)),
        emoji: '☀️',
        checkIns: {
          HabitModel.formatDate(yesterday): true,
          HabitModel.formatDate(twoDaysAgo): true,
        },
      ),
      HabitModel(
        id: 'habit_focus_sprint',
        title: 'Deep Focus Sprint',
        subtitle: '90 mins uninterrupted coding or deep work',
        frequency: HabitFrequency.specificWeekdays(const [
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
        ]),
        routineGroup: 'Focus',
        accentIndex: 1,
        createdAt: today.subtract(const Duration(days: 10)),
        emoji: '⚡',
        checkIns: {
          HabitModel.formatDate(yesterday): true,
        },
      ),
      HabitModel(
        id: 'habit_hydration',
        title: 'Hydration Target (3L)',
        subtitle: 'Electrolytes & consistent water intake',
        frequency: const HabitFrequency.daily(),
        routineGroup: 'Health',
        accentIndex: 2,
        createdAt: today.subtract(const Duration(days: 7)),
        emoji: '💧',
        checkIns: {
          HabitModel.formatDate(yesterday): true,
          HabitModel.formatDate(twoDaysAgo): true,
        },
      ),
      HabitModel(
        id: 'habit_gratitude',
        title: 'Evening Gratitude Journal',
        subtitle: 'Reflect on 3 micro-wins before sleep',
        frequency: const HabitFrequency.daily(),
        routineGroup: 'Evening',
        accentIndex: 3,
        createdAt: today.subtract(const Duration(days: 21)),
        emoji: '📖',
        checkIns: {
          HabitModel.formatDate(yesterday): true,
        },
      ),
      HabitModel(
        id: 'habit_strength',
        title: 'Strength & Mobility',
        subtitle: 'Compound lifts or bodyweight circuit',
        frequency: const HabitFrequency.timesPerWeek(3),
        routineGroup: 'Fitness',
        accentIndex: 4,
        createdAt: today.subtract(const Duration(days: 30)),
        emoji: '💪',
        checkIns: {
          HabitModel.formatDate(yesterday): true,
        },
      ),
    ];
  }
}

/// Global provider for habit list state.
final habitListProvider =
    AsyncNotifierProvider<HabitListNotifier, List<HabitModel>>(
  HabitListNotifier.new,
);

/// Habits filtered by the active routine group.
final filteredHabitsProvider = Provider<List<HabitModel>>((ref) {
  final habitsAsync = ref.watch(habitListProvider);
  final filter = ref.watch(activeRoutineFilterProvider);

  final habits = habitsAsync.valueOrNull ?? const [];
  if (filter == kAllHabitsFilter) {
    return habits.where((h) => !h.isArchived).toList();
  }
  if (filter == kArchivedHabitsFilter) {
    return habits.where((h) => h.isArchived).toList();
  }
  return habits
      .where((h) => !h.isArchived && h.routineGroup.toLowerCase() == filter.toLowerCase())
      .toList();
});

/// Summary statistics for the currently selected date.
class DailyHabitStats {
  final int totalScheduled;
  final int completedCount;
  final double completionRate;
  final int activeStreaksCount;
  final int longestActiveStreak;

  const DailyHabitStats({
    required this.totalScheduled,
    required this.completedCount,
    required this.completionRate,
    required this.activeStreaksCount,
    required this.longestActiveStreak,
  });
}

/// Provider computing daily completion stats and active streaks.
final dailyHabitStatsProvider = Provider<DailyHabitStats>((ref) {
  final habits = ref.watch(habitListProvider).valueOrNull ?? const [];
  final selectedDate = ref.watch(selectedDateProvider);

  final activeHabits = habits.where((h) => !h.isArchived).toList();
  final scheduledHabits =
      activeHabits.where((h) => h.frequency.isScheduledFor(selectedDate)).toList();

  final completedCount =
      scheduledHabits.where((h) => h.isCompletedOn(selectedDate)).length;

  final totalScheduled = scheduledHabits.length;
  final completionRate =
      totalScheduled > 0 ? completedCount / totalScheduled : 0.0;

  int activeStreaksCount = 0;
  int longestStreak = 0;

  for (final habit in activeHabits) {
    final streak = habit.calculateCurrentStreak(asOf: selectedDate);
    if (streak > 0) {
      activeStreaksCount++;
      if (streak > longestStreak) {
        longestStreak = streak;
      }
    }
  }

  return DailyHabitStats(
    totalScheduled: totalScheduled,
    completedCount: completedCount,
    completionRate: completionRate,
    activeStreaksCount: activeStreaksCount,
    longestActiveStreak: longestStreak,
  );
});

/// Filter options: [kAllHabitsFilter], each routine group used by an active
/// habit, then [kArchivedHabitsFilter] when any habit is archived.
final routineGroupsProvider = Provider<List<String>>((ref) {
  final habits = ref.watch(habitListProvider).valueOrNull ?? const [];
  final groups = <String>{kAllHabitsFilter};
  var hasArchived = false;
  for (final habit in habits) {
    if (habit.isArchived) {
      hasArchived = true;
    } else if (habit.routineGroup.trim().isNotEmpty) {
      groups.add(habit.routineGroup.trim());
    }
  }
  return [...groups, if (hasArchived) kArchivedHabitsFilter];
});

/// Number of archived (paused) habits.
final archivedHabitCountProvider = Provider<int>((ref) {
  final habits = ref.watch(habitListProvider).valueOrNull ?? const [];
  return habits.where((h) => h.isArchived).length;
});
