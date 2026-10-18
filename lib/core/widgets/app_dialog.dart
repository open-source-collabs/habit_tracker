import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
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
    final effectiveIconBg =
        iconBackgroundColor ??
        (isDestructive
            ? AppColors.error.withValues(alpha: 0.15)
            : context.primaryAccent.withValues(alpha: 0.15));

    return Dialog(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      shadowColor: AppColors.transparent,
      surfaceTintColor: AppColors.transparent,
      shape: const RoundedRectangleBorder(side: BorderSide.none),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: AppSizes.compactDialogMaxWidth,
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: context.cardBorderColor,
              width: AppSizes.borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: context.shadowColor,
                blurRadius: 20,
                offset: const Offset(0, 6),
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
                    width: 40.r,
                    height: 40.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: effectiveIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: icon,
                  ),
                ),
                SizedBox(height: 10.h),
              ],
              Text(title, style: AppTextStyles.titleLarge(context)),
              if (message != null) ...[
                SizedBox(height: 4.h),
                Text(
                  message!,
                  style: AppTextStyles.bodyMedium(
                    context,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
              if (content != null) ...[
                SizedBox(height: 10.h),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: content!,
                  ),
                ),
              ],
              SizedBox(height: 14.h),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10.w,
                runSpacing: 8.h,
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
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: context.barrierColor,
    barrierLabel: 'Dismiss',
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, anim1, anim2) => builder(ctx),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 5.0 * curved.value,
          sigmaY: 5.0 * curved.value,
        ),
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
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
      icon:
          icon ??
          (isDestructive
              ? Icon(
                  Icons.delete_rounded,
                  color: AppColors.error,
                  size: AppIconSizes.xl,
                )
              : Icon(
                  Icons.help_rounded,
                  color: context.primaryAccent,
                  size: AppIconSizes.xl,
                )),
      onConfirm: () => Navigator.of(ctx).pop(true),
      onCancel: () => Navigator.of(ctx).pop(false),
    ),
  );

  return result ?? false;
}
