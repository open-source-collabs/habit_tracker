import '../../features/habits/data/models/habit_model.dart';

/// Centralized route constants for all application navigation paths.
abstract final class AppRoutes {
  /// Root Dashboard (Today tab)
  static const String dashboard = '/';

  /// Direct Dashboard Tabs
  static const String analytics = '/analytics';
  static const String themes = '/themes';
  static const String sync = '/sync';

  /// Habit Creation & Editing
  static const String createHabit = '/habits/create';
  static const String editHabit = '/habits/edit';

  /// Theme Studio
  static const String themeStudio = '/themes/studio';

  /// Data Portability & Sync Backup
  static const String dataPortability = '/settings/data-portability';
}

/// Strongly-typed arguments for habit creation/editing via named routes.
class HabitRouteArgs {
  final HabitModel? habit;

  const HabitRouteArgs({this.habit});
}
