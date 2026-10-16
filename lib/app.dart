import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routes/routes.dart';
import 'core/services/notification_service.dart';
import 'features/dashboard/presentation/providers/dashboard_provider.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';
import 'features/sync/presentation/providers/sync_controller.dart';
import 'core/theme/theme_factory.dart';
import 'core/widgets/app_screen_util_init.dart';
import 'core/widgets_kit/habit_widget_sync_service.dart';
import 'core/widgets_kit/widgets_kit_interop.dart';
import 'features/habits/presentation/providers/habit_provider.dart';
import 'features/themes/presentation/providers/theme_provider.dart';

/// Root application widget configuring screen utilities, dynamic theme switching,
/// named route navigation, and the responsive Bento dashboard.
class HabitTrackerApp extends ConsumerStatefulWidget {
  const HabitTrackerApp({super.key});

  @override
  ConsumerState<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends ConsumerState<HabitTrackerApp> {
  StreamSubscription<String>? _notificationTaps;

  @override
  void initState() {
    super.initState();
    // Subscribe once for the app's lifetime, not on every rebuild.
    WidgetsKitInterop.initialize(ref);

    final notifications = ref.read(notificationServiceProvider);
    _notificationTaps = notifications.notificationTaps.listen(_openFromNotification);
    // After the first frame so launch stays fast; reminders are rebuilt from
    // stored habits in case the OS dropped them (reboot, app update).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Starts cloud sync if this device has it turned on (no-op otherwise).
      ref.read(syncControllerProvider);
      await ref.read(reminderSyncProvider).restoreAll();
      final launchPayload = await notifications.takeLaunchPayload();
      if (launchPayload != null && mounted) _openFromNotification(launchPayload);
    });
  }

  /// Brings the user to today's habits, where the reminded habit can be
  /// checked off.
  void _openFromNotification(String payload) {
    final now = DateTime.now();
    ref.read(selectedDashboardTabProvider.notifier).state = 0;
    ref.read(selectedDateProvider.notifier).state =
        DateTime(now.year, now.month, now.day);
    ref.read(activeRoutineFilterProvider.notifier).state = kAllHabitsFilter;
    AppRouter.navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _notificationTaps?.cancel();
    WidgetsKitInterop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);

    // Sync home screen widget when active theme changes
    ref.listen(themeProvider, (prev, next) {
      if (prev?.activeThemeId != next.activeThemeId) {
        final habits = ref.read(habitListProvider).valueOrNull ?? [];
        ref
            .read(habitWidgetSyncServiceProvider)
            .syncHabits(habits: habits, activeTheme: next.activeTheme);
      }
    });

    return AppScreenUtilInit(
      builder: (context) {
        return MaterialApp(
          title: 'Track Free',
          debugShowCheckedModeBanner: false,
          theme: ThemeFactory.applyScreenScale(themeState.themeData),
          navigatorKey: AppRouter.navigatorKey,
          initialRoute: AppRoutes.dashboard,
          onGenerateRoute: AppRouter.onGenerateRoute,
          onUnknownRoute: AppRouter.onUnknownRoute,
        );
      },
    );
  }
}
