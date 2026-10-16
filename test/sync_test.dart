import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/data/app_data_repository.dart';
import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/habits/data/storage/web_habit_storage.dart';
import 'package:habit_tracker/features/habits/presentation/providers/habit_provider.dart';
import 'package:habit_tracker/features/sync/data/cloud_backends.dart';
import 'package:habit_tracker/features/sync/data/cloud_sync_backend.dart';
import 'package:habit_tracker/features/sync/data/drive_app_data_client.dart';
import 'package:habit_tracker/features/sync/domain/merge_engine.dart';
import 'package:habit_tracker/features/sync/domain/sync_engine.dart';
import 'package:habit_tracker/features/sync/presentation/providers/sync_controller.dart';
import 'package:habit_tracker/features/themes/data/models/app_payload_model.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An in-memory "cloud": the single sync file shared by fake devices.
class _FakeCloud implements CloudSyncBackend {
  _FakeCloud({this.contents});

  String? contents;
  int uploads = 0;
  Completer<void>? downloadGate;
  Object? authError;

  @override
  CloudProvider get provider => CloudProvider.googleDrive;

  @override
  bool get isAvailable => true;

  @override
  Future<String?> restoreSession() async => 'me@example.com';

  @override
  Future<String> connect() async {
    if (authError != null) throw authError!;
    return 'me@example.com';
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<String?> download() async {
    if (authError != null) throw authError!;
    await downloadGate?.future;
    return contents;
  }

  @override
  Future<void> upload(String data) async {
    uploads++;
    contents = data;
  }
}

final _t0 = DateTime.utc(2026, 10, 1, 9);
DateTime _at(int minutes) => _t0.add(Duration(minutes: minutes));
int _ms(int minutes) => _at(minutes).millisecondsSinceEpoch;

HabitModel _habit(
  String id, {
  Map<String, bool> checkIns = const {},
  Map<String, int> changedAt = const {},
  int modifiedMinute = 0,
  String title = 'Habit',
}) => HabitModel(
  id: id,
  title: title,
  frequency: const HabitFrequency.daily(),
  createdAt: _t0,
  checkIns: checkIns,
  checkInChangedAt: changedAt,
  lastModifiedAt: _at(modifiedMinute),
);

AppPayloadModel _payload(
  List<HabitModel> habits, {
  int modifiedMinute = 0,
  Map<String, DateTime> deletedHabits = const {},
  List<UserThemeModel> themes = const [],
  Map<String, DateTime> deletedThemes = const {},
}) => AppPayloadModel(
  version: AppPayloadModel.currentSchemaVersion,
  lastModifiedBy: 'device',
  lastModifiedAt: _at(modifiedMinute),
  activeThemeId: UserThemeModel.defaultTheme.id,
  userThemes: themes,
  habits: habits,
  deletedHabits: deletedHabits,
  deletedThemes: deletedThemes,
);

HabitModel _only(AppPayloadModel p) => p.habits.single;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Merge: per-day check-ins', () {
    const day = '2026-10-01';

    test('an un-check made later on another device propagates', () {
      final checkedHere = _payload([
        _habit('h', checkIns: {day: true}, changedAt: {day: _ms(1)}),
      ]);
      final uncheckedThere = _payload([
        _habit('h', changedAt: {day: _ms(5)}, modifiedMinute: 5),
      ], modifiedMinute: 5);

      final merged = mergePayloads(
        local: checkedHere,
        incoming: uncheckedThere,
      );
      expect(_only(merged).isCompletedOn(DateTime(2026, 10, 1)), isFalse);
      expect(_only(merged).checkInChangedAt[day], _ms(5));
    });

    test('a check made after an un-check wins', () {
      final unchecked = _payload([
        _habit('h', changedAt: {day: _ms(1)}),
      ]);
      final checkedLater = _payload([
        _habit('h', checkIns: {day: true}, changedAt: {day: _ms(2)}),
      ]);

      final merged = mergePayloads(local: unchecked, incoming: checkedLater);
      expect(_only(merged).checkIns[day], isTrue);
    });

