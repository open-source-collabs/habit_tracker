import 'package:flutter/material.dart';

/// Flutter [ThemeExtension] enabling dynamic access to card borders,
/// elevated surfaces, vibrant habit palettes, and active-state glowing shadows.
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color cardBorder;
  final Color surfaceElevated;
  final List<Color> accentPalette;

  const AppThemeExtension({
    required this.cardBorder,
    required this.surfaceElevated,
    required this.accentPalette,
  });

  /// Produces the signature glowing accent drop shadow for active habit cards
  BoxShadow cardGlowShadow(
    Color accent, {
    double blurRadius = 20.0,
    double alpha = 0.35,
  }) {
    return BoxShadow(
      color: accent.withValues(alpha: alpha),
      blurRadius: blurRadius,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    );
  }

  /// Builds a 24px rounded card decoration with 1.2px borders and active glow
  BoxDecoration cardDecoration({
    required Color cardColor,
    Color? accentColor,
    bool isActive = false,
    double borderRadius = 24.0,
    double borderWidth = 1.2,
  }) {
    final effectiveBorderColor =
        (isActive && accentColor != null) ? accentColor : cardBorder;

    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: effectiveBorderColor,
        width: borderWidth,
      ),
      boxShadow: (isActive && accentColor != null)
          ? [cardGlowShadow(accentColor)]
          : const [],
    );
  }

  @override
  AppThemeExtension copyWith({
    Color? cardBorder,
    Color? surfaceElevated,
    List<Color>? accentPalette,
  }) {
    return AppThemeExtension(
      cardBorder: cardBorder ?? this.cardBorder,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      accentPalette: accentPalette ?? this.accentPalette,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t) ?? cardBorder,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t) ??
          surfaceElevated,
      accentPalette: t < 0.5 ? accentPalette : other.accentPalette,
    );
  }
}
