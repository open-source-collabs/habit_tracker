import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_dimensions.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import 'app_routes.dart';

/// Bento-styled 404 Route Not Found screen.
class NotFoundScreen extends StatelessWidget {
  final String? routeName;

  const NotFoundScreen({super.key, this.routeName});

  @override
  Widget build(BuildContext context) {
    final primaryAccent = context.primaryAccent;

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Page Not Found',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.textPrimaryColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.dialogMaxWidth,
              ),
              padding: EdgeInsets.all(32.r),
              decoration: BoxDecoration(
                color: context.cardBackgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: context.cardBorderColor,
                  width: AppSizes.borderWidth,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: primaryAccent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.explore_off_rounded,
                      size: AppIconSizes.hero,
                      color: primaryAccent,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    '404 - Route Not Found',
                    textAlign: TextAlign.center,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    routeName != null
                        ? 'The destination "$routeName" does not exist or has moved.'
                        : 'The requested route could not be found.',
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.textMutedColor,
                    ),
                  ),
                  SizedBox(height: 28.h),
                  AppButton(
                    text: 'Back to Dashboard',
                    leadingIcon: const Icon(Icons.arrow_back_rounded),
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.md,
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context)
                            .pushReplacementNamed(AppRoutes.dashboard);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
