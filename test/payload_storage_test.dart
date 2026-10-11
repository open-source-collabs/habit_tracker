import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/core/theme/dynamic_theme_model.dart';
import 'package:habit_tracker/data/models/app_payload_model.dart';
import 'package:habit_tracker/data/models/habit_model.dart';
import 'package:habit_tracker/data/storage/habit_storage.dart';
import 'package:habit_tracker/data/storage/habit_storage_factory.dart';
import 'package:habit_tracker/data/storage/io_habit_storage.dart';
import 'package:habit_tracker/data/storage/web_habit_storage.dart';

void main() {
  group('HabitModel & Frequency Specifications', () {
    test('JSON serialization round-trip for daily habit', () {
      final habit = HabitModel(
        id: 'h_1',
        title: 'Morning Sunlight',
        subtitle: '15 mins outdoors',
        frequency: const HabitFrequency.daily(),
        routineGroup: 'Morning Routine',
        accentIndex: 1,
        createdAt: DateTime(2026, 1, 1),
        isArchived: false,
        checkIns: const {'2026-10-09': true, '2026-10-10': true},
      );

      final json = habit.toJson();
      final restored = HabitModel.fromJson(json);

      expect(restored.id, habit.id);
      expect(restored.title, habit.title);
      expect(restored.subtitle, habit.subtitle);
      expect(restored.frequency.type, HabitFrequencyType.daily);
      expect(restored.routineGroup, 'Morning Routine');
      expect(restored.accentIndex, 1);
      expect(restored.checkIns, habit.checkIns);
    });

    test('JSON serialization for specific weekdays frequency', () {
      final habit = HabitModel(
        id: 'h_2',
        title: 'Gym Workout',
        frequency: HabitFrequency.specificWeekdays([
          DateTime.monday,
          DateTime.wednesday,
          DateTime.friday,
        ]),
        createdAt: DateTime(2026, 1, 1),
      );

      final restored = HabitModel.fromJson(habit.toJson());
      expect(restored.frequency.type, HabitFrequencyType.specificWeekdays);
      expect(restored.frequency.daysOfWeek, [
        DateTime.monday,
        DateTime.wednesday,
        DateTime.friday,
      ]);
    });

    test('JSON serialization for timesPerWeek frequency', () {
      final habit = HabitModel(
        id: 'h_3',
        title: 'Read 30 mins',
        frequency: const HabitFrequency.timesPerWeek(4),
        createdAt: DateTime(2026, 1, 1),
      );

      final restored = HabitModel.fromJson(habit.toJson());
      expect(restored.frequency.type, HabitFrequencyType.timesPerWeek);
      expect(restored.frequency.targetTimesPerWeek, 4);
    });

    test('toggleCheckIn toggles completion status immutably', () {
      final habit = HabitModel(
        id: 'h_toggle',
        title: 'Hydration',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 1, 1),
      );

      final testDate = DateTime(2026, 10, 11);
      expect(habit.isCompletedOn(testDate), isFalse);

      final toggledOn = habit.toggleCheckIn(testDate);
      expect(toggledOn.isCompletedOn(testDate), isTrue);
      expect(habit.isCompletedOn(testDate), isFalse); // immutable

      final toggledOff = toggledOn.toggleCheckIn(testDate);
      expect(toggledOff.isCompletedOn(testDate), isFalse);
    });
  });

  group('Streak Calculation Algorithms', () {
    test('Daily habit: calculates current and longest streaks correctly', () {
      final asOf = DateTime(2026, 10, 11); // Sunday

      // Case 1: Active streak including today (11, 10, 09, 08 completed)
      final habitActiveToday = HabitModel(
        id: 'h_streak_1',
        title: 'Meditation',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 10, 1),
        checkIns: const {
          '2026-10-08': true,
          '2026-10-09': true,
          '2026-10-10': true,
          '2026-10-11': true,
        },
      );
      expect(habitActiveToday.calculateCurrentStreak(asOf: asOf), 4);
      expect(habitActiveToday.calculateLongestStreak(), 4);

      // Case 2: Today not completed yet, but yesterday was completed (streak preserved)
      final habitPendingToday = HabitModel(
        id: 'h_streak_2',
        title: 'Meditation',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 10, 1),
        checkIns: const {
          '2026-10-08': true,
          '2026-10-09': true,
          '2026-10-10': true,
        },
      );
      expect(habitPendingToday.calculateCurrentStreak(asOf: asOf), 3);
      expect(habitPendingToday.calculateLongestStreak(), 3);

      // Case 3: Both today and yesterday missed -> streak broken to 0
      final habitBroken = HabitModel(
        id: 'h_streak_3',
        title: 'Meditation',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 10, 1),
        checkIns: const {
          '2026-10-07': true,
          '2026-10-08': true,
          '2026-10-09': true,
        },
      );
      expect(habitBroken.calculateCurrentStreak(asOf: asOf), 0);
      expect(habitBroken.calculateLongestStreak(), 3);

      // Case 4: Longest streak surpasses current streak across historical gap
      final habitHistorical = HabitModel(
        id: 'h_streak_4',
        title: 'Meditation',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 9, 1),
        checkIns: const {
          // Historical streak: 5 days
          '2026-09-10': true,
          '2026-09-11': true,
          '2026-09-12': true,
          '2026-09-13': true,
          '2026-09-14': true,
          // Gap...
          // Current streak: 2 days
          '2026-10-10': true,
          '2026-10-11': true,
        },
      );
      expect(habitHistorical.calculateCurrentStreak(asOf: asOf), 2);
      expect(habitHistorical.calculateLongestStreak(), 5);
    });

    test(
      'Specific weekdays habit: computes streaks across scheduled days only',
      () {
        // Monday (Oct 5), Wednesday (Oct 7), Friday (Oct 9), Monday (Oct 12)
        final habit = HabitModel(
          id: 'h_weekdays',
          title: 'Strength Training',
          frequency: HabitFrequency.specificWeekdays([
            DateTime.monday,
            DateTime.wednesday,
            DateTime.friday,
          ]),
          createdAt: DateTime(2026, 10, 1),
          checkIns: const {
            '2026-10-05': true, // Mon
            '2026-10-07': true, // Wed
            '2026-10-09': true, // Fri
          },
        );

        // On Saturday Oct 10 (not a scheduled day): Friday Oct 9 was completed
        final saturday = DateTime(2026, 10, 10);
        expect(habit.calculateCurrentStreak(asOf: saturday), 3);

        // On Sunday Oct 11 (not a scheduled day): Friday Oct 9 was completed
        final sunday = DateTime(2026, 10, 11);
        expect(habit.calculateCurrentStreak(asOf: sunday), 3);

        // On Monday Oct 12: before completing, previous scheduled day (Fri) was done
        final mondayBeforeCheckIn = DateTime(2026, 10, 12);
        expect(habit.calculateCurrentStreak(asOf: mondayBeforeCheckIn), 3);

        // After completing Monday Oct 12
        final habitMondayDone = habit.toggleCheckIn(DateTime(2026, 10, 12));
        expect(
          habitMondayDone.calculateCurrentStreak(asOf: mondayBeforeCheckIn),
          4,
        );
        expect(habitMondayDone.calculateLongestStreak(), 4);
      },
    );

    test('Times per week habit: computes weekly completed cycles', () {
      // Target: 2 times per week
      // Week 1 (Oct 5..11): 2 completions
      // Week 2 (Oct 12..18): 2 completions
      final habit = HabitModel(
        id: 'h_times_per_week',
        title: 'Long Run',
        frequency: const HabitFrequency.timesPerWeek(2),
        createdAt: DateTime(2026, 10, 1),
        checkIns: const {
          // Week 1
          '2026-10-06': true,
          '2026-10-08': true,
          // Week 2
          '2026-10-13': true,
          '2026-10-15': true,
        },
      );

      final duringWeek2 = DateTime(2026, 10, 16);
      expect(habit.calculateCurrentStreak(asOf: duringWeek2), 2);
      expect(habit.calculateLongestStreak(), 2);
    });
  });

  group('AppPayloadModel Root Container', () {
    test('initial factory provides built-in themes and default metadata', () {
      final initial = AppPayloadModel.initial(lastModifiedBy: 'device_abc');

      expect(initial.version, 1);
      expect(initial.lastModifiedBy, 'device_abc');
      expect(initial.activeThemeId, UserThemeModel.obsidianTwilight.id);
      expect(initial.userThemes.length, greaterThanOrEqualTo(2));
      expect(initial.habits, isEmpty);
    });

    test('Full JSON serialization round-trip with custom themes and dynamic habits', () {
      const customTheme = UserThemeModel(
        id: 'custom_matrix',
        name: 'Matrix Cyberpunk',
        fontFamily: 'Inter',
        scaffoldBgHex: '#001100',
        cardBgHex: '#002200',
        cardBorderHex: '#004400',
        textPrimaryHex: '#00FF66',
        accentPaletteHex: ['#00FF66', '#00CC44'],
        isBuiltIn: false,
      );

      final habit = HabitModel(
        id: 'habit_code',
        title: 'Deep Coding',
        subtitle: 'Ship production features',
        frequency: const HabitFrequency.daily(),
        routineGroup: 'Productivity',
        accentIndex: 0,
        createdAt: DateTime(2026, 10, 1),
        checkIns: const {'2026-10-11': true},
      );

      final payload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'engineer_desktop',
        lastModifiedAt: DateTime(2026, 10, 11, 16, 30),
        activeThemeId: customTheme.id,
        userThemes: [...UserThemeModel.builtInPresets, customTheme],
        habits: [habit],
      );

      final rawJson = payload.toRawJson(pretty: true);
      final restored = AppPayloadModel.fromRawJson(rawJson);

      expect(restored.version, payload.version);
      expect(restored.lastModifiedBy, payload.lastModifiedBy);
      expect(restored.activeThemeId, payload.activeThemeId);
      expect(restored.userThemes.length, payload.userThemes.length);
      expect(restored.userThemes.any((t) => t.id == 'custom_matrix'), isTrue);
      expect(restored.habits.length, 1);
      expect(restored.habits.first.title, 'Deep Coding');
      expect(restored.habits.first.checkIns['2026-10-11'], isTrue);
    });
  });

  group('IoHabitStorage Atomic Writes & Rolling Backups', () {
    late Directory testDir;
    late IoHabitStorage storage;

    setUp(() {
      testDir = Directory.systemTemp.createTempSync('habit_storage_test_');
      storage = IoHabitStorage(directory: testDir);
    });

    tearDown(() {
      if (testDir.existsSync()) {
        testDir.deleteSync(recursive: true);
      }
    });

    test('initial load returns null on clean directory', () async {
      final payload = await storage.loadPayload();
      expect(payload, isNull);
      expect(await storage.listBackups(), isEmpty);
    });

    test(
      'persists payload and creates primary file without temp leftovers',
      () async {
        final payload = AppPayloadModel.initial(lastModifiedBy: 'tester_1');
        await storage.savePayload(payload);

        final primaryFile = File('${testDir.path}/app_data.json');
        expect(await primaryFile.exists(), isTrue);

        final loaded = await storage.loadPayload();
        expect(loaded, isNotNull);
        expect(loaded!.lastModifiedBy, 'tester_1');

        // Verify no stray .tmp_ files remain in directory
        final tmpFiles = testDir
            .listSync()
            .where((f) => f.path.contains('.tmp_'))
            .toList();
        expect(tmpFiles, isEmpty);
      },
    );

    test(
      'maintains exactly 3 rolling snapshot backups on subsequent writes',
      () async {
        final p1 = AppPayloadModel.initial(lastModifiedBy: 'save_1');
        final p2 = AppPayloadModel.initial(lastModifiedBy: 'save_2');
        final p3 = AppPayloadModel.initial(lastModifiedBy: 'save_3');
        final p4 = AppPayloadModel.initial(lastModifiedBy: 'save_4');

        // 1st Write: only app_data.json exists
        await storage.savePayload(p1);
        expect(await storage.listBackups(), isEmpty);

        // 2nd Write: backup_1 holds p1, primary holds p2
        await storage.savePayload(p2);
        var backups = await storage.listBackups();
        expect(backups, contains('backup_1.json'));
        expect(backups.length, 1);

        var b1Content = await File('${testDir.path}/backup_1.json')
            .readAsString();
        expect(AppPayloadModel.fromRawJson(b1Content).lastModifiedBy, 'save_1');
        expect((await storage.loadPayload())!.lastModifiedBy, 'save_2');

        // 3rd Write: backup_2 holds p1, backup_1 holds p2, primary holds p3
        await storage.savePayload(p3);
        backups = await storage.listBackups();
        expect(backups, containsAll(['backup_1.json', 'backup_2.json']));
        expect(backups.length, 2);

        var b2Content = await File('${testDir.path}/backup_2.json')
            .readAsString();
        expect(AppPayloadModel.fromRawJson(b2Content).lastModifiedBy, 'save_1');

        // 4th Write: backup_3 holds p1, backup_2 holds p2, backup_1 holds p3, primary holds p4
        await storage.savePayload(p4);
        backups = await storage.listBackups();
        expect(
          backups,
          containsAll(['backup_1.json', 'backup_2.json', 'backup_3.json']),
        );
        expect(backups.length, 3);

        var b3Content = await File('${testDir.path}/backup_3.json')
            .readAsString();
        expect(AppPayloadModel.fromRawJson(b3Content).lastModifiedBy, 'save_1');
        expect((await storage.loadPayload())!.lastModifiedBy, 'save_4');
      },
    );

    test(
      'automatically recovers from backup_1 when primary file is corrupted',
      () async {
        final p1 = AppPayloadModel.initial(lastModifiedBy: 'stable_payload');
        final p2 = AppPayloadModel.initial(lastModifiedBy: 'newest_payload');

        await storage.savePayload(p1);
        await storage.savePayload(p2);

        // Intentionally corrupt primary file
        final primaryFile = File('${testDir.path}/app_data.json');
        await primaryFile.writeAsString(
          '{{CORRUPT_BYTES_FAILED_WRITE::',
          flush: true,
        );

        // Storage load should detect corruption and recover from backup_1.json
        final recovered = await storage.loadPayload();
        expect(recovered, isNotNull);
        expect(recovered!.lastModifiedBy, 'stable_payload');

        // And primary file is restored to valid state
        final repairedContent = await primaryFile.readAsString();
        expect(
          AppPayloadModel.fromRawJson(repairedContent).lastModifiedBy,
          'stable_payload',
        );
      },
    );

    test(
      'recovers from backup_2 if both primary and backup_1 are corrupted',
      () async {
        final p1 = AppPayloadModel.initial(lastModifiedBy: 'oldest_stable');
        final p2 = AppPayloadModel.initial(lastModifiedBy: 'middle_payload');
        final p3 = AppPayloadModel.initial(lastModifiedBy: 'latest_payload');

        await storage.savePayload(p1);
        await storage.savePayload(p2);
        await storage.savePayload(p3);

        // Corrupt primary and backup_1
        await File('${testDir.path}/app_data.json')
            .writeAsString('CORRUPT', flush: true);
        await File('${testDir.path}/backup_1.json')
            .writeAsString('CORRUPT', flush: true);

        final recovered = await storage.loadPayload();
        expect(recovered, isNotNull);
        expect(recovered!.lastModifiedBy, 'oldest_stable');
      },
    );

    test('restoreBackup manually restores a chosen snapshot', () async {
      final p1 = AppPayloadModel.initial(lastModifiedBy: 'snapshot_alpha');
      final p2 = AppPayloadModel.initial(lastModifiedBy: 'snapshot_beta');

      await storage.savePayload(p1);
      await storage.savePayload(p2);

      final restored = await storage.restoreBackup('backup_1.json');
      expect(restored, isNotNull);
      expect(restored!.lastModifiedBy, 'snapshot_alpha');

      final current = await storage.loadPayload();
      expect(current!.lastModifiedBy, 'snapshot_alpha');
    });

    test('clear removes all storage and backup files', () async {
      await storage.savePayload(AppPayloadModel.initial(lastModifiedBy: 'p1'));
      await storage.savePayload(AppPayloadModel.initial(lastModifiedBy: 'p2'));

      expect(await storage.listBackups(), isNotEmpty);
      await storage.clear();

      expect(await storage.loadPayload(), isNull);
      expect(await storage.listBackups(), isEmpty);
    });
  });

  group('WebHabitStorage Staged Persistence & Rolling Keys', () {
    late InMemoryWebStore mockStore;
    late WebHabitStorage webStorage;

    setUp(() {
      mockStore = InMemoryWebStore();
      webStorage = WebHabitStorage(mockStore);
    });

    test('persists payload and rotates backup keys in web storage', () async {
      final p1 = AppPayloadModel.initial(lastModifiedBy: 'web_1');
      final p2 = AppPayloadModel.initial(lastModifiedBy: 'web_2');
      final p3 = AppPayloadModel.initial(lastModifiedBy: 'web_3');

      await webStorage.savePayload(p1);
      expect(await webStorage.listBackups(), isEmpty);

      await webStorage.savePayload(p2);
      expect(await webStorage.listBackups(), ['backup_1.json']);

      await webStorage.savePayload(p3);
      expect(await webStorage.listBackups(), [
        'backup_1.json',
        'backup_2.json',
      ]);

      final loaded = await webStorage.loadPayload();
      expect(loaded!.lastModifiedBy, 'web_3');
    });

    test(
      'recovers from web backup key when primary key is corrupted',
      () async {
        final p1 = AppPayloadModel.initial(lastModifiedBy: 'web_backup');
        final p2 = AppPayloadModel.initial(
          lastModifiedBy: 'web_corrupt_candidate',
        );

        await webStorage.savePayload(p1);
        await webStorage.savePayload(p2);

        // Corrupt primary key
        await mockStore.setString(
          WebHabitStorage.primaryKey,
          'INVALID_JSON_DATA',
        );

        final recovered = await webStorage.loadPayload();
        expect(recovered, isNotNull);
        expect(recovered!.lastModifiedBy, 'web_backup');
      },
    );
  });

  group('HabitStorageFactory Resolution', () {
    test('instantiates HabitStorage implementation without throwing', () {
      final storage = HabitStorageFactory.createStorage();
      expect(storage, isA<HabitStorage>());
    });
  });
}
