import 'package:flutter/material.dart';

import '../../features/themes/data/models/dynamic_theme_model.dart';
import 'app_colors.dart';
import 'app_theme_extension.dart';
import 'theme_factory.dart';

/// Pre-configured base themes and theme helpers.
abstract final class AppTheme {
  /// Default Dusk dark theme (Obsidian Twilight)
  static final ThemeData darkTheme = ThemeFactory.createTheme(
    UserThemeModel.obsidianTwilight,
  );

  /// Default Dawn light theme (Porcelain Sunrise)
  static final ThemeData lightTheme = ThemeFactory.createTheme(
    UserThemeModel.porcelainSunrise,
  );
}

/// Convenience extension on [BuildContext] to access custom tokens effortlessly.
extension ThemeExtensionHelper on BuildContext {
  /// Base ThemeData from the active context
  ThemeData get theme => Theme.of(this);

  /// Standard Material text hierarchy
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Material 3 ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Custom design system extension tokens (card borders, elevated surfaces, glow shadows)
  AppThemeExtension get appThemeExtension =>
      Theme.of(this).extension<AppThemeExtension>() ??
      const AppThemeExtension(
        cardBorder: AppColors.borderSubtle,
        surfaceElevated: AppColors.surfaceElevated,
        accentPalette: [],
      );

  /// Semantic Scaffold background color
  Color get scaffoldBackgroundColor => theme.scaffoldBackgroundColor;

  /// Semantic Card background surface
  Color get cardBackgroundColor => colorScheme.surface;

  /// Semantic 1.2px subtle card border outline
  Color get cardBorderColor => appThemeExtension.cardBorder;

  /// Elevated surface for floating pills or elevated modules
  Color get surfaceElevatedColor => appThemeExtension.surfaceElevated;

  /// Primary vibrant accent color
  Color get primaryAccent => colorScheme.primary;

  /// Secondary accent color
  Color get secondaryAccent => colorScheme.secondary;

  /// High-contrast text/icon color on primary accents
  Color get onPrimaryColor => colorScheme.onPrimary;

  /// Primary high-contrast text color
  Color get textPrimaryColor => colorScheme.onSurface;

  /// Secondary subdued text color
  Color get textSecondaryColor =>
      isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryLight;

  /// Muted or helper text color
  Color get textMutedColor =>
      isDarkMode ? AppColors.textMuted : AppColors.textMutedLight;

  /// Semantic transparent color
  Color get transparent => AppColors.transparent;

  /// Context-aware ambient shadow color
  Color get shadowColor => AppColors.shadow(isDark: isDarkMode);

  /// Modal dialog backdrop barrier color
  Color get barrierColor => AppColors.barrier;

  /// Semantic status colors
  Color get errorColor => AppColors.error;
  Color get successColor => AppColors.success;
  Color get warningColor => AppColors.warning;
  Color get infoColor => AppColors.info;

  /// Whether current theme is dark mode
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// Dynamic list of accent colors from active theme
  List<Color> get accentPalette => appThemeExtension.accentPalette.isNotEmpty
      ? appThemeExtension.accentPalette
      : AppColors.unmodifiableHabitPalette;
}
