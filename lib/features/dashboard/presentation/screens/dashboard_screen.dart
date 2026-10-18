import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/routes/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../sync/presentation/screens/sync_tab_view.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/analytics_tab_view.dart';
import '../widgets/dashboard/dashboard_greeting_header.dart';
import '../widgets/dashboard/dashboard_habit_actions.dart';
import '../widgets/dashboard/dashboard_nav_bar.dart';
import '../widgets/dashboard/dashboard_today_tab.dart';
import '../widgets/themes_tab_view.dart';

/// Responsive Dashboard Screen adapting dynamically to screen width.
/// - Mobile (<768px): Single-column focused Bento feed.
/// - Desktop/Web (≥768px): Multi-column asymmetric Bento grid.
class DashboardScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const DashboardScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  /// Bound to this screen's context so undo snackbars outlive removed cards.
  late final _habitActions = DashboardHabitActions(context: context, ref: ref);

  @override
  void initState() {
    super.initState();
    if (widget.initialTabIndex != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(selectedDashboardTabProvider.notifier).state =
              widget.initialTabIndex;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fall back to "All" when the selected filter disappears, e.g. after the
    // last archived habit is restored or a routine's last habit is deleted.
    ref.listen(routineGroupsProvider, (_, groups) {
      final filter = ref.read(activeRoutineFilterProvider);
      if (!groups.any((g) => g.toLowerCase() == filter.toLowerCase())) {
        ref.read(activeRoutineFilterProvider.notifier).state = kAllHabitsFilter;
      }
    });
    final selectedTabIndex = ref.watch(selectedDashboardTabProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: AppIconButton(
              icon: Icons.settings_rounded,
              tooltip: 'Settings',
              onPressed: () => AppNavigator.toSettings(context),
            ),
          ),
        ],
        title: const DashboardGreetingHeader(),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: selectedTabIndex,
                children: [
                  DashboardTodayTab(actions: _habitActions),
                  const AnalyticsTabView(),
                  const ThemesTabView(),
                  const SyncTabView(),
                ],
              ),
            ),
            DashboardNavBar(
              currentIndex: selectedTabIndex,
              onTabSelected: (index) {
                ref.read(selectedDashboardTabProvider.notifier).state = index;
              },
              onNewHabit: () => AppNavigator.toCreateHabit(context),
            ),
          ],
        ),
      ),
    );
  }
}
