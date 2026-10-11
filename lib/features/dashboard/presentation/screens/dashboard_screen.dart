import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';
import 'package:habit_tracker/core/theme/app_text_styles.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../habits/data/models/habit_model.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../habits/presentation/widgets/habit_card.dart';
import '../../../themes/data/models/dynamic_theme_model.dart';
import '../../../themes/presentation/providers/theme_provider.dart';
import '../../../themes/presentation/screens/theme_studio_sheet.dart';
import '../widgets/bento_stats_card.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/consistency_chart.dart';
import '../widgets/favorite_activities_carousel.dart';

/// Responsive Dashboard Screen adapting dynamically to screen width.
/// - Mobile (<768px): Single-column focused Bento feed.
/// - Desktop/Web (≥768px): Multi-column asymmetric Bento grid.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const double _kDesktopBreakpoint = 768.0;

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
    final primaryAccent = context.primaryAccent;

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, activeTheme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHabitDialog(context, activeTheme),
        backgroundColor: primaryAccent,
        foregroundColor: context.onPrimaryColor,
        elevation: 4,
        icon: Icon(Icons.add_rounded, size: 22.sp.clamp(20.0, 24.0)),
        label: Text(
          'New Habit',
          style: context.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.onPrimaryColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= _kDesktopBreakpoint;

            return habitsAsync.when(
              loading: () => Center(
                child: Padding(
                  padding: EdgeInsets.all(32.r),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                  ),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Text(
                    'Failed to load habits: $err',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
              ),
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
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    UserThemeModel activeTheme,
  ) {
    final primaryAccent = context.primaryAccent;

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
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: FilledButton.tonalIcon(
            icon: Icon(Icons.palette_outlined, size: 16.sp, color: primaryAccent),
            label: Text(
              'Theme Studio',
              style: context.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12.sp,
                color: context.textPrimaryColor,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: context.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
                side: BorderSide(color: context.cardBorderColor, width: 1.2),
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            ),
            onPressed: () => ThemeStudioSheet.show(context),
          ),
        ),
      ],
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
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      children: [
        // 7-Day Interactive Calendar Strip
        CalendarStrip(
          onAddTap: () => _showAddHabitDialog(context, activeTheme),
        ),
        SizedBox(height: 18.h),

        // Consistency score weekly chart
        const ConsistencyChart(),
        SizedBox(height: 18.h),

        // Favorite activities carousel
        const FavoriteActivitiesCarousel(),
        SizedBox(height: 20.h),

        // Progress Overview Stats Card
        const BentoStatsCard(),
        SizedBox(height: 22.h),

        // Routine Category Filter Chips
        _buildFilterChips(context, routineGroups, activeFilter),
        SizedBox(height: 16.h),

        // Section Title
        Text(
          'ACTIVE HABITS',
          style: context.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 11.sp,
            color: context.textMutedColor,
          ),
        ),
        SizedBox(height: 12.h),

        // Habits List
        if (filteredHabits.isEmpty)
          _buildEmptyState(context)
        else
          ...filteredHabits.map((habit) {
            return Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: BentoHabitCard(
                habit: habit,
                date: selectedDate,
              ),
            );
          }),
        SizedBox(height: 72.h),
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
            padding: EdgeInsets.all(24.r.clamp(16.0, 24.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CalendarStrip(
                  onAddTap: () => _showAddHabitDialog(context, activeTheme),
                ),
                SizedBox(height: 20.h.clamp(14.0, 22.0)),
                const ConsistencyChart(),
                SizedBox(height: 20.h.clamp(14.0, 22.0)),
                const FavoriteActivitiesCarousel(),
                SizedBox(height: 20.h.clamp(14.0, 22.0)),
                const BentoStatsCard(),
                SizedBox(height: 20.h.clamp(14.0, 22.0)),
                _buildStreakChampionTile(context),
              ],
            ),
          ),
        ),

        // Right Column: Filter chips & Habits Feed
        Expanded(
          flex: 6,
          child: ListView(
            padding: EdgeInsets.all(24.r.clamp(16.0, 24.0)),
            children: [
              _buildFilterChips(context, routineGroups, activeFilter),
              SizedBox(height: 16.h.clamp(12.0, 18.0)),
              Text(
                'ACTIVE HABITS',
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 11.sp.clamp(10.0, 12.0),
                  color: context.textMutedColor,
                ),
              ),
              SizedBox(height: 12.h.clamp(8.0, 14.0)),
              if (filteredHabits.isEmpty)
                _buildEmptyState(context)
              else
                ...filteredHabits.map((habit) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 14.h.clamp(10.0, 16.0)),
                    child: BentoHabitCard(
                      habit: habit,
                      date: selectedDate,
                    ),
                  );
                }),
              SizedBox(height: 80.h.clamp(60.0, 90.0)),
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
                color: isSelected ? context.onPrimaryColor : context.textPrimaryColor,
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
      padding: EdgeInsets.all(20.r.clamp(16.0, 22.0)),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(24.r.clamp(16.0, 24.0)),
        border: Border.all(color: context.cardBorderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: accent,
              size: 28.sp.clamp(24.0, 30.0),
            ),
          ),
          SizedBox(width: 16.w.clamp(12.0, 18.0)),
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
    AppHaptics.mediumImpact();
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    String selectedRoutine = 'General';
    int selectedAccent = 0;

    final routineItems = const [
      AppDropdownItem(value: 'General', label: 'General Routine', icon: Text('🎯')),
      AppDropdownItem(value: 'Morning', label: 'Morning Routine', icon: Text('☀️')),
      AppDropdownItem(value: 'Focus', label: 'Deep Focus', icon: Text('⚡')),
      AppDropdownItem(value: 'Health', label: 'Health & Hydration', icon: Text('💧')),
      AppDropdownItem(value: 'Evening', label: 'Evening Calm', icon: Text('🌙')),
      AppDropdownItem(value: 'Fitness', label: 'Fitness & Gym', icon: Text('💪')),
    ];

    showAppDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AppDialog(
              title: 'New Habit',
              message: 'Establish a new intentional routine to track daily.',
              icon: Icon(
                Icons.add_task_rounded,
                size: 24.sp,
                color: context.primaryAccent,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: titleController,
                    labelText: 'HABIT TITLE',
                    hintText: 'e.g. Morning Breathwork',
                    showClearButton: true,
                    autofocus: true,
                  ),
                  SizedBox(height: 14.h),
                  AppTextField(
                    controller: subtitleController,
                    labelText: 'SUBTITLE / NOTES',
                    hintText: 'e.g. 15 minutes outdoors',
                  ),
                  SizedBox(height: 14.h),
                  AppDropdown<String>(
                    labelText: 'ROUTINE CATEGORY',
                    value: selectedRoutine,
                    items: routineItems,
                    onChanged: (val) {
                      setDialogState(() => selectedRoutine = val);
                    },
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'ACCENT COLOR',
                    style: AppTextStyles.labelSmall(context),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(
                      context.accentPalette.length,
                      (idx) {
                        final color = context.accentPalette[idx];
                        final isSelected = selectedAccent == idx;
                        return GestureDetector(
                          onTap: () {
                            AppHaptics.selectionClick();
                            setDialogState(() => selectedAccent = idx);
                          },
                          child: Container(
                            width: 32.r,
                            height: 32.r,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: AppColors.white, width: 2.5)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.5),
                                        blurRadius: 8.r,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              confirmText: 'Add Habit',
              cancelText: 'Cancel',
              onConfirm: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final newHabit = HabitModel(
                  id: 'habit_${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  subtitle: subtitleController.text.trim(),
                  frequency: const HabitFrequency.daily(),
                  routineGroup: selectedRoutine,
                  accentIndex: selectedAccent,
                  createdAt: DateTime.now(),
                );

                ref.read(habitListProvider.notifier).createHabit(newHabit);
                Navigator.of(dialogContext).pop();
                AppHaptics.heavyImpact();
              },
              onCancel: () => Navigator.of(dialogContext).pop(),
            );
          },
        );
      },
    );
  }
}
