import 'package:flutter/material.dart';

import '../../../../../core/widgets/widgets.dart';

/// Floating bottom navigation for the dashboard tabs (Today, Analytics,
/// Themes, Sync) with the centre "New Habit" action.
class DashboardNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onNewHabit;

  const DashboardNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onNewHabit,
  });

  static const _items = [
    AppFloatingNavBarItem(
      icon: Icons.grid_view_rounded,
      activeIcon: Icons.grid_view_rounded,
      label: 'Today',
      tooltip: 'Today Dashboard',
    ),
    AppFloatingNavBarItem(
      icon: Icons.insights_rounded,
      activeIcon: Icons.insights_rounded,
      label: 'Analytics',
      tooltip: 'Habit Analytics & Heatmap',
    ),
    AppFloatingNavBarItem(
      icon: Icons.palette_rounded,
      activeIcon: Icons.palette_rounded,
      label: 'Themes',
      tooltip: 'Theme Studio',
    ),
    AppFloatingNavBarItem(
      icon: Icons.cloud_sync_rounded,
      activeIcon: Icons.cloud_sync_rounded,
      label: 'Sync',
      tooltip: 'Cloud Sync & Backups',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppFloatingNavBar(
      currentIndex: currentIndex,
      onTap: onTabSelected,
      onCenterActionPressed: onNewHabit,
      centerActionTooltip: 'New Habit',
      items: _items,
    );
  }
}
