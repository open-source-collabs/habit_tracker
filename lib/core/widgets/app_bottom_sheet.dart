  import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
          constraints: BoxConstraints(maxWidth: 600.w.clamp(400.0, 640.0)),
          padding: padding ??
              EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 12.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDragHandle) ...[
                Center(
                  child: Container(
                    width: 40.w.clamp(36.0, 48.0),
                    height: 4.5.h.clamp(4.0, 6.0),
                    decoration: BoxDecoration(
                      color: context.cardBorderColor,
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
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
                          SizedBox(height: 3.h),
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
                      size: 34.r,
                      iconSize: 18.sp,
                      border: false,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
              SizedBox(height: 16.h),
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
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
    ),
    builder: builder,
  );
}
