import 'package:flutter/foundation.dart';

/// Recent uncaught errors, kept in memory only (nothing leaves the device).
/// Users can copy it from Settings to include in a bug report.
abstract final class AppErrorLog {
  static const int capacity = 50;

  static final List<String> _entries = [];

  static List<String> get entries => List.unmodifiable(_entries);

  static void record(Object error, StackTrace? stack, {String? context}) {
    final buffer = StringBuffer()
      ..write(DateTime.now().toIso8601String())
      ..write(context == null ? '' : ' [$context]')
      ..write(' $error');
    if (stack != null) {
      // The top frames are enough to locate a problem.
      final frames = stack.toString().split('\n').take(8).join('\n');
      buffer.write('\n$frames');
    }
    _entries.add(buffer.toString());
    if (_entries.length > capacity) _entries.removeAt(0);
  }

  /// Plain-text report for the clipboard.
  static String export({String appVersion = ''}) => [
        'Track Free diagnostics${appVersion.isEmpty ? '' : ' — $appVersion'}',
        'Platform: ${defaultTargetPlatform.name}',
        if (_entries.isEmpty) 'No errors recorded since the app started.',
        ..._entries,
      ].join('\n\n');

  @visibleForTesting
  static void clear() => _entries.clear();
}
