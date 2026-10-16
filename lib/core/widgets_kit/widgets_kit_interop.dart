import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgets_kit/widgets_kit.dart';

import '../../features/habits/presentation/providers/habit_provider.dart';

/// Interop helper managing widget tap events and deep-link lifecycle from [WidgetsKit].
class WidgetsKitInterop {
  static StreamSubscription<Uri?>? _clickSubscription;

  /// Initializes listening to widget click events from Android & iOS.
  static void initialize(WidgetRef ref) {
    if (!WidgetsKit.isSupported) {
      return;
    }

    _clickSubscription?.cancel();
    _clickSubscription = WidgetsKit.widgetClicked.listen(
      (uri) {
        if (uri != null) {
          handleWidgetClick(uri, ref);
        }
      },
      onError: (Object e) {
        debugPrint('WidgetsKitInterop: Error on widgetClicked stream: $e');
      },
    );
  }

  /// Handles incoming URIs triggered by widget clicks.
  static void handleWidgetClick(Uri uri, WidgetRef ref) {
    debugPrint('WidgetsKitInterop: Received widget click URI: $uri');

    // URI scheme format:
    // habittracker://open
    // habittracker://toggle?id=<habitId>
    if (uri.scheme == 'habittracker') {
      if (uri.host == 'toggle') {
        final habitId = uri.queryParameters['id'];
        if (habitId != null && habitId.isNotEmpty) {
          final today = DateTime.now();
          ref.read(habitListProvider.notifier).toggleHabit(habitId, today);
        }
      }
    }
  }

  /// Disposes active stream subscriptions.
  static void dispose() {
    _clickSubscription?.cancel();
    _clickSubscription = null;
  }
}
