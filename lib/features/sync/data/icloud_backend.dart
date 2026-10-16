import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'cloud_sync_backend.dart';

/// Syncs through the app's iCloud Documents container, using the iCloud
/// account the device is already signed in to (no sign-in inside the app).
class ICloudBackend implements CloudSyncBackend {
  ICloudBackend({this.containerId = SyncConfig.iCloudContainerId});

  final String containerId;

  static const Duration _transferTimeout = Duration(seconds: 60);

  @override
  CloudProvider get provider => CloudProvider.iCloud;

  @override
  bool get isAvailable =>
      !kIsWeb &&
      containerId.isNotEmpty &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  Future<String?> restoreSession() async {
    try {
      await ICloudStorage.gather(containerId: containerId);
      return 'iCloud';
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> connect() async {
    try {
      await ICloudStorage.gather(containerId: containerId);
      return 'iCloud';
    } on PlatformException catch (e) {
      throw SyncAuthException(_describe(e));
    }
  }

  /// Nothing to revoke: the device's iCloud account stays signed in. The
  /// sync file is kept so other devices continue to work.
  @override
  Future<void> disconnect() async {}

  @override
  Future<String?> download() async {
    try {
      final files = await ICloudStorage.gather(containerId: containerId);
      if (!files.any((f) => f.relativePath == SyncConfig.syncFileName)) {
        return null;
      }
      final local = await _tempFile('download');
      final done = Completer<void>();
      await ICloudStorage.download(
        containerId: containerId,
        relativePath: SyncConfig.syncFileName,
        destinationFilePath: local.path,
        onProgress: (progress) => _completeWhenDone(progress, done),
      );
      await done.future.timeout(_transferTimeout);
      final contents = await local.readAsString();
      await local.delete();
      return contents.trim().isEmpty ? null : contents;
    } on PlatformException catch (e) {
      throw _translate(e);
    } on TimeoutException {
      throw const SyncTransportException('iCloud download timed out');
    }
  }

  @override
  Future<void> upload(String contents) async {
    try {
      final local = await _tempFile('upload');
      await local.writeAsString(contents, flush: true);
      final done = Completer<void>();
      await ICloudStorage.upload(
        containerId: containerId,
        filePath: local.path,
        destinationRelativePath: SyncConfig.syncFileName,
        onProgress: (progress) => _completeWhenDone(progress, done),
      );
      await done.future.timeout(_transferTimeout);
    } on PlatformException catch (e) {
      throw _translate(e);
    } on TimeoutException {
      throw const SyncTransportException('iCloud upload timed out');
    }
  }

  /// The plugin's futures complete when a transfer *starts*; completion is
  /// signalled by the progress stream closing.
  void _completeWhenDone(Stream<double> progress, Completer<void> done) {
    progress.listen(
      (_) {},
      onDone: () {
        if (!done.isCompleted) done.complete();
      },
      onError: (Object e) {
        if (!done.isCompleted) done.completeError(e);
      },
      cancelOnError: true,
    );
  }

  Future<File> _tempFile(String purpose) async {
    final dir = await getTemporaryDirectory();
    return File('${dir.path}/icloud_${purpose}_${SyncConfig.syncFileName}');
  }

  Exception _translate(PlatformException e) =>
      e.code == PlatformExceptionCode.iCloudConnectionOrPermission
      ? SyncAuthException(_describe(e))
      : SyncTransportException(_describe(e));

  String _describe(PlatformException e) =>
      e.code == PlatformExceptionCode.iCloudConnectionOrPermission
      ? 'Sign in to iCloud on this device and allow iCloud Drive for '
            'this app'
      : 'iCloud error: ${e.message ?? e.code}';
}

CloudSyncBackend createICloudBackend() => ICloudBackend();
