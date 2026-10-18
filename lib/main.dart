import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/theme/app_fonts.dart';
import 'core/utils/app_error_log.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the native launch screen up until the first screen is ready
  // (released in HabitTrackerApp), so there is no blank or flickering frame.
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  _installErrorHandlers();
  _registerFontLicenses();
  await AppDatabase.initializePlatform();
  runApp(
    const ProviderScope(
      child: HabitTrackerApp(),
    ),
  );
}

/// Records uncaught errors locally instead of losing them. Release builds
/// also silence `debugPrint`, which otherwise writes raw exceptions (and
/// sometimes user data) to the system log.
void _installErrorHandlers() {
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  final defaultFlutterHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    AppErrorLog.record(
      details.exception,
      details.stack,
      context: details.library,
    );
    defaultFlutterHandler?.call(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppErrorLog.record(error, stack, context: 'async');
    if (!kReleaseMode) {
      // Keep surfacing async errors loudly while developing.
      debugPrint('Uncaught async error: $error\n$stack');
    }
    return true;
  };
}

/// The SIL Open Font License requires shipping each font's license; this
/// lists them on the licenses page.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in AppFonts.licenseAssets.entries) {
      final text = await rootBundle.loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
}
