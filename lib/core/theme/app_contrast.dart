import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// WCAG 2.x contrast helpers for user-built themes.
abstract final class AppContrast {
  /// Minimum ratio for normal-size body text (WCAG AA).
  static const double minTextRatio = 4.5;

  /// Contrast ratio between two opaque colors, from 1 (none) to 21.
  static double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  static bool isReadable(Color text, Color background) =>
      ratio(text, background) >= minTextRatio;
}
