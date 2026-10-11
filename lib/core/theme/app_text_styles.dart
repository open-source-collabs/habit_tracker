import 'package:flutter/material.dart';

import 'app_font_sizes.dart';
import 'app_theme.dart';

/// Semantic typographic styles dynamically conforming to the active theme's
/// font family, line heights, letter-spacing, and color hierarchy.
abstract final class AppTextStyles {
  /// Display Large (32.sp): Monumental metrics and celebrations
  static TextStyle displayLarge(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w900,
  }) {
    return TextStyle(
      fontFamily: context.theme.textTheme.bodyMedium?.fontFamily,
      fontSize: AppFontSizes.displayLarge,
      fontWeight: fontWeight,
      letterSpacing: -0.5,
      color: color ?? context.textPrimaryColor,
      height: 1.2,
    );
  }

  /// Display Medium (28.sp): Major metric counters and hero progress
  static TextStyle displayMedium(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w800,
  }) {
    return TextStyle(
      fontFamily: context.theme.textTheme.bodyMedium?.fontFamily,
      fontSize: AppFontSizes.displayMedium,
      fontWeight: fontWeight,
      letterSpacing: -0.4,
      color: color ?? context.textPrimaryColor,
      height: 1.22,
    );
  }

  /// Headline Large (22.sp): Main screen headers & hero titles
  static TextStyle headlineLarge(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w800,
  }) {
    return TextStyle(
      fontFamily: context.theme.textTheme.bodyMedium?.fontFamily,
      fontSize: AppFontSizes.headlineLarge,
      fontWeight: fontWeight,
      letterSpacing: -0.35,
      color: color ?? context.textPrimaryColor,
      height: 1.25,
    );
  }

  /// Headline Medium (20.sp): App bar titles and primary section titles
  static TextStyle headlineMedium(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: context.theme.textTheme.bodyMedium?.fontFamily,
      fontSize: AppFontSizes.headlineMedium,
      fontWeight: fontWeight,
      letterSpacing: -0.3,
      color: color ?? context.textPrimaryColor,
      height: 1.3,
    );
  }

  /// Headline Small (18.sp): Section headers, modal titles
  static TextStyle headlineSmall(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: context.theme.textTheme.bodyMedium?.fontFamily,
      fontSize: AppFontSizes.headlineSmall,
      fontWeight: fontWeight,
      letterSpacing: -0.25,
      color: color ?? context.textPrimaryColor,
      height: 1.3,
    );
  }

  /// Title Large (18.sp): Card titles, dialog headers
  static TextStyle titleLarge(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: context.theme.textTheme.bodyMedium?.fontFamily,
      fontSize: AppFontSizes.titleLarge,
      fontWeight: fontWeight,
      letterSpacing: -0.2,
      color: color ?? context.textPrimaryColor,
      height: 1.3,
    );
  }

  /// Title Medium (16.sp): Bento habit card title, list item headers
  static TextStyle titleMedium(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: context.theme.textTheme.bodyMedium?.fontFamily,
      fontSize: AppFontSizes.titleMedium,
      fontWeight: fontWeight,
      letterSpacing: -0.2,
      color: color ?? context.textPrimaryColor,
      height: 1.35,
    );
  }

  /// Title Small (14.sp): Secondary titles, metric subtitles
  static TextStyle titleSmall(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: context.theme.textTheme.bodyMedium?.fontFamily,
      fontSize: AppFontSizes.titleSmall,
      fontWeight: fontWeight,
      letterSpacing: -0.15,
      color: color ?? context.textPrimaryColor,
      height: 1.35,
    );
  }

  /// Body Large (16.sp): Prominent paragraph text & dialog content
  static TextStyle bodyLarge(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: context.theme.textTheme.bodyMedium?.fontFamily,
      fontSize: AppFontSizes.bodyLarge,
      fontWeight: fontWeight,
      letterSpacing: -0.2,
      color: color ?? context.textPrimaryColor,
      height: 1.45,
    );
  }

  /// Body Medium (14.sp): Standard description, notes, input field text
  static TextStyle bodyMedium(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: context.theme.textTheme.bodyMedium?.fontFamily,
      fontSize: AppFontSizes.bodyMedium,
      fontWeight: fontWeight,
      letterSpacing: -0.15,
      color: color ?? context.textSecondaryColor,
      height: 1.4,
    );
  }

  /// Body Small (12.sp): Compact secondary descriptions, helper text
  static TextStyle bodySmall(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: context.theme.textTheme.bodyMedium?.fontFamily,
      fontSize: AppFontSizes.bodySmall,
      fontWeight: fontWeight,
      letterSpacing: -0.1,
      color: color ?? context.textMutedColor,
      height: 1.35,
    );
  }

  /// Label Large (14.sp): Primary button text, prominent action tabs
  static TextStyle labelLarge(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: context.theme.textTheme.bodyMedium?.fontFamily,
      fontSize: AppFontSizes.labelLarge,
      fontWeight: fontWeight,
      letterSpacing: 0.2,
      color: color ?? context.textPrimaryColor,
      height: 1.2,
    );
  }

  /// Label Medium (12.sp): Filter chips, standard buttons, tabs
  static TextStyle labelMedium(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: context.theme.textTheme.bodyMedium?.fontFamily,
      fontSize: AppFontSizes.labelMedium,
      fontWeight: fontWeight,
      letterSpacing: 0.1,
      color: color ?? context.textPrimaryColor,
      height: 1.2,
    );
  }

  /// Label Small (11.sp): Section headers (e.g. 'ACTIVE HABITS'), streak badges
  static TextStyle labelSmall(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w800,
    bool uppercase = true,
  }) {
    return TextStyle(
      fontFamily: context.theme.textTheme.bodyMedium?.fontFamily,
      fontSize: AppFontSizes.labelSmall,
      fontWeight: fontWeight,
      letterSpacing: uppercase ? 1.2 : 0.0,
      color: color ?? context.textMutedColor,
      height: 1.2,
    );
  }

  /// Micro (10.sp): Tiny category pills, frequency tags
  static TextStyle micro(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w800,
    bool uppercase = true,
  }) {
    return TextStyle(
      fontFamily: context.theme.textTheme.bodyMedium?.fontFamily,
      fontSize: AppFontSizes.micro,
      fontWeight: fontWeight,
      letterSpacing: uppercase ? 1.0 : 0.0,
      color: color ?? context.textMutedColor,
      height: 1.2,
    );
  }
}
