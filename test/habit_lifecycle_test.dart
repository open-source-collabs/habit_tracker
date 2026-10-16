import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/app.dart';
import 'package:habit_tracker/core/data/app_data_repository.dart';
import 'package:habit_tracker/core/data/device_identity.dart';
import 'package:habit_tracker/core/services/notification_service.dart';
import 'package:habit_tracker/features/dashboard/presentation/widgets/favorite_activities_carousel.dart';
import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/habits/data/storage/web_habit_storage.dart';
import 'package:habit_tracker/features/habits/presentation/providers/habit_provider.dart';
import 'package:habit_tracker/features/settings/presentation/providers/profile_provider.dart';
import 'package:habit_tracker/features/sync/domain/merge_engine.dart';
import 'package:habit_tracker/features/themes/data/models/app_payload_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records reminder side effects instead of calling the platform plugin.
class _FakeNotifications implements NotificationService {
  final List<String> cancelled = [];
  final List<HabitModel> synced = [];

  @override
  Future<void> cancelHabitReminder(String habitId) async =>
      cancelled.add(habitId);

  @override
  Future<void> syncHabitReminder(HabitModel habit) async => synced.add(habit);

  @override
  Future<void> rescheduleAll(List<HabitModel> habits) async {}

  @override
  bool remindersEnabled = true;

  @override
  Stream<String> get notificationTaps => const Stream.empty();

  @override
  Future<void> init() async {}

  @override
  Future<String?> takeLaunchPayload() async => null;

