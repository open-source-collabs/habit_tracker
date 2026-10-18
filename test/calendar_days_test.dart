import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/utils/calendar_days.dart';
import 'package:habit_tracker/features/habits/data/models/habit_model.dart';

/// These checks are meaningful in any time zone and catch the DST bug when
/// run where clocks change (e.g. `TZ=America/New_York flutter test`):
/// 2026-03-08 is 23 hours long there, 2026-11-01 is 25 hours long.
void main() {
  group('CalendarDays', () {
    test('steps across spring-forward without skipping a day', () {
      final dayAfter = DateTime(2026, 3, 9);
      expect(CalendarDays.addDays(dayAfter, -1), DateTime(2026, 3, 8));
      expect(CalendarDays.addDays(dayAfter, -2), DateTime(2026, 3, 7));
    });

    test('steps across fall-back without repeating a day', () {
      final dayAfter = DateTime(2026, 11, 2);
      expect(CalendarDays.addDays(dayAfter, -1), DateTime(2026, 11, 1));
      expect(CalendarDays.addDays(DateTime(2026, 10, 31), 2),
          DateTime(2026, 11, 2));
    });

    test('daysBetween counts calendar days, not 24h blocks', () {
      expect(
        CalendarDays.daysBetween(DateTime(2026, 3, 8), DateTime(2026, 3, 9)),
        1,
      );
      expect(
        CalendarDays.daysBetween(DateTime(2026, 3, 1), DateTime(2026, 4, 1)),
        31,
      );
    });

    test('mondayOf', () {
      expect(CalendarDays.mondayOf(DateTime(2026, 3, 8)), DateTime(2026, 3, 2));
      expect(CalendarDays.mondayOf(DateTime(2026, 3, 9)), DateTime(2026, 3, 9));
    });
  });

  group('streaks across daylight-saving changes', () {
    HabitModel dailyWith(List<DateTime> days) => HabitModel(
          id: 'h',
          title: 'h',
          frequency: const HabitFrequency.daily(),
          createdAt: DateTime(2026, 1, 1),
          checkIns: {for (final d in days) HabitModel.formatDate(d): true},
        );

    final aroundSpringForward = [
      for (var d = 5; d <= 10; d++) DateTime(2026, 3, d),
    ];
    final aroundFallBack = [
      DateTime(2026, 10, 30),
      DateTime(2026, 10, 31),
      DateTime(2026, 11, 1),
      DateTime(2026, 11, 2),
      DateTime(2026, 11, 3),
    ];

    test('current streak survives spring-forward', () {
      final habit = dailyWith(aroundSpringForward);
      expect(habit.calculateCurrentStreak(asOf: DateTime(2026, 3, 10)), 6);
    });

    test('longest streak survives spring-forward and fall-back', () {
      expect(dailyWith(aroundSpringForward).calculateLongestStreak(), 6);
      expect(dailyWith(aroundFallBack).calculateLongestStreak(), 5);
    });

    test('weekly target streak spans the DST week', () {
      final habit = HabitModel(
        id: 'w',
        title: 'w',
        frequency: const HabitFrequency.timesPerWeek(2),
        createdAt: DateTime(2026, 1, 1),
        checkIns: {
          for (final d in [
            DateTime(2026, 3, 3),
            DateTime(2026, 3, 5),
            DateTime(2026, 3, 8),
            DateTime(2026, 3, 9),
            DateTime(2026, 3, 10),
          ])
            HabitModel.formatDate(d): true,
        },
      );
      expect(habit.calculateCurrentStreak(asOf: DateTime(2026, 3, 10)), 2);
    });
  });
}
