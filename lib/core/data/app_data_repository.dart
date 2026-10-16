import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/habits/data/storage/habit_storage.dart';
import '../../features/habits/data/storage/habit_storage_factory.dart';
import '../../features/themes/data/models/app_payload_model.dart';
import 'device_identity.dart';

/// Injects the platform-appropriate [HabitStorage] instance.
final habitStorageProvider = Provider<HabitStorage>((ref) {
  return HabitStorageFactory.createStorage();
});

/// Source of this installation's id, written into `lastModifiedBy`.
final deviceIdentityProvider = Provider<DeviceIdentity>(
  (ref) => const DeviceIdentity(),
);

/// Single owner of the persisted [AppPayloadModel].
final appDataRepositoryProvider = Provider<AppDataRepository>((ref) {
  return AppDataRepository(
    ref.watch(habitStorageProvider),
    deviceIdResolver: ref.watch(deviceIdentityProvider).getOrCreate,
  );
});

/// This installation's id (see [DeviceIdentity]).
final deviceIdProvider = FutureProvider<String>(
  (ref) => ref.watch(appDataRepositoryProvider).deviceId,
);

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
  AppDataRepository(this._storage, {this._deviceIdResolver});

  final HabitStorage _storage;
  final Future<String> Function()? _deviceIdResolver;
  Future<String>? _deviceId;

  /// This installation's id, resolved once.
  Future<String> get deviceId => _deviceId ??=
      _deviceIdResolver?.call() ?? Future.value(DeviceIdentity.fallbackId);

  AppPayloadModel? _current;
  Future<AppDataSnapshot>? _loadFuture;
  bool _loaded = false;
  bool _writesBlocked = false;
  final StreamController<void> _localChanges =
      StreamController<void>.broadcast();

  /// Fires after each local edit is applied (not for [replace], so applying
  /// a sync result doesn't trigger another sync).
  Stream<void> get localChanges => _localChanges.stream;

  bool _hasPendingWrite = false;
  Future<void>? _activeDrain;
  final Set<Future<void>> _pendingUpdates = {};

  /// The in-memory payload, or `null` before a successful [load].
  AppPayloadModel? get current => _current;

  /// Loads the payload once; concurrent callers share the result. Once
  /// loaded, later calls return the current in-memory payload (so notifiers
  /// rebuilt after a sync see the synced data). A failed load is not cached,
  /// so calling [load] again retries.
  Future<AppDataSnapshot> load() {
    final current = _current;
    if (_loaded && current != null) {
      return Future.value(AppDataSnapshot(payload: current, isFirstRun: false));
    }
    return _loadFuture ??= _load();
  }

  /// Replaces the whole payload and persists it. Notifiers should be rebuilt
  /// afterwards to pick it up. Doesn't fire [localChanges].
  Future<void> replace(AppPayloadModel payload) => replaceWith((_) => payload);

  /// Like [update], but for applying external data such as a sync merge:
  /// doesn't fire [localChanges], and if [transform] returns the current
  /// payload unchanged (identical), nothing is written.
  Future<void> replaceWith(
    AppPayloadModel Function(AppPayloadModel current) transform,
  ) =>
      _track(_update(transform, notify: false));

  Future<AppDataSnapshot> _load() async {
    try {
      final stored = await _storage.loadPayload();
      _current =
          stored ?? AppPayloadModel.initial(lastModifiedBy: await deviceId);
      _writesBlocked = false;
      _loaded = true;
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
  ) =>
      _track(_update(transform, notify: true));

  Future<void> _track(Future<void> pending) {
    _pendingUpdates.add(pending);
    pending.whenComplete(() => _pendingUpdates.remove(pending)).ignore();
    return pending;
  }

  Future<void> _update(
    AppPayloadModel Function(AppPayloadModel current) transform, {
    required bool notify,
  }) async {
    await load();
    if (_writesBlocked) {
      throw StateError('Writes are blocked until stored data is recovered');
    }
    final modifiedBy = await deviceId;

    final next = transform(_current!);
    if (identical(next, _current)) return;
    _current = next.copyWith(
      version: AppPayloadModel.currentSchemaVersion,
      lastModifiedBy: modifiedBy,
      lastModifiedAt: DateTime.now(),
    );
    final write = _scheduleWrite();
    if (notify) _localChanges.add(null);
    return write;
  }

  /// Abandons unreadable stored data and starts from an empty payload.
  /// Storage keeps its own copy of the damaged record (see [HabitStorage]).
  Future<void> discardStoredData() async {
    _writesBlocked = false;
    _loaded = true;
    _current = AppPayloadModel.initial(lastModifiedBy: await deviceId);
    _loadFuture = Future.value(
      AppDataSnapshot(payload: _current!, isFirstRun: false),
    );
    await _scheduleWrite();
  }

  /// Completes when every update started so far has been written (or has
  /// failed). Errors are not rethrown; callers of [update] receive them.
  Future<void> flush() async {
    while (_pendingUpdates.isNotEmpty || _activeDrain != null) {
      await Future.wait([
        for (final pending in [..._pendingUpdates])
          pending.catchError((Object _) {}),
        if (_activeDrain != null) _activeDrain!.catchError((Object _) {}),
      ]);
    }
  }

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
