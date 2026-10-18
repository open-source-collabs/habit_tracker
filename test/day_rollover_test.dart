import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/utils/calendar_days.dart';
import 'package:habit_tracker/features/habits/presentation/providers/habit_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = CalendarDays.dateOnly(DateTime.now());
  final yesterday = CalendarDays.addDays(today, -1);

  ProviderContainer containerStartingOn(DateTime day, {DateTime? selected}) {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(currentDayProvider.notifier).state = day;
    container.read(selectedDateProvider.notifier).state = selected ?? day;
    return container;
  }

  test('past midnight, "today" moves to the new day', () {
    final container = containerStartingOn(yesterday);

    container.read(dayRolloverWatcherProvider).refresh();

    expect(container.read(currentDayProvider), today);
    expect(container.read(selectedDateProvider), today);
  });

  test('a deliberately selected past day is left alone', () {
    final threeDaysAgo = CalendarDays.addDays(today, -3);
    final container = containerStartingOn(yesterday, selected: threeDaysAgo);

    container.read(dayRolloverWatcherProvider).refresh();

    expect(container.read(currentDayProvider), today);
    expect(container.read(selectedDateProvider), threeDaysAgo);
  });

  test('refreshing on the same day changes nothing', () {
    final container = containerStartingOn(today);
    container.read(dayRolloverWatcherProvider).refresh();
    expect(container.read(selectedDateProvider), today);
  });
}
