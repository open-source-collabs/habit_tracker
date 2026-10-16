import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Stable, random identifier for this installation, written into
/// `lastModifiedBy` so synced payloads record which device changed them.
///
/// Deliberately device-local (never synced) and not derived from any
/// hardware or account identifier.
class DeviceIdentity {
  static const String prefsKey = 'habit_tracker_device_id_v1';
  static const String fallbackId = 'local_device';

  const DeviceIdentity();

  /// Returns the stored id, creating one on first use. Falls back to
  /// [fallbackId] if local preferences are unavailable.
  Future<String> getOrCreate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(prefsKey);
      if (existing != null && existing.isNotEmpty) return existing;

      final created = generateId();
      await prefs.setString(prefsKey, created);
      return created;
    } catch (_) {
      return fallbackId;
    }
  }

  /// A random RFC 4122 version-4 UUID.
  static String generateId([Random? random]) {
    final rng = random ?? Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