  @override
  Future<bool> checkPermissionStatus() async => true;

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelDigest(int id) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

HabitModel _habit(
  String id, {
  String routine = 'Morning',
  bool archived = false,
  Map<String, bool> checkIns = const {},
}) =>
    HabitModel(
      id: id,
      title: 'Habit $id',
      frequency: const HabitFrequency.daily(),
      routineGroup: routine,
      createdAt: DateTime(2026, 1, 1),
      isArchived: archived,
      checkIns: checkIns,
    );

Map<String, bool> _daysBack(int count, {int startOffset = 0}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return {
    for (var i = startOffset; i < startOffset + count; i++)
      HabitModel.formatDate(today.subtract(Duration(days: i))): true,
  };
}

Future<WebHabitStorage> _storageWith(List<HabitModel> habits) async {
  final storage = WebHabitStorage(InMemoryWebStore());
  await storage.savePayload(
    AppPayloadModel.initial(lastModifiedBy: 'seed').copyWith(habits: habits),
  );
  return storage;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late _FakeNotifications notifications;

  Future<ProviderContainer> containerWith(List<HabitModel> habits) async {
    notifications = _FakeNotifications();
    final container = ProviderContainer(
      overrides: [
        habitStorageProvider.overrideWithValue(await _storageWith(habits)),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);
    await container.read(habitListProvider.future);
    return container;
  }

  group('Archiving', () {
    test('pauses a habit without losing history and restores it', () async {
      final container = await containerWith([
        _habit('a', checkIns: _daysBack(3)),
        _habit('b'),
      ]);
      final notifier = container.read(habitListProvider.notifier);

      await notifier.setArchived('a', archived: true);

      final archived =
          container.read(habitListProvider).value!.firstWhere((h) => h.id == 'a');
      expect(archived.isArchived, isTrue);
      expect(archived.checkIns.length, 3, reason: 'history is kept');
      expect(container.read(filteredHabitsProvider).map((h) => h.id), ['b']);
      expect(container.read(dailyHabitStatsProvider).totalScheduled, 1);
      expect(container.read(routineGroupsProvider), contains(kArchivedHabitsFilter));
      expect(container.read(archivedHabitCountProvider), 1);
      expect(notifications.synced.single.isArchived, isTrue,
          reason: 'reminder is brought in line (cancelled) on archive');

      container.read(activeRoutineFilterProvider.notifier).state =
          kArchivedHabitsFilter;
      expect(container.read(filteredHabitsProvider).map((h) => h.id), ['a']);

      await notifier.setArchived('a', archived: false);
      expect(
        container.read(routineGroupsProvider),
        isNot(contains(kArchivedHabitsFilter)),
      );
    });

    test('archived habits cannot be checked off', () async {
      final container = await containerWith([_habit('a', archived: true)]);

      await container
          .read(habitListProvider.notifier)
          .toggleHabit('a', DateTime.now());

      final habit = container.read(habitListProvider).value!.single;
      expect(habit.isCompletedOn(DateTime.now()), isFalse);
    });
  });

  group('Delete & undo', () {
    test('delete cancels the reminder and undo restores position', () async {
      final container = await containerWith(
        [_habit('a'), _habit('b', checkIns: _daysBack(2)), _habit('c')],
      );
      final notifier = container.read(habitListProvider.notifier);

      final removed = await notifier.deleteHabit('b');

      expect(removed!.index, 1);
      expect(notifications.cancelled, ['b']);
      expect(
        container.read(habitListProvider).value!.map((h) => h.id),
        ['a', 'c'],
      );

      await notifier.restoreHabit(removed.habit, index: removed.index);

      final restored = container.read(habitListProvider).value!;
      expect(restored.map((h) => h.id), ['a', 'b', 'c']);
      expect(restored[1].checkIns.length, 2);
      expect(notifications.synced.last.id, 'b');
    });

    test('deleting an unknown habit is a no-op', () async {
      final container = await containerWith([_habit('a')]);
      expect(
        await container.read(habitListProvider.notifier).deleteHabit('zzz'),
        isNull,
      );
    });
  });

  group('Device identity', () {
    test('generates RFC 4122 v4 ids and keeps them stable', () async {
      final id = DeviceIdentity.generateId();
      expect(
        id,
        matches(RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        )),
      );

      const identity = DeviceIdentity();
      final first = await identity.getOrCreate();
      expect(await identity.getOrCreate(), first);
    });

    test('saves are stamped with this device id', () async {
      final storage = WebHabitStorage(InMemoryWebStore());
      final repo = AppDataRepository(
        storage,
        deviceIdResolver: () async => 'device-123',
      );

      await repo.update((p) => p.copyWith(habits: [_habit('a')]));

      expect((await storage.loadPayload())!.lastModifiedBy, 'device-123');
    });
  });

  group('Display name', () {
    test('is trimmed, length-limited, and persisted', () async {
      final container = await containerWith(const []);

      await container
          .read(displayNameProvider.notifier)
          .setDisplayName('  ${'x' * 60}  ');
      await container.read(appDataRepositoryProvider).flush();

      final name = container.read(displayNameProvider);
      expect(name.length, DisplayNameNotifier.maxLength);
      final stored = await container.read(habitStorageProvider).loadPayload();
      expect(stored!.displayName, name);
    });

    test('merge keeps the newest non-empty name', () {
      final older = AppPayloadModel.initial().copyWith(
        displayName: 'Old',
        lastModifiedAt: DateTime(2026, 1, 1),
      );
      final newerUnnamed = AppPayloadModel.initial().copyWith(
        lastModifiedAt: DateTime(2026, 2, 1),
      );
      final newerNamed = newerUnnamed.copyWith(displayName: 'New');

      expect(
        mergePayloads(local: older, incoming: newerNamed).displayName,
        'New',
      );
      expect(
        mergePayloads(local: older, incoming: newerUnnamed).displayName,
        'Old',
      );
    });
  });

  test('top habits rank by streak, then total, skipping archived and unused',
      () async {
    final container = await containerWith([
      _habit('long', checkIns: _daysBack(5)),
      _habit('lapsed', checkIns: _daysBack(9, startOffset: 3)),
      _habit('short', checkIns: _daysBack(2)),
      _habit('archived', archived: true, checkIns: _daysBack(10)),
      _habit('never'),
    ]);

    expect(
      container.read(topHabitsProvider).map((h) => h.id),
      ['long', 'short', 'lapsed'],
    );
  });

  testWidgets('dashboard: delete a habit from its menu, then undo',
      (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = await _storageWith([_habit('a')]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitStorageProvider.overrideWithValue(storage),
          notificationServiceProvider.overrideWithValue(_FakeNotifications()),
        ],
        child: const HabitTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Habit a'), findsWidgets);

    await tester.tap(find.byTooltip('Habit actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Delete "Habit a"?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Habit actions'), findsNothing);
    expect(find.text('"Habit a" deleted.'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Habit actions'), findsOneWidget);
  });
}
