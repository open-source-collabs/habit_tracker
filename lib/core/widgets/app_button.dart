import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

enum AppButtonSize { sm, md, lg }

/// Tactile, responsive app button adapting to active themes.
/// Includes 0.96 scale-down spring press animation, light impact haptics,
/// loading spinner support, and multiple visual hierarchy variants.
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool isLoading;
  final bool isDisabled;
  final bool fullWidth;
  final Color? customColor;
  final bool glow;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isDisabled = false,
    this.fullWidth = false,
    this.customColor,
    this.glow = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _springController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _springController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  bool get _canInteract =>
      !widget.isDisabled && !widget.isLoading && widget.onPressed != null;

  void _handleTap() {
    if (!_canInteract) return;
    AppHaptics.lightImpact();
    widget.onPressed?.call();
  }

  double get _height {
    switch (widget.size) {
      case AppButtonSize.sm:
        return AppSizes.buttonHeightSm;
      case AppButtonSize.md:
        return AppSizes.buttonHeightMd;
      case AppButtonSize.lg:
        return AppSizes.buttonHeightLg;
    }
  }

  EdgeInsetsGeometry get _padding {
    switch (widget.size) {
      case AppButtonSize.sm:
        return EdgeInsets.symmetric(horizontal: 12.w);
      case AppButtonSize.md:
        return EdgeInsets.symmetric(horizontal: 16.w);
      case AppButtonSize.lg:
        return EdgeInsets.symmetric(horizontal: 22.w);
    }
  }

  double get _borderRadius {
    switch (widget.size) {
      case AppButtonSize.sm:
        return 10.r;
      case AppButtonSize.md:
        return AppRadius.chip;
      case AppButtonSize.lg:
        return AppRadius.lg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = widget.customColor ?? context.primaryAccent;

    // Visual styling per variant
    Color backgroundColor;
    Color foregroundColor;
    Border? border;
    List<BoxShadow> shadows = const [];

    switch (widget.variant) {
      case AppButtonVariant.primary:
        backgroundColor = effectiveAccent;
        foregroundColor = context.onPrimaryColor;
        border = null;
        if (widget.glow && _canInteract) {
          shadows = [
            BoxShadow(
              color: effectiveAccent.withValues(alpha: 0.38),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ];
        }
        break;

      case AppButtonVariant.secondary:
        backgroundColor = context.surfaceElevatedColor;
        foregroundColor = context.textPrimaryColor;
        border = Border.all(
          color: context.cardBorderColor,
          width: AppSizes.borderWidth,
        );
        break;

      case AppButtonVariant.outline:
        backgroundColor = AppColors.transparent;
        foregroundColor = widget.customColor ?? context.textPrimaryColor;
        border = Border.all(
          color: widget.customColor ?? context.cardBorderColor,
          width: 1.4,
        );
        break;

      case AppButtonVariant.ghost:
        backgroundColor = AppColors.transparent;
        foregroundColor = widget.customColor ?? context.textPrimaryColor;
        border = null;
        break;

      case AppButtonVariant.danger:
        backgroundColor = AppColors.error;
        foregroundColor = AppColors.white;
        border = null;
        if (widget.glow && _canInteract) {
          shadows = [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ];
        }
        break;
    }

    final TextStyle textStyle = widget.size == AppButtonSize.sm
        ? AppTextStyles.labelMedium(context, color: foregroundColor)
        : AppTextStyles.labelLarge(context, color: foregroundColor);

    // Icons inherit the label's color and size so they always read as one unit.
    final iconTheme = IconThemeData(
      color: foregroundColor,
      size: widget.size == AppButtonSize.sm ? AppIconSizes.sm : AppIconSizes.md,
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: widget.isDisabled ? 0.45 : 1.0,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) {
            if (_canInteract) _springController.forward();
          },
          onPointerUp: (_) {
            if (_canInteract) _springController.reverse();
          },
          onPointerCancel: (_) {
            if (_canInteract) _springController.reverse();
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              height: _height,
              padding: _padding,
              constraints: BoxConstraints(
                minWidth: widget.fullWidth ? double.infinity : 0,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(_borderRadius),
                border: border,
                boxShadow: shadows,
              ),
              child: IconTheme.merge(
                data: iconTheme,
                child: Row(
                  mainAxisSize: widget.fullWidth
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.isLoading) ...[
                      SizedBox(
                        width: AppIconSizes.md,
                        height: AppIconSizes.md,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            foregroundColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                    ] else if (widget.leadingIcon != null) ...[
                      widget.leadingIcon!,
                      SizedBox(width: 8.w),
                    ],
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.text,
                          style: textStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (widget.trailingIcon != null && !widget.isLoading) ...[
                      SizedBox(width: 8.w),
                      widget.trailingIcon!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tactile icon button in circular or squircle surface with spring physics.
class AppIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double? size;
  final double? iconSize;
  final String? tooltip;
  final bool isCircle;
  final bool border;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.backgroundColor,
    this.size,
    this.iconSize,
    this.tooltip,
    this.isCircle = true,
    this.border = true,
  });

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onPressed == null) return;
    AppHaptics.selectionClick();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final double boxSize = widget.size ?? 40.r;
    final double iSize = widget.iconSize ?? AppIconSizes.md;
    final Color iconColor = widget.color ?? context.textPrimaryColor;
    final Color bgColor = widget.backgroundColor ?? context.cardBackgroundColor;

    Widget button = ScaleTransition(
      scale: _scaleAnimation,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          if (widget.onPressed != null) _controller.forward();
        },
        onPointerUp: (_) {
          if (widget.onPressed != null) _controller.reverse();
        },
        onPointerCancel: (_) {
          if (widget.onPressed != null) _controller.reverse();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          // The visual can be smaller than a finger; the touch area never is.
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSizes.minTapTarget,
              minHeight: AppSizes.minTapTarget,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Container(
                width: boxSize,
                height: boxSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape:
                      widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: widget.isCircle
                      ? null
                      : BorderRadius.circular(AppRadius.chip),
                  color: bgColor,
                  border: widget.border
                      ? Border.all(
                          color: context.cardBorderColor,
                          width: AppSizes.borderWidth,
                        )
                      : null,
                ),
                child: Icon(widget.icon, size: iSize, color: iconColor),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    // The tooltip (when given) provides the spoken label.
    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      child: button,
    );
  }
}
