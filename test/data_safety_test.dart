import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/data/app_data_repository.dart';
import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/habits/data/storage/habit_storage.dart';
import 'package:habit_tracker/features/habits/data/storage/io_habit_storage.dart';
import 'package:habit_tracker/features/habits/data/storage/web_habit_storage.dart';
import 'package:habit_tracker/features/habits/presentation/providers/habit_provider.dart';
import 'package:habit_tracker/features/themes/data/models/app_payload_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage whose saves can be held open, to observe write ordering.
class _RecordingStorage implements HabitStorage {
  _RecordingStorage({this.stored, this.loadError});

  AppPayloadModel? stored;
  final Object? loadError;
  final List<AppPayloadModel> saves = [];
  int inFlight = 0;
  int maxInFlight = 0;
  Completer<void>? gate;

  @override
  Future<AppPayloadModel?> loadPayload() async {
    if (loadError != null) throw loadError!;
    return stored;
  }

  @override
  Future<void> savePayload(AppPayloadModel payload) async {
    inFlight++;
    maxInFlight = inFlight > maxInFlight ? inFlight : maxInFlight;
    try {
      await (gate?.future ?? Future<void>.value());
      saves.add(payload);
      stored = payload;
    } finally {
      inFlight--;
    }
  }

  @override
  Future<List<String>> listBackups() async => const [];

  @override
  Future<AppPayloadModel?> restoreBackup(String backupName) async => null;

  @override
  Future<void> clear() async => stored = null;
}

HabitModel _habit(String id, {Map<String, bool> checkIns = const {}}) =>
    HabitModel(
      id: id,
      title: id,
      frequency: const HabitFrequency.daily(),
      createdAt: DateTime(2026, 1, 1),
      checkIns: checkIns,
    );

