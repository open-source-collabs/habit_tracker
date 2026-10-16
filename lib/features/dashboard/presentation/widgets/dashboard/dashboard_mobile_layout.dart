import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/routes/routes.dart';
import '../../../../habits/data/models/habit_model.dart';
import '../bento_stats_card.dart';
import '../calendar_strip.dart';
import '../consistency_chart.dart';
import '../favorite_activities_carousel.dart';
import 'dashboard_habit_actions.dart';
import 'dashboard_habit_feed.dart';

/// Single-column Today feed for widths below `AppBreakpoints.desktop`.
class DashboardMobileLayout extends StatelessWidget {
  final List<HabitModel> habits;
  final String activeFilter;
  final DateTime selectedDate;
  final DashboardHabitActions actions;

  const DashboardMobileLayout({
    super.key,
    required this.habits,
    required this.activeFilter,
    required this.selectedDate,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      children: [
        CalendarStrip(onAddTap: () => AppNavigator.toCreateHabit(context)),
        SizedBox(height: 10.h),
        const ConsistencyChart(),
        SizedBox(height: 10.h),
        const FavoriteActivitiesCarousel(),
        SizedBox(height: 10.h),
        const BentoStatsCard(),
        SizedBox(height: 10.h),
        ...dashboardHabitFeedChildren(
          habits: habits,
          activeFilter: activeFilter,
          date: selectedDate,
          actions: actions,
          chipsSpacing: 8.h,
        ),
      ],
    );
  }
}
