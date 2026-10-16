import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cloud_sync_backend.dart';
import 'google_drive_backend.dart';
import 'icloud_backend_stub.dart' if (dart.library.io) 'icloud_backend.dart';

/// A backend that is never available (wrong platform for this build).
class UnavailableBackend implements CloudSyncBackend {
  const UnavailableBackend(this.provider);

  @override
  final CloudProvider provider;

  @override
  bool get isAvailable => false;

  @override
  Future<String?> restoreSession() async => null;

  @override
  Future<String> connect() =>
      throw SyncAuthException('${provider.label} is not available here');

  @override
  Future<void> disconnect() async {}

  @override
  Future<String?> download() =>
      throw SyncTransportException('${provider.label} is not available here');

  @override
  Future<void> upload(String contents) =>
      throw SyncTransportException('${provider.label} is not available here');
}

/// Every backend this build knows, keyed by provider. Overridden in tests.
final cloudBackendsProvider = Provider<Map<CloudProvider, CloudSyncBackend>>(
  (ref) => {
    CloudProvider.googleDrive: GoogleDriveBackend(),
    CloudProvider.iCloud: createICloudBackend(),
  },
);
