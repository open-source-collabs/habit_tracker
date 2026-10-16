import 'dart:convert';

import 'package:http/http.dart' as http;

import 'cloud_sync_backend.dart';

/// Minimal Google Drive v3 client confined to the hidden, app-scoped
/// `appDataFolder` (scope `drive.appdata`): the app can only see the files it
/// created there, never the rest of the user's Drive.
class DriveAppDataClient {
  static const String scope = 'https://www.googleapis.com/auth/drive.appdata';

  static const String _api = 'https://www.googleapis.com/drive/v3';
  static const String _uploadApi = 'https://www.googleapis.com/upload/drive/v3';
  static const String _boundary = 'habit_tracker_sync_boundary';

  DriveAppDataClient({
    required this._accessToken,
    http.Client? client,
    this.fileName = SyncConfig.syncFileName,
  }) : _client = client ?? http.Client();

  final Future<String> Function() _accessToken;
  final http.Client _client;
  final String fileName;

  /// Id of the sync file, or null if it doesn't exist yet.
  Future<String?> findFileId() async {
    final query = Uri.encodeQueryComponent(
      "name = '$fileName' and trashed = false",
    );
    final response = await _send(
      (headers) => _client.get(
        Uri.parse(
          '$_api/files?spaces=appDataFolder&q=$query'
          '&fields=files(id,modifiedTime)&orderBy=modifiedTime desc',
        ),
        headers: headers,
      ),
    );
    final files =
        (jsonDecode(response.body) as Map<String, dynamic>)['files'] as List?;
    if (files == null || files.isEmpty) return null;
    return (files.first as Map<String, dynamic>)['id'] as String?;
  }

  Future<String?> download() async {
    final fileId = await findFileId();
    if (fileId == null) return null;
    final response = await _send(
      (headers) => _client.get(
        Uri.parse('$_api/files/$fileId?alt=media'),
        headers: headers,
      ),
    );
    return response.body.trim().isEmpty ? null : response.body;
  }

  Future<void> upload(String contents) async {
    final fileId = await findFileId();
    if (fileId != null) {
      await _send(
        (headers) => _client.patch(
          Uri.parse('$_uploadApi/files/$fileId?uploadType=media'),
          headers: {...headers, 'Content-Type': 'application/json'},
          body: contents,
        ),
      );
      return;
    }

    final metadata = jsonEncode({
      'name': fileName,
      'parents': ['appDataFolder'],
      'mimeType': 'application/json',
    });
    final body =
        '--$_boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '$metadata\r\n'
        '--$_boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '$contents\r\n'
        '--$_boundary--\r\n';
    await _send(
      (headers) => _client.post(
        Uri.parse('$_uploadApi/files?uploadType=multipart'),
        headers: {
          ...headers,
          'Content-Type': 'multipart/related; boundary=$_boundary',
        },
        body: body,
      ),
    );
  }

  Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    final token = await _accessToken();
    final http.Response response;
    try {
      response = await request({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
    } catch (e) {
      throw SyncTransportException('Could not reach Google Drive: $e');
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw SyncAuthException(
        'Google Drive access was denied (${response.statusCode})',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SyncTransportException(
        'Google Drive returned ${response.statusCode}',
      );
    }
    return response;
  }
}
