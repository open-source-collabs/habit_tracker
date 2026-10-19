import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/theme/theme_factory.dart';

import 'core/routes/routes.dart';
import 'core/services/notification_service.dart';
import 'core/widgets/app_screen_util_init.dart';
import 'core/widgets_kit/habit_widget_sync_service.dart';
import 'core/widgets_kit/widgets_kit_interop.dart';
import 'features/dashboard/presentation/providers/dashboard_provider.dart';
import 'features/habits/presentation/providers/habit_provider.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';
import 'features/onboarding/presentation/onboarding_gate.dart';
import 'features/splash/presentation/launch_overlay.dart';
import 'features/sync/presentation/providers/sync_controller.dart';
import 'features/themes/presentation/providers/theme_provider.dart';

/// Root application widget configuring screen utilities, dynamic theme switching,
/// named route navigation, and the responsive Bento dashboard.
class HabitTrackerApp extends ConsumerStatefulWidget {
  const HabitTrackerApp({super.key});

  @override
  ConsumerState<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends ConsumerState<HabitTrackerApp>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _notificationTaps;
  StreamSubscription<Object>? _saveErrors;
  AppLifecycleListener? _lifecycle;

  /// Reminders are scheduled in the device's zone; after travelling they are
  /// rebuilt so they still fire at the chosen local time.
  Future<void> _onResume() async {
    final notifications = ref.read(notificationServiceProvider);
    if (!await notifications.refreshTimeZone() || !mounted) return;
    ref.invalidate(notificationSettingsProvider); // reschedules digests
    await ref.read(reminderSyncProvider).restoreAll();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Subscribe once for the app's lifetime, not on every rebuild.
    WidgetsKitInterop.initialize(ref);
    _saveErrors = ref
        .read(appDataRepositoryProvider)
        .saveErrors
        .listen((_) => _showSaveFailed());
    ref.read(dayRolloverWatcherProvider).start();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    unawaited(_appReady);

    final notifications = ref.read(notificationServiceProvider);
    _notificationTaps = notifications.notificationTaps.listen(
      _openFromNotification,
    );
    // After the first frame so launch stays fast; reminders are rebuilt from
    // stored habits in case the OS dropped them (reboot, app update).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      unawaited(showOnboardingIfNeeded(ref));
      // Starts cloud sync if this device has it turned on (no-op otherwise).
      ref.read(syncControllerProvider);
      // Skips tonight's streak-saver once everything is done.
      ref.read(eveningDigestSyncProvider);
      await ref.read(reminderSyncProvider).restoreAll();
      final launchPayload = await notifications.takeLaunchPayload();
      if (launchPayload != null && mounted) {
        _openFromNotification(launchPayload);
      } else {
        // Cold start deep-link check (e.g. launched from home screen widget)
        final defaultRoute =
            WidgetsBinding.instance.platformDispatcher.defaultRouteName;
        final defaultUri = Uri.tryParse(defaultRoute);
        if (defaultUri != null && mounted) {
          _handleIncomingDeepLink(defaultUri);
        }
      }
    });
  }

  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final uri = routeInformation.uri;
    if (_handleIncomingDeepLink(uri)) {
      return true;
    }
    return super.didPushRouteInformation(routeInformation);
  }

  bool _handleIncomingDeepLink(Uri? uri) {
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    final scheme = uri.scheme.toLowerCase();

    final isWidgetOrTodayLink =
        (scheme == 'habittracker' &&
            (host == 'open' ||
                host == 'today' ||
                host == 'dashboard' ||
                (host.isEmpty &&
                    (path == '' ||
                        path == '/' ||
                        path == '/open' ||
                        path == '/today' ||
                        path == '/dashboard')))) ||
        (scheme.isEmpty && (path == '/open' || path == '/today'));

    if (isWidgetOrTodayLink) {
      _openTodayDashboard();
      return true;
    }

    if (scheme == 'habittracker' && host == 'toggle') {
      final habitId = uri.queryParameters['id'];
      if (habitId != null && habitId.isNotEmpty) {
        final today = DateTime.now();
        ref.read(habitListProvider.notifier).toggleHabit(habitId, today);
      }
      _openTodayDashboard();
      return true;
    }

    return false;
  }

  /// Brings the user to Today's habits on the root dashboard, resetting
  /// any active filters or sub-screens.
  void _openTodayDashboard() {
    ref.read(dayRolloverWatcherProvider).refresh();
    ref.read(selectedDashboardTabProvider.notifier).state = 0;
    ref.read(selectedDateProvider.notifier).state = ref.read(
      currentDayProvider,
    );
    ref.read(activeRoutineFilterProvider.notifier).state = kAllHabitsFilter;
    AppRouter.navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  /// Brings the user to today's habits and, for a habit reminder (payload is
  /// the habit id), scrolls to and highlights that habit.
  void _openFromNotification(String payload) {
    _openTodayDashboard();

    final habits = ref.read(habitListProvider).valueOrNull ?? const [];
    if (habits.any((h) => h.id == payload && !h.isArchived)) {
      ref.read(highlightedHabitIdProvider.notifier).state = payload;
    }
  }

  /// Completes once stored habits (and with them the saved theme) are loaded
  /// and onboarding, if due, has been pushed — the launch overlay reveals the
  /// app only then, so the first screen appears complete and in the right
  /// theme. Capped so a slow or failing load never keeps the launch up.
  late final Future<void> _appReady = _waitUntilReady();

  Future<void> _waitUntilReady() async {
    try {
      await ref
          .read(habitListProvider.future)
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Error screen or timeout: show whatever is ready.
    }
    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
  }

  /// The change stays on screen and in memory; the next save retries it.
  void _showSaveFailed() {
    AppRouter.scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't save your latest change. It will be retried with your "
            'next edit — check that your device has free storage.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveErrors?.cancel();
    _lifecycle?.dispose();
    _notificationTaps?.cancel();
    WidgetsKitInterop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);

    // A new day: refresh the home screen widget with today's numbers.
    ref.listen(currentDayProvider, (prev, next) {
      if (prev == next) return;
      final habits = ref.read(habitListProvider).valueOrNull ?? [];
      ref
          .read(habitWidgetSyncServiceProvider)
          .syncHabits(habits: habits, activeTheme: themeState.activeTheme);
    });

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
          scaffoldMessengerKey: AppRouter.scaffoldMessengerKey,
          initialRoute: AppRoutes.dashboard,
          onGenerateRoute: AppRouter.onGenerateRoute,
          onUnknownRoute: AppRouter.onUnknownRoute,
          // Screens without an AppBar (dashboard, onboarding) still get
          // status-bar icons that contrast with the active theme.
          builder: (context, child) {
            final theme = Theme.of(context);
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: ThemeFactory.systemOverlayStyle(
                isDark: theme.brightness == Brightness.dark,
                navigationBarColor: theme.scaffoldBackgroundColor,
              ),
              child: LaunchOverlay(
                ready: _appReady,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        );
      },
    );
  }
}
