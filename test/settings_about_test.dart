import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/constants/app_links.dart';
import 'package:habit_tracker/core/theme/theme_factory.dart';
import 'package:habit_tracker/core/widgets/app_screen_util_init.dart';
import 'package:habit_tracker/features/settings/data/privacy_policy_content.dart';
import 'package:habit_tracker/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:habit_tracker/features/themes/data/models/dynamic_theme_model.dart';

void main() {
  testWidgets('privacy policy is fully readable offline', (tester) async {
    await tester.pumpWidget(
      AppScreenUtilInit(
        builder: (_) => MaterialApp(
          theme: ThemeFactory.createTheme(UserThemeModel.defaultTheme),
          home: const PrivacyPolicyScreen(),
        ),
      ),
    );

    for (final section in PrivacyPolicyContent.sections) {
      await tester.scrollUntilVisible(find.text(section.heading), 200);
      expect(find.text(section.heading), findsOneWidget);
    }
    // No hosted URL in test builds, so no dead "View online" button.
    expect(find.text('View online'), findsNothing);
  });

  group('AppLinks', () {
    test('Android always links to its Play listing', () {
      expect(
        AppLinks.storeListing(TargetPlatform.android).toString(),
        contains('id=${AppLinks.androidPackage}'),
      );
    });

    test('unconfigured links are hidden rather than broken', () {
      expect(AppLinks.privacyPolicy, isNull);
      expect(AppLinks.feedbackEmail, isNull);
      expect(AppLinks.storeListing(TargetPlatform.iOS), isNull);
    });
  });
}
