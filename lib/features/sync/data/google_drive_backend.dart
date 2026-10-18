import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'cloud_sync_backend.dart';
import 'drive_app_data_client.dart';

/// Syncs through the Google Drive App Data folder, authorized with Google
/// Sign-In (OAuth consent for `drive.appdata` only — no password, no account
/// with us).
class GoogleDriveBackend implements CloudSyncBackend {
  GoogleDriveBackend({GoogleSignIn? signIn})
    : _signIn = signIn ?? GoogleSignIn.instance;

  final GoogleSignIn _signIn;
  Future<void>? _initialized;
  GoogleSignInAccount? _account;

  late final DriveAppDataClient _drive = DriveAppDataClient(
    accessToken: _accessToken,
  );

  static const List<String> _scopes = [DriveAppDataClient.scope];

  @override
  CloudProvider get provider => CloudProvider.googleDrive;

  @override
  bool get isAvailable {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => SyncConfig.googleServerClientId.isNotEmpty,
      // Without an iOS client id (and its URL scheme in Info.plist) sign-in
      // can't complete, so don't offer Drive at all.
      TargetPlatform.iOS ||
      TargetPlatform.macOS => SyncConfig.googleClientId.isNotEmpty,
      _ => false,
    };
  }

  Future<void> _ensureInitialized() => _initialized ??= _signIn.initialize(
    clientId: SyncConfig.googleClientId.isEmpty
        ? null
        : SyncConfig.googleClientId,
    serverClientId: SyncConfig.googleServerClientId.isEmpty
        ? null
        : SyncConfig.googleServerClientId,
  );

  @override
  Future<String?> restoreSession() async {
    await _ensureInitialized();
    _account ??= await _signIn.attemptLightweightAuthentication();
    final account = _account;
    if (account == null) return null;
    final authorization = await account.authorizationClient
        .authorizationForScopes(_scopes);
    return authorization == null ? null : account.email;
  }

  @override
  Future<String> connect() async {
    await _ensureInitialized();
    try {
      final account = await _signIn.authenticate(scopeHint: _scopes);
      await account.authorizationClient.authorizeScopes(_scopes);
      _account = account;
      return account.email;
    } on GoogleSignInException catch (e) {
      throw SyncAuthException(
        e.code == GoogleSignInExceptionCode.canceled
            ? 'Sign-in was cancelled'
            : 'Google sign-in failed: ${e.description ?? e.code.name}',
      );
    }
  }

  @override
  Future<void> disconnect() async {
    await _ensureInitialized();
    _account = null;
    await _signIn.disconnect();
  }

  @override
  Future<String?> download() => _drive.download();

  @override
  Future<void> upload(String contents) => _drive.upload(contents);

  /// A token without prompting; sync never interrupts the user. If consent
  /// is missing the user reconnects from the Sync tab.
  Future<String> _accessToken() async {
    await _ensureInitialized();
    _account ??= await _signIn.attemptLightweightAuthentication();
    final account = _account;
    if (account == null) {
      throw const SyncAuthException('Not signed in to Google');
    }
    final authorization = await account.authorizationClient
        .authorizationForScopes(_scopes);
    if (authorization == null) {
      throw const SyncAuthException('Google Drive access needs to be granted');
    }
    return authorization.accessToken;
  }
}
