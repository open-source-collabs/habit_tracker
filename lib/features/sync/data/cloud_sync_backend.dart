/// The cloud storage a user can sync through. Both are the user's own
/// storage; the app has no server.
enum CloudProvider {
  /// Hidden, app-scoped App Data folder in the user's Google Drive.
  googleDrive('Google Drive'),

  /// The app's iCloud Documents container in the user's iCloud Drive.
  iCloud('iCloud');

  const CloudProvider(this.label);

  final String label;

  static CloudProvider? fromName(String? name) =>
      CloudProvider.values.where((p) => p.name == name).firstOrNull;
}

/// Transport for the single sync file. Implementations only move bytes;
/// merging lives in the sync engine.
abstract interface class CloudSyncBackend {
  CloudProvider get provider;

  /// Whether this build and platform can use the backend at all (correct OS
  /// and the required build-time configuration present).
  bool get isAvailable;

  /// Silently restores a previous connection. Returns an account label, or
  /// null when the user needs to connect interactively.
  Future<String?> restoreSession();

  /// Interactive connect: sign-in and consent where needed. Returns an
  /// account label. Throws [SyncAuthException] if the user cancels.
  Future<String> connect();

  Future<void> disconnect();

  /// Contents of the sync file, or null when none has been written yet.
  Future<String?> download();

  /// Creates or replaces the sync file.
  Future<void> upload(String contents);
}

/// The user must (re)connect before syncing: not signed in, consent
/// revoked, or token expired beyond silent refresh.
class SyncAuthException implements Exception {
  final String message;

  const SyncAuthException(this.message);

  @override
  String toString() => 'SyncAuthException: $message';
}

/// The cloud provider could not be reached or rejected the request.
class SyncTransportException implements Exception {
  final String message;

  const SyncTransportException(this.message);

  @override
  String toString() => 'SyncTransportException: $message';
}

/// Build-time configuration, passed with `--dart-define` so no project
/// identifiers are committed. See docs/SYNC_SETUP.md.
abstract final class SyncConfig {
  /// OAuth client id of the *web* application in the Google Cloud project
  /// (required by Google Sign-In on Android, optional elsewhere).
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// Platform OAuth client id (iOS/macOS); may also be set in Info.plist.
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
  );

  /// iCloud container, e.g. `iCloud.co.trackfree.solforge`.
  static const String iCloudContainerId = String.fromEnvironment(
    'ICLOUD_CONTAINER_ID',
  );

  /// Name of the sync file in the user's cloud storage.
  static const String syncFileName = 'habit_tracker_sync.json';
}
