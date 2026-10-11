import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/haptics.dart';
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
    final themeData = Theme.of(context);
    final selectedDate = ref.watch(selectedDateProvider);
    final habitsAsync = ref.watch(habitListProvider);
    final filteredHabits = ref.watch(filteredHabitsProvider);
    final routineGroups = ref.watch(routineGroupsProvider);
    final activeFilter = ref.watch(activeRoutineFilterProvider);
    final accents = activeTheme.accentPalette;
    final primaryAccent = accents.isNotEmpty
        ? accents.first
        : themeData.colorScheme.primary;

    return Scaffold(
      backgroundColor: activeTheme.scaffoldBg,
      appBar: _buildAppBar(context, activeTheme, themeData),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHabitDialog(context, activeTheme),
        backgroundColor: primaryAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          'New Habit',
          style: TextStyle(
            fontFamily: activeTheme.fontFamily,
            fontWeight: FontWeight.w700,
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
                  padding: const EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                  ),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load habits: $err',
                    style: TextStyle(
                      fontFamily: activeTheme.fontFamily,
                      color: activeTheme.textPrimary,
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
    ThemeData themeData,
  ) {
    final accents = activeTheme.accentPalette;
    final primaryAccent = accents.isNotEmpty
        ? accents.first
        : themeData.colorScheme.primary;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${_getGreeting()}, Frede',
                style: TextStyle(
                  fontFamily: activeTheme.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: activeTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              const Text('👋', style: TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Dusk & Dawn Tracker',
            style: TextStyle(
              fontFamily: activeTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: activeTheme.textPrimary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FilledButton.tonalIcon(
            icon: Icon(Icons.palette_outlined, size: 16, color: primaryAccent),
            label: Text(
              'Theme Studio',
              style: TextStyle(
                fontFamily: activeTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: activeTheme.textPrimary,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: activeTheme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: activeTheme.cardBorder, width: 1.2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // 7-Day Interactive Calendar Strip
        CalendarStrip(
          onAddTap: () => _showAddHabitDialog(context, activeTheme),
        ),
        const SizedBox(height: 18),

        // Consistency score weekly chart
        const ConsistencyChart(),
        const SizedBox(height: 18),

        // Favorite activities carousel
        const FavoriteActivitiesCarousel(),
        const SizedBox(height: 20),

        // Progress Overview Stats Card
        const BentoStatsCard(),
        const SizedBox(height: 22),

        // Routine Category Filter Chips
        _buildFilterChips(activeTheme, routineGroups, activeFilter),
        const SizedBox(height: 16),

        // Section Title
        Text(
          'ACTIVE HABITS',
          style: TextStyle(
            fontFamily: activeTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: activeTheme.textPrimary.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 12),

        // Habits List
        if (filteredHabits.isEmpty)
          _buildEmptyState(activeTheme)
        else
          ...filteredHabits.map((habit) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: BentoHabitCard(
                habit: habit,
                date: selectedDate,
              ),
            );
          }),
        const SizedBox(height: 72),
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
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CalendarStrip(
                onAddTap: () => _showAddHabitDialog(context, activeTheme),
              ),
              const SizedBox(height: 20),
              const ConsistencyChart(),
              const SizedBox(height: 20),
              const FavoriteActivitiesCarousel(),
              const SizedBox(height: 20),
              const BentoStatsCard(),
            ],
          ),
        ),

        // Right Column: Filter chips & Habits Feed
        Expanded(
          flex: 6,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildFilterChips(activeTheme, routineGroups, activeFilter),
              const SizedBox(height: 16),
              Text(
                'ACTIVE HABITS',
                style: TextStyle(
                  fontFamily: activeTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: activeTheme.textPrimary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 12),
              if (filteredHabits.isEmpty)
                _buildEmptyState(activeTheme)
              else
                ...filteredHabits.map((habit) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: BentoHabitCard(
                      habit: habit,
                      date: selectedDate,
                    ),
                  );
                }),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(
    UserThemeModel activeTheme,
    List<String> routineGroups,
    String activeFilter,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: routineGroups.map((group) {
          final isSelected = activeFilter.toLowerCase() == group.toLowerCase();
          final accents = activeTheme.accentPalette;
          final primaryAccent = accents.isNotEmpty
              ? accents.first
              : Theme.of(context).colorScheme.primary;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(group),
              selected: isSelected,
              onSelected: (_) {
                AppHaptics.selectionClick();
                ref.read(activeRoutineFilterProvider.notifier).state = group;
              },
              selectedColor: primaryAccent,
              backgroundColor: activeTheme.cardBg,
              labelStyle: TextStyle(
                fontFamily: activeTheme.fontFamily,
                color: isSelected ? Colors.white : activeTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
              side: BorderSide(
                color: isSelected ? primaryAccent : activeTheme.cardBorder,
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(UserThemeModel activeTheme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: activeTheme.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: activeTheme.cardBorder, width: 1.2),
      ),
      child: Center(
        child: Column(
          children: [
            Text('🎯', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            Text(
              'No habits in this routine',
              style: TextStyle(
                fontFamily: activeTheme.fontFamily,
                fontWeight: FontWeight.w700,
                color: activeTheme.textPrimary,
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
    final routineController = TextEditingController(text: 'General');
    int selectedAccent = 0;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: activeTheme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: activeTheme.cardBorder, width: 1.2),
              ),
              title: Text(
                'New Habit',
                style: TextStyle(
                  fontFamily: activeTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  color: activeTheme.textPrimary,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: TextStyle(
                        fontFamily: activeTheme.fontFamily,
                        color: activeTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Habit Title',
                        hintText: 'e.g. Morning Breathwork',
                        labelStyle: TextStyle(
                          color: activeTheme.textPrimary.withValues(alpha: 0.6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subtitleController,
                      style: TextStyle(
                        fontFamily: activeTheme.fontFamily,
                        color: activeTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Subtitle / Notes',
                        hintText: 'e.g. 15 minutes outdoors',
                        labelStyle: TextStyle(
                          color: activeTheme.textPrimary.withValues(alpha: 0.6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: routineController,
                      style: TextStyle(
                        fontFamily: activeTheme.fontFamily,
                        color: activeTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Routine Group',
                        hintText: 'e.g. Morning, Evening, Focus',
                        labelStyle: TextStyle(
                          color: activeTheme.textPrimary.withValues(alpha: 0.6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Accent Color Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                        activeTheme.accentPalette.length,
                        (idx) {
                          final color = activeTheme.accentPalette[idx];
                          final isSelected = selectedAccent == idx;
                          return GestureDetector(
                            onTap: () {
                              AppHaptics.selectionClick();
                              setDialogState(() => selectedAccent = idx);
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 2.5)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: 8,
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: activeTheme.textPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: activeTheme.accentPalette.isNotEmpty
                        ? activeTheme.accentPalette[selectedAccent % activeTheme.accentPalette.length]
                        : Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    final newHabit = HabitModel(
                      id: 'habit_${DateTime.now().millisecondsSinceEpoch}',
                      title: title,
                      subtitle: subtitleController.text.trim(),
                      frequency: const HabitFrequency.daily(),
                      routineGroup: routineController.text.trim().isEmpty
                          ? 'General'
                          : routineController.text.trim(),
                      accentIndex: selectedAccent,
                      createdAt: DateTime.now(),
                    );

                    ref.read(habitListProvider.notifier).createHabit(newHabit);
                    Navigator.of(dialogContext).pop();
                    AppHaptics.heavyImpact();
                  },
                  child: const Text('Add Habit'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
