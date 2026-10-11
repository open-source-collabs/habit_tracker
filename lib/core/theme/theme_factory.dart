import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme_extension.dart';
import 'dynamic_theme_model.dart';

/// Pure factory for transforming any [UserThemeModel] into a complete [ThemeData]
/// with dynamic typography, card geometry, and [AppThemeExtension].
abstract final class ThemeFactory {
  /// Builds a complete [ThemeData] from a [UserThemeModel].
  static ThemeData createTheme(UserThemeModel model) {
    final isDark = model.isDark;
    final primaryAccent = model.accentPalette.isNotEmpty
        ? model.accentPalette.first
        : AppColors.neonLavender;
    final secondaryAccent = model.accentPalette.length > 1
        ? model.accentPalette[1]
        : AppColors.cyanGlow;

    final colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primaryAccent,
      onPrimary: Colors.white,
      secondary: secondaryAccent,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: model.cardBg,
      onSurface: model.textPrimary,
      outline: model.cardBorder,
      outlineVariant: model.cardBorder.withValues(alpha: 0.6),
    );

    // Build the dynamic geometric TextTheme with tight letter spacing
    final textTheme = _buildTextTheme(
      fontFamily: model.fontFamily,
      primaryTextColor: model.textPrimary,
      isDark: isDark,
    );

    // Elevated surface computation (subtly lighter for dark, deeper for light)
    final surfaceElevated = isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.05), model.cardBg)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.03), model.cardBg);

    final appExtension = AppThemeExtension(
      cardBorder: model.cardBorder,
      surfaceElevated: surfaceElevated,
      accentPalette: model.accentPalette,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: model.scaffoldBg,
      canvasColor: model.scaffoldBg,
      fontFamily: model.fontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      // 24px border radius with subtle 1.2px border and zero elevation
      cardTheme: CardThemeData(
        elevation: 0,
        color: model.cardBg,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: BorderSide(
            color: model.cardBorder,
            width: 1.2,
          ),
        ),
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: model.textPrimary),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: model.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Dialogs & Bottom Sheets
      dialogTheme: DialogThemeData(
        backgroundColor: model.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: BorderSide(color: model.cardBorder, width: 1.2),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: model.cardBg,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
        ),
      ),

      // Smooth Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: model.cardBorder,
        thickness: 1.2,
        space: 1.2,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: model.cardBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: model.cardBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: model.cardBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: primaryAccent, width: 1.6),
        ),
      ),

      // Extensions
      extensions: [appExtension],
    );
  }

  /// Constructs the typography hierarchy with tight letter spacing
  static TextTheme _buildTextTheme({
    required String fontFamily,
    required Color primaryTextColor,
    required bool isDark,
  }) {
    final secondaryTextColor =
        isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final mutedTextColor =
        isDark ? AppColors.textMuted : AppColors.textMutedLight;

    return TextTheme(
      // Display: Extra prominent headings with aggressive tight tracking
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: primaryTextColor,
        height: 1.15,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: primaryTextColor,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: primaryTextColor,
        height: 1.25,
      ),

      // Headlines
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: primaryTextColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: primaryTextColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: primaryTextColor,
      ),

      // Titles
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: primaryTextColor,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: primaryTextColor,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: secondaryTextColor,
      ),

      // Body: Clean, crisp text
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        color: primaryTextColor,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.15,
        color: secondaryTextColor,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color: mutedTextColor,
        height: 1.35,
      ),

      // Labels: Compact badges and tabs
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: primaryTextColor,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.0,
        color: secondaryTextColor,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.0,
        color: mutedTextColor,
      ),
    );
  }
}
