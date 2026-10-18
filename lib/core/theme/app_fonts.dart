import 'package:flutter/foundation.dart';

/// One bundled font family the user can pick in Theme Studio.
@immutable
class FontOption {
  /// Family name as registered in `pubspec.yaml`.
  final String family;
  final String displayName;
  final String tagline;

  const FontOption({
    required this.family,
    required this.displayName,
    required this.tagline,
  });
}

/// Bundled (offline) font families. Every file is a variable font, so all
/// weights render natively instead of being synthesized.
abstract final class AppFonts {
  static const String plusJakartaSans = 'PlusJakartaSans';
  static const String inter = 'Inter';
  static const String outfit = 'Outfit';
  static const String manrope = 'Manrope';
  static const String dmSans = 'DMSans';
  static const String sora = 'Sora';

  /// Used when a theme names a family this build doesn't bundle.
  static const String fallback = plusJakartaSans;

  static const List<FontOption> options = [
    FontOption(
      family: plusJakartaSans,
      displayName: 'Plus Jakarta Sans',
      tagline: 'Tactile Geometric Sans',
    ),
    FontOption(
      family: inter,
      displayName: 'Inter',
      tagline: 'Modern Precision Sans',
    ),
    FontOption(
      family: outfit,
      displayName: 'Outfit',
      tagline: 'Rounded Geometric Sans',
    ),
    FontOption(
      family: manrope,
      displayName: 'Manrope',
      tagline: 'Open Modern Grotesque',
    ),
    FontOption(
      family: dmSans,
      displayName: 'DM Sans',
      tagline: 'Clean Low-Contrast Sans',
    ),
    FontOption(
      family: sora,
      displayName: 'Sora',
      tagline: 'Wide Technical Sans',
    ),
  ];

  /// Bundled license files, keyed by the package name shown on the
  /// licenses page.
  static const Map<String, String> licenseAssets = {
    'Plus Jakarta Sans font': 'assets/fonts/licenses/plusjakartasans-OFL.txt',
    'Inter font': 'assets/fonts/licenses/inter-OFL.txt',
    'Outfit font': 'assets/fonts/licenses/outfit-OFL.txt',
    'Manrope font': 'assets/fonts/licenses/manrope-OFL.txt',
    'DM Sans font': 'assets/fonts/licenses/dmsans-OFL.txt',
    'Sora font': 'assets/fonts/licenses/sora-OFL.txt',
  };

  static bool isBundled(String? family) =>
      options.any((option) => option.family == family);

  /// [family] when bundled, otherwise [fallback] — e.g. for a theme synced
  /// from a build with a different font set.
  static String resolve(String? family) =>
      isBundled(family) ? family! : fallback;

  static FontOption optionFor(String? family) {
    final resolved = resolve(family);
    return options.firstWhere((option) => option.family == resolved);
  }
}
