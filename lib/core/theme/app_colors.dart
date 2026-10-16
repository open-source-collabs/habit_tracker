import 'package:flutter/material.dart';

/// Semantic colors, base surfaces, and vibrant habit palettes
/// representing the "Dusk & Dawn" mental wellness aesthetic.
abstract final class AppColors {
  // ===========================================================================
  // Tier 1: Primitives, Scrims & Ambient Shadows
  // ===========================================================================
  static const Color transparent = Color(0x00000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color black87 = Color(0xDD000000);

  /// Canonical modal scrim and overlays
  static const Color scrim = Color(0x80000000); // 50% black
  static const Color barrier = Color(0x8C000000); // 55% modal barrier
  static const Color overlay50 = scrim;

  /// Ambient elevations
  static const Color shadowDark = Color(0x40000000); // 25% black
  static const Color shadowLight = Color(0x0A000000); // 4% black

  /// Dynamic shadow color respecting theme brightness
  static Color shadow({required bool isDark}) =>
      isDark ? shadowDark : shadowLight;

  // ===========================================================================
  // Tier 2: Neutral Slate Palette (Single Hex Source of Truth)
  // ===========================================================================
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate900 = Color(0xFF0F172A);

  // Semantic Typography Mappings (Zero duplicate hex codes)
  static const Color textPrimary = slate50;
  static const Color textSecondary = slate400;
  static const Color textMuted = slate500;
  static const Color textDisabled = slate600;

  static const Color textPrimaryLight = slate900;
  static const Color textSecondaryLight = slate600;
  static const Color textMutedLight = slate400;

  // ===========================================================================
  // Tier 3: Base Surfaces ("Dusk & Dawn")
  // ===========================================================================
  // Dusk (Dark Mode)
  static const Color obsidianTwilight = Color(0xFF0F1016);
  static const Color darkScaffold = obsidianTwilight;
  static const Color cardSurface = Color(0xFF181924);
  static const Color surfaceElevated = Color(0xFF202230);
  static const Color borderSubtle = Color(0xFF262837);

  // Dawn (Light Mode)
  static const Color porcelainBg = Color(0xFFF8F9FD);
  static const Color porcelainCard =
      white; // Canonical alias to white (zero duplicate hex)
  static const Color porcelainBorder = Color(0xFFE2E8F0);

  // ===========================================================================
  // Tier 4: Vibrant Habit Accents & Semantic Feedback
  // ===========================================================================
  static const Color sunsetCoral = Color(0xFFFF6B55);
  static const Color neonLavender = Color(0xFF8B5CF6);
  static const Color emeraldMint = Color(0xFF10B981);
  static const Color cyanGlow = Color(0xFF06B6D4);
  static const Color mangoSunrise = Color(0xFFFFAE33);
  static const Color bubblegumPink = Color(0xFFEC4899);
  static const Color crimsonError = Color(0xFFEF4444);

  // Semantic Status Aliases (Cleanly mapped to palette, zero duplicate hexes)
  static const Color success = emeraldMint;
  static const Color warning = mangoSunrise;
  static const Color info = cyanGlow;
  static const Color error = crimsonError;

  // ===========================================================================
  // Tier 5: Curated Editorial Swatches
  // ===========================================================================
  static const Color nordicTeal = Color(0xFF0E4856);
  static const Color nordicMist = Color(0xFFEBF2F5);
  static const Color nordicBorder = Color(0xFFDCE5EA);
  static const Color peachMist = Color(0xFFFFF7F2);
  static const Color peachBorder = Color(0xFFF5E2D8);
  static const Color etherealOrchid = Color(0xFFA855F7);
  static const Color roseQuartz = Color(0xFFFB7185);
  static const Color espressoText = Color(0xFF231924);

  // ===========================================================================
  // Tier 6: Habit Palette & Utilities
  // ===========================================================================
  static const List<Color> habitPalette = <Color>[
    sunsetCoral,
    neonLavender,
    emeraldMint,
    cyanGlow,
    mangoSunrise,
    bubblegumPink,
  ];

  /// Unmodifiable view of the habit accent colors
  static List<Color> get unmodifiableHabitPalette =>
      List.unmodifiable(habitPalette);

  /// Full hue wheel (red → yellow → green → cyan → blue → purple → red)
  /// used for "custom color" swatches and hue sweep gradients.
  static const List<Color> hueSpectrum = [
    Color(0xFFF44336), // red
    Color(0xFFFFEB3B), // yellow
    Color(0xFF4CAF50), // green
    Color(0xFF00BCD4), // cyan
    Color(0xFF2196F3), // blue
    Color(0xFF9C27B0), // purple
    Color(0xFFF44336), // red (closes the sweep)
  ];

  /// Computes a pastel container surface for habit chips and activity cards.
  /// In light themes, creates a soft watercolor tint. In dark themes, creates an ambient glow.
  static Color pastelSurface(
    Color accent, {
    bool isDark = false,
    double opacity = 0.12,
  }) {
    if (isDark) {
      return Color.alphaBlend(
        accent.withValues(alpha: opacity + 0.04),
        cardSurface,
      );
    }
    return Color.alphaBlend(accent.withValues(alpha: opacity), white);
  }

  // --- Hex Utilities ---
  /// Parses a hex color string (e.g., `#0F1016`, `#FF0F1016`, `0F1016`).
  /// Falls back to [fallback] if parsing fails.
  static Color hexToColor(String hex, {Color fallback = obsidianTwilight}) {
    final cleanHex = hex.replaceAll('#', '').trim();
    if (cleanHex.length == 6) {
      final value = int.tryParse('FF$cleanHex', radix: 16);
      if (value != null) return Color(value);
    } else if (cleanHex.length == 8) {
      final value = int.tryParse(cleanHex, radix: 16);
      if (value != null) return Color(value);
    }
    return fallback;
  }

  /// Converts a [Color] into a standard `#RRGGBB` or `#AARRGGBB` hex string.
  static String colorToHex(Color color, {bool includeAlpha = false}) {
    final a = (color.a * 255).round().toRadixString(16).padLeft(2, '0');
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return includeAlpha
        ? '#${a.toUpperCase()}${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}'
        : '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}';
  }
}
