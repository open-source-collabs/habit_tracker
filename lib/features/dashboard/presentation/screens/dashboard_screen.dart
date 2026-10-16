import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/routes/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../habits/data/models/habit_model.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../habits/presentation/widgets/data_load_error_view.dart';
import '../../../habits/presentation/widgets/habit_card.dart';
import '../../../themes/data/models/dynamic_theme_model.dart';
import '../../../themes/presentation/providers/theme_provider.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/analytics_tab_view.dart';
import '../widgets/bento_stats_card.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/consistency_chart.dart';
import '../widgets/favorite_activities_carousel.dart';
import '../widgets/sync_tab_view.dart';
import '../widgets/themes_tab_view.dart';

/// Responsive Dashboard Screen adapting dynamically to screen width.
/// - Mobile (<768px): Single-column focused Bento feed.
/// - Desktop/Web (≥768px): Multi-column asymmetric Bento grid.
class DashboardScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const DashboardScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const double _kDesktopBreakpoint = 768.0;

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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final activeTheme = themeState.activeTheme;
    final selectedDate = ref.watch(selectedDateProvider);
    final habitsAsync = ref.watch(habitListProvider);
    final filteredHabits = ref.watch(filteredHabitsProvider);
    final routineGroups = ref.watch(routineGroupsProvider);
    final activeFilter = ref.watch(activeRoutineFilterProvider);
    final selectedTabIndex = ref.watch(selectedDashboardTabProvider);
    final primaryAccent = context.primaryAccent;

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, activeTheme),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: selectedTabIndex,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop =
                          constraints.maxWidth >= _kDesktopBreakpoint;

                      return habitsAsync.when(
                        loading: () => Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.r),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryAccent,
                              ),
                            ),
                          ),
                        ),
                        error: (err, _) => DataLoadErrorView(error: err),
                        data: (_) {
                          if (isDesktop) {
                            return _buildDesktopLayout(
                              context: context,
                              activeTheme: activeTheme,
                              filteredHabits: filteredHabits,
                              routineGroups: routineGroups,
                              activeFilter: activeFilter,
                              selectedDate: selectedDate,
                              maxWidth: constraints.maxWidth,
                            );
                          } else {
                            return _buildMobileLayout(
                              context: context,
                              activeTheme: activeTheme,
                              filteredHabits: filteredHabits,
                              routineGroups: routineGroups,
                              activeFilter: activeFilter,
                              selectedDate: selectedDate,
                            );
                          }
                        },
                      );
                    },
                  ),
                  const AnalyticsTabView(),
                  const ThemesTabView(),
                  const SyncTabView(),
                ],
              ),
            ),
            AppFloatingNavBar(
              currentIndex: selectedTabIndex,
              onTap: (index) {
                ref.read(selectedDashboardTabProvider.notifier).state = index;
              },
              onCenterActionPressed: () =>
                  _showAddHabitDialog(context, activeTheme),
              centerActionTooltip: 'New Habit',
              items: const [
                AppFloatingNavBarItem(
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                  label: 'Today',
                  tooltip: 'Today Dashboard',
                ),
                AppFloatingNavBarItem(
                  icon: Icons.insights_outlined,
                  activeIcon: Icons.insights_rounded,
                  label: 'Analytics',
                  tooltip: 'Habit Analytics & Heatmap',
                ),
                AppFloatingNavBarItem(
                  icon: Icons.palette_outlined,
                  activeIcon: Icons.palette_rounded,
                  label: 'Themes',
                  tooltip: 'Theme Studio',
                ),
                AppFloatingNavBarItem(
                  icon: Icons.cloud_sync_outlined,
                  activeIcon: Icons.cloud_sync_rounded,
                  label: 'Sync',
                  tooltip: 'Cloud Sync & Backups',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    UserThemeModel activeTheme,
  ) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '${_getGreeting()}, Frede',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20.sp,
                    letterSpacing: -0.4,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Text('👋', style: TextStyle(fontSize: 18.sp)),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Dusk & Dawn Tracker',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
              color: context.textMutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout({
    required BuildContext context,
    required UserThemeModel activeTheme,
    required List<HabitModel> filteredHabits,
    required List<String> routineGroups,
    required String activeFilter,
    required DateTime selectedDate,
  }) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w.clamp(14.0, 20.0), vertical: 10.h),
      children: [
        // 7-Day Interactive Calendar Strip
        CalendarStrip(
          onAddTap: () => _showAddHabitDialog(context, activeTheme),
        ),
        SizedBox(height: 10.h),

        // Consistency score weekly chart
        const ConsistencyChart(),
        SizedBox(height: 10.h),

        // Favorite activities carousel
        const FavoriteActivitiesCarousel(),
        SizedBox(height: 10.h),

        // Progress Overview Stats Card
        const BentoStatsCard(),
        SizedBox(height: 10.h),

        // Routine Category Filter Chips
        _buildFilterChips(context, routineGroups, activeFilter),
        SizedBox(height: 8.h),

        // Section Title
        Text(
          'ACTIVE HABITS',
          style: context.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 10.5.sp.clamp(9.5, 12.0),
            color: context.textMutedColor,
          ),
        ),
        SizedBox(height: 8.h),

        // Habits List
        if (filteredHabits.isEmpty)
          _buildEmptyState(context)
        else
          ...filteredHabits.map((habit) {
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: BentoHabitCard(habit: habit, date: selectedDate),
            );
          }),
        SizedBox(height: 100.h),
      ],
    );
  }

  Widget _buildDesktopLayout({
    required BuildContext context,
    required UserThemeModel activeTheme,
    required List<HabitModel> filteredHabits,
    required List<String> routineGroups,
    required String activeFilter,
    required DateTime selectedDate,
    required double maxWidth,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Consistency Chart, Favorite Activities, Progress Overview
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(18.r.clamp(14.0, 20.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CalendarStrip(
                  onAddTap: () => _showAddHabitDialog(context, activeTheme),
                ),
                SizedBox(height: 12.h.clamp(10.0, 16.0)),
                const ConsistencyChart(),
                SizedBox(height: 12.h.clamp(10.0, 16.0)),
                const FavoriteActivitiesCarousel(),
                SizedBox(height: 12.h.clamp(10.0, 16.0)),
                const BentoStatsCard(),
                SizedBox(height: 12.h.clamp(10.0, 16.0)),
                _buildStreakChampionTile(context),
                SizedBox(height: 100.h.clamp(80.0, 110.0)),
              ],
            ),
          ),
        ),

        // Right Column: Filter chips & Habits Feed
        Expanded(
          flex: 6,
          child: ListView(
            padding: EdgeInsets.all(18.r.clamp(14.0, 20.0)),
            children: [
              _buildFilterChips(context, routineGroups, activeFilter),
              SizedBox(height: 10.h.clamp(8.0, 14.0)),
              Text(
                'ACTIVE HABITS',
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 10.5.sp.clamp(9.5, 12.0),
                  color: context.textMutedColor,
                ),
              ),
              SizedBox(height: 8.h.clamp(6.0, 12.0)),
              if (filteredHabits.isEmpty)
                _buildEmptyState(context)
              else
                ...filteredHabits.map((habit) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h.clamp(8.0, 14.0)),
                    child: BentoHabitCard(habit: habit, date: selectedDate),
                  );
                }),
              SizedBox(height: 100.h.clamp(80.0, 110.0)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    List<String> routineGroups,
    String activeFilter,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: routineGroups.map((group) {
          final isSelected = activeFilter.toLowerCase() == group.toLowerCase();
          final primaryAccent = context.primaryAccent;

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              label: Text(group),
              selected: isSelected,
              onSelected: (_) {
                AppHaptics.selectionClick();
                ref.read(activeRoutineFilterProvider.notifier).state = group;
              },
              selectedColor: primaryAccent,
              backgroundColor: context.cardBackgroundColor,
              labelStyle: context.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? context.onPrimaryColor
                    : context.textPrimaryColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12.sp,
              ),
              side: BorderSide(
                color: isSelected ? primaryAccent : context.cardBorderColor,
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStreakChampionTile(BuildContext context) {
    final stats = ref.watch(dailyHabitStatsProvider);
    final accents = context.accentPalette;
    final accent = accents.length > 2
        ? accents[2]
        : (accents.isNotEmpty ? accents.first : context.primaryAccent);

    return Container(
      padding: EdgeInsets.all(14.r.clamp(12.0, 16.0)),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20.r.clamp(16.0, 22.0)),
        border: Border.all(color: context.cardBorderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: accent,
              size: 24.sp.clamp(20.0, 26.0),
            ),
          ),
          SizedBox(width: 12.w.clamp(10.0, 16.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STREAK CHAMPION',
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    fontSize: 11.sp.clamp(10.0, 12.0),
                    color: context.textMutedColor,
                  ),
                ),
                SizedBox(height: 4.h.clamp(2.0, 6.0)),
                Text(
                  stats.longestActiveStreak > 0
                      ? '${stats.longestActiveStreak} Days Streak Master'
                      : 'Keep going to build your championship streak!',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp.clamp(12.0, 15.0),
                    color: context.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(32.r),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(24.r.clamp(16.0, 24.0)),
        border: Border.all(color: context.cardBorderColor, width: 1.2),
      ),
      child: Center(
        child: Column(
          children: [
            Text('🎯', style: TextStyle(fontSize: 32.sp.clamp(26.0, 36.0))),
            SizedBox(height: 10.h),
            Text(
              'No habits in this routine',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context, UserThemeModel activeTheme) {
    AppNavigator.toCreateHabit(context);
  }
}
