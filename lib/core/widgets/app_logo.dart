import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_theme.dart';

/// Colors of the "Bento Check" brand mark.
///
/// Brand accents stay fixed across user themes so the logo is recognisable;
/// only the surfaces adapt to Dusk (dark) or Dawn (light).
@immutable
class AppLogoPalette {
  final Color background;
  final Color tile;
  final Color outline;
  final Color checkStart;
  final Color checkEnd;
  final Color spark;

  const AppLogoPalette({
    required this.background,
    required this.tile,
    required this.outline,
    required this.checkStart,
    required this.checkEnd,
    required this.spark,
  });

  /// Flagship Obsidian Twilight palette (launcher icons, store listing).
  static const AppLogoPalette dusk = AppLogoPalette(
    background: AppColors.obsidianTwilight,
    tile: AppColors.cardSurface,
    outline: AppColors.neonLavender,
    checkStart: AppColors.neonLavender,
    checkEnd: AppColors.emeraldMint,
    spark: AppColors.mangoSunrise,
  );

  /// Porcelain daylight palette for light surfaces.
  static const AppLogoPalette dawn = AppLogoPalette(
    background: AppColors.porcelainBg,
    tile: AppColors.porcelainCard,
    outline: AppColors.neonLavender,
    checkStart: AppColors.neonLavender,
    checkEnd: AppColors.emeraldMint,
    spark: AppColors.mangoSunrise,
  );

  /// Single-color silhouette (Android themed icons, notifications).
  const AppLogoPalette.monochrome(Color color)
      : background = AppColors.transparent,
        tile = AppColors.transparent,
        outline = color,
        checkStart = color,
        checkEnd = color,
        spark = color;
}

/// How the mark's backdrop is painted.
enum AppLogoBackdrop {
  /// Mark only, on whatever is behind it.
  none,

  /// Full-bleed square (iOS, web, Play Store, Android adaptive background).
  fullBleed,

  /// Rounded tile with transparent margin (macOS, Windows, legacy Android).
  rounded,
}

/// Paints the "Bento Check" mark: a Bento card tile holding a habit checkmark,
/// with a streak spark on its top-right corner.
///
/// Geometry is authored on the 108-unit Android adaptive-icon grid, the same
/// grid as `assets/branding/*.svg` and the Android launcher vectors, so every
/// platform renders an identical mark.
class AppLogoPainter extends CustomPainter {
  final AppLogoPalette palette;
  final AppLogoBackdrop backdrop;

  /// Scale of the mark around the center. 1.0 keeps it inside the adaptive
  /// icon safe zone; larger values fill non-masked icons.
  final double markScale;

  const AppLogoPainter({
    required this.palette,
    this.backdrop = AppLogoBackdrop.none,
    this.markScale = 1.0,
  });

  static const double grid = 108;
  static const double _center = grid / 2;

  // macOS app-icon proportions: 824 tile on a 1024 canvas, ~22.5% corners.
  static const double _roundedInset = grid * 100 / 1024;
  static const double _roundedRadius = grid * 185 / 1024;

  static const Rect _tileRect = Rect.fromLTRB(30, 30, 78, 78);
  static const double _tileRadius = 11.5;
  static const double _outlineWidth = 2.4;
  static const double _checkWidth = 6.5;
  static const Offset _sparkCenter = Offset(74, 34);
  static const double _sparkRadius = 7;
  static const double _sparkGap = 2.8;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / grid, size.height / grid);
    _paintBackdrop(canvas);

    canvas.saveLayer(const Rect.fromLTWH(0, 0, grid, grid), Paint());
    canvas.translate(_center, _center);
    canvas.scale(markScale);
    canvas.translate(-_center, -_center);
    _paintMark(canvas);
    canvas.restore();

    canvas.restore();
  }

  void _paintBackdrop(Canvas canvas) {
    if (backdrop == AppLogoBackdrop.none) return;
    final rect = backdrop == AppLogoBackdrop.rounded
        ? const Rect.fromLTWH(0, 0, grid, grid).deflate(_roundedInset)
        : const Rect.fromLTWH(0, 0, grid, grid);
    final shape = backdrop == AppLogoBackdrop.rounded
        ? RRect.fromRectAndRadius(rect, const Radius.circular(_roundedRadius))
        : RRect.fromRectAndRadius(rect, Radius.zero);

    canvas.drawRRect(shape, Paint()..color = palette.background);
    // Soft ambient glow behind the tile, in the outline accent.
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.outline.withValues(alpha: 0.18),
            palette.outline.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(center: const Offset(_center, _center), radius: 40),
        ),
    );
  }

  void _paintMark(Canvas canvas) {
    final tile = RRect.fromRectAndRadius(
      _tileRect,
      const Radius.circular(_tileRadius),
    );
    canvas.drawRRect(tile, Paint()..color = palette.tile);
    canvas.drawRRect(
      tile,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _outlineWidth
        ..color = palette.outline,
    );

    final check = Path()
      ..moveTo(39, 55)
      ..lineTo(48.5, 64.5)
      ..lineTo(67.5, 45.5);
    canvas.drawPath(
      check,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _checkWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(
          colors: [palette.checkStart, palette.checkEnd],
        ).createShader(const Rect.fromLTRB(39, 45.5, 67.5, 64.5)),
    );

    final spark = sparkPath(_sparkCenter, _sparkRadius);
    // Knock a gap around the spark so it reads as separate from the tile.
    canvas.drawPath(
      spark,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _sparkGap
        ..strokeJoin = StrokeJoin.round
        ..blendMode = BlendMode.clear,
    );
    canvas.drawPath(spark, Paint()..color = palette.spark);
  }

  /// Four-point concave sparkle centered on [c] with tip radius [r].
  static Path sparkPath(Offset c, double r) {
    final k = r * 0.15;
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
      ..close();
  }

  @override
  bool shouldRepaint(AppLogoPainter oldDelegate) =>
      oldDelegate.palette != palette ||
      oldDelegate.backdrop != backdrop ||
      oldDelegate.markScale != markScale;
}

/// The Track Free brand mark for in-app use (onboarding, about, empty states).
///
/// Uses the Dusk or Dawn palette to match the active brightness, with the tile
/// filled by the current theme's card color.
class AppLogo extends StatelessWidget {
  /// Edge length; defaults to [AppIconSizes.hero].
  final double? size;

  /// Overrides the theme-derived palette.
  final AppLogoPalette? palette;

  const AppLogo({super.key, this.size, this.palette});

  @override
  Widget build(BuildContext context) {
    final brand = context.isDarkMode ? AppLogoPalette.dusk : AppLogoPalette.dawn;
    final resolved = palette ??
        AppLogoPalette(
          background: brand.background,
          tile: context.cardBackgroundColor,
          outline: brand.outline,
          checkStart: brand.checkStart,
          checkEnd: brand.checkEnd,
          spark: brand.spark,
        );
    final extent = size ?? AppIconSizes.hero;

    return Semantics(
      label: 'Track Free logo',
      image: true,
      child: SizedBox.square(
        dimension: extent,
        child: CustomPaint(
          painter: AppLogoPainter(palette: resolved, markScale: 1.95),
        ),
      ),
    );
  }
}
