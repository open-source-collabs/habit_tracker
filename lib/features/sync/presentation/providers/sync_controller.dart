import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/app_data_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../settings/presentation/providers/profile_provider.dart';
import '../../../themes/presentation/providers/theme_provider.dart';
import '../../data/cloud_backends.dart';
import '../../data/cloud_sync_backend.dart';
import '../../data/sync_preferences.dart';
import '../../domain/sync_engine.dart';

enum SyncStatus {
  /// Sync isn't set up on this device (the default; the app is offline-first).
  off,
  idle,
  syncing,

  /// Connected, but the provider needs the user to sign in or re-consent.
  needsSignIn,
  error,
}

@immutable
class SyncState {
  final SyncStatus status;
  final CloudProvider? provider;
  final String? accountLabel;
  final DateTime? lastSyncedAt;

  /// User-facing explanation for [SyncStatus.error] / [SyncStatus.needsSignIn].
  final String? message;

  const SyncState({
    this.status = SyncStatus.off,
    this.provider,
    this.accountLabel,
    this.lastSyncedAt,
    this.message,
  });

  bool get isConnected => provider != null;

  SyncState copyWith({
    SyncStatus? status,
    String? accountLabel,
    DateTime? lastSyncedAt,
    String? message,
    bool clearMessage = false,
  }) {
    return SyncState(
      status: status ?? this.status,
      provider: provider,
      accountLabel: accountLabel ?? this.accountLabel,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

/// Owns this device's sync connection and runs sync passes.
///
/// Sync is opt-in and never blocks the app: it runs after launch, when the
/// app returns to the foreground, a few seconds after local edits, and on
/// "Sync now". Failures are reported in [SyncState]; local data is never
/// put at risk by them.
class SyncController extends Notifier<SyncState> {
  /// Quiet period after the last local edit before syncing it.
  static const Duration editDebounce = Duration(seconds: 5);

  Timer? _debounce;
  Future<void>? _inFlight;
  bool _rerunRequested = false;

  @override
  SyncState build() {
    final repository = ref.watch(appDataRepositoryProvider);
    final changes = repository.localChanges.listen((_) => _scheduleSoon());
    AppLifecycleListener? lifecycle;
    try {
      lifecycle = AppLifecycleListener(onResume: () => unawaited(syncNow()));
    } catch (_) {
      // No widgets binding (pure unit tests): no resume events to follow.
    }
    ref.onDispose(() {
      _debounce?.cancel();
      changes.cancel();
      lifecycle?.dispose();
    });

    Future.microtask(_restore);
    return const SyncState();
  }

  CloudSyncBackend? _backend(CloudProvider? provider) =>
      provider == null ? null : ref.read(cloudBackendsProvider)[provider];

  /// Providers that can be offered on this device.
  List<CloudProvider> get availableProviders => [
    for (final entry in ref.read(cloudBackendsProvider).entries)
      if (entry.value.isAvailable) entry.key,
  ];

  Future<void> _restore() async {
    final stored = await ref.read(syncPreferencesProvider).read();
    final backend = _backend(stored.provider);
    if (stored.provider == null || backend == null || !backend.isAvailable) {
      return;
    }
    state = SyncState(
      status: SyncStatus.idle,
      provider: stored.provider,
      accountLabel: stored.accountLabel,
      lastSyncedAt: stored.lastSyncedAt,
    );
    try {
      final account = await backend.restoreSession();
      if (account == null) {
        state = state.copyWith(
          status: SyncStatus.needsSignIn,
          message: 'Reconnect ${stored.provider!.label} to keep syncing.',
        );
        return;
      }
      state = state.copyWith(accountLabel: account);
    } catch (e) {
      debugPrint('SyncController: session not restored: $e');
    }
    await syncNow();
  }

  /// Connects [provider] interactively, then syncs right away.
  Future<void> connect(CloudProvider provider) async {
    final backend = _backend(provider);
    if (backend == null || !backend.isAvailable) return;
    try {
      final account = await backend.connect();
      await ref.read(syncPreferencesProvider).saveConnection(provider, account);
      state = SyncState(
        status: SyncStatus.idle,
        provider: provider,
        accountLabel: account,
      );
    } on SyncAuthException catch (e) {
      state = SyncState(
        status: state.isConnected ? SyncStatus.needsSignIn : SyncStatus.off,
        provider: state.provider,
        accountLabel: state.accountLabel,
        lastSyncedAt: state.lastSyncedAt,
        message: e.message,
      );
      return;
    }
    await syncNow();
  }

  /// Stops syncing on this device. Local data and the cloud copy are kept.
  Future<void> disconnect() async {
    _debounce?.cancel();
    final backend = _backend(state.provider);
    try {
      await backend?.disconnect();
    } catch (e) {
      debugPrint('SyncController: disconnect: $e');
    }
    await ref.read(syncPreferencesProvider).clear();
    state = const SyncState();
  }

  /// Runs a sync pass now. Concurrent requests collapse into one follow-up.
  Future<void> syncNow() {
    if (!state.isConnected || state.status == SyncStatus.needsSignIn) {
      return Future.value();
    }
    if (_inFlight != null) {
      _rerunRequested = true;
      return _inFlight!;
    }
    return _inFlight = _runLoop().whenComplete(() => _inFlight = null);
  }

  void _scheduleSoon() {
    if (!state.isConnected) return;
    _debounce?.cancel();
    _debounce = Timer(editDebounce, () => unawaited(syncNow()));
  }

  Future<void> _runLoop() async {
    do {
      _rerunRequested = false;
      await _runOnce();
    } while (_rerunRequested && state.status == SyncStatus.idle);
  }

  Future<void> _runOnce() async {
    final backend = _backend(state.provider);
    if (backend == null) return;
    state = state.copyWith(status: SyncStatus.syncing, clearMessage: true);

    try {
      final repository = ref.read(appDataRepositoryProvider);
      final outcome = await SyncEngine.run(
        backend: backend,
        repository: repository,
      );
      if (outcome.localChanged) _reloadFrom(repository);

      final now = DateTime.now();
      await ref.read(syncPreferencesProvider).saveLastSynced(now);
      state = state.copyWith(status: SyncStatus.idle, lastSyncedAt: now);
    } on SyncAuthException catch (e) {
      state = state.copyWith(
        status: SyncStatus.needsSignIn,
        message: e.message,
      );
    } on SyncNewerVersionException {
      state = state.copyWith(
        status: SyncStatus.error,
        message:
            'Your cloud data was saved by a newer version of the app. '
            'Update the app on this device to keep syncing.',
      );
    } on SyncRemoteUnreadableException {
      state = state.copyWith(
        status: SyncStatus.error,
        message:
            'The copy in your cloud can\'t be read, so it was left '
            'untouched. Your data on this device is safe.',
      );
    } on SyncTransportException catch (e) {
      state = state.copyWith(status: SyncStatus.error, message: e.message);
    } catch (e) {
      debugPrint('SyncController: sync failed: $e');
      state = state.copyWith(
        status: SyncStatus.error,
        message: 'Sync failed. Your data on this device is safe.',
      );
    }
  }

  /// Rebuilds the features that hold their own copy of payload data, and
  /// brings reminders in line with the merged habits.
  void _reloadFrom(AppDataRepository repository) {
    ref.invalidate(habitListProvider);
    ref.invalidate(themeProvider);
    ref.invalidate(displayNameProvider);
    final habits = repository.current?.habits;
    if (habits != null) {
      unawaited(ref.read(notificationServiceProvider).rescheduleAll(habits));
    }
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);
