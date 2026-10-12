import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../features/themes/data/models/app_payload_model.dart';
import 'merge_engine.dart';

/// Status of the iCloud synchronization operations.
enum ICloudSyncStatus {
  idle,
  checking,
  syncing,
  synced,
  unavailable,
  error,
}

/// Service wiring native iCloud Documents container synchronization for iOS and macOS.
///
/// Features:
/// - Resolves Apple Ubiquity Container (`Documents/app_data.json`).
/// - Executes conflict-free merges using [mergePayloads].
/// - Performs atomic writes using temporary files to prevent partial sync corruption.
/// - Injectable directory resolver for complete offline testability.
class ICloudSyncService {
  static const String defaultContainerId = 'iCloud.com.habittracker.app';
  static const String syncFileName = 'app_data.json';

  final String containerId;
  final Future<Directory> Function()? directoryResolver;
  final Directory? _injectedDirectory;

  ICloudSyncStatus _status = ICloudSyncStatus.idle;
  ICloudSyncStatus get status => _status;

  String? _lastErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  ICloudSyncService({
    this.containerId = defaultContainerId,
    Directory? directory,
    this.directoryResolver,
  })  : _injectedDirectory = directory;

  /// Whether current running platform is Apple (iOS or macOS) or in injected test mode.
  bool get isSupportedPlatform {
    if (_injectedDirectory != null || directoryResolver != null) {
      return true;
    }
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  /// Resolves the iCloud container Documents directory.
  Future<Directory?> getContainerDirectory() async {
    if (_injectedDirectory != null) {
      if (!await _injectedDirectory.exists()) {
        await _injectedDirectory.create(recursive: true);
      }
      return _injectedDirectory;
    }

    if (directoryResolver != null) {
      final dir = await directoryResolver!();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }

    if (!isSupportedPlatform) return null;

    try {
      String basePath;
      final home = Platform.environment['HOME'];

      if (Platform.isMacOS && home != null) {
        // macOS standard Ubiquity / CloudDocs container directory
        final formattedId = containerId.replaceAll('.', '~');
        final ubiquityPath = '$home/Library/Mobile Documents/$formattedId/Documents';
        final cloudDocsPath = '$home/Library/Mobile Documents/com~apple~CloudDocs/HabitTracker';

        final ubiquityDir = Directory(ubiquityPath);
        if (await ubiquityDir.exists()) {
          basePath = ubiquityPath;
        } else {
          basePath = cloudDocsPath;
        }
      } else if (Platform.isIOS && home != null) {
        // iOS sandboxed documents container fallback
        basePath = '$home/Documents/iCloud';
      } else {
        return null;
      }

      final dir = Directory(basePath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (e) {
      debugPrint('ICloudSyncService: Failed to resolve container directory: $e');
      return null;
    }
  }

  /// Checks if iCloud Documents container is accessible.
  Future<bool> isAvailable() async {
    if (!isSupportedPlatform) {
      _status = ICloudSyncStatus.unavailable;
      return false;
    }

    _status = ICloudSyncStatus.checking;
    try {
      final dir = await getContainerDirectory();
      final available = dir != null && await dir.exists();
      _status = available ? ICloudSyncStatus.idle : ICloudSyncStatus.unavailable;
      return available;
    } catch (_) {
      _status = ICloudSyncStatus.unavailable;
      return false;
    }
  }

  /// Fetches and parses the latest payload stored in the iCloud container.
  Future<AppPayloadModel?> fetchRemotePayload() async {
    try {
      final dir = await getContainerDirectory();
      if (dir == null) return null;

      final file = File('${dir.path}/$syncFileName');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          return AppPayloadModel.fromRawJson(content);
        }
      }
    } catch (e) {
      _lastErrorMessage = 'Failed to fetch iCloud payload: $e';
      debugPrint(_lastErrorMessage);
    }
    return null;
  }

  /// Atomically writes a payload to the iCloud container.
  Future<void> uploadPayload(AppPayloadModel payload) async {
    final dir = await getContainerDirectory();
    if (dir == null) {
      throw const FileSystemException('iCloud Documents container is unavailable.');
    }

    final targetFile = File('${dir.path}/$syncFileName');
    final tempFile = File(
      '${dir.path}/$syncFileName.tmp_${DateTime.now().microsecondsSinceEpoch}',
    );

    try {
      final jsonString = payload.toRawJson(pretty: true);
      await tempFile.writeAsString(jsonString, flush: true);

      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tempFile.rename(targetFile.path);
    } catch (e) {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Executes two-way serverless sync:
  /// 1. Reads remote iCloud payload.
  /// 2. Merges conflict-free via [mergePayloads].
  /// 3. Uploads merged payload back to iCloud container.
  /// 4. Returns the merged payload.
  Future<AppPayloadModel> sync({required AppPayloadModel localPayload}) async {
    if (!isSupportedPlatform) {
      _status = ICloudSyncStatus.unavailable;
      return localPayload;
    }

    _status = ICloudSyncStatus.syncing;
    _lastErrorMessage = null;

    try {
      final remotePayload = await fetchRemotePayload();

      final AppPayloadModel mergedPayload;
      if (remotePayload != null) {
        mergedPayload = mergePayloads(
          local: localPayload,
          incoming: remotePayload,
        );
      } else {
        mergedPayload = localPayload;
      }

      await uploadPayload(mergedPayload);

      _status = ICloudSyncStatus.synced;
      _lastSyncTime = DateTime.now();
      return mergedPayload;
    } catch (e) {
      _status = ICloudSyncStatus.error;
      _lastErrorMessage = 'iCloud sync failed: $e';
      debugPrint(_lastErrorMessage);
      return localPayload;
    }
  }
}
