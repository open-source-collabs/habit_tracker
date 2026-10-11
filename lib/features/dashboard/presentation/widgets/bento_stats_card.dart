import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../themes/presentation/providers/theme_provider.dart';

/// Bento Stats Card showing daily completion progress, streaks, and completion rate.
class BentoStatsCard extends ConsumerWidget {
  const BentoStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final activeTheme = themeState.activeTheme;
    final stats = ref.watch(dailyHabitStatsProvider);
    final accents = activeTheme.accentPalette;
    final primaryAccent = accents.isNotEmpty
        ? accents.first
        : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: activeTheme.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: activeTheme.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: activeTheme.isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROGRESS OVERVIEW',
                style: TextStyle(
                  fontFamily: activeTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: activeTheme.textPrimary.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '${stats.completedCount}/${stats.totalScheduled} Complete',
                style: TextStyle(
                  fontFamily: activeTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: activeTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: stats.totalScheduled > 0 ? stats.completionRate : 0.0,
              minHeight: 8,
              backgroundColor: activeTheme.cardBorder.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
            ),
          ),
          if (stats.longestActiveStreak > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 15,
                  color: primaryAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  'Best streak: ${stats.longestActiveStreak} days in a row',
                  style: TextStyle(
                    fontFamily: activeTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: activeTheme.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
