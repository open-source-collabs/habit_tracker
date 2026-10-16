import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/habits/data/storage/habit_storage.dart';
import '../../features/habits/data/storage/habit_storage_factory.dart';
import '../../features/themes/data/models/app_payload_model.dart';

/// Injects the platform-appropriate [HabitStorage] instance.
final habitStorageProvider = Provider<HabitStorage>((ref) {
  return HabitStorageFactory.createStorage();
});

/// Single owner of the persisted [AppPayloadModel].
final appDataRepositoryProvider = Provider<AppDataRepository>((ref) {
  return AppDataRepository(ref.watch(habitStorageProvider));
});

/// Result of the initial load.
@immutable
class AppDataSnapshot {
  final AppPayloadModel payload;

  /// True when storage held no data at all, i.e. the app has never saved.
  final bool isFirstRun;

  const AppDataSnapshot({required this.payload, required this.isFirstRun});
}

/// The only writer of the persisted payload. Habits and themes each update
/// their own slice through [update], so neither feature has to rebuild the
/// whole payload from the other's state.
///
/// Guarantees:
/// - Writes are serialized and coalesced: a burst of updates results in
///   sequential saves of the latest state, never concurrent backup rotation.
/// - After a failed load (e.g. [CorruptPayloadException]) every write is
///   refused, so damaged data and its backups are never overwritten. Writes
///   resume only after a successful [load] or an explicit [discardStoredData].
class AppDataRepository {
  AppDataRepository(this._storage, {this.deviceId = 'local_device'});

  final HabitStorage _storage;
  final String deviceId;

  AppPayloadModel? _current;
  Future<AppDataSnapshot>? _loadFuture;
  bool _writesBlocked = false;

  bool _hasPendingWrite = false;
  Future<void>? _activeDrain;

  /// The in-memory payload, or `null` before a successful [load].
  AppPayloadModel? get current => _current;

  /// Loads the payload once; concurrent and later callers share the result.
  /// A failed load is not cached, so calling [load] again retries.
  Future<AppDataSnapshot> load() => _loadFuture ??= _load();

  Future<AppDataSnapshot> _load() async {
    try {
      final stored = await _storage.loadPayload();
      _current = stored ?? AppPayloadModel.initial(lastModifiedBy: deviceId);
      _writesBlocked = false;
      return AppDataSnapshot(payload: _current!, isFirstRun: stored == null);
    } catch (_) {
      _writesBlocked = true;
      _loadFuture = null;
      rethrow;
    }
  }

  /// Applies [transform] to the current payload and persists the result.
  ///
  /// The in-memory payload changes immediately; the returned future completes
  /// once the write (and any writes queued behind it) has finished.
  Future<void> update(
    AppPayloadModel Function(AppPayloadModel current) transform,
  ) async {
    await load();
    if (_writesBlocked) {
      throw StateError('Writes are blocked until stored data is recovered');
    }

    _current = transform(_current!).copyWith(
      version: AppPayloadModel.currentSchemaVersion,
      lastModifiedBy: deviceId,
      lastModifiedAt: DateTime.now(),
    );
    return _scheduleWrite();
  }

  /// Abandons unreadable stored data and starts from an empty payload.
  /// Storage keeps its own copy of the damaged record (see [HabitStorage]).
  Future<void> discardStoredData() async {
    _writesBlocked = false;
    _current = AppPayloadModel.initial(lastModifiedBy: deviceId);
    _loadFuture = Future.value(
      AppDataSnapshot(payload: _current!, isFirstRun: false),
    );
    await _scheduleWrite();
  }

  /// Completes when every queued write has finished.
  Future<void> flush() => _activeDrain ?? Future.value();

  Future<void> _scheduleWrite() {
    _hasPendingWrite = true;
    return _activeDrain ??= _drainWrites();
  }

  Future<void> _drainWrites() async {
    Object? lastError;
    StackTrace? lastStackTrace;
    try {
      while (_hasPendingWrite) {
        _hasPendingWrite = false;
        try {
          await _storage.savePayload(_current!);
          lastError = null;
          lastStackTrace = null;
        } catch (e, st) {
          lastError = e;
          lastStackTrace = st;
        }
      }
    } finally {
      _activeDrain = null;
    }
    if (lastError != null) {
      Error.throwWithStackTrace(lastError, lastStackTrace!);
    }
  }
}
