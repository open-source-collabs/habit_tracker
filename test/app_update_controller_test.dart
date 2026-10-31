import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/app_update/data/app_update_preferences.dart';
import 'package:habit_tracker/features/app_update/data/play_update_gateway.dart';
import 'package:habit_tracker/features/app_update/presentation/providers/app_update_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGateway implements PlayUpdateGateway {
  PlayUpdateInfo info = const PlayUpdateInfo();
  PlayUpdateOutcome flexibleOutcome = PlayUpdateOutcome.accepted;
  PlayUpdateOutcome immediateOutcome = PlayUpdateOutcome.accepted;
  Object? checkError;
  int checks = 0;
  int immediateStarts = 0;
  int installs = 0;
  // ignore: close_sinks
  final downloads = StreamController<PlayDownloadStatus>.broadcast();

  @override
  Future<PlayUpdateInfo> check() async {
    checks++;
    if (checkError != null) throw checkError!;
    return info;
  }

  @override
  Future<PlayUpdateOutcome> startFlexible() async => flexibleOutcome;

  @override
  Future<PlayUpdateOutcome> startImmediate() async {
    immediateStarts++;
    return immediateOutcome;
  }

  @override
  Future<void> completeFlexible() async => installs++;

  @override
  Stream<PlayDownloadStatus> get downloadStatus => downloads.stream;
}

void main() {
  late _FakeGateway gateway;
  late DateTime now;

  AppUpdateController build({bool supported = true}) => AppUpdateController(
        gateway: gateway,
        prefs: const AppUpdatePreferences(),
        isSupported: supported,
        now: () => now,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    gateway = _FakeGateway();
    now = DateTime.utc(2026, 1, 1);
  });

  test('unsupported platforms never talk to Play', () async {
    final controller = build(supported: false);
    expect(await controller.check(manual: true), AppUpdateStatus.unsupported);
    expect(gateway.checks, 0);
  });

  test('reports up to date when Play has nothing newer', () async {
    final controller = build();
    expect(await controller.check(), AppUpdateStatus.upToDate);
  });

  test('offers a flexible update and reaches ready-to-install', () async {
    gateway.info = const PlayUpdateInfo(
      updateAvailable: true,
      flexibleAllowed: true,
      versionCode: 7,
    );
    final controller = build();
    expect(await controller.check(), AppUpdateStatus.available);
    expect(controller.state.immediate, isFalse);

    await controller.startUpdate();
    expect(controller.state.status, AppUpdateStatus.readyToInstall);

    await controller.installDownloaded();
    expect(gateway.installs, 1);
  });

  test('high-priority releases use the immediate flow', () async {
    gateway.info = const PlayUpdateInfo(
      updateAvailable: true,
      immediateAllowed: true,
      flexibleAllowed: true,
      priority: 5,
      versionCode: 8,
    );
    final controller = build();
    await controller.check();
    expect(controller.state.immediate, isTrue);

    await controller.startUpdate();
    expect(gateway.immediateStarts, 1);
  });

  test('automatic checks are rate-limited, manual ones are not', () async {
    final controller = build();
    await controller.check();
    await controller.check();
    expect(gateway.checks, 1);

    await controller.check(manual: true);
    expect(gateway.checks, 2);

    now = now.add(AppUpdateController.checkInterval);
    await controller.check();
    expect(gateway.checks, 3);
  });

  test('a declined version is not offered again automatically', () async {
    gateway.info = const PlayUpdateInfo(
      updateAvailable: true,
      flexibleAllowed: true,
      versionCode: 9,
    );
    final controller = build();
    await controller.check();
    await controller.dismiss();
    expect(controller.state.status, AppUpdateStatus.idle);

    now = now.add(const Duration(days: 2));
    expect(await controller.check(), AppUpdateStatus.idle);
    expect(await controller.check(manual: true), AppUpdateStatus.available);
  });

  test('a failed check surfaces as failed instead of throwing', () async {
    gateway.checkError = Exception('not installed from Play');
    final controller = build();
    expect(await controller.check(manual: true), AppUpdateStatus.failed);
  });

  test('a finished background download becomes ready to install', () async {
    final controller = build();
    gateway.downloads.add(PlayDownloadStatus.downloaded);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.status, AppUpdateStatus.readyToInstall);
  });
}
