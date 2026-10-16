import 'package:flutter/foundation.dart';

import '../../../core/data/app_data_repository.dart';
import '../../themes/data/models/app_payload_model.dart';
import '../data/cloud_sync_backend.dart';
import 'merge_engine.dart';

/// What one sync pass did.
@immutable
class SyncOutcome {
  /// Local data changed (merged-in changes from another device).
  final bool localChanged;

  /// The cloud copy was created or updated.
  final bool uploaded;

  const SyncOutcome({required this.localChanged, required this.uploaded});
}

/// The cloud copy was written by a newer version of the app.
class SyncNewerVersionException implements Exception {
  const SyncNewerVersionException();
}

/// The cloud copy exists but can't be read. It's left untouched.
class SyncRemoteUnreadableException implements Exception {
  final Object cause;

  const SyncRemoteUnreadableException(this.cause);
}

/// One sync pass: download → merge into local → upload the merged result.
///
/// The merge is applied with [AppDataRepository.replaceWith], i.e. against
/// whatever local data exists at that moment, so edits made while the
/// download was in flight are kept. Nothing is written when nothing changed.
abstract final class SyncEngine {
  static Future<SyncOutcome> run({
    required CloudSyncBackend backend,
    required AppDataRepository repository,
  }) async {
    await repository.load();

    final raw = await backend.download();
    AppPayloadModel? remote;
    if (raw != null) {
      try {
        remote = AppPayloadModel.fromRawJson(raw);
      } on UnsupportedPayloadVersionException {
        throw const SyncNewerVersionException();
      } catch (e) {
        throw SyncRemoteUnreadableException(e);
      }
    }

    var localChanged = false;
    if (remote != null) {
      final incoming = remote;
      await repository.replaceWith((current) {
        final merged = mergePayloads(local: current, incoming: incoming);
        localChanged = !sameContent(merged, current);
        return localChanged ? merged : current;
      });
    }

    final current = repository.current!;
    final needsUpload = remote == null || !sameContent(current, remote);
    if (needsUpload) {
      await backend.upload(current.toRawJson());
    }
    return SyncOutcome(localChanged: localChanged, uploaded: needsUpload);
  }

  /// Equal user data, ignoring who/when last wrote it and the schema stamp.
  @visibleForTesting
  static bool sameContent(AppPayloadModel a, AppPayloadModel b) {
    AppPayloadModel normalize(AppPayloadModel p) =>
        p.copyWith(version: 0, lastModifiedBy: '');
    return normalize(a) == normalize(b);
  }
}
