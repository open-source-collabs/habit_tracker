import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/sync/merge_engine.dart';
import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/themes/data/models/app_payload_model.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';

void main() {
  group('MergeEngine: Custom Theme Merge', () {
    test('merging custom themes created on separate devices while offline', () {
      final now = DateTime(2026, 10, 12, 10, 0, 0);

      const localCustomTheme = UserThemeModel(
        id: 'theme_zen_garden',
        name: 'Zen Garden',
        fontFamily: 'Inter',
        scaffoldBgHex: '#101820',
        cardBgHex: '#1A232E',
        cardBorderHex: '#2C3A4A',
        textPrimaryHex: '#F0F4F8',
        accentPaletteHex: ['#48BB78', '#38B2AC'],
        isBuiltIn: false,
      );

      const incomingCustomTheme = UserThemeModel(
        id: 'theme_cosmic_neon',
        name: 'Cosmic Neon',
        fontFamily: 'PlusJakartaSans',
        scaffoldBgHex: '#0A0518',
        cardBgHex: '#150D2E',
        cardBorderHex: '#2E1E5C',
        textPrimaryHex: '#FFFFFF',
        accentPaletteHex: ['#9F7AEA', '#ED64A6'],
        isBuiltIn: false,
      );

      final localPayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'device_a',
        lastModifiedAt: now,
        activeThemeId: localCustomTheme.id,
        userThemes: [...UserThemeModel.builtInPresets, localCustomTheme],
        habits: const [],
      );

      final incomingPayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'device_b',
        lastModifiedAt: now.add(const Duration(minutes: 5)),
        activeThemeId: incomingCustomTheme.id,
        userThemes: [...UserThemeModel.builtInPresets, incomingCustomTheme],
        habits: const [],
      );

      final merged = mergePayloads(local: localPayload, incoming: incomingPayload);

      final themeIds = merged.userThemes.map((t) => t.id).toList();

      // Both offline-created themes must be present in the merged payload
      expect(themeIds.contains('theme_zen_garden'), isTrue);
      expect(themeIds.contains('theme_cosmic_neon'), isTrue);

      // All built-in presets must be preserved
      for (final preset in UserThemeModel.builtInPresets) {
        expect(themeIds.contains(preset.id), isTrue);
      }

      // Newer incoming active theme is selected
      expect(merged.activeThemeId, 'theme_cosmic_neon');
    });

    test('resolves conflicting theme edits where newest lastModifiedAt wins', () {
      final t1 = DateTime(2026, 10, 12, 10, 0, 0);
      final t2 = DateTime(2026, 10, 12, 10, 30, 0);

      final localTheme = UserThemeModel(
        id: 'custom_theme_x',
        name: 'Theme X (Old Edit)',
        fontFamily: 'Inter',
        scaffoldBgHex: '#111111',
        cardBgHex: '#222222',
        cardBorderHex: '#333333',
        textPrimaryHex: '#EEEEEE',
        accentPaletteHex: const ['#FF0000'],
        isBuiltIn: false,
        lastModifiedAt: t1,
      );

      final incomingTheme = UserThemeModel(
        id: 'custom_theme_x',
        name: 'Theme X (Newer Edit)',
        fontFamily: 'PlusJakartaSans',
        scaffoldBgHex: '#000000',
        cardBgHex: '#121212',
        cardBorderHex: '#242424',
        textPrimaryHex: '#FFFFFF',
        accentPaletteHex: const ['#00FF00'],
        isBuiltIn: false,
        lastModifiedAt: t2,
      );

      final localPayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'device_a',
        lastModifiedAt: t1,
        activeThemeId: localTheme.id,
        userThemes: [localTheme],
        habits: const [],
      );

      final incomingPayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'device_b',
        lastModifiedAt: t2,
        activeThemeId: incomingTheme.id,
        userThemes: [incomingTheme],
        habits: const [],
      );

      final merged = mergePayloads(local: localPayload, incoming: incomingPayload);

      final resolvedTheme =
          merged.userThemes.firstWhere((t) => t.id == 'custom_theme_x');
      expect(resolvedTheme.name, 'Theme X (Newer Edit)');
      expect(resolvedTheme.fontFamily, 'PlusJakartaSans');
      expect(resolvedTheme.scaffoldBgHex, '#000000');
    });

    test('local theme edit wins when local lastModifiedAt is newer', () {
      final tOld = DateTime(2026, 10, 12, 10, 0, 0);
      final tNew = DateTime(2026, 10, 12, 11, 0, 0);

      final localTheme = UserThemeModel(
        id: 'custom_theme_y',
        name: 'Theme Y (Newest Local)',
        fontFamily: 'Inter',
        scaffoldBgHex: '#101010',
        cardBgHex: '#202020',
        cardBorderHex: '#303030',
        textPrimaryHex: '#FAFAFA',
        accentPaletteHex: const ['#0000FF'],
        isBuiltIn: false,
        lastModifiedAt: tNew,
      );

      final incomingTheme = UserThemeModel(
        id: 'custom_theme_y',
        name: 'Theme Y (Stale Remote)',
        fontFamily: 'Inter',
        scaffoldBgHex: '#151515',
        cardBgHex: '#252525',
        cardBorderHex: '#353535',
        textPrimaryHex: '#EAEAEA',
        accentPaletteHex: const ['#FFFF00'],
        isBuiltIn: false,
        lastModifiedAt: tOld,
      );

      final localPayload = AppPayloadModel(
        version: 2,
        lastModifiedBy: 'device_a',
        lastModifiedAt: tNew,
        activeThemeId: localTheme.id,
        userThemes: [localTheme],
        habits: const [],
      );

      final incomingPayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'device_b',
        lastModifiedAt: tOld,
        activeThemeId: incomingTheme.id,
        userThemes: [incomingTheme],
        habits: const [],
      );

      final merged = mergePayloads(local: localPayload, incoming: incomingPayload);
      final resolved =
          merged.userThemes.firstWhere((t) => t.id == 'custom_theme_y');
      expect(resolved.name, 'Theme Y (Newest Local)');
    });
  });

  group('MergeEngine: Habit Check-In Union (Additive)', () {
    test('additive check-in union across alternating days', () {
      final createdAt = DateTime(2026, 10, 1);

      // Device A checked in on Day 1, Day 3, Day 5
      final habitA = HabitModel(
        id: 'habit_run',
        title: 'Morning 5K Run',
        frequency: const HabitFrequency.daily(),
        createdAt: createdAt,
        checkIns: const {
          '2026-10-01': true,
          '2026-10-03': true,
          '2026-10-05': true,
        },
      );

      // Device B checked in on Day 2, Day 4, Day 6
      final habitB = HabitModel(
        id: 'habit_run',
        title: 'Morning 5K Run',
        frequency: const HabitFrequency.daily(),
        createdAt: createdAt,
        checkIns: const {
          '2026-10-02': true,
          '2026-10-04': true,
          '2026-10-06': true,
        },
      );

      final localPayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'phone_a',
        lastModifiedAt: DateTime(2026, 10, 5, 8, 0),
        activeThemeId: UserThemeModel.obsidianTwilight.id,
        userThemes: UserThemeModel.builtInPresets,
        habits: [habitA],
      );

      final incomingPayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'tablet_b',
        lastModifiedAt: DateTime(2026, 10, 6, 8, 0),
        activeThemeId: UserThemeModel.obsidianTwilight.id,
        userThemes: UserThemeModel.builtInPresets,
        habits: [habitB],
      );

      final merged = mergePayloads(local: localPayload, incoming: incomingPayload);

      expect(merged.habits.length, 1);
      final mergedHabit = merged.habits.first;
      expect(mergedHabit.id, 'habit_run');

      // Check-ins MUST contain all 6 days additively
      expect(mergedHabit.checkIns['2026-10-01'], isTrue);
      expect(mergedHabit.checkIns['2026-10-02'], isTrue);
      expect(mergedHabit.checkIns['2026-10-03'], isTrue);
      expect(mergedHabit.checkIns['2026-10-04'], isTrue);
      expect(mergedHabit.checkIns['2026-10-05'], isTrue);
      expect(mergedHabit.checkIns['2026-10-06'], isTrue);
      expect(mergedHabit.checkIns.length, 6);
    });

    test('additive check-in union preserves overlapping days without duplication', () {
      final habitA = HabitModel(
        id: 'habit_hydrate',
        title: 'Drink 2L Water',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 10, 1),
        checkIns: const {
          '2026-10-10': true,
          '2026-10-11': true,
        },
      );

      final habitB = HabitModel(
        id: 'habit_hydrate',
        title: 'Drink 2L Water',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 10, 1),
        checkIns: const {
          '2026-10-11': true,
          '2026-10-12': true,
        },
      );

      final localPayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'device_1',
        lastModifiedAt: DateTime(2026, 10, 11),
        activeThemeId: UserThemeModel.obsidianTwilight.id,
        userThemes: const [],
        habits: [habitA],
      );

      final incomingPayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'device_2',
        lastModifiedAt: DateTime(2026, 10, 12),
        activeThemeId: UserThemeModel.obsidianTwilight.id,
        userThemes: const [],
        habits: [habitB],
      );

      final merged = mergePayloads(local: localPayload, incoming: incomingPayload);
      final mergedHabit = merged.habits.first;

      expect(mergedHabit.checkIns.length, 3);
      expect(mergedHabit.checkIns['2026-10-10'], isTrue);
      expect(mergedHabit.checkIns['2026-10-11'], isTrue);
      expect(mergedHabit.checkIns['2026-10-12'], isTrue);
    });
  });

  group('MergeEngine: Habit Metadata Conflict Resolution', () {
    test('conflicting habit metadata resolves via latest lastModifiedAt while combining check-ins', () {
      final t1 = DateTime(2026, 10, 10, 9, 0);
      final t2 = DateTime(2026, 10, 10, 12, 0);

      // Local has older metadata and Day 1 check-in
      final localHabit = HabitModel(
        id: 'habit_meditate',
        title: '10 Min Meditation',
        subtitle: 'Basic breathwork',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 10, 1),
        emoji: '🧘',
        routineGroup: 'Morning',
        lastModifiedAt: t1,
        checkIns: const {'2026-10-08': true},
      );

      // Incoming has newer metadata (renamed title, changed emoji) and Day 2 check-in
      final incomingHabit = HabitModel(
        id: 'habit_meditate',
        title: '20 Min Vipassana',
        subtitle: 'Deep focus breathwork',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 10, 1),
        emoji: '✨',
        routineGroup: 'Mindfulness',
        lastModifiedAt: t2,
        checkIns: const {'2026-10-09': true},
      );

      final localPayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'device_a',
        lastModifiedAt: t1,
        activeThemeId: UserThemeModel.obsidianTwilight.id,
        userThemes: const [],
        habits: [localHabit],
      );

      final incomingPayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'device_b',
        lastModifiedAt: t2,
        activeThemeId: UserThemeModel.obsidianTwilight.id,
        userThemes: const [],
        habits: [incomingHabit],
      );

      final merged = mergePayloads(local: localPayload, incoming: incomingPayload);
      final result = merged.habits.first;

      // Metadata from newer incoming edit wins
      expect(result.title, '20 Min Vipassana');
      expect(result.subtitle, 'Deep focus breathwork');
      expect(result.emoji, '✨');
      expect(result.routineGroup, 'Mindfulness');
      expect(result.lastModifiedAt, t2);

      // Check-ins from both devices are preserved additively
      expect(result.checkIns['2026-10-08'], isTrue);
      expect(result.checkIns['2026-10-09'], isTrue);
      expect(result.checkIns.length, 2);
    });
  });

  group('MergeEngine: Never Lose User Data', () {
    test('unions habits that exist exclusively on local or incoming device', () {
      final habitOnlyOnA = HabitModel(
        id: 'habit_reading',
        title: 'Read 20 Pages',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 10, 1),
        checkIns: const {'2026-10-02': true},
      );

      final habitOnlyOnB = HabitModel(
        id: 'habit_coding',
        title: 'Build Open Source Project',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 10, 1),
        checkIns: const {'2026-10-03': true},
      );

      final localPayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'laptop_a',
        lastModifiedAt: DateTime(2026, 10, 10),
        activeThemeId: UserThemeModel.obsidianTwilight.id,
        userThemes: const [],
        habits: [habitOnlyOnA],
      );

      final incomingPayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'desktop_b',
        lastModifiedAt: DateTime(2026, 10, 11),
        activeThemeId: UserThemeModel.obsidianTwilight.id,
        userThemes: const [],
        habits: [habitOnlyOnB],
      );

      final merged = mergePayloads(local: localPayload, incoming: incomingPayload);

      expect(merged.habits.length, 2);
      final habitIds = merged.habits.map((h) => h.id).toSet();
      expect(habitIds, containsAll(['habit_reading', 'habit_coding']));
    });

    test('merge operation is idempotent', () {
      final habit = HabitModel(
        id: 'habit_sleep',
        title: '8 Hours Sleep',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 10, 1),
        checkIns: const {'2026-10-10': true},
      );

      final payload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'dev_1',
        lastModifiedAt: DateTime(2026, 10, 12),
        activeThemeId: UserThemeModel.obsidianTwilight.id,
        userThemes: UserThemeModel.builtInPresets,
        habits: [habit],
      );

      final mergedOnce = mergePayloads(local: payload, incoming: payload);
      final mergedTwice = mergePayloads(local: mergedOnce, incoming: payload);

      expect(mergedTwice.habits.length, 1);
      expect(mergedTwice.habits.first.checkIns, habit.checkIns);
      expect(mergedTwice.userThemes.length, mergedOnce.userThemes.length);
    });
  });
}
