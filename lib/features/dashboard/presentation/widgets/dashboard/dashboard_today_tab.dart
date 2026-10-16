import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_breakpoints.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../habits/presentation/providers/habit_provider.dart';
import '../../../../habits/presentation/widgets/data_load_error_view.dart';
import 'dashboard_desktop_layout.dart';
import 'dashboard_habit_actions.dart';
import 'dashboard_mobile_layout.dart';

/// The "Today" tab: waits for habits to load, then picks the mobile feed or
/// the desktop Bento grid from the available width.
class DashboardTodayTab extends ConsumerWidget {
  final DashboardHabitActions actions;

  const DashboardTodayTab({super.key, required this.actions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitListProvider);
    final filteredHabits = ref.watch(filteredHabitsProvider);
    final activeFilter = ref.watch(activeRoutineFilterProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = AppBreakpoints.isDesktopWidth(constraints.maxWidth);

        return habitsAsync.when(
          loading: () => Center(
            child: Padding(
              padding: EdgeInsets.all(32.r),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.primaryAccent,
                ),
              ),
            ),
          ),
          error: (err, _) => DataLoadErrorView(error: err),
          data: (_) => isDesktop
              ? DashboardDesktopLayout(
                  habits: filteredHabits,
                  activeFilter: activeFilter,
                  selectedDate: selectedDate,
                  actions: actions,
                )
              : DashboardMobileLayout(
                  habits: filteredHabits,
                  activeFilter: activeFilter,
                  selectedDate: selectedDate,
                  actions: actions,
                ),
        );
      },
    );
  }
}
