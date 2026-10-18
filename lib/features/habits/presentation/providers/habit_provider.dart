import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:habit_tracker/core/widgets_kit/habit_widget_sync_service.dart';
import '../../../../core/data/app_data_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/calendar_days.dart';
import '../../../themes/presentation/providers/theme_provider.dart';
import '../../data/models/habit_model.dart';
import '../../data/models/starter_habits.dart';

export '../../../../core/data/app_data_repository.dart'
    show appDataRepositoryProvider, habitStorageProvider;

/// Today's date (local midnight). Unlike reading `DateTime.now()` in build,
/// watchers rebuild when the day changes: [DayRolloverWatcher] updates it at
/// midnight and whenever the app returns to the foreground.
final currentDayProvider = StateProvider<DateTime>(
  (ref) => CalendarDays.dateOnly(DateTime.now()),
);

/// Currently selected date for inspecting or checking off habits (defaults to today).
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return ref.read(currentDayProvider);
});

/// Keeps [currentDayProvider] in step with the clock. When the day changes
/// while the user is looking at "today", the selection moves to the new day,
/// so check-ins after midnight don't land on yesterday.
class DayRolloverWatcher {
  DayRolloverWatcher(this._ref);

  final Ref _ref;
  Timer? _midnight;
  AppLifecycleListener? _lifecycle;

  void start() {
    _lifecycle ??= AppLifecycleListener(onResume: refresh);
    _scheduleMidnight();
  }

  /// Re-reads the clock now (also called on resume).
  void refresh() {
    final today = CalendarDays.dateOnly(DateTime.now());
    final previous = _ref.read(currentDayProvider);
    if (!CalendarDays.isSameDay(previous, today)) {
      final selected = _ref.read(selectedDateProvider.notifier);
      final wasOnToday = CalendarDays.isSameDay(selected.state, previous);
      _ref.read(currentDayProvider.notifier).state = today;
      if (wasOnToday) selected.state = today;
    }
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    final next = CalendarDays.addDays(now, 1);
    // A second of slack so the timer never fires just before midnight.
    _midnight = Timer(next.difference(now) + const Duration(seconds: 1), refresh);
  }

  void dispose() {
    _midnight?.cancel();
    _lifecycle?.dispose();
    _midnight = null;
    _lifecycle = null;
  }
}

final dayRolloverWatcherProvider = Provider<DayRolloverWatcher>((ref) {
  final watcher = DayRolloverWatcher(ref);
  ref.onDispose(watcher.dispose);
  return watcher;
});

/// Filter value showing every active habit.
const String kAllHabitsFilter = 'All';

/// Filter value showing archived (paused) habits instead of active ones.
const String kArchivedHabitsFilter = 'Archived';

/// Active routine category filter: [kAllHabitsFilter], a routine group name,
/// or [kArchivedHabitsFilter].
final activeRoutineFilterProvider =
    StateProvider<String>((ref) => kAllHabitsFilter);

/// Habit to scroll to and briefly highlight in the feed (e.g. after its
/// reminder notification was tapped). The feed clears it once shown.
final highlightedHabitIdProvider = StateProvider<String?>((ref) => null);

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

    // A first run starts empty; onboarding lets the user pick starters.
    final habits = snapshot.payload.habits;
    if (!snapshot.isFirstRun) {
      unawaited(Future.microtask(() => _syncWidgets(habits)));
    }
    return habits;
  }

  /// Finishes onboarding: adds the [picked] starters (with no history) and
  /// saves, which also marks the first run as done — even when nothing was
  /// picked.
  Future<void> completeOnboarding(List<StarterHabit> picked) async {
    final currentList = state.valueOrNull;
    if (currentList == null) return;
    final now = DateTime.now();
    final created = [
      for (var i = 0; i < picked.length; i++) picked[i].toHabit(now, index: i),
    ];
    final updatedList = [...currentList, ...created];

    state = AsyncData(updatedList);
    final notifications = ref.read(notificationServiceProvider);
    for (final habit in created) {
      unawaited(notifications.syncHabitReminder(habit));
    }
    await _persist(updatedList);
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
    // Done today → today's reminder is skipped; unchecked → it's back.
    if (updatedHabit.reminderTime != null &&
        CalendarDays.isSameDay(day, now)) {
      unawaited(
        ref.read(notificationServiceProvider).syncHabitReminder(updatedHabit),
      );
    }
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
