import 'cloud_backends.dart';
import 'cloud_sync_backend.dart';

/// Web build: iCloud Documents needs the native iOS/macOS plugin.
CloudSyncBackend createICloudBackend() =>
    const UnavailableBackend(CloudProvider.iCloud);
