import 'package:flutter/foundation.dart';

/// External links shown in Settings → About.
///
/// Values come from the build so nothing personal is hardcoded:
/// ```
/// flutter build appbundle \
///   --dart-define=PRIVACY_POLICY_URL=https://example.github.io/track-free/privacy \
///   --dart-define=SUPPORT_EMAIL=support@example.com \
///   --dart-define=APP_STORE_ID=1234567890
/// ```
/// When a value is missing, the matching row is hidden (the privacy policy
/// is always readable in-app).
abstract final class AppLinks {
  static const String androidPackage = 'co.trackfree.solforge';

  static const String privacyPolicyUrl =
      String.fromEnvironment('PRIVACY_POLICY_URL');
  static const String supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
  static const String appStoreId = String.fromEnvironment('APP_STORE_ID');

  static Uri? get privacyPolicy =>
      privacyPolicyUrl.isEmpty ? null : Uri.tryParse(privacyPolicyUrl);

  static Uri? get feedbackEmail => supportEmail.isEmpty
      ? null
      : Uri(
          scheme: 'mailto',
          path: supportEmail,
          query: 'subject=${Uri.encodeComponent('Track Free feedback')}',
        );

  /// Store page for rating, or `null` where none is configured.
  static Uri? storeListing(TargetPlatform platform) => switch (platform) {
        TargetPlatform.android => Uri.parse(
            'https://play.google.com/store/apps/details?id=$androidPackage',
          ),
        TargetPlatform.iOS || TargetPlatform.macOS => appStoreId.isEmpty
            ? null
            : Uri.parse(
                'https://apps.apple.com/app/id$appStoreId?action=write-review',
              ),
        _ => null,
      };
}