    test('legacy check-ins without times are a union (nothing lost)', () {
      final a = _payload([
        _habit('h', checkIns: {'2026-10-01': true}),
      ]);
      final b = _payload([
        _habit('h', checkIns: {'2026-10-02': true}),
      ]);

      expect(
        _only(mergePayloads(local: a, incoming: b)).checkIns.keys.toSet(),
        {'2026-10-01', '2026-10-02'},
      );
    });
  });

  group('Merge: deletions', () {
    test('a deleted habit stays deleted on the other device', () {
      final stillHasIt = _payload([_habit('h')]);
      final deletedIt = _payload(
        const [],
        modifiedMinute: 10,
        deletedHabits: {'h': _at(10)},
      );

      final merged = mergePayloads(local: stillHasIt, incoming: deletedIt);
      expect(merged.habits, isEmpty);
      expect(merged.deletedHabits.keys, ['h']);
    });

    test('an edit made after the deletion keeps the habit', () {
      final editedLater = _payload([_habit('h', modifiedMinute: 20)]);
      final deletedEarlier = _payload(const [], deletedHabits: {'h': _at(10)});

      expect(
        mergePayloads(local: editedLater, incoming: deletedEarlier).habits,
        hasLength(1),
      );
    });

    test('deleted custom themes stay deleted', () {
      final theme = UserThemeModel.obsidianTwilight.copyWith(
        id: 'custom_1',
        isBuiltIn: false,
        lastModifiedAt: _at(0),
      );
      final merged = mergePayloads(
        local: _payload(const [], themes: [theme]),
        incoming: _payload(const [], deletedThemes: {'custom_1': _at(5)}),
      );
      expect(merged.userThemes.where((t) => t.id == 'custom_1'), isEmpty);
    });
  });

  group('Merge: algebra', () {
    final a = _payload(
      [
        _habit(
          'shared',
          checkIns: {'2026-10-01': true},
          changedAt: {'2026-10-01': _ms(1)},
        ),
        _habit('onlyA', title: 'A'),
      ],
      deletedHabits: {'gone': _at(3)},
    );
    final b = _payload([
      _habit(
        'shared',
        changedAt: {'2026-10-01': _ms(4)},
        checkIns: {'2026-10-02': true},
        modifiedMinute: 4,
      ),
      _habit('onlyB', title: 'B'),
      _habit('gone'),
    ], modifiedMinute: 4);

    Map<String, HabitModel> byId(AppPayloadModel p) => {
      for (final h in p.habits) h.id: h,
    };

    test('is commutative in content', () {
      final ab = mergePayloads(local: a, incoming: b);
      final ba = mergePayloads(local: b, incoming: a);
      expect(byId(ab), byId(ba));
      expect(ab.deletedHabits, ba.deletedHabits);
      expect(byId(ab).keys.toSet(), {'shared', 'onlyA', 'onlyB'});
    });

    test('is idempotent', () {
      final once = mergePayloads(local: a, incoming: b);
      final twice = mergePayloads(local: once, incoming: b);
      expect(byId(twice), byId(once));
    });
  });

  test('migrates v1 JSON to v2 without losing check-ins', () {
    final v1 = {
      'version': 1,
      'lastModifiedBy': 'old',
      'lastModifiedAt': _t0.toIso8601String(),
      'activeThemeId': UserThemeModel.defaultTheme.id,
      'userThemes': <dynamic>[],
      'habits': [
        {
          'id': 'h',
          'title': 'Old habit',
          'frequency': {'type': 'daily'},
          'createdAt': _t0.toIso8601String(),
          'checkIns': {'2026-10-01': true},
        },
      ],
    };

    final payload = AppPayloadModel.fromJson(v1);
    expect(payload.version, 2);
    expect(payload.deletedHabits, isEmpty);
    expect(payload.habits.single.checkIns, {'2026-10-01': true});
  });

  group('SyncEngine', () {
    Future<AppDataRepository> repoWith(AppPayloadModel payload) async {
      final storage = WebHabitStorage(InMemoryWebStore());
      await storage.savePayload(payload);
      return AppDataRepository(storage);
    }

    test('first sync uploads local data', () async {
      final repo = await repoWith(_payload([_habit('h')]));
      final cloud = _FakeCloud();

      final outcome = await SyncEngine.run(backend: cloud, repository: repo);

      expect(outcome.uploaded, isTrue);
      expect(outcome.localChanged, isFalse);
      expect(
        AppPayloadModel.fromRawJson(cloud.contents!).habits.single.id,
        'h',
      );
    });

    test(
      'merges the other device\'s changes, then uploads the union',
      () async {
        final repo = await repoWith(_payload([_habit('mine')]));
        final cloud = _FakeCloud(
          contents: _payload([_habit('theirs')]).toRawJson(),
        );

        final outcome = await SyncEngine.run(backend: cloud, repository: repo);

        expect(outcome.localChanged, isTrue);
        expect(repo.current!.habits.map((h) => h.id), ['mine', 'theirs']);
        final uploaded = AppPayloadModel.fromRawJson(cloud.contents!);
        expect(uploaded.habits.map((h) => h.id).toSet(), {'mine', 'theirs'});
      },
    );

    test('does nothing when already in sync', () async {
      final data = _payload([_habit('h')]);
      final repo = await repoWith(data);
      final cloud = _FakeCloud(contents: data.toRawJson());

      final outcome = await SyncEngine.run(backend: cloud, repository: repo);

      expect(outcome.uploaded, isFalse);
      expect(outcome.localChanged, isFalse);
      expect(cloud.uploads, 0);
    });

    test('leaves an unreadable cloud copy untouched', () async {
      final repo = await repoWith(_payload([_habit('h')]));
      final cloud = _FakeCloud(contents: '{not json');

      await expectLater(
        SyncEngine.run(backend: cloud, repository: repo),
        throwsA(isA<SyncRemoteUnreadableException>()),
      );
      expect(cloud.contents, '{not json');
      expect(repo.current!.habits.single.id, 'h');
    });

    test('refuses cloud data from a newer app version', () async {
      final repo = await repoWith(_payload([_habit('h')]));
      final newer =
          jsonDecode(_payload(const []).toRawJson()) as Map<String, dynamic>
            ..['version'] = AppPayloadModel.currentSchemaVersion + 1;
      final cloud = _FakeCloud(contents: jsonEncode(newer));

      await expectLater(
        SyncEngine.run(backend: cloud, repository: repo),
        throwsA(isA<SyncNewerVersionException>()),
      );
      expect(cloud.uploads, 0);
    });

    test('keeps a local edit made while the download was in flight', () async {
      final repo = await repoWith(_payload([_habit('a')]));
      final cloud = _FakeCloud(
        contents: _payload([_habit('remote')]).toRawJson(),
      )..downloadGate = Completer<void>();

      final syncing = SyncEngine.run(backend: cloud, repository: repo);
      await pumpEventQueue();
      await repo.update(
        (p) => p.copyWith(habits: [...p.habits, _habit('editedMeanwhile')]),
      );
      cloud.downloadGate!.complete();
      await syncing;

      expect(repo.current!.habits.map((h) => h.id).toSet(), {
        'a',
        'editedMeanwhile',
        'remote',
      });
    });

    test('two devices converge on deletions and un-checks', () async {
      const day = '2026-10-01';
      final start = _payload([
        _habit('keep', checkIns: {day: true}, changedAt: {day: _ms(0)}),
        _habit('drop'),
      ]);
      final deviceA = await repoWith(start);
      final deviceB = await repoWith(start);
      final cloud = _FakeCloud();

      await SyncEngine.run(backend: cloud, repository: deviceA);
      await SyncEngine.run(backend: cloud, repository: deviceB);

      // A deletes "drop"; B un-checks "keep" on the same day.
      await deviceA.update(
        (p) => p.copyWith(
          habits: p.habits.where((h) => h.id != 'drop').toList(),
          deletedHabits: {...p.deletedHabits, 'drop': DateTime.now()},
        ),
      );
      await deviceB.update(
        (p) => p.copyWith(
          habits: [
            for (final h in p.habits)
              h.id == 'keep' ? h.toggleCheckIn(DateTime(2026, 10, 1)) : h,
          ],
        ),
      );

      await SyncEngine.run(backend: cloud, repository: deviceA);
      await SyncEngine.run(backend: cloud, repository: deviceB);
      await SyncEngine.run(backend: cloud, repository: deviceA);

      for (final device in [deviceA, deviceB]) {
        final habits = device.current!.habits;
        expect(habits.map((h) => h.id), ['keep']);
        expect(habits.single.checkIns[day], isNull, reason: 'un-check synced');
      }
      expect(
        SyncEngine.sameContent(deviceA.current!, deviceB.current!),
        isTrue,
      );
    });
  });

  group('DriveAppDataClient', () {
    test(
      'creates the file in appDataFolder, then updates it in place',
      () async {
        final requests = <http.Request>[];
        var fileExists = false;
        final client = MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET' && request.url.path.endsWith('/files')) {
            return http.Response(
              jsonEncode({
                'files': fileExists
                    ? [
                        {'id': 'file_1'},
                      ]
                    : <Object>[],
              }),
              200,
            );
          }
          if (request.method == 'POST') {
            fileExists = true;
            return http.Response(jsonEncode({'id': 'file_1'}), 200);
          }
          return http.Response('{}', 200);
        });
        final drive = DriveAppDataClient(
          accessToken: () async => 'token',
          client: client,
        );

        await drive.upload('{"v":1}');
        await drive.upload('{"v":2}');

        final post = requests.firstWhere((r) => r.method == 'POST');
        expect(post.url.queryParameters['uploadType'], 'multipart');
        expect(post.body, contains('"appDataFolder"'));
        expect(post.headers['Authorization'], 'Bearer token');
        final patch = requests.firstWhere((r) => r.method == 'PATCH');
        expect(patch.url.path, endsWith('/files/file_1'));
        expect(patch.body, '{"v":2}');
      },
    );

    test('reports rejected credentials as an auth problem', () async {
      final drive = DriveAppDataClient(
        accessToken: () async => 'expired',
        client: MockClient((_) async => http.Response('nope', 401)),
      );
      await expectLater(drive.download(), throwsA(isA<SyncAuthException>()));
    });
  });

  group('SyncController', () {
    late _FakeCloud cloud;
    late WebHabitStorage storage;

    Future<ProviderContainer> container() async {
      storage = WebHabitStorage(InMemoryWebStore());
      await storage.savePayload(_payload([_habit('local')]));
      final c = ProviderContainer(
        overrides: [
          habitStorageProvider.overrideWithValue(storage),
          cloudBackendsProvider.overrideWithValue({
            CloudProvider.googleDrive: cloud,
          }),
        ],
      );
      addTearDown(c.dispose);
      await c.read(habitListProvider.future);
      return c;
    }

    test('connecting syncs immediately and refreshes habits', () async {
      cloud = _FakeCloud(contents: _payload([_habit('fromCloud')]).toRawJson());
      final c = await container();

      await c
          .read(syncControllerProvider.notifier)
          .connect(CloudProvider.googleDrive);
      await pumpEventQueue();

      final sync = c.read(syncControllerProvider);
      expect(sync.status, SyncStatus.idle);
      expect(sync.accountLabel, 'me@example.com');
      expect(sync.lastSyncedAt, isNotNull);
      final habits = await c.read(habitListProvider.future);
      expect(habits.map((h) => h.id).toSet(), {'local', 'fromCloud'});
    });

    test('a cancelled sign-in leaves sync off', () async {
      cloud = _FakeCloud()
        ..authError = const SyncAuthException('Sign-in was cancelled');
      final c = await container();

      await c
          .read(syncControllerProvider.notifier)
          .connect(CloudProvider.googleDrive);

      final sync = c.read(syncControllerProvider);
      expect(sync.isConnected, isFalse);
      expect(sync.message, 'Sign-in was cancelled');
    });

    test('turning sync off keeps local data', () async {
      cloud = _FakeCloud();
      final c = await container();
      final controller = c.read(syncControllerProvider.notifier);
      await controller.connect(CloudProvider.googleDrive);

      await controller.disconnect();

      expect(c.read(syncControllerProvider).isConnected, isFalse);
      expect((await c.read(habitListProvider.future)).single.id, 'local');
    });
  });
}
