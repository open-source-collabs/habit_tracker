import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

/// Professional modal bottom sheet container with drag handle, header title bar,
/// dismiss control, and safe keyboard insets.
class AppBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool showCloseButton;
  final bool showDragHandle;
  final EdgeInsetsGeometry? padding;

  const AppBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.showCloseButton = true,
    this.showDragHandle = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: AppSizes.sheetMaxWidth),
          padding:
              padding ??
              EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                top: 10.h,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 14.h,
              ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDragHandle) ...[
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.w,
                    decoration: BoxDecoration(
                      color: context.cardBorderColor,
                      borderRadius: BorderRadius.circular(AppRadius.hairline),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.headlineSmall(context),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: 2.h),
                          Text(
                            subtitle!,
                            style: AppTextStyles.bodySmall(context),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showCloseButton)
                    AppIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Close',
                      size: AppIconSizes.xxl,
                      iconSize: AppIconSizes.md,
                      border: false,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
              SizedBox(height: 10.h),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function displaying a styled modal bottom sheet.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: context.cardBackgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: builder,
  );
}
