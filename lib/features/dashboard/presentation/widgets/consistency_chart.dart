import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../themes/presentation/providers/theme_provider.dart';

/// "Consistency score" weekly bar chart directly inspired by Reference Image 1.
class ConsistencyChart extends ConsumerWidget {
  const ConsistencyChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final activeTheme = themeState.activeTheme;
    final accents = activeTheme.accentPalette;
    final primaryAccent = accents.isNotEmpty
        ? accents.first
        : Theme.of(context).colorScheme.primary;

    final habits = ref.watch(habitListProvider).value ?? const [];
    final selectedDate = ref.watch(selectedDateProvider);

    const weekLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thr', 'Fri', 'Sat'];

    // Calculate completions for the current week (Sun..Sat)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Sunday of the week
    final sunday = today.subtract(Duration(days: today.weekday % 7));

    final weekData = List.generate(7, (i) {
      final day = sunday.add(Duration(days: i));
      final scheduled = habits.where((h) => !h.isArchived && h.frequency.isScheduledFor(day)).toList();
      final done = scheduled.where((h) => h.isCompletedOn(day)).length;
      final rate = scheduled.isNotEmpty ? done / scheduled.length : 0.0;
      return (
        date: day,
        label: weekLabels[i],
        rate: rate,
        isToday: day.year == today.year && day.month == today.month && day.day == today.day,
        isSelected: day.year == selectedDate.year && day.month == selectedDate.month && day.day == selectedDate.day,
      );
    });

    final avgRate = weekData.map((e) => e.rate).reduce((a, b) => a + b) / 7;
    final avgPercent = (avgRate * 100).round();

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
          // Header & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consistency score',
                style: TextStyle(
                  fontFamily: activeTheme.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: activeTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: activeTheme.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFF11252E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Avg. $avgPercent%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bar Chart
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekData.map((bar) {
                final heightFactor = (bar.rate.clamp(0.15, 1.0));
                final isHighlight = bar.isToday || bar.isSelected;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isHighlight) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(bar.rate * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: 28,
                      height: 70 * heightFactor,
                      decoration: BoxDecoration(
                        color: isHighlight
                            ? primaryAccent
                            : (activeTheme.isDark
                                ? const Color(0xFF262837)
                                : const Color(0xFFDCE4E9)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: isHighlight
                            ? primaryAccent.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bar.label,
                        style: TextStyle(
                          fontFamily: activeTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                          color: isHighlight
                              ? primaryAccent
                              : activeTheme.textPrimary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
