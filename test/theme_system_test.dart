import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';
import 'package:habit_tracker/core/theme/app_theme_extension.dart';
import 'package:habit_tracker/core/theme/theme_factory.dart';
import 'package:habit_tracker/core/utils/haptics.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';
import 'package:habit_tracker/features/themes/presentation/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    test('habitPalette contains exactly 6 vibrant colors and is unmodifiable', () {
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
    });
  });

  group('UserThemeModel', () {
    test('JSON serialization round-trip succeeds', () {
      final original = UserThemeModel.obsidianTwilight;
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
    test('generates ThemeData with 24px rounded card geometry and 1.2px borders', () {
      final theme = ThemeFactory.createTheme(UserThemeModel.obsidianTwilight);

      expect(theme.scaffoldBackgroundColor, const Color(0xFF0F1016));
      expect(theme.cardTheme.elevation, 0);
      expect(theme.cardTheme.color, const Color(0xFF181924));

      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(24.0));
      expect(shape.side.color, const Color(0xFF262837));
      expect(shape.side.width, 1.2);
    });

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
      await expectLater(AppHaptics.lightImpact(), completes);
      await expectLater(AppHaptics.selectionClick(), completes);
      await expectLater(AppHaptics.mediumImpact(), completes);
      await expectLater(AppHaptics.heavyImpact(), completes);
      await expectLater(AppHaptics.vibrate(), completes);
    });
  });

  group('ThemeNotifier State & Operations', () {
    test('initializes with builtInPresets and Obsidian Twilight active', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(themeProvider);

      expect(state.allThemes.length, greaterThanOrEqualTo(2));
      expect(state.activeThemeId, 'obsidian_twilight');
      expect(state.activeTheme.name, 'Obsidian Twilight');
    });

    test('saves, duplicates, and deletes custom themes protecting built-ins', () async {
      final container = ProviderContainer();
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
        container.read(themeProvider).allThemes.any((t) => t.id == 'custom_test_1'),
        isTrue,
      );

      // Duplicate
      final copy = await notifier.duplicateTheme(customTheme);
      expect(copy.name, 'Neon Cyber (Copy)');
      expect(container.read(themeProvider).activeThemeId, copy.id);

      // Attempt to delete built-in (should be blocked)
      await notifier.deleteTheme('obsidian_twilight');
      expect(
        container.read(themeProvider).allThemes.any((t) => t.id == 'obsidian_twilight'),
        isTrue,
      );

      // Delete custom theme
      await notifier.deleteTheme(customTheme.id);
      expect(
        container.read(themeProvider).allThemes.any((t) => t.id == 'custom_test_1'),
        isFalse,
      );
    });
  });
}
