import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/app_data_repository.dart';

/// The user's display name, stored in the app payload so it follows the user
/// to their other devices. Empty when not set.
class DisplayNameNotifier extends Notifier<String> {
  static const int maxLength = 40;

  late AppDataRepository _repository;
  late Future<void> _hydration;
  bool _disposed = false;

  @override
  String build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    _repository = ref.watch(appDataRepositoryProvider);
    _hydration = _hydrate();
    return _repository.current?.displayName ?? '';
  }

  Future<void> _hydrate() async {
    try {
      final snapshot = await _repository.load();
      if (!_disposed) state = snapshot.payload.displayName;
    } catch (_) {
      // Unreadable data is surfaced and recovered by the habits feature.
    }
  }

  Future<void> setDisplayName(String name) async {
    var trimmed = name.trim();
    if (trimmed.length > maxLength) trimmed = trimmed.substring(0, maxLength);
    // Let the stored value load first so it can't overwrite this edit.
    await _hydration;
    if (_disposed) return;
    state = trimmed;
    try {
      await _repository.update((p) => p.copyWith(displayName: trimmed));
    } catch (e) {
      debugPrint('DisplayNameNotifier: failed to persist display name: $e');
    }
  }
}

final displayNameProvider = NotifierProvider<DisplayNameNotifier, String>(
  DisplayNameNotifier.new,
);
