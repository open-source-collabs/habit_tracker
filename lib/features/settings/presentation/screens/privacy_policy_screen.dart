import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_links.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/privacy_policy_content.dart';
import '../widgets/about_links.dart';

/// Full privacy policy, readable offline.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onlineCopy = AppLinks.privacyPolicy;

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Privacy policy',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.textPrimaryColor,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.pageMaxWidth),
          child: ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              Text(
                'Effective ${PrivacyPolicyContent.effectiveDate}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.textMutedColor,
                ),
              ),
              SizedBox(height: 12.h),
              for (final section in PrivacyPolicyContent.sections) ...[
                Text(
                  section.heading,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  section.body,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.textSecondaryColor,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 18.h),
              ],
              if (onlineCopy != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    text: 'View online',
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.sm,
                    onPressed: () => openExternalLink(context, onlineCopy),
                  ),
                ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
