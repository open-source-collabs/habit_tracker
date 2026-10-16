import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../habits/data/models/habit_model.dart';
import 'dashboard_empty_state.dart';
import 'dashboard_filter_chips.dart';
import 'dashboard_habit_actions.dart';
import 'dashboard_habit_tile.dart';
import 'dashboard_section_title.dart';

/// Children of the habits feed shared by the mobile and desktop layouts:
/// filter chips, section title, then one tile per habit (or the empty state)
/// and bottom clearance for the floating nav bar.
///
/// Returned as a flat list so callers splice it into their own [ListView],
/// keeping habit cards lazily built.
List<Widget> dashboardHabitFeedChildren({
  required List<HabitModel> habits,
  required String activeFilter,
  required DateTime date,
  required DashboardHabitActions actions,
  required double chipsSpacing,
}) {
  return [
    const DashboardFilterChips(),
    SizedBox(height: chipsSpacing),
    DashboardSectionTitle(activeFilter: activeFilter),
    SizedBox(height: 8.h),
    if (habits.isEmpty)
      DashboardEmptyState(activeFilter: activeFilter)
    else
      for (final habit in habits)
        DashboardHabitTile(habit: habit, date: date, actions: actions),
    SizedBox(height: 100.h),
  ];
}
