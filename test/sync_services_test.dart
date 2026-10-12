import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:habit_tracker/data/sync/drive_sync_service.dart';
import 'package:habit_tracker/data/sync/icloud_sync_service.dart';
import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/themes/data/models/app_payload_model.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';

void main() {
  group('ICloudSyncService Tests', () {
    late Directory tempDir;
    late ICloudSyncService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('icloud_test_');
      service = ICloudSyncService(directory: tempDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('isAvailable returns true when directory exists', () async {
      expect(await service.isAvailable(), isTrue);
    });

    test('syncs local payload when no remote file exists', () async {
      final habit = HabitModel(
        id: 'habit_1',
        title: 'Morning Yoga',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 10, 1),
        checkIns: const {'2026-10-10': true},
      );

      final localPayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'device_a',
        lastModifiedAt: DateTime(2026, 10, 10),
        activeThemeId: UserThemeModel.obsidianTwilight.id,
        userThemes: UserThemeModel.builtInPresets,
        habits: [habit],
      );

      final result = await service.sync(localPayload: localPayload);
      expect(result.habits.length, 1);
      expect(service.status, ICloudSyncStatus.synced);

      final file = File('${tempDir.path}/${ICloudSyncService.syncFileName}');
      expect(await file.exists(), isTrue);

      final remotePayload = await service.fetchRemotePayload();
      expect(remotePayload, isNotNull);
      expect(remotePayload!.habits.first.id, 'habit_1');
    });

    test('merges local and remote payloads conflict-free', () async {
      final remoteHabit = HabitModel(
        id: 'habit_1',
        title: 'Morning Yoga',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 10, 1),
        checkIns: const {'2026-10-09': true},
      );

      final remotePayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'macbook',
        lastModifiedAt: DateTime(2026, 10, 9),
        activeThemeId: UserThemeModel.obsidianTwilight.id,
        userThemes: UserThemeModel.builtInPresets,
        habits: [remoteHabit],
      );

      // Pre-populate remote file
      await service.uploadPayload(remotePayload);

      final localHabit = HabitModel(
        id: 'habit_1',
        title: 'Morning Yoga & Breathwork',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 10, 1),
        lastModifiedAt: DateTime(2026, 10, 10, 10, 0),
        checkIns: const {'2026-10-10': true},
      );

      final localPayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'iphone',
        lastModifiedAt: DateTime(2026, 10, 10, 10, 0),
        activeThemeId: UserThemeModel.obsidianTwilight.id,
        userThemes: UserThemeModel.builtInPresets,
        habits: [localHabit],
      );

      final mergedResult = await service.sync(localPayload: localPayload);

      expect(mergedResult.habits.length, 1);
      final mergedHabit = mergedResult.habits.first;
      expect(mergedHabit.title, 'Morning Yoga & Breathwork');
      // Both days preserved additively
      expect(mergedHabit.checkIns['2026-10-09'], isTrue);
      expect(mergedHabit.checkIns['2026-10-10'], isTrue);
    });
  });

  group('DriveSyncService Tests', () {
    test('findAppDataFileId finds existing file', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/files') &&
            request.url.queryParameters['spaces'] == 'appDataFolder') {
          expect(request.headers['Authorization'], 'Bearer test_token');
          return http.Response(
            jsonEncode({
              'files': [
                {'id': 'file_123', 'name': 'app_data.json'}
              ]
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = DriveSyncService(client: mockClient);
      final fileId = await service.findAppDataFileId(accessToken: 'test_token');
      expect(fileId, 'file_123');
    });

    test('downloadPayload retrieves AppPayloadModel from Drive', () async {
      final samplePayload = AppPayloadModel.initial(lastModifiedBy: 'drive_source');

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/files/file_123') &&
            request.url.queryParameters['alt'] == 'media') {
          return http.Response(samplePayload.toRawJson(), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = DriveSyncService(client: mockClient);
      final payload = await service.downloadPayload(
        accessToken: 'test_token',
        fileId: 'file_123',
      );

      expect(payload, isNotNull);
      expect(payload!.lastModifiedBy, 'drive_source');
    });

    test('uploadNewPayload creates multipart file in appDataFolder', () async {
      final samplePayload = AppPayloadModel.initial(lastModifiedBy: 'device_upload');

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/upload/drive/v3/files') &&
            request.method == 'POST') {
          expect(request.headers['Authorization'], 'Bearer test_token');
          expect(request.body.contains('appDataFolder'), isTrue);
          expect(request.body.contains('device_upload'), isTrue);
          return http.Response(jsonEncode({'id': 'new_file_999'}), 200);
        }
        return http.Response('Error', 500);
      });

      final service = DriveSyncService(client: mockClient);
      final fileId = await service.uploadNewPayload(
        accessToken: 'test_token',
        payload: samplePayload,
      );

      expect(fileId, 'new_file_999');
    });

    test('two-way Drive sync performs conflict-free merge and update', () async {
      final remoteHabit = HabitModel(
        id: 'habit_read',
        title: 'Read Books',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 10, 1),
        checkIns: const {'2026-10-05': true},
      );

      final remotePayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'web_client',
        lastModifiedAt: DateTime(2026, 10, 5),
        activeThemeId: UserThemeModel.obsidianTwilight.id,
        userThemes: UserThemeModel.builtInPresets,
        habits: [remoteHabit],
      );

      String? patchedBody;

      final mockClient = MockClient((request) async {
        // Query appDataFolder
        if (request.method == 'GET' && request.url.queryParameters['spaces'] == 'appDataFolder') {
          return http.Response(
            jsonEncode({
              'files': [{'id': 'drive_file_abc', 'name': 'app_data.json'}]
            }),
            200,
          );
        }

        // Download media
        if (request.method == 'GET' && request.url.path.contains('/files/drive_file_abc')) {
          return http.Response(remotePayload.toRawJson(), 200);
        }

        // Patch file
        if (request.method == 'PATCH' && request.url.path.contains('/files/drive_file_abc')) {
          patchedBody = request.body;
          return http.Response('{}', 200);
        }

        return http.Response('Bad Request', 400);
      });

      final service = DriveSyncService(client: mockClient);

      final localHabit = HabitModel(
        id: 'habit_read',
        title: 'Read Daily',
        frequency: const HabitFrequency.daily(),
        createdAt: DateTime(2026, 10, 1),
        checkIns: const {'2026-10-06': true},
        lastModifiedAt: DateTime(2026, 10, 6),
      );

      final localPayload = AppPayloadModel(
        version: 1,
        lastModifiedBy: 'android_client',
        lastModifiedAt: DateTime(2026, 10, 6),
        activeThemeId: UserThemeModel.obsidianTwilight.id,
        userThemes: UserThemeModel.builtInPresets,
        habits: [localHabit],
      );

      final merged = await service.sync(
        accessToken: 'test_token',
        localPayload: localPayload,
      );

      expect(service.status, DriveSyncStatus.synced);
      expect(merged.habits.length, 1);
      final habit = merged.habits.first;
      expect(habit.title, 'Read Daily');
      expect(habit.checkIns['2026-10-05'], isTrue);
      expect(habit.checkIns['2026-10-06'], isTrue);

      expect(patchedBody, isNotNull);
      final patchedPayload = AppPayloadModel.fromRawJson(patchedBody!);
      expect(patchedPayload.habits.first.checkIns.length, 2);
    });
  });
}
