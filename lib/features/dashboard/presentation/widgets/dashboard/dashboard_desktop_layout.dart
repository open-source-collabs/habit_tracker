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
import 'dashboard_streak_champion_tile.dart';

/// Dual-column Bento Today view for widths at or above
/// `AppBreakpoints.desktop`: analytics on the left (flex 5), the habits feed
/// on the right (flex 6).
class DashboardDesktopLayout extends StatelessWidget {
  final List<HabitModel> habits;
  final String activeFilter;
  final DateTime selectedDate;
  final DashboardHabitActions actions;

  const DashboardDesktopLayout({
    super.key,
    required this.habits,
    required this.activeFilter,
    required this.selectedDate,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(18.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CalendarStrip(
                  onAddTap: () => AppNavigator.toCreateHabit(context),
                ),
                SizedBox(height: 12.h),
                const ConsistencyChart(),
                SizedBox(height: 12.h),
                const FavoriteActivitiesCarousel(),
                SizedBox(height: 12.h),
                const BentoStatsCard(),
                SizedBox(height: 12.h),
                const DashboardStreakChampionTile(),
                SizedBox(height: 100.h),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: ListView(
            padding: EdgeInsets.all(18.r),
            children: dashboardHabitFeedChildren(
              habits: habits,
              activeFilter: activeFilter,
              date: selectedDate,
              actions: actions,
              chipsSpacing: 10.h,
            ),
          ),
        ),
      ],
    );
  }
}
