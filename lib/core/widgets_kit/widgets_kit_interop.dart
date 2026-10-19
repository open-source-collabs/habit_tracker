import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgets_kit/widgets_kit.dart';

import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../features/habits/presentation/providers/habit_provider.dart';
import '../routes/routes.dart';

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

  /// Brings the user directly to Today's habits on the root Dashboard.
  static void openTodayDashboard(WidgetRef ref) {
    ref.read(dayRolloverWatcherProvider).refresh();
    ref.read(selectedDashboardTabProvider.notifier).state = 0;
    ref.read(selectedDateProvider.notifier).state =
        ref.read(currentDayProvider);
    ref.read(activeRoutineFilterProvider.notifier).state = kAllHabitsFilter;
    AppRouter.navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  /// Handles incoming URIs triggered by widget clicks.
  static void handleWidgetClick(Uri uri, WidgetRef ref) {
    debugPrint('WidgetsKitInterop: Received widget click URI: $uri');

    // URI scheme format:
    // habittracker://open
    // habittracker://today
    // habittracker://toggle?id=<habitId>
    if (uri.scheme == 'habittracker') {
      final host = uri.host.toLowerCase();
      final path = uri.path.toLowerCase();

      if (host == 'toggle') {
        final habitId = uri.queryParameters['id'];
        if (habitId != null && habitId.isNotEmpty) {
          final today = DateTime.now();
          ref.read(habitListProvider.notifier).toggleHabit(habitId, today);
        }
        openTodayDashboard(ref);
        return;
      }

      if (host == 'open' ||
          host == 'today' ||
          host == 'dashboard' ||
          (host.isEmpty &&
              (path == '' ||
                  path == '/' ||
                  path == '/open' ||
                  path == '/today' ||
                  path == '/dashboard'))) {
        openTodayDashboard(ref);
      }
    }
  }

  /// Disposes active stream subscriptions.
  static void dispose() {
    _clickSubscription?.cancel();
    _clickSubscription = null;
  }
}
