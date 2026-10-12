import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../features/habits/data/models/habit_model.dart';

/// Standalone visual card intended for off-screen rendering via
/// [WidgetsKit.renderFlutterWidget] to provide high-fidelity home screen previews.
class HabitWidgetSnapshotView extends StatelessWidget {
  final List<HabitModel> habits;
  final DateTime date;
  final double width;
  final double height;

  const HabitWidgetSnapshotView({
    super.key,
    required this.habits,
    required this.date,
    this.width = 320,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final scheduled = habits
        .where((h) => h.frequency.isScheduledFor(normalizedDate))
        .toList();
    final completed = scheduled
        .where((h) => h.isCompletedOn(normalizedDate))
        .length;
    final total = scheduled.length;
    final ratio = total > 0 ? (completed / total) : 0.0;
    final percent = (ratio * 100).round();

    int highestStreak = 0;
    for (final h in habits) {
      final s = h.calculateCurrentStreak(asOf: normalizedDate);
      if (s > highestStreak) highestStreak = s;
    }

    final accent = context.primaryAccent;
    final cardBg = context.cardBackgroundColor;
    final border = context.cardBorderColor;
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: App name & Streak Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Habit Tracker',
                style: context.textTheme.labelMedium?.copyWith(
                  color: textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              if (highestStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.pastelSurface(
                      accent,
                      isDark: context.isDarkMode,
                      opacity: 0.16,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 13,
                        color: accent,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$highestStreak d',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),

          // Progress & Metric row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$completed / $total',
                style: context.textTheme.headlineMedium?.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'completed today ($percent%)',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Custom visual progress indicator bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: context.surfaceElevatedColor,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
