import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/haptics.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../themes/presentation/providers/theme_provider.dart';

/// 7-day horizontal interactive calendar strip inspired by Reference Image 1 & 2.
class CalendarStrip extends ConsumerWidget {
  final VoidCallback? onAddTap;

  const CalendarStrip({super.key, this.onAddTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final activeTheme = themeState.activeTheme;
    final selectedDate = ref.watch(selectedDateProvider);
    final accents = activeTheme.accentPalette;
    final primaryAccent = accents.isNotEmpty
        ? accents.first
        : Theme.of(context).colorScheme.primary;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Compute the 7-day window centered or ending on today
    final days = List.generate(7, (i) {
      return today.subtract(Duration(days: 3 - i));
    });

    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ...days.map((date) {
            final isSelected = date.year == selectedDate.year &&
                date.month == selectedDate.month &&
                date.day == selectedDate.day;
            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final label = dayLabels[(date.weekday - 1).clamp(0, 6)];

            return GestureDetector(
              onTap: () {
                AppHaptics.selectionClick();
                ref.read(selectedDateProvider.notifier).state = date;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 38,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryAccent
                      : (isToday
                          ? primaryAccent.withValues(alpha: 0.12)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(16),
                  border: isToday && !isSelected
                      ? Border.all(color: primaryAccent.withValues(alpha: 0.4), width: 1.2)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: activeTheme.fontFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : activeTheme.textPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontFamily: activeTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : activeTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (onAddTap != null)
            GestureDetector(
              onTap: () {
                AppHaptics.lightImpact();
                onAddTap!();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primaryAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: primaryAccent,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
