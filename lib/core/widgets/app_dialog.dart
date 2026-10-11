import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

/// Professional modal dialog with frosted backdrop, theme card surfaces,
/// optional circular icon badge, and primary/secondary button controls.
class AppDialog extends StatelessWidget {
  final Widget? icon;
  final Color? iconBackgroundColor;
  final String title;
  final String? message;
  final Widget? content;
  final String? confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final bool isConfirmLoading;

  const AppDialog({
    super.key,
    this.icon,
    this.iconBackgroundColor,
    required this.title,
    this.message,
    this.content,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.isConfirmLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconBg = iconBackgroundColor ??
        (isDestructive
            ? AppColors.error.withValues(alpha: 0.15)
            : context.primaryAccent.withValues(alpha: 0.15));

    return Dialog(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 420.w.clamp(320.0, 460.0),
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: context.cardBorderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: context.shadowColor,
                blurRadius: 24.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (icon != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 48.r,
                    height: 48.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: effectiveIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: icon,
                  ),
                ),
                SizedBox(height: 16.h),
              ],
              Text(
                title,
                style: AppTextStyles.titleLarge(context),
              ),
              if (message != null) ...[
                SizedBox(height: 8.h),
                Text(
                  message!,
                  style: AppTextStyles.bodyMedium(
                    context,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
              if (content != null) ...[
                SizedBox(height: 16.h),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: content!,
                  ),
                ),
              ],
              SizedBox(height: 24.h),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10.w.clamp(8.0, 14.0),
                runSpacing: 8.h.clamp(6.0, 12.0),
                children: [
                  AppButton(
                    text: cancelText,
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.md,
                    onPressed: () {
                      if (onCancel != null) {
                        onCancel!();
                      } else {
                        Navigator.of(context).pop(false);
                      }
                    },
                  ),
                  if (confirmText != null)
                    AppButton(
                      text: confirmText!,
                      variant: isDestructive
                          ? AppButtonVariant.danger
                          : AppButtonVariant.primary,
                      size: AppButtonSize.md,
                      isLoading: isConfirmLoading,
                      glow: !isDestructive,
                      onPressed: () {
                        if (onConfirm != null) {
                          onConfirm!();
                        } else {
                          Navigator.of(context).pop(true);
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function showing a customized modal dialog.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: context.barrierColor,
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: builder(ctx),
    ),
  );
}

/// Helper for standard confirmation / destructive prompt dialogs.
Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  String? message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  bool isDestructive = false,
  Widget? icon,
}) async {
  final result = await showAppDialog<bool>(
    context: context,
    builder: (ctx) => AppDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDestructive,
      icon: icon ??
          (isDestructive
              ? Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 24.sp)
              : Icon(Icons.help_outline_rounded,
                  color: context.primaryAccent, size: 24.sp)),
      onConfirm: () => Navigator.of(ctx).pop(true),
      onCancel: () => Navigator.of(ctx).pop(false),
    ),
  );

  return result ?? false;
}
