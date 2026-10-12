import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../features/themes/data/models/app_payload_model.dart';
import 'merge_engine.dart';

/// Status of the Google Drive synchronization operations.
enum DriveSyncStatus {
  idle,
  searching,
  syncing,
  synced,
  error,
}

/// Service wiring Google Drive v3 REST API scoped strictly to `drive.appdata`
/// for Android, Windows, Linux, and Web.
///
/// Scopes:
/// - strictly `https://www.googleapis.com/auth/drive.appdata`
///
/// Features:
/// - Confines all file operations exclusively to Google Drive's hidden `appDataFolder`.
/// - Executes conflict-free merges using [mergePayloads].
/// - Works cross-platform across Android, Windows, Linux, and Web using [http.Client].
/// - Injectable client for offline unit testing without real network requests.
class DriveSyncService {
  /// Strict Google Drive OAuth2 scope for private Application Data Folder.
  static const String driveAppDataScope =
      'https://www.googleapis.com/auth/drive.appdata';

  static const String syncFileName = 'app_data.json';
  static const String _driveApiBase = 'https://www.googleapis.com/drive/v3';
  static const String _uploadApiBase =
      'https://www.googleapis.com/upload/drive/v3';

  final http.Client _client;

  DriveSyncStatus _status = DriveSyncStatus.idle;
  DriveSyncStatus get status => _status;

  String? _lastErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  DriveSyncService({http.Client? client}) : _client = client ?? http.Client();

  /// Headers with OAuth2 Bearer authorization and JSON content type.
  Map<String, String> _buildHeaders(String accessToken,
      {String contentType = 'application/json'}) {
    return {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': contentType,
      'Accept': 'application/json',
    };
  }

  /// Searches for `app_data.json` located strictly inside Google Drive `appDataFolder`.
  Future<String?> findAppDataFileId({required String accessToken}) async {
    final uri = Uri.parse(
      '$_driveApiBase/files?spaces=appDataFolder&q=name%3D\'$syncFileName\'+and+trashed%3Dfalse&fields=files(id,name,modifiedTime)',
    );

    final response = await _client.get(
      uri,
      headers: _buildHeaders(accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to query appDataFolder (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final files = decoded['files'] as List<dynamic>?;
    if (files != null && files.isNotEmpty) {
      final first = files.first as Map<String, dynamic>;
      return first['id'] as String?;
    }

    return null;
  }

  /// Downloads and parses the [AppPayloadModel] file from `appDataFolder`.
  Future<AppPayloadModel?> downloadPayload({
    required String accessToken,
    required String fileId,
  }) async {
    final uri = Uri.parse('$_driveApiBase/files/$fileId?alt=media');
    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to download payload ($fileId): ${response.statusCode}',
      );
    }

    if (response.body.trim().isEmpty) return null;
    return AppPayloadModel.fromRawJson(response.body);
  }

  /// Creates a new `app_data.json` strictly inside `appDataFolder` using multipart upload.
  Future<String> uploadNewPayload({
    required String accessToken,
    required AppPayloadModel payload,
  }) async {
    final uri = Uri.parse('$_uploadApiBase/files?uploadType=multipart');
    const boundary = 'HABIT_TRACKER_SYNC_BOUNDARY';

    final metadata = jsonEncode({
      'name': syncFileName,
      'parents': ['appDataFolder'],
      'mimeType': 'application/json',
    });
    final mediaContent = payload.toRawJson(pretty: true);

    final bodyBuffer = StringBuffer();
    bodyBuffer.write('--$boundary\r\n');
    bodyBuffer.write('Content-Type: application/json; charset=UTF-8\r\n\r\n');
    bodyBuffer.write('$metadata\r\n');
    bodyBuffer.write('--$boundary\r\n');
    bodyBuffer.write('Content-Type: application/json; charset=UTF-8\r\n\r\n');
    bodyBuffer.write('$mediaContent\r\n');
    bodyBuffer.write('--$boundary--\r\n');

    final response = await _client.post(
      uri,
      headers: _buildHeaders(
        accessToken,
        contentType: 'multipart/related; boundary=$boundary',
      ),
      body: bodyBuffer.toString(),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to upload new payload (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['id'] as String;
  }

  /// Updates existing `app_data.json` file in `appDataFolder` with the merged payload.
  Future<void> updateExistingPayload({
    required String accessToken,
    required String fileId,
    required AppPayloadModel payload,
  }) async {
    final uri = Uri.parse('$_uploadApiBase/files/$fileId?uploadType=media');
    final response = await _client.patch(
      uri,
      headers: _buildHeaders(accessToken, contentType: 'application/json'),
      body: payload.toRawJson(pretty: true),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update existing payload ($fileId): ${response.statusCode}',
      );
    }
  }

  /// Executes two-way serverless sync with Google Drive appDataFolder:
  /// 1. Finds `app_data.json` inside private `appDataFolder`.
  /// 2. Downloads and parses incoming remote payload if available.
  /// 3. Performs conflict-free merge via [mergePayloads].
  /// 4. Uploads or patches the merged result in `appDataFolder`.
  /// 5. Returns the authoritative merged payload.
  Future<AppPayloadModel> sync({
    required String accessToken,
    required AppPayloadModel localPayload,
  }) async {
    _status = DriveSyncStatus.syncing;
    _lastErrorMessage = null;

    try {
      final existingFileId = await findAppDataFileId(accessToken: accessToken);

      final AppPayloadModel mergedPayload;
      if (existingFileId != null) {
        final remotePayload = await downloadPayload(
          accessToken: accessToken,
          fileId: existingFileId,
        );

        if (remotePayload != null) {
          mergedPayload = mergePayloads(
            local: localPayload,
            incoming: remotePayload,
          );
        } else {
          mergedPayload = localPayload;
        }

        await updateExistingPayload(
          accessToken: accessToken,
          fileId: existingFileId,
          payload: mergedPayload,
        );
      } else {
        mergedPayload = localPayload;
        await uploadNewPayload(
          accessToken: accessToken,
          payload: mergedPayload,
        );
      }

      _status = DriveSyncStatus.synced;
      _lastSyncTime = DateTime.now();
      return mergedPayload;
    } catch (e) {
      _status = DriveSyncStatus.error;
      _lastErrorMessage = 'Google Drive sync failed: $e';
      debugPrint(_lastErrorMessage);
      return localPayload;
    }
  }
}
