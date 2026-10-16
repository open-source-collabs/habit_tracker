import 'dart:ui';

import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/habits/data/models/habit_model.dart';
import '../../features/habits/presentation/widgets/habit_creator_sheet.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/sync/presentation/widgets/data_portability_dialog.dart';
import '../../features/themes/presentation/screens/theme_studio_sheet.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_colors.dart';
import 'app_routes.dart';
import 'not_found_screen.dart';

/// Centralized route generator configuring named route resolution,
/// adaptive screen/modal transitions, typed arguments, and 404 fallbacks.
class AppRouter {
  AppRouter._();

  /// Global navigator key allowing decoupled navigation throughout the app.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Primary route generation handler for [MaterialApp.onGenerateRoute].
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.dashboard:
        return _buildPageRoute(
          const DashboardScreen(initialTabIndex: 0),
          settings,
        );

      case AppRoutes.analytics:
        return _buildPageRoute(
          const DashboardScreen(initialTabIndex: 1),
          settings,
        );

      case AppRoutes.themes:
        return _buildPageRoute(
          const DashboardScreen(initialTabIndex: 2),
          settings,
        );

      case AppRoutes.sync:
        return _buildPageRoute(
          const DashboardScreen(initialTabIndex: 3),
          settings,
        );

      case AppRoutes.createHabit:
        return _buildAdaptiveModalRoute<HabitModel?>(
          (context) => HabitCreatorSheet(isDialog: context.isDesktop),
          settings,
        );

      case AppRoutes.editHabit:
        final args = settings.arguments as HabitRouteArgs?;
        return _buildAdaptiveModalRoute<HabitModel?>(
          (context) => HabitCreatorSheet(
            initialHabit: args?.habit,
            isDialog: context.isDesktop,
          ),
          settings,
        );

      case AppRoutes.themeStudio:
        return _buildAdaptiveModalRoute<void>(
          (context) => const ThemeStudioSheet(),
          settings,
        );

      case AppRoutes.settings:
        return _buildPageRoute(const SettingsScreen(), settings);

      case AppRoutes.dataPortability:
        return _buildAdaptiveDialogRoute<void>(
          (context) => const DataPortabilityDialog(),
          settings,
        );

      default:
        return onUnknownRoute(settings);
    }
  }

  /// Fallback handler for unmapped routes, returning the Bento [NotFoundScreen].
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return _buildPageRoute(NotFoundScreen(routeName: settings.name), settings);
  }

  /// Builds a standard Material page route.
  static PageRoute<T> _buildPageRoute<T>(Widget page, RouteSettings settings) {
    return MaterialPageRoute<T>(builder: (_) => page, settings: settings);
  }

  /// Builds an adaptive modal route that displays as a bottom sheet on mobile
  /// and a centered dialog on desktop.
  static Route<T> _buildAdaptiveModalRoute<T>(
    Widget Function(BuildContext) builder,
    RouteSettings settings,
  ) {
    return _AdaptiveModalRoute<T>(builder: builder, settings: settings);
  }

  /// Builds an adaptive dialog route with subtle zoom and fade animation.
  static Route<T> _buildAdaptiveDialogRoute<T>(
    Widget Function(BuildContext) builder,
    RouteSettings settings,
  ) {
    return RawDialogRoute<T>(
      pageBuilder: (buildContext, animation, secondaryAnimation) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: builder(buildContext),
          ),
        );
      },
      barrierDismissible: true,
      barrierColor: AppColors.barrier,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5.0 * curved.value,
            sigmaY: 5.0 * curved.value,
          ),
          child: FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
      settings: settings,
    );
  }
}

/// Adaptive modal route that switches dynamically between bottom sheet (mobile)
/// and centered card (desktop) while providing unified Route lifecycle semantics.
class _AdaptiveModalRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  _AdaptiveModalRoute({required this.builder, super.settings});

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => AppColors.barrier;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final content = builder(context);

    if (context.isDesktop) {
      return Center(
        child: Material(type: MaterialType.transparency, child: content),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(type: MaterialType.transparency, child: content),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    if (context.isDesktop) {
      return FadeTransition(
        opacity: curvedAnimation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curvedAnimation),
          child: child,
        ),
      );
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.6, end: 1.0).animate(curvedAnimation),
        child: child,
      ),
    );
  }
}
