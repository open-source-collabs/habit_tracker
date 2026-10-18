import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/theme/app_fonts.dart';
import 'package:habit_tracker/core/theme/theme_factory.dart';
import 'package:habit_tracker/core/widgets/app_screen_util_init.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';
import 'package:habit_tracker/features/themes/presentation/widgets/theme_studio/theme_studio_font_selector.dart';

void main() {
  group('AppFonts', () {
    test('bundles six distinct families', () {
      final families = AppFonts.options.map((o) => o.family).toSet();
      expect(families, hasLength(6));
      expect(
        families,
        containsAll(<String>[
          AppFonts.outfit,
          AppFonts.manrope,
          AppFonts.dmSans,
          AppFonts.sora,
        ]),
      );
    });

    test('resolve keeps bundled families and falls back otherwise', () {
      expect(AppFonts.resolve(AppFonts.sora), AppFonts.sora);
      expect(AppFonts.resolve('Comic Sans'), AppFonts.fallback);
      expect(AppFonts.resolve(null), AppFonts.fallback);
    });

    test('ThemeFactory never applies an unbundled family', () {
      final theme = ThemeFactory.createTheme(
        UserThemeModel.obsidianTwilight.copyWith(fontFamily: 'Unknown'),
      );
      expect(theme.textTheme.bodyMedium?.fontFamily, AppFonts.fallback);
    });

    test('every family and license is declared in pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final option in AppFonts.options) {
        expect(
          RegExp('family: ${option.family}\\s*\$', multiLine: true)
              .hasMatch(pubspec),
          isTrue,
          reason: option.family,
        );
      }
      for (final path in AppFonts.licenseAssets.values) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });
  });

  testWidgets('font selector shows every font and reports taps',
      (tester) async {
    String? picked;
    const theme = UserThemeModel.obsidianTwilight;
    final themeData = ThemeFactory.createTheme(theme);

    await tester.pumpWidget(
      AppScreenUtilInit(
        builder: (context) => MaterialApp(
          theme: themeData,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ThemeStudioFontSelector(
                theme: theme,
                previewTheme: themeData,
                onFontSelected: (font) => picked = font,
              ),
            ),
          ),
        ),
      ),
    );

    for (final option in AppFonts.options) {
      expect(find.text(option.displayName), findsOneWidget);
    }
    expect(find.textContaining('6 PROFESSIONAL FONTS'), findsOneWidget);

    await tester.tap(find.text('Outfit'));
    expect(picked, AppFonts.outfit);
  });
}
