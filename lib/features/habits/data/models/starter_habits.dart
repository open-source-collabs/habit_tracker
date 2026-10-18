import 'package:flutter/foundation.dart';

import 'habit_model.dart';

/// A suggested habit offered during onboarding. Creates a real habit with no
/// history — new users never start with made-up streaks.
@immutable
class StarterHabit {
  final String key;
  final String title;
  final String subtitle;
  final String emoji;
  final String routineGroup;
  final int accentIndex;
  final HabitFrequency frequency;

  const StarterHabit({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.routineGroup,
    required this.accentIndex,
    required this.frequency,
  });

  /// A new habit created [now]. The id is unique per creation, so a starter
  /// picked on two devices stays two habits instead of silently merging.
  HabitModel toHabit(DateTime now, {int index = 0}) {
    final today = DateTime(now.year, now.month, now.day);
    return HabitModel(
      id: 'habit_${key}_${now.millisecondsSinceEpoch + index}',
      title: title,
      subtitle: subtitle,
      frequency: frequency,
      routineGroup: routineGroup,
      accentIndex: accentIndex,
      createdAt: today,
      emoji: emoji,
      lastModifiedAt: now,
    );
  }
}

/// Curated suggestions shown on the onboarding "pick your habits" page.
abstract final class StarterHabits {
  static const List<StarterHabit> all = [
    StarterHabit(
      key: 'sunlight',
      title: 'Morning Sunlight & Breath',
      subtitle: '15 mins outdoors within 1 hour of waking',
      emoji: '☀️',
      routineGroup: 'Morning',
      accentIndex: 0,
      frequency: HabitFrequency.daily(),
    ),
    StarterHabit(
      key: 'focus_sprint',
      title: 'Deep Focus Sprint',
      subtitle: '90 mins uninterrupted deep work',
      emoji: '⚡',
      routineGroup: 'Focus',
      accentIndex: 1,
      frequency: HabitFrequency.specificWeekdays([
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
      ]),
    ),
    StarterHabit(
      key: 'hydration',
      title: 'Hydration Target (3L)',
      subtitle: 'Consistent water intake through the day',
      emoji: '💧',
      routineGroup: 'Health',
      accentIndex: 2,
      frequency: HabitFrequency.daily(),
    ),
    StarterHabit(
      key: 'gratitude',
      title: 'Evening Gratitude Journal',
      subtitle: 'Reflect on 3 micro-wins before sleep',
      emoji: '📖',
      routineGroup: 'Evening',
      accentIndex: 3,
      frequency: HabitFrequency.daily(),
    ),
    StarterHabit(
      key: 'strength',
      title: 'Strength & Mobility',
      subtitle: 'Compound lifts or a bodyweight circuit',
      emoji: '💪',
      routineGroup: 'Fitness',
      accentIndex: 4,
      frequency: HabitFrequency.timesPerWeek(3),
    ),
  ];
}
