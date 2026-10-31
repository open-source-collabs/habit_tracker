import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_error_log.dart';
import '../../data/app_update_preferences.dart';
import '../../data/play_update_gateway.dart';

enum AppUpdateStatus {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  readyToInstall,

  /// Not an Android install from Google Play (iOS, web, desktop).
  unsupported,
  failed,
}

@immutable
class AppUpdateState {
  final AppUpdateStatus status;
  final int? versionCode;

  /// Play marked this release high priority: it is applied with Play's
  /// blocking full-screen flow instead of a background download.
  final bool immediate;

  const AppUpdateState({
    this.status = AppUpdateStatus.idle,
    this.versionCode,
    this.immediate = false,
  });
}

/// Drives Google Play in-app updates: a flexible (background) download by
/// default, an immediate one only for high-priority releases.
class AppUpdateController extends StateNotifier<AppUpdateState> {
  /// Release priority (set when publishing on Play) at or above which the
  /// update is mandatory.
  static const int immediatePriority = 4;

  /// Minimum gap between automatic checks.
  static const Duration checkInterval = Duration(hours: 24);

  final PlayUpdateGateway gateway;
  final AppUpdatePreferences prefs;
  final bool isSupported;
  final DateTime Function() _now;
  StreamSubscription<PlayDownloadStatus>? _downloads;

  AppUpdateController({
    required this.gateway,
    required this.prefs,
    required this.isSupported,
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        super(
          AppUpdateState(
            status: isSupported
                ? AppUpdateStatus.idle
                : AppUpdateStatus.unsupported,
          ),
        ) {
    if (isSupported) _listenForDownloads();
  }

  void _listenForDownloads() {
    _downloads = gateway.downloadStatus.listen(
      (status) {
        switch (status) {
          case PlayDownloadStatus.downloading:
            _set(AppUpdateStatus.downloading);
          case PlayDownloadStatus.downloaded:
            _set(AppUpdateStatus.readyToInstall);
          case PlayDownloadStatus.failed:
            _set(AppUpdateStatus.failed);
          case PlayDownloadStatus.other:
            break;
        }
      },
      // No Play Store (emulator, sideload): checks fail on their own.
      onError: (_) {},
    );
  }

  void _set(
    AppUpdateStatus status, {
    int? versionCode,
    bool? immediate,
  }) {
    if (!mounted) return;
    state = AppUpdateState(
      status: status,
      versionCode: versionCode ?? state.versionCode,
      immediate: immediate ?? state.immediate,
    );
  }

  /// Asks Play whether a newer version exists.
  ///
  /// Automatic checks (`manual: false`) are rate-limited and stay quiet about
  /// a version the user already declined; a manual check always answers.
  Future<AppUpdateStatus> check({bool manual = false}) async {
    if (!isSupported) return AppUpdateStatus.unsupported;
    switch (state.status) {
      case AppUpdateStatus.checking ||
          AppUpdateStatus.downloading ||
          AppUpdateStatus.readyToInstall:
        return state.status;
      default:
    }
    if (!manual && !await _checkDue()) return state.status;

    _set(AppUpdateStatus.checking);
    try {
      final info = await gateway.check();
      await prefs.saveLastChecked(_now());

      if (info.downloaded) {
        _set(AppUpdateStatus.readyToInstall, versionCode: info.versionCode);
      } else if (info.inProgress) {
        // An immediate update was interrupted; Play requires resuming it.
        _set(
          AppUpdateStatus.available,
          versionCode: info.versionCode,
          immediate: true,
        );
      } else if (!info.updateAvailable) {
        _set(AppUpdateStatus.upToDate);
      } else {
        final immediate =
            info.priority >= immediatePriority && info.immediateAllowed;
        if (!immediate && !info.flexibleAllowed) {
          _set(AppUpdateStatus.upToDate);
        } else if (!manual &&
            !immediate &&
            await prefs.dismissedVersion() == info.versionCode) {
          _set(AppUpdateStatus.idle);
        } else {
          _set(
            AppUpdateStatus.available,
            versionCode: info.versionCode,
            immediate: immediate,
          );
        }
      }
    } catch (error, stack) {
      AppErrorLog.record(error, stack, context: 'update check');
      _set(AppUpdateStatus.failed);
    }
    return state.status;
  }

  Future<bool> _checkDue() async {
    final last = await prefs.lastChecked();
    return last == null || _now().toUtc().difference(last) >= checkInterval;
  }

  /// Starts the update the user agreed to.
  Future<void> startUpdate() async {
    if (state.status != AppUpdateStatus.available) return;
    final versionCode = state.versionCode;
    try {
      if (state.immediate) {
        // Play shows its own blocking screen and restarts the app when done.
        final outcome = await gateway.startImmediate();
        _set(
          outcome == PlayUpdateOutcome.failed
              ? AppUpdateStatus.failed
              : AppUpdateStatus.idle,
        );
        return;
      }
      _set(AppUpdateStatus.downloading);
      final outcome = await gateway.startFlexible();
      switch (outcome) {
        case PlayUpdateOutcome.accepted:
          _set(AppUpdateStatus.readyToInstall);
        case PlayUpdateOutcome.declined:
          await prefs.saveDismissedVersion(versionCode);
          _set(AppUpdateStatus.idle);
        case PlayUpdateOutcome.failed:
          _set(AppUpdateStatus.failed);
      }
    } catch (error, stack) {
      AppErrorLog.record(error, stack, context: 'update start');
      _set(AppUpdateStatus.failed);
    }
  }

  /// The user chose "Later" for the offered version.
  Future<void> dismiss() async {
    if (state.status != AppUpdateStatus.available) return;
    await prefs.saveDismissedVersion(state.versionCode);
    _set(AppUpdateStatus.idle);
  }

  /// Installs a finished download; Play restarts the app.
  Future<void> installDownloaded() async {
    if (state.status != AppUpdateStatus.readyToInstall) return;
    try {
      await gateway.completeFlexible();
    } catch (error, stack) {
      AppErrorLog.record(error, stack, context: 'update install');
      _set(AppUpdateStatus.failed);
    }
  }

  @override
  void dispose() {
    _downloads?.cancel();
    super.dispose();
  }
}

final playUpdateGatewayProvider = Provider<PlayUpdateGateway>(
  (ref) => const InAppPlayUpdateGateway(),
);

final appUpdatePreferencesProvider = Provider<AppUpdatePreferences>(
  (ref) => const AppUpdatePreferences(),
);

final appUpdateControllerProvider =
    StateNotifierProvider<AppUpdateController, AppUpdateState>(
  (ref) => AppUpdateController(
    gateway: ref.watch(playUpdateGatewayProvider),
    prefs: ref.watch(appUpdatePreferencesProvider),
    isSupported: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
  ),
);
