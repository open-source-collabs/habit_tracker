import 'package:flutter/material.dart';

/// Semantic colors, base surfaces, and vibrant habit palettes
/// representing the "Dusk & Dawn" mental wellness aesthetic.
abstract final class AppColors {
  // --- Dark Base Surfaces ("Dusk") ---
  static const Color obsidianTwilight = Color(0xFF0F1016);
  static const Color cardSurface = Color(0xFF181924);
  static const Color surfaceElevated = Color(0xFF202230);
  static const Color borderSubtle = Color(0xFF262837);
  static const Color borderActive = Color(0xFF383B4F);

  // --- Light Base Surfaces ("Dawn") ---
  static const Color porcelainBg = Color(0xFFF8F9FD);
  static const Color porcelainCard = Color(0xFFFFFFFF);
  static const Color porcelainBorder = Color(0xFFE2E8F0);

  // --- Vibrant Habit Accent Palette ---
  static const Color sunsetCoral = Color(0xFFFF6B55);
  static const Color neonLavender = Color(0xFF8B5CF6);
  static const Color emeraldMint = Color(0xFF10B981);
  static const Color cyanGlow = Color(0xFF06B6D4);
  static const Color mangoSunrise = Color(0xFFFFAE33);
  static const Color bubblegumPink = Color(0xFFEC4899);

  // --- Reference Design Surfaces & Accents ---
  static const Color nordicTeal = Color(0xFF0E4856);
  static const Color nordicMist = Color(0xFFEBF2F5);
  static const Color nordicBorder = Color(0xFFDCE5EA);

  static const Color peachMist = Color(0xFFFFF7F2);

  /// Warm Peach border outline (#F5E2D8)
  static const Color peachBorder = Color(0xFFF5E2D8);

  /// Ethereal Orchid accent (#A855F7)
  static const Color etherealOrchid = Color(0xFFA855F7);

  /// Rose Quartz accent (#FB7185)
  static const Color roseQuartz = Color(0xFFFB7185);

  /// Deep Espresso Plum text (#231924)
  static const Color espressoText = Color(0xFF231924);

  /// Immutable list of the core vibrant habit accent colors
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
    return Color.alphaBlend(accent.withValues(alpha: opacity), porcelainCard);
  }

  // --- Typography & Content Hierarchy (Dark) ---
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF475569);

  // --- Typography & Content Hierarchy (Light) ---
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // --- Semantic State Feedback ---
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFFAE33);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);

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
