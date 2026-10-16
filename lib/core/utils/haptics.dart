import 'dart:async';

import 'package:flutter/services.dart';

/// Ergonomic, cross-platform safe wrappers for tactile micro-interactions.
///
/// Fire-and-forget: callers never wait on the platform channel, and failures
/// (e.g. desktop without a haptic engine) are swallowed.
abstract final class AppHaptics {
  /// Global switch to enable/disable haptic vibrations across the app
  static bool enabled = true;

  /// Light tactile tap (e.g. habit completion check-off, counter increment, toggle)
  static void lightImpact() => _play(HapticFeedback.lightImpact);

  /// Subtle click feeling (e.g. font family toggle, tab switch, slider step)
  static void selectionClick() => _play(HapticFeedback.selectionClick);

  /// Medium impact feedback (e.g. theme application, bottom sheet dismiss)
  static void mediumImpact() => _play(HapticFeedback.mediumImpact);

  /// Heavy feedback (e.g. streak milestones, habit creation celebrations)
  static void heavyImpact() => _play(HapticFeedback.heavyImpact);

  /// Standard alert vibration
  static void vibrate() => _play(HapticFeedback.vibrate);

  static void _play(Future<void> Function() feedback) {
    if (!enabled) return;
    unawaited(_safely(feedback));
  }

  static Future<void> _safely(Future<void> Function() feedback) async {
    try {
      await feedback();
    } catch (_) {
      // Ignored safely on platforms without haptic engine support.
    }
  }
}
