import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:habit_tracker/core/widgets_kit/habit_widget_sync_service.dart';
import '../../../themes/data/models/app_payload_model.dart';
import '../../../themes/presentation/providers/theme_provider.dart';
import '../../data/models/habit_model.dart';
import '../../data/storage/habit_storage.dart';
import '../../data/storage/habit_storage_factory.dart';

/// Injects the platform-appropriate [HabitStorage] instance.
final habitStorageProvider = Provider<HabitStorage>((ref) {
  return HabitStorageFactory.createStorage();
});

/// Currently selected date for inspecting or checking off habits (defaults to today).
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Active routine category filter ('All', 'Morning', 'Focus', 'Health', 'Evening', etc.)
final activeRoutineFilterProvider = StateProvider<String>((ref) => 'All');

/// Tracks heatmap expansion toggle state per habit ID.
final habitHeatmapExpandedProvider = StateProvider.family<bool, String>((ref, habitId) => false);

/// Notifier managing habit state with 0ms optimistic updates and asynchronous persistence.
class HabitListNotifier extends AsyncNotifier<List<HabitModel>> {
  @override
  Future<List<HabitModel>> build() async {
    final storage = ref.watch(habitStorageProvider);

    List<HabitModel> loadedHabits;
    try {
      final payload = await storage.loadPayload();
      if (payload != null) {
        loadedHabits = payload.habits;
      } else {
        loadedHabits = _generateStarterHabits();
      }
    } catch (e) {
      debugPrint('HabitListNotifier: Error reading from storage: $e');
      loadedHabits = _generateStarterHabits();
    }

    // Schedule initial home screen widget sync
    Future.microtask(() {
      try {
        final syncService = ref.read(habitWidgetSyncServiceProvider);
        final themeState = ref.read(themeProvider);
        syncService.syncHabits(
          habits: loadedHabits,
          activeTheme: themeState.activeTheme,
        );
      } catch (_) {}
    });

    return loadedHabits;
  }

  /// Optimistically toggles habit check-in status for [date] with 0ms latency
  /// and writes to local storage asynchronously in the background.
  Future<void> toggleHabit(String habitId, 
  DateTime date) async {
    final currentList = state.value ?? [];
    final habitIndex = currentList.indexWhere((h) => h.id == habitId);
    if (habitIndex == -1) return;

    final targetHabit = currentList[habitIndex];
    final updatedHabit = targetHabit.toggleCheckIn(date);

    final updatedList = List<HabitModel>.from(currentList);
    updatedList[habitIndex] = updatedHabit;

    state = AsyncData(updatedList);
    await _persistHabits(updatedList);
  }

  /// Creates and appends a new dynamic habit with optimistic UI update.
  Future<void> createHabit(HabitModel habit) async {
    final currentList = state.value ?? [];
    final updatedHabit = habit.copyWith(lastModifiedAt: DateTime.now());
    final updatedList = [...currentList, updatedHabit];

    state = AsyncData(updatedList);
    await _persistHabits(updatedList);
  }

  /// Updates an existing habit's configuration or frequency.
  Future<void> updateHabit(HabitModel habit) async {
    final currentList = state.value ?? [];
    final index = currentList.indexWhere((h) => h.id == habit.id);
    if (index == -1) return;

    final updatedHabit = habit.copyWith(lastModifiedAt: DateTime.now());
    final updatedList = List<HabitModel>.from(currentList);
    updatedList[index] = updatedHabit;

    state = AsyncData(updatedList);
    await _persistHabits(updatedList);
  }

  /// Removes a habit by [habitId] and persists the updated collection.
  Future<void> deleteHabit(String habitId) async {
    final currentList = state.value ?? [];
    final updatedList = currentList.where((h) => h.id != habitId).toList();

    state = AsyncData(updatedList);
    await _persistHabits(updatedList);
  }

  /// Restores and persists an imported collection of habits atomically.
  Future<void> restoreHabits(List<HabitModel> habits) async {
    state = AsyncData(habits);
    await _persistHabits(habits);
  }

  /// Persists current habits alongside the user's active theme in atomic [AppPayloadModel].
  Future<void> _persistHabits(List<HabitModel> habits) async {
    try {
      final storage = ref.read(habitStorageProvider);
      final themeState = ref.read(themeProvider);

      final payload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'local_device',
        lastModifiedAt: DateTime.now(),
        activeThemeId: themeState.activeThemeId,
        userThemes: themeState.allThemes,
        habits: habits,
      );

      await storage.savePayload(payload);

      // Push updated state to native home screen widgets via widgets_kit
      try {
        final syncService = ref.read(habitWidgetSyncServiceProvider);
        unawaited(
          syncService.syncHabits(
            habits: habits,
            activeTheme: themeState.activeTheme,
          ),
        );
      } catch (e) {
        debugPrint('HabitListNotifier: Error syncing widgets_kit: $e');
      }
    } catch (e) {
      debugPrint('HabitListNotifier: Failed to persist habits: $e');
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

  final habits = habitsAsync.value ?? const [];
  if (filter == 'All') {
    return habits.where((h) => !h.isArchived).toList();
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
  final habits = ref.watch(habitListProvider).value ?? const [];
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

/// List of all unique routine categories present in active habits.
final routineGroupsProvider = Provider<List<String>>((ref) {
  final habits = ref.watch(habitListProvider).value ?? const [];
  final groups = <String>{'All'};
  for (final habit in habits) {
    if (!habit.isArchived && habit.routineGroup.trim().isNotEmpty) {
      groups.add(habit.routineGroup.trim());
    }
  }
  return groups.toList();
});
