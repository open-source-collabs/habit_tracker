import 'package:flutter/material.dart';

import '../../features/habits/data/models/habit_model.dart';
import 'app_router.dart';
import 'app_routes.dart';

/// Type-safe programmatic navigation helper facade for Habit Tracker.
abstract final class AppNavigator {
  /// Global navigator key accessing the root NavigatorState.
  static GlobalKey<NavigatorState> get navigatorKey => AppRouter.navigatorKey;

  /// Current build context from the root navigator, if mounted.
  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Pushes a named route using the context-based Navigator.
  static Future<T?> pushNamed<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Pushes a named route and replaces the current route.
  static Future<T?> pushReplacementNamed<T, TO>(
    BuildContext context,
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    return Navigator.of(context).pushReplacementNamed<T, TO>(
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  /// Pops the topmost route.
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }

  /// Checks if the navigator can pop.
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  /// Navigates to the main Dashboard (Today tab).
  static Future<void> toDashboard(BuildContext context) {
    return pushNamed(context, AppRoutes.dashboard);
  }

  /// Navigates directly to the Analytics tab.
  static Future<void> toAnalytics(BuildContext context) {
    return pushNamed(context, AppRoutes.analytics);
  }

  /// Navigates directly to the Themes tab.
  static Future<void> toThemes(BuildContext context) {
    return pushNamed(context, AppRoutes.themes);
  }

  /// Navigates directly to the Sync tab.
  static Future<void> toSync(BuildContext context) {
    return pushNamed(context, AppRoutes.sync);
  }

  /// Navigates to the Habit Creator studio sheet via named route.
  static Future<HabitModel?> toCreateHabit(BuildContext context) {
    return pushNamed<HabitModel?>(context, AppRoutes.createHabit);
  }

  /// Navigates to edit an existing habit via named route with typed args.
  static Future<HabitModel?> toEditHabit(
    BuildContext context,
    HabitModel habit,
  ) {
    return pushNamed<HabitModel?>(
      context,
      AppRoutes.editHabit,
      arguments: HabitRouteArgs(habit: habit),
    );
  }

  /// Navigates to Theme Studio via named route.
  static Future<void> toThemeStudio(BuildContext context) {
    return pushNamed(context, AppRoutes.themeStudio);
  }

  /// Navigates to the Settings screen.
  static Future<void> toSettings(BuildContext context) {
    return pushNamed(context, AppRoutes.settings);
  }

  /// Navigates to Data Portability & Sync dialog via named route.
  static Future<void> toDataPortability(BuildContext context) {
    return pushNamed(context, AppRoutes.dataPortability);
  }
}
