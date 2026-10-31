import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// What Google Play reports about the installed app.
@immutable
class PlayUpdateInfo {
  final bool updateAvailable;

  /// An immediate update the user started earlier was interrupted and must be
  /// resumed.
  final bool inProgress;

  /// A flexible update has finished downloading and awaits installation.
  final bool downloaded;
  final bool immediateAllowed;
  final bool flexibleAllowed;

  /// Developer-assigned priority, 0 (default) to 5.
  final int priority;
  final int? versionCode;

  const PlayUpdateInfo({
    this.updateAvailable = false,
    this.inProgress = false,
    this.downloaded = false,
    this.immediateAllowed = false,
    this.flexibleAllowed = false,
    this.priority = 0,
    this.versionCode,
  });
}

enum PlayUpdateOutcome { accepted, declined, failed }

enum PlayDownloadStatus { downloading, downloaded, failed, other }

/// Thin seam over the Play In-App Updates API so the update logic can be
/// tested without Google Play.
abstract interface class PlayUpdateGateway {
  Future<PlayUpdateInfo> check();
  Future<PlayUpdateOutcome> startFlexible();
  Future<PlayUpdateOutcome> startImmediate();
  Future<void> completeFlexible();
  Stream<PlayDownloadStatus> get downloadStatus;
}

class InAppPlayUpdateGateway implements PlayUpdateGateway {
  const InAppPlayUpdateGateway();

  @override
  Future<PlayUpdateInfo> check() async {
    final info = await InAppUpdate.checkForUpdate();
    return PlayUpdateInfo(
      updateAvailable:
          info.updateAvailability == UpdateAvailability.updateAvailable,
      inProgress: info.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress,
      downloaded: info.installStatus == InstallStatus.downloaded,
      immediateAllowed: info.immediateUpdateAllowed,
      flexibleAllowed: info.flexibleUpdateAllowed,
      priority: info.updatePriority,
      versionCode: info.availableVersionCode,
    );
  }

  @override
  Future<PlayUpdateOutcome> startFlexible() async =>
      _outcome(await InAppUpdate.startFlexibleUpdate());

  @override
  Future<PlayUpdateOutcome> startImmediate() async =>
      _outcome(await InAppUpdate.performImmediateUpdate());

  @override
  Future<void> completeFlexible() => InAppUpdate.completeFlexibleUpdate();

  @override
  Stream<PlayDownloadStatus> get downloadStatus =>
      InAppUpdate.installUpdateListener.map(
        (status) => switch (status) {
          InstallStatus.pending ||
          InstallStatus.downloading => PlayDownloadStatus.downloading,
          InstallStatus.downloaded => PlayDownloadStatus.downloaded,
          InstallStatus.failed ||
          InstallStatus.canceled => PlayDownloadStatus.failed,
          _ => PlayDownloadStatus.other,
        },
      );

  PlayUpdateOutcome _outcome(AppUpdateResult result) => switch (result) {
        AppUpdateResult.success => PlayUpdateOutcome.accepted,
        AppUpdateResult.userDeniedUpdate => PlayUpdateOutcome.declined,
        AppUpdateResult.inAppUpdateFailed => PlayUpdateOutcome.failed,
      };
}
