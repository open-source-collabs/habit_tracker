import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../../themes/data/models/app_payload_model.dart';
import 'habit_storage.dart';

/// Platform storage implementation for Mobile and Desktop platforms using `dart:io`.
/// Implements atomic writes via temporary files and maintains rolling snapshots
/// (`backup_1.json`, `backup_2.json`, `backup_3.json`) to prevent data loss or corruption.
class IoHabitStorage implements HabitStorage {
  static const String primaryFileName = 'app_data.json';
  static const String backup1FileName = 'backup_1.json';
  static const String backup2FileName = 'backup_2.json';
  static const String backup3FileName = 'backup_3.json';

  final Directory? _injectedDirectory;
  final Future<Directory> Function()? _directoryResolver;

  IoHabitStorage({
    Directory? directory,
    this._directoryResolver,
  })  : _injectedDirectory = directory;

  Future<Directory> _getDirectory() async {
    if (_injectedDirectory != null) {
      if (!await _injectedDirectory.exists()) {
        await _injectedDirectory.create(recursive: true);
      }
      return _injectedDirectory;
    }

    if (_directoryResolver != null) {
      final dir = await _directoryResolver();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }

    return _resolveDefaultDirectory();
  }

  Future<Directory> _resolveDefaultDirectory() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final target = Directory('${docDir.path}/habit_tracker_data');
      if (!await target.exists()) {
        await target.create(recursive: true);
      }
      return target;
    } catch (_) {
      // Graceful fallback for test or mock environments
      String basePath = './habit_tracker_data';

      if (Platform.isWindows) {
        final appData =
            Platform.environment['APPDATA'] ?? Platform.environment['USERPROFILE'];
        if (appData != null) {
          basePath = '$appData/HabitTracker';
        }
      } else if (Platform.isLinux || Platform.isMacOS) {
        final home = Platform.environment['HOME'];
        if (home != null) {
          basePath = '$home/.habit_tracker';
        }
      }

      final dir = Directory(basePath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
  }

  static const String corruptCopyFileName = 'app_data.corrupt.json';

  @override
  Future<AppPayloadModel?> loadPayload() async {
    final dir = await _getDirectory();
    final primaryFile = File('${dir.path}/$primaryFileName');

    var foundData = false;
    Object? lastError;

    if (await primaryFile.exists()) {
      try {
        final content = await primaryFile.readAsString();
        if (content.trim().isNotEmpty) {
          foundData = true;
          return AppPayloadModel.fromRawJson(content);
        }
      } catch (e) {
        // Primary file corrupt; attempt recovery from backups
        lastError = e;
      }
    }

    final backupNames = [backup1FileName, backup2FileName, backup3FileName];
    for (final name in backupNames) {
      final file = File('${dir.path}/$name');
      if (!await file.exists()) continue;
      try {
        final content = await file.readAsString();
        if (content.trim().isEmpty) continue;
        foundData = true;
        final payload = AppPayloadModel.fromRawJson(content);
        await _preserveCorruptPrimary(dir);
        await _safeCopy(file, primaryFile);
        return payload;
      } catch (e) {
        // Continue scanning older backups
        lastError = e;
      }
    }

    if (foundData || lastError != null) {
      await _preserveCorruptPrimary(dir);
      throw CorruptPayloadException(lastError);
    }
    return null;
  }

  /// Keeps one copy of an unreadable primary file so it is never lost to
  /// backup rotation. An existing copy is not overwritten.
  Future<void> _preserveCorruptPrimary(Directory dir) async {
    try {
      final primaryFile = File('${dir.path}/$primaryFileName');
      final corruptCopy = File('${dir.path}/$corruptCopyFileName');
      if (await primaryFile.exists() && !await corruptCopy.exists()) {
        await primaryFile.copy(corruptCopy.path);
      }
    } catch (_) {
      // Best effort: failing to keep a copy must not block recovery.
    }
  }

  @override
  Future<void> savePayload(AppPayloadModel payload) async {
    final dir = await _getDirectory();
    final primaryFile = File('${dir.path}/$primaryFileName');
    final backup1File = File('${dir.path}/$backup1FileName');
    final backup2File = File('${dir.path}/$backup2FileName');
    final backup3File = File('${dir.path}/$backup3FileName');

    final tempFile = File(
      '${dir.path}/$primaryFileName.tmp_${DateTime.now().microsecondsSinceEpoch}',
    );

    try {
      final jsonString = payload.toRawJson(pretty: true);
      await tempFile.writeAsString(jsonString, flush: true);

      final written = await tempFile.readAsString();
      if (written.isEmpty) {
        throw const FileSystemException('Temporary file was written empty');
      }

      if (await primaryFile.exists() && (await primaryFile.length()) > 0) {
        if (await backup2File.exists()) {
          await _safeCopy(backup2File, backup3File);
        }
        if (await backup1File.exists()) {
          await _safeCopy(backup1File, backup2File);
        }
        await _safeCopy(primaryFile, backup1File);
      }

      await _safeReplace(tempFile, primaryFile);
    } catch (e) {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  @override
  Future<List<String>> listBackups() async {
    final dir = await _getDirectory();
    final backupNames = [backup1FileName, backup2FileName, backup3FileName];
    final existing = <String>[];

    for (final name in backupNames) {
      final file = File('${dir.path}/$name');
      if (await file.exists()) {
        existing.add(name);
      }
    }

    return existing;
  }

  @override
  Future<AppPayloadModel?> restoreBackup(String backupName) async {
    final dir = await _getDirectory();
    final backupFile = File('${dir.path}/$backupName');

    if (!await backupFile.exists()) {
      return null;
    }

    final content = await backupFile.readAsString();
    final payload = AppPayloadModel.fromRawJson(content);

    final primaryFile = File('${dir.path}/$primaryFileName');
    await _safeCopy(backupFile, primaryFile);

    return payload;
  }

  @override
  Future<void> clear() async {
    final dir = await _getDirectory();
    final allFiles = [
      primaryFileName,
      backup1FileName,
      backup2FileName,
      backup3FileName,
    ];

    for (final name in allFiles) {
      final file = File('${dir.path}/$name');
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> _safeCopy(File source, File destination) async {
    if (await destination.exists()) {
      await destination.delete();
    }
    await source.copy(destination.path);
  }

  Future<void> _safeReplace(File source, File destination) async {
    if (await destination.exists()) {
      await destination.delete();
    }
    try {
      await source.rename(destination.path);
    } catch (_) {
      await source.copy(destination.path);
      if (await source.exists()) {
        await source.delete();
      }
    }
  }
}

HabitStorage createPlatformHabitStorage() => IoHabitStorage();