AppPayloadModel _payloadWith(List<HabitModel> habits) =>
    AppPayloadModel.initial(lastModifiedBy: 'test').copyWith(habits: habits);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AppDataRepository', () {
    test('serializes and coalesces a burst of writes', () async {
      final storage = _RecordingStorage(stored: _payloadWith(const []));
      final repo = AppDataRepository(storage);
      await repo.load();

      storage.gate = Completer<void>();
      final writes = [
        for (var i = 0; i < 5; i++)
          repo.update((p) => p.copyWith(habits: [_habit('h$i')])),
      ];
      await pumpEventQueue();
      storage.gate!.complete();
      await Future.wait(writes);

      expect(storage.maxInFlight, 1, reason: 'saves must never overlap');
      expect(storage.saves.length, lessThan(5), reason: 'bursts coalesce');
      expect(storage.stored!.habits.single.id, 'h4', reason: 'latest wins');
    });

    test('refuses writes when stored data is unreadable', () async {
      final storage = _RecordingStorage(
        loadError: const CorruptPayloadException('bad json'),
      );
      final repo = AppDataRepository(storage);

      await expectLater(repo.load(), throwsA(isA<CorruptPayloadException>()));
      await expectLater(
        repo.update((p) => p.copyWith(habits: [_habit('x')])),
        throwsA(isA<CorruptPayloadException>()),
      );
      expect(storage.saves, isEmpty);
    });

    test('discardStoredData starts empty and re-enables writes', () async {
      final storage = _RecordingStorage(
        loadError: const CorruptPayloadException(),
      );
      final repo = AppDataRepository(storage);
      await expectLater(repo.load(), throwsA(isA<CorruptPayloadException>()));

      await repo.discardStoredData();
      final snapshot = await repo.load();
      expect(snapshot.payload.habits, isEmpty);
      expect(snapshot.isFirstRun, isFalse);

      await repo.update((p) => p.copyWith(habits: [_habit('fresh')]));
      expect(storage.stored!.habits.single.id, 'fresh');
    });

    test('a failed save is reported and retried by the next write', () async {
      final storage = _FlakyStorage(stored: _payloadWith(const []));
      final repo = AppDataRepository(storage);
      await repo.load();
      final errors = <Object>[];
      final sub = repo.saveErrors.listen(errors.add);
      addTearDown(sub.cancel);

      storage.failNext = true;
      await expectLater(
        repo.update((p) => p.copyWith(habits: [_habit('a')])),
        throwsA(isA<FileSystemException>()),
      );
      await pumpEventQueue();
      expect(errors, hasLength(1));
      expect(repo.lastWriteFailed, isTrue);
      expect(repo.current!.habits.single.id, 'a', reason: 'change kept');

      await repo.update((p) => p.copyWith(habits: [...p.habits, _habit('b')]));
      expect(repo.lastWriteFailed, isFalse);
      expect(storage.stored!.habits.map((h) => h.id), ['a', 'b']);
    });

    test('deleteAllData wipes storage and the next load is a first run',
        () async {
      final storage = _RecordingStorage(stored: _payloadWith([_habit('x')]));
      final repo = AppDataRepository(storage);
      await repo.load();

      await repo.deleteAllData();
      expect(storage.stored, isNull);
      expect((await repo.load()).isFirstRun, isTrue);
    });
  });

  group('HabitListNotifier data safety', () {
    ProviderContainer containerFor(HabitStorage storage) {
      final container = ProviderContainer(
        overrides: [habitStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('unreadable data surfaces an error and is never overwritten',
        () async {
      final storage = _RecordingStorage(
        loadError: const CorruptPayloadException(),
      );
      final container = containerFor(storage);

      await expectLater(
        container.read(habitListProvider.future),
        throwsA(isA<CorruptPayloadException>()),
      );
      expect(container.read(habitListProvider).hasError, isTrue);

      final notifier = container.read(habitListProvider.notifier);
      await notifier.createHabit(_habit('new'));
      await notifier.toggleHabit('new', DateTime.now());
      await pumpEventQueue();

      expect(storage.saves, isEmpty, reason: 'no demo data, no overwrite');
      expect(container.read(dailyHabitStatsProvider).totalScheduled, 0);
    });

    test('a first run seeds nothing and saves only once onboarding ends',
        () async {
      final storage = _RecordingStorage();
      final container = containerFor(storage);
      final repository = container.read(appDataRepositoryProvider);

      expect(await container.read(habitListProvider.future), isEmpty);
      await repository.flush();
      expect(storage.saves, isEmpty, reason: 'no demo data written');
      expect(repository.hasNeverSaved, isTrue);

      await container
          .read(habitListProvider.notifier)
          .completeOnboarding(const []);
      expect(storage.saves, hasLength(1));
      expect(repository.hasNeverSaved, isFalse);
    });

    test('an existing empty habit list is not replaced by starter habits',
        () async {
      final storage = _RecordingStorage(stored: _payloadWith(const []));
      final container = containerFor(storage);

      expect(await container.read(habitListProvider.future), isEmpty);
    });

    test('future dates cannot be checked off', () async {
      final storage = _RecordingStorage(stored: _payloadWith([_habit('h')]));
      final container = containerFor(storage);
      await container.read(habitListProvider.future);

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await container
          .read(habitListProvider.notifier)
          .toggleHabit('h', tomorrow);

      final habit = container.read(habitListProvider).value!.single;
      expect(habit.isCompletedOn(tomorrow), isFalse);
      expect(storage.saves, isEmpty);
    });

    test('discardUnreadableData recovers to an empty, writable list',
        () async {
      final storage = _RecordingStorage(
        loadError: const CorruptPayloadException(),
      );
      final container = containerFor(storage);
      await expectLater(
        container.read(habitListProvider.future),
        throwsA(isA<CorruptPayloadException>()),
      );

      await container
          .read(habitListProvider.notifier)
          .discardUnreadableData();
      expect(await container.read(habitListProvider.future), isEmpty);

      await container.read(habitListProvider.notifier).createHabit(_habit('a'));
      await container.read(appDataRepositoryProvider).flush();
      expect(storage.stored!.habits.single.id, 'a');
    });
  });

  group('Storage corruption handling', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('habit_corrupt_'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('IoHabitStorage throws and keeps a copy when nothing is readable',
        () async {
      final storage = IoHabitStorage(directory: dir);
      await storage.savePayload(AppPayloadModel.initial());
      await storage.savePayload(AppPayloadModel.initial());
      for (final name in ['app_data.json', 'backup_1.json']) {
        File('${dir.path}/$name').writeAsStringSync('{broken');
      }

      await expectLater(
        storage.loadPayload(),
        throwsA(isA<CorruptPayloadException>()),
      );
      final copy = File('${dir.path}/${IoHabitStorage.corruptCopyFileName}');
      expect(copy.readAsStringSync(), '{broken');
    });

    test('WebHabitStorage throws and keeps a copy when nothing is readable',
        () async {
      final store = InMemoryWebStore();
      await store.setString(WebHabitStorage.primaryKey, '{broken');
      final storage = WebHabitStorage(store);

      await expectLater(
        storage.loadPayload(),
        throwsA(isA<CorruptPayloadException>()),
      );
      expect(
        await store.getString(WebHabitStorage.corruptCopyKey),
        '{broken',
      );
    });

    test('data from a newer schema version is rejected, not dropped', () {
      final json = AppPayloadModel.initial().toJson()
        ..['version'] = AppPayloadModel.currentSchemaVersion + 1;

      expect(
        () => AppPayloadModel.fromJson(json),
        throwsA(isA<UnsupportedPayloadVersionException>()),
      );
    });
  });

  group('HabitModel', () {
    test('equal habits hash equally regardless of check-in order', () {
      final a = _habit('h', checkIns: {'2026-01-01': true, '2026-01-02': true});
      final b = _habit('h', checkIns: {'2026-01-02': true, '2026-01-01': true});

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith can clear nullable fields', () {
      final habit = _habit('h').copyWith(reminderTime: '08:30', emoji: '🔥');
      final cleared = habit.copyWith(clearReminderTime: true, clearEmoji: true);

      expect(cleared.reminderTime, isNull);
      expect(cleared.emoji, isNull);
    });
  });
}

/// Storage whose next save can be made to fail once.
class _FlakyStorage extends _RecordingStorage {
  _FlakyStorage({super.stored});

  bool failNext = false;

  @override
  Future<void> savePayload(AppPayloadModel payload) async {
    if (failNext) {
      failNext = false;
      throw const FileSystemException('disk full');
    }
    await super.savePayload(payload);
  }
}
