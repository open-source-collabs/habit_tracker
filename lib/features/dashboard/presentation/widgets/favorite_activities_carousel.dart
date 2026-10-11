import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/haptics.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../themes/presentation/providers/theme_provider.dart';

/// "Favorite activities" pastel-tinted wellness card carousel directly from Reference Image 1.
class FavoriteActivitiesCarousel extends ConsumerWidget {
  const FavoriteActivitiesCarousel({super.key});

  static const List<({
    String title,
    String stat,
    IconData icon,
    Color accentColor,
    String routineGroup,
  })> _activities = [
    (
      title: 'Mind Detox',
      stat: '13h logged',
      icon: Icons.psychology_alt_rounded,
      accentColor: Color(0xFF8B5CF6), // Neon Lavender
      routineGroup: 'Focus',
    ),
    (
      title: 'Gratitude Notes',
      stat: '34 entries',
      icon: Icons.wb_sunny_rounded,
      accentColor: Color(0xFF06B6D4), // Cyan Glow
      routineGroup: 'Evening',
    ),
    (
      title: 'Conscious Breath',
      stat: '34 sessions',
      icon: Icons.spa_rounded,
      accentColor: Color(0xFF10B981), // Emerald Mint
      routineGroup: 'Morning',
    ),
    (
      title: 'Strength Training',
      stat: '18 workouts',
      icon: Icons.fitness_center_rounded,
      accentColor: Color(0xFFFF6B55), // Sunset Coral
      routineGroup: 'Fitness',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final activeTheme = themeState.activeTheme;
    final activeFilter = ref.watch(activeRoutineFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Favorite activities',
            style: TextStyle(
              fontFamily: activeTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: activeTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _activities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final act = _activities[index];
              final isSelected = activeFilter.toLowerCase() == act.routineGroup.toLowerCase();

              // In light theme: soft pastel watercolor tint; in dark theme: ambient blended surface
              final bgColor = AppColors.pastelSurface(
                act.accentColor,
                isDark: activeTheme.isDark,
                opacity: 0.16,
              );

              return GestureDetector(
                onTap: () {
                  AppHaptics.selectionClick();
                  final newFilter = isSelected ? 'All' : act.routineGroup;
                  ref.read(activeRoutineFilterProvider.notifier).state = newFilter;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 130,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? act.accentColor
                          : act.accentColor.withValues(alpha: 0.25),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: act.accentColor.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              act.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: activeTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: activeTheme.isDark
                                    ? Colors.white
                                    : const Color(0xFF11252E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            act.stat,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: activeTheme.isDark
                                  ? Colors.white70
                                  : const Color(0xFF5C6E76),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: act.accentColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              act.icon,
                              size: 16,
                              color: act.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
