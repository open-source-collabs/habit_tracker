import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/services/notification_service.dart';
import 'package:habit_tracker/core/services/reminder_schedule.dart';
import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/habits/data/storage/web_habit_storage.dart';
import 'package:habit_tracker/features/habits/presentation/providers/habit_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

HabitModel _habit({
  String id = 'habit_1',
  HabitFrequency frequency = const HabitFrequency.daily(),
  String? reminderTime = '08:30',
  bool archived = false,
}) =>
    HabitModel(
      id: id,
      title: 'Read',
      frequency: frequency,
      createdAt: DateTime(2026, 1, 1),
      reminderTime: reminderTime,
      isArchived: archived,
    );

class _RecordingNotifications implements NotificationService {
  final List<HabitModel> synced = [];
  final List<List<HabitModel>> rescheduled = [];

  @override
  bool remindersEnabled = true;

  @override
  Future<void> syncHabitReminder(HabitModel habit) async => synced.add(habit);

  @override
  Future<void> rescheduleAll(List<HabitModel> habits) async =>
      rescheduled.add(habits);

  @override
  Future<void> cancelHabitReminder(String habitId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Reminder ids', () {
    test('FNV-1a matches published test vectors', () {
      expect(ReminderSchedule.fnv1a32(''), 0x811c9dc5);
      expect(ReminderSchedule.fnv1a32('a'), 0xe40c292c);
      expect(ReminderSchedule.fnv1a32('foobar'), 0xbf9cf968);
    });

    test('are stable, outside the reserved range, and fit in 32 bits', () {
      final ids = [for (var i = 0; i < 500; i++) 'habit_${1700000000000 + i}'];
      final bases = ids.map(ReminderSchedule.baseId).toList();

      expect(bases.toSet().length, bases.length, reason: 'no collisions');
      for (final base in bases) {
        expect(base, greaterThanOrEqualTo(ReminderSchedule.reservedIdCeiling));
        expect(base + 7, lessThan(0x80000000));
      }
      expect(ReminderSchedule.baseId(ids.first), bases.first);
      expect(ReminderSchedule.allIds(ids.first),
          [for (var i = 0; i < 8; i++) bases.first + i]);
    });
  });

  group('Reminder slots', () {
    test('daily and times-per-week habits get one daily reminder', () {
      for (final frequency in const [
        HabitFrequency.daily(),
        HabitFrequency.timesPerWeek(3),
      ]) {
        final slots = ReminderSchedule.slotsFor(_habit(frequency: frequency));
        expect(slots, [
          ReminderSlot(
            id: ReminderSchedule.baseId('habit_1'),
            weekday: null,
            hour: 8,
            minute: 30,
          ),
        ]);
      }
    });

    test('weekday habits get one weekly reminder per scheduled day', () {
      final slots = ReminderSchedule.slotsFor(
        _habit(frequency: const HabitFrequency.specificWeekdays([5, 1, 3, 3])),
      );
      final base = ReminderSchedule.baseId('habit_1');

      expect(slots.map((s) => s.weekday), [1, 3, 5]);
      expect(slots.map((s) => s.id), [base + 1, base + 3, base + 5]);
    });

    test('all seven weekdays collapse into a daily reminder', () {
      final slots = ReminderSchedule.slotsFor(
        _habit(frequency: const HabitFrequency.specificWeekdays([1, 2, 3, 4, 5, 6, 7])),
      );
      expect(slots.single.weekday, isNull);
    });

    test('archived habits and missing or invalid times get none', () {
      expect(ReminderSchedule.slotsFor(_habit(archived: true)), isEmpty);
      expect(ReminderSchedule.slotsFor(_habit(reminderTime: null)), isEmpty);
      for (final bad in ['24:00', '8', 'aa:bb', '07:60']) {
        expect(ReminderSchedule.slotsFor(_habit(reminderTime: bad)), isEmpty,
            reason: bad);
      }
    });
  });

  group('Next occurrence', () {
    // Wednesday 2026-10-14, 10:00
    final now = DateTime(2026, 10, 14, 10, 0);

    test('daily: later today, otherwise tomorrow', () {
      expect(
        ReminderSchedule.nextOccurrence(now, hour: 18, minute: 0),
        DateTime(2026, 10, 14, 18, 0),
      );
      expect(
        ReminderSchedule.nextOccurrence(now, hour: 9, minute: 0),
        DateTime(2026, 10, 15, 9, 0),
      );
      expect(
        ReminderSchedule.nextOccurrence(now, hour: 10, minute: 0),
        DateTime(2026, 10, 15, 10, 0),
        reason: 'a reminder for "now" is already due, so the next is tomorrow',
      );
    });

    test('weekly: the next matching weekday', () {
      expect(
        ReminderSchedule.nextOccurrence(now, hour: 8, minute: 0, weekday: 5),
        DateTime(2026, 10, 16, 8, 0),
      );
      expect(
        ReminderSchedule.nextOccurrence(now, hour: 8, minute: 0, weekday: 1),
        DateTime(2026, 10, 19, 8, 0),
      );
      expect(
        ReminderSchedule.nextOccurrence(now, hour: 18, minute: 0, weekday: 3),
        DateTime(2026, 10, 14, 18, 0),
      );
      expect(
        ReminderSchedule.nextOccurrence(now, hour: 9, minute: 0, weekday: 3),
        DateTime(2026, 10, 21, 9, 0),
      );
    });
  });

  group('HabitListNotifier keeps reminders in step', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('create, edit, and import sync reminders', () async {
      final notifications = _RecordingNotifications();
      final container = ProviderContainer(
        overrides: [
          habitStorageProvider.overrideWithValue(
            WebHabitStorage(InMemoryWebStore()),
          ),
          notificationServiceProvider.overrideWithValue(notifications),
        ],
      );
      addTearDown(container.dispose);
      await container.read(habitListProvider.future);
      final notifier = container.read(habitListProvider.notifier);

      await notifier.createHabit(_habit(id: 'new'));
      expect(notifications.synced.single.id, 'new');

      await notifier.updateHabit(_habit(id: 'new', reminderTime: null));
      expect(notifications.synced.last.reminderTime, isNull,
          reason: 'clearing the time must cancel the reminder');

      await notifier.restoreHabits([_habit(id: 'imported')]);
      expect(notifications.rescheduled.single.single.id, 'imported');
    });
  });
}
