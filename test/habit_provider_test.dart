import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/habits/data/storage/habit_storage.dart';
import 'package:habit_tracker/features/habits/presentation/providers/habit_provider.dart';
import 'package:habit_tracker/features/themes/data/models/app_payload_model.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';

class InMemoryHabitStorage implements HabitStorage {
  AppPayloadModel? storedPayload;
  int saveCount = 0;

  InMemoryHabitStorage([this.storedPayload]);

  @override
  Future<AppPayloadModel?> loadPayload() async => storedPayload;

  @override
  Future<void> savePayload(AppPayloadModel payload) async {
    storedPayload = payload;
    saveCount++;
  }

  @override
  Future<List<String>> listBackups() async => [];

  @override
  Future<AppPayloadModel?> restoreBackup(String backupName) async =>
      storedPayload;

  @override
  Future<void> clear() async {
    storedPayload = null;
  }
}

void main() {
  group('HabitListNotifier State Management & Optimistic Updates', () {
    test('Loads starter habits when storage is empty', () async {
      final fakeStorage = InMemoryHabitStorage();
      final container = ProviderContainer(
        overrides: [
          habitStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(container.dispose);

      final habits = await container.read(habitListProvider.future);
      expect(habits, isNotEmpty);
      expect(habits.length, greaterThanOrEqualTo(4));
      expect(
        habits.any((h) => h.title.contains('Morning Sunlight')),
        isTrue,
      );
    });

    test('Loads existing habits from storage when present', () async {
      final existingHabits = [
        HabitModel(
          id: 'custom_1',
          title: 'Cold Shower',
          frequency: const HabitFrequency.daily(),
          routineGroup: 'Morning',
          createdAt: DateTime(2026, 1, 1),
        ),
      ];

      final fakeStorage = InMemoryHabitStorage(
        AppPayloadModel(
          version: 1,
          lastModifiedBy: 'test',
          lastModifiedAt: DateTime(2026, 10, 11),
          activeThemeId: UserThemeModel.obsidianTwilight.id,
          userThemes: UserThemeModel.builtInPresets,
          habits: existingHabits,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          habitStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(container.dispose);

      final habits = await container.read(habitListProvider.future);
      expect(habits.length, 1);
      expect(habits.first.id, 'custom_1');
      expect(habits.first.title, 'Cold Shower');
    });

    test(
        'toggleHabit performs 0ms synchronous UI update and updates streak',
        () async {
      final today = DateTime(2026, 10, 11);
      final yesterday = DateTime(2026, 10, 10);

      final habit = HabitModel(
        id: 'h_optimistic',
        title: 'Meditation',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 10, 1),
        checkIns: {
          HabitModel.formatDate(yesterday): true,
        },
      );

      final fakeStorage = InMemoryHabitStorage(
        AppPayloadModel(
          version: 1,
          lastModifiedBy: 'test',
          lastModifiedAt: today,
          activeThemeId: UserThemeModel.obsidianTwilight.id,
          userThemes: UserThemeModel.builtInPresets,
          habits: [habit],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          habitStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(container.dispose);

      // Await initial build
      await container.read(habitListProvider.future);

      final initialHabit = container
          .read(habitListProvider)
          .value!
          .firstWhere((h) => h.id == 'h_optimistic');
      expect(initialHabit.isCompletedOn(today), isFalse);
      expect(initialHabit.calculateCurrentStreak(asOf: today), 1);

      // Perform toggleHabit
      final notifier = container.read(habitListProvider.notifier);
      final futureToggle = notifier.toggleHabit('h_optimistic', today);

      // Synchronous check: 0ms optimistic update
      final immediateState = container.read(habitListProvider).value!;
      final toggledHabit =
          immediateState.firstWhere((h) => h.id == 'h_optimistic');
      expect(toggledHabit.isCompletedOn(today), isTrue);
      expect(toggledHabit.calculateCurrentStreak(asOf: today), 2);

      // Await async persistence
      await futureToggle;
      expect(fakeStorage.saveCount, greaterThanOrEqualTo(1));
      expect(
        fakeStorage.storedPayload?.habits
            .firstWhere((h) => h.id == 'h_optimistic')
            .isCompletedOn(today),
        isTrue,
      );

      // Toggle off again
      await notifier.toggleHabit('h_optimistic', today);
      final offState = container.read(habitListProvider).value!;
      final offHabit = offState.firstWhere((h) => h.id == 'h_optimistic');
      expect(offHabit.isCompletedOn(today), isFalse);
      expect(offHabit.calculateCurrentStreak(asOf: today), 1);
    });

    test('createHabit adds new habit optimistically and saves to storage',
        () async {
      final fakeStorage = InMemoryHabitStorage(
        AppPayloadModel(
          version: 1,
          lastModifiedBy: 'test',
          lastModifiedAt: DateTime.now(),
          activeThemeId: UserThemeModel.obsidianTwilight.id,
          userThemes: UserThemeModel.builtInPresets,
          habits: const [],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          habitStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(container.dispose);

      await container.read(habitListProvider.future);

      final newHabit = HabitModel(
        id: 'new_habit_1',
        title: 'Read 20 pages',
        frequency: const HabitFrequency.daily(),
        routineGroup: 'Evening',
        createdAt: DateTime.now(),
        emoji: '📚',
      );

      await container.read(habitListProvider.notifier).createHabit(newHabit);

      final currentList = container.read(habitListProvider).value!;
      expect(currentList.length, 1);
      expect(currentList.first.id, 'new_habit_1');
      expect(currentList.first.emoji, '📚');
      expect(fakeStorage.storedPayload?.habits.length, 1);
    });

    test('updateHabit and deleteHabit update state and storage', () async {
      final habit = HabitModel(
        id: 'h_crud',
        title: 'Original Title',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime.now(),
      );

      final fakeStorage = InMemoryHabitStorage(
        AppPayloadModel(
          version: 1,
          lastModifiedBy: 'test',
          lastModifiedAt: DateTime.now(),
          activeThemeId: UserThemeModel.obsidianTwilight.id,
          userThemes: UserThemeModel.builtInPresets,
          habits: [habit],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          habitStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(container.dispose);

      await container.read(habitListProvider.future);

      // Update
      final updated = habit.copyWith(title: 'Updated Title');
      await container.read(habitListProvider.notifier).updateHabit(updated);

      var list = container.read(habitListProvider).value!;
      expect(list.first.title, 'Updated Title');

      // Delete
      await container.read(habitListProvider.notifier).deleteHabit('h_crud');
      list = container.read(habitListProvider).value!;
      expect(list.isEmpty, isTrue);
      expect(fakeStorage.storedPayload?.habits.isEmpty, isTrue);
    });

    test('dailyHabitStatsProvider and filteredHabitsProvider compute correctly',
        () async {
      final today = DateTime(2026, 10, 11);
      final yesterday = DateTime(2026, 10, 10);

      final h1 = HabitModel(
        id: 'h1',
        title: 'Morning Water',
        routineGroup: 'Morning',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 1, 1),
        checkIns: {
          HabitModel.formatDate(today): true,
          HabitModel.formatDate(yesterday): true,
        },
      );

      final h2 = HabitModel(
        id: 'h2',
        title: 'Deep Focus',
        routineGroup: 'Focus',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 1, 1),
      );

      final fakeStorage = InMemoryHabitStorage(
        AppPayloadModel(
          version: 1,
          lastModifiedBy: 'test',
          lastModifiedAt: today,
          activeThemeId: UserThemeModel.obsidianTwilight.id,
          userThemes: UserThemeModel.builtInPresets,
          habits: [h1, h2],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          habitStorageProvider.overrideWithValue(fakeStorage),
          selectedDateProvider.overrideWith((ref) => today),
        ],
      );
      addTearDown(container.dispose);

      await container.read(habitListProvider.future);

      final stats = container.read(dailyHabitStatsProvider);
      expect(stats.totalScheduled, 2);
      expect(stats.completedCount, 1);
      expect(stats.completionRate, 0.5);
      expect(stats.activeStreaksCount, 1);
      expect(stats.longestActiveStreak, 2);

      // Filtering test
      container.read(activeRoutineFilterProvider.notifier).state = 'Morning';
      final filteredMorning = container.read(filteredHabitsProvider);
      expect(filteredMorning.length, 1);
      expect(filteredMorning.first.id, 'h1');

      container.read(activeRoutineFilterProvider.notifier).state = 'All';
      final filteredAll = container.read(filteredHabitsProvider);
      expect(filteredAll.length, 2);
    });
  });
}
