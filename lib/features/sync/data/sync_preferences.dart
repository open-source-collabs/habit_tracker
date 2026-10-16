import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_sync_backend.dart';

/// Per-device sync settings. Deliberately not part of the synced payload:
/// each device chooses for itself whether and where to sync.
@immutable
class StoredSyncSettings {
  final CloudProvider? provider;
  final String? accountLabel;
  final DateTime? lastSyncedAt;

  const StoredSyncSettings({
    this.provider,
    this.accountLabel,
    this.lastSyncedAt,
  });
}

class SyncPreferences {
  static const String _providerKey = 'habit_tracker_sync_provider_v1';
  static const String _accountKey = 'habit_tracker_sync_account_v1';
  static const String _lastSyncedKey = 'habit_tracker_sync_last_synced_v1';

  const SyncPreferences();

  Future<StoredSyncSettings> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSynced = prefs.getString(_lastSyncedKey);
      return StoredSyncSettings(
        provider: CloudProvider.fromName(prefs.getString(_providerKey)),
        accountLabel: prefs.getString(_accountKey),
        lastSyncedAt: lastSynced == null ? null : DateTime.tryParse(lastSynced),
      );
    } catch (_) {
      return const StoredSyncSettings();
    }
  }

  Future<void> saveConnection(
    CloudProvider provider,
    String accountLabel,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, provider.name);
    await prefs.setString(_accountKey, accountLabel);
  }

  Future<void> saveLastSynced(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncedKey, time.toUtc().toIso8601String());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_providerKey);
    await prefs.remove(_accountKey);
    await prefs.remove(_lastSyncedKey);
  }
}

final syncPreferencesProvider = Provider<SyncPreferences>(
  (ref) => const SyncPreferences(),
);
