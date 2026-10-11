import 'package:flutter/material.dart';
import 'app_theme_extension.dart';
import 'dynamic_theme_model.dart';
import 'theme_factory.dart';

/// Pre-configured base themes and theme helpers.
abstract final class AppTheme {
  /// Default Dusk dark theme (Obsidian Twilight)
  static final ThemeData darkTheme =
      ThemeFactory.createTheme(UserThemeModel.obsidianTwilight);

  /// Default Dawn light theme (Porcelain Sunrise)
  static final ThemeData lightTheme =
      ThemeFactory.createTheme(UserThemeModel.porcelainSunrise);
}

/// Convenience extension on [BuildContext] to access custom tokens effortlessly.
extension ThemeExtensionHelper on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  AppThemeExtension get appThemeExtension =>
      Theme.of(this).extension<AppThemeExtension>() ??
      const AppThemeExtension(
        cardBorder: Color(0xFF262837),
        surfaceElevated: Color(0xFF202230),
        accentPalette: [],
      );
}
