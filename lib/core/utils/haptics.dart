import 'package:flutter/services.dart';

/// Ergonomic, cross-platform safe wrappers for tactile micro-interactions.
abstract final class AppHaptics {
  /// Global switch to enable/disable haptic vibrations across the app
  static bool enabled = true;

  /// Light tactile tap (e.g. habit completion check-off, counter increment, toggle)
  static Future<void> lightImpact() async {
    if (!enabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {
      // Ignored safely on platforms without haptic engine support (e.g. desktop)
    }
  }

  /// Subtle click feeling (e.g. font family toggle, tab switch, slider step)
  static Future<void> selectionClick() async {
    if (!enabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // Ignored safely
    }
  }

  /// Medium impact feedback (e.g. theme application, bottom sheet dismiss)
  static Future<void> mediumImpact() async {
    if (!enabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Ignored safely
    }
  }

  /// Heavy feedback (e.g. streak milestones, habit creation celebrations)
  static Future<void> heavyImpact() async {
    if (!enabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {
      // Ignored safely
    }
  }

  /// Standard alert vibration
  static Future<void> vibrate() async {
    if (!enabled) return;
    try {
      await HapticFeedback.vibrate();
    } catch (_) {
      // Ignored safely
    }
  }
}
