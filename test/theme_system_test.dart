import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/data/app_data_repository.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';
import 'package:habit_tracker/core/theme/app_theme_extension.dart';
import 'package:habit_tracker/core/theme/theme_factory.dart';
import 'package:habit_tracker/core/utils/haptics.dart';
import 'package:habit_tracker/features/habits/data/storage/habit_storage.dart';
import 'package:habit_tracker/features/habits/data/storage/web_habit_storage.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';
import 'package:habit_tracker/features/themes/data/storage/legacy_theme_preferences.dart';
import 'package:habit_tracker/features/themes/presentation/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps theme persistence off the real disk.
Override _inMemoryStorage([HabitStorage? storage]) => habitStorageProvider
    .overrideWithValue(storage ?? WebHabitStorage(InMemoryWebStore()));

const _neonCyber = UserThemeModel(
  id: 'custom_neon',
  name: 'Neon Cyber',
  fontFamily: 'Inter',
  scaffoldBgHex: '#0A0A0F',
  cardBgHex: '#12121A',
  cardBorderHex: '#222233',
  textPrimaryHex: '#FFFFFF',
  accentPaletteHex: ['#8B5CF6'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppColors & Hex Utilities', () {
    test('hexToColor parses valid hex strings correctly', () {
      expect(AppColors.hexToColor('#0F1016'), const Color(0xFF0F1016));
      expect(AppColors.hexToColor('0F1016'), const Color(0xFF0F1016));
      expect(AppColors.hexToColor('#FF6B55'), const Color(0xFFFF6B55));
    });

    test('colorToHex produces uppercase hex strings', () {
      expect(AppColors.colorToHex(const Color(0xFF0F1016)), '#0F1016');
      expect(AppColors.colorToHex(const Color(0xFFFF6B55)), '#FF6B55');
    });

    test(
      'habitPalette contains exactly 6 vibrant colors and is unmodifiable',
      () {
        expect(AppColors.habitPalette.length, 6);
        expect(
          AppColors.unmodifiableHabitPalette,
          containsAll([
            AppColors.sunsetCoral,
            AppColors.neonLavender,
            AppColors.emeraldMint,
            AppColors.cyanGlow,
            AppColors.mangoSunrise,
            AppColors.bubblegumPink,
          ]),
        );
      },
    );
  });

  group('UserThemeModel', () {
    test('JSON serialization round-trip succeeds', () {
      const original = UserThemeModel.obsidianTwilight;
      final json = original.toJson();
      final reconstructed = UserThemeModel.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.name, original.name);
      expect(reconstructed.fontFamily, original.fontFamily);
      expect(reconstructed.scaffoldBgHex, original.scaffoldBgHex);
      expect(reconstructed.cardBgHex, original.cardBgHex);
      expect(reconstructed.cardBorderHex, original.cardBorderHex);
      expect(reconstructed.textPrimaryHex, original.textPrimaryHex);
      expect(reconstructed.accentPaletteHex, original.accentPaletteHex);
      expect(reconstructed.isBuiltIn, original.isBuiltIn);
    });

    test('copyWith updates properties accurately', () {
      final modified = UserThemeModel.obsidianTwilight.copyWith(
        name: 'Custom Midnight',
        fontFamily: 'Inter',
      );

      expect(modified.name, 'Custom Midnight');
      expect(modified.fontFamily, 'Inter');
      expect(modified.id, UserThemeModel.obsidianTwilight.id);
    });

    test('builtInPresets contains Nordic Serenity, Sunset Aurora, Obsidian Twilight, and Porcelain Sunrise', () {
      final presets = UserThemeModel.builtInPresets;
      expect(presets.length, 4);
      expect(presets.any((t) => t.id == 'nordic_serenity'), isTrue);
      expect(presets.any((t) => t.id == 'sunset_aurora'), isTrue);
      expect(presets.any((t) => t.id == 'obsidian_twilight'), isTrue);
      expect(presets.any((t) => t.id == 'porcelain_sunrise'), isTrue);
    });
  });

  group('ThemeFactory & AppThemeExtension', () {
    test(
      'generates ThemeData with 24px rounded card geometry and 1.2px borders',
      () {
        final theme = ThemeFactory.createTheme(UserThemeModel.obsidianTwilight);

        expect(theme.scaffoldBackgroundColor, const Color(0xFF0F1016));
        expect(theme.cardTheme.elevation, 0);
        expect(theme.cardTheme.color, const Color(0xFF181924));

        final shape = theme.cardTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(24.0));
        expect(shape.side.color, const Color(0xFF262837));
        expect(shape.side.width, 1.2);
      },
    );

    test('AppThemeExtension generates active glowing drop shadows', () {
      final theme = ThemeFactory.createTheme(UserThemeModel.obsidianTwilight);
      final extension = theme.extension<AppThemeExtension>();

      expect(extension, isNotNull);
      const testAccent = Color(0xFFFF6B55);
      final shadow = extension!.cardGlowShadow(testAccent);

      expect(shadow.blurRadius, 20.0);
      expect(shadow.color.a, closeTo(0.35, 0.01));
    });
  });

  group('AppHaptics Safety', () {
    test('executes all tactile methods without uncaught exceptions', () async {
      expect(AppHaptics.lightImpact, returnsNormally);
      expect(AppHaptics.selectionClick, returnsNormally);
      expect(AppHaptics.mediumImpact, returnsNormally);
      expect(AppHaptics.heavyImpact, returnsNormally);
      expect(AppHaptics.vibrate, returnsNormally);
    });
  });

  group('ThemeNotifier State & Operations', () {
    test('initializes with builtInPresets and Obsidian Twilight active', () {
      final container = ProviderContainer(overrides: [_inMemoryStorage()]);
      addTearDown(container.dispose);

      final state = container.read(themeProvider);

      expect(state.allThemes.length, greaterThanOrEqualTo(2));
      expect(state.activeThemeId, 'obsidian_twilight');
      expect(state.activeTheme.name, 'Obsidian Twilight');
    });

    test(
      'saves, duplicates, and deletes custom themes protecting built-ins',
      () async {
        final container = ProviderContainer(overrides: [_inMemoryStorage()]);
        addTearDown(container.dispose);

        final notifier = container.read(themeProvider.notifier);

        // Create new custom theme
        const customTheme = UserThemeModel(
          id: 'custom_test_1',
          name: 'Neon Cyber',
          fontFamily: 'Inter',
          scaffoldBgHex: '#0A0A0F',
          cardBgHex: '#12121A',
          cardBorderHex: '#222233',
          textPrimaryHex: '#FFFFFF',
          accentPaletteHex: ['#8B5CF6'],
          isBuiltIn: false,
        );

        await notifier.saveCustomTheme(customTheme);
        expect(container.read(themeProvider).activeThemeId, 'custom_test_1');
        expect(
          container
              .read(themeProvider)
              .allThemes
              .any((t) => t.id == 'custom_test_1'),
          isTrue,
        );

        // Duplicate
        final copy = await notifier.duplicateTheme(customTheme);
        expect(copy.name, 'Neon Cyber (Copy)');
        expect(container.read(themeProvider).activeThemeId, copy.id);

        // Attempt to delete built-in (should be blocked)
        await notifier.deleteTheme('obsidian_twilight');
        expect(
          container
              .read(themeProvider)
              .allThemes
              .any((t) => t.id == 'obsidian_twilight'),
          isTrue,
        );

        // Delete custom theme
        await notifier.deleteTheme(customTheme.id);
        expect(
          container
              .read(themeProvider)
              .allThemes
              .any((t) => t.id == 'custom_test_1'),
          isFalse,
        );
      },
    );

    test(
      'saving an edited built-in preset creates a new custom theme',
      () async {
        final container = ProviderContainer(overrides: [_inMemoryStorage()]);
        addTearDown(container.dispose);

        final edited = UserThemeModel.obsidianTwilight.copyWith(
          name: 'My Twilight',
        );
        final saved = await container
            .read(themeProvider.notifier)
            .saveCustomTheme(edited);

        expect(saved.id, isNot(UserThemeModel.obsidianTwilight.id));
        expect(saved.isBuiltIn, isFalse);

        final state = container.read(themeProvider);
        final ids = state.allThemes.map((t) => t.id).toList();
        expect(
          ids.toSet().length,
          ids.length,
          reason: 'theme ids must be unique',
        );
        expect(
          state.allThemes.firstWhere(
            (t) => t.id == UserThemeModel.obsidianTwilight.id,
          ),
          UserThemeModel.obsidianTwilight,
        );
        expect(state.activeThemeId, saved.id);
      },
    );

    test(
      'themes persist in the app payload and reload in a new session',
      () async {
        final storage = WebHabitStorage(InMemoryWebStore());

        final first = ProviderContainer(overrides: [_inMemoryStorage(storage)]);
        await first.read(themeProvider.notifier).saveCustomTheme(_neonCyber);
        await first.read(appDataRepositoryProvider).flush();
        first.dispose();

        final stored = await storage.loadPayload();
        expect(stored!.activeThemeId, 'custom_neon');
        expect(stored.userThemes.map((t) => t.id), [
          'custom_neon',
        ], reason: 'built-in presets are not persisted');

        final second = ProviderContainer(
          overrides: [_inMemoryStorage(storage)],
        );
        addTearDown(second.dispose);
        second.read(themeProvider);
        await second.read(appDataRepositoryProvider).load();
        await pumpEventQueue();

        expect(second.read(themeProvider).activeThemeId, 'custom_neon');
      },
    );

    test(
      'migrates legacy SharedPreferences themes into the payload once',
      () async {
        SharedPreferences.setMockInitialValues({
          LegacyThemePreferences.customThemesKey: '[${_jsonOf(_neonCyber)}]',
          LegacyThemePreferences.activeThemeKey: 'custom_neon',
        });
        final storage = WebHabitStorage(InMemoryWebStore());

        final container = ProviderContainer(
          overrides: [_inMemoryStorage(storage)],
        );
        addTearDown(container.dispose);
        container.read(themeProvider);
        await pumpEventQueue();
        await container.read(appDataRepositoryProvider).flush();

        expect(container.read(themeProvider).activeThemeId, 'custom_neon');
        expect((await storage.loadPayload())!.activeThemeId, 'custom_neon');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(LegacyThemePreferences.customThemesKey), isNull);
        expect(prefs.getString(LegacyThemePreferences.activeThemeKey), isNull);
      },
    );
  });
}

String _jsonOf(UserThemeModel theme) => jsonEncode(theme.toJson());
