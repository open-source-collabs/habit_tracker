import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';
import 'app_text_field_provider.dart';

/// Professional, zero-hardcoding text input field adhering to the Bento design system.
///
/// Features:
/// - Smooth animated focus transitions with tactile glow halo
/// - Clean single-border architecture eliminating any duplicate outline leakage
/// - Dynamic Riverpod theme adaptation with custom accent override support
/// - Built-in clear button and password visibility toggle with tactile haptics
/// - Robust controller and FocusNode lifecycle management (including didUpdateWidget)
/// - Comprehensive customization: inputFormatters, textCapitalization, padding, styles
class AppTextField extends ConsumerStatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool showClearButton;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final VoidCallback? onTap;
  final int maxLines;
  final int minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final Color? accentColor;
  final FocusNode? focusNode;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry? contentPadding;
  final double? borderRadius;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;

  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.showClearButton = false,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.maxLines = 1,
    this.minLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.accentColor,
    this.focusNode,
    this.style,
    this.hintStyle,
    this.labelStyle,
    this.contentPadding,
    this.borderRadius,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
  });

  @override
  ConsumerState<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends ConsumerState<AppTextField> {
  TextEditingController? _internalController;
  FocusNode? _internalFocusNode;

  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController!;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  late final AppTextFieldParams _params = AppTextFieldParams(
    id: 'textfield_${identityHashCode(this)}',
    initialObscure: widget.isPassword || widget.obscureText,
    initialShowClear:
        (widget.controller?.text ?? widget.initialValue ?? '').isNotEmpty,
  );

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController(text: widget.initialValue);
    }
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }

    _effectiveFocusNode.addListener(_handleFocusChanged);
    _effectiveController.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle controller updates cleanly without leaking listeners
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleTextChange);
      _internalController?.removeListener(_handleTextChange);

      if (widget.controller == null) {
        _internalController = TextEditingController(
          text: oldWidget.controller?.text ?? widget.initialValue,
        );
        _internalController!.addListener(_handleTextChange);
      } else {
        _internalController?.dispose();
        _internalController = null;
        widget.controller!.addListener(_handleTextChange);
      }
      ref
          .read(appTextFieldUiProvider(_params).notifier)
          .setShowClear(_effectiveController.text.isNotEmpty);
    }

    // Handle focus node updates cleanly
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChanged);
      _internalFocusNode?.removeListener(_handleFocusChanged);

      if (widget.focusNode == null) {
        _internalFocusNode = FocusNode();
        _internalFocusNode!.addListener(_handleFocusChanged);
      } else {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
        widget.focusNode!.addListener(_handleFocusChanged);
      }
      ref
          .read(appTextFieldUiProvider(_params).notifier)
          .setFocused(_effectiveFocusNode.hasFocus);
    }

    // Handle password / obscurity changes
    if (widget.isPassword != oldWidget.isPassword ||
        widget.obscureText != oldWidget.obscureText) {
      ref
          .read(appTextFieldUiProvider(_params).notifier)
          .setObscure(widget.isPassword || widget.obscureText);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChanged);
    _effectiveController.removeListener(_handleTextChange);
    _internalFocusNode?.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    final currentFocused = ref.read(appTextFieldUiProvider(_params)).isFocused;
    if (_effectiveFocusNode.hasFocus != currentFocused) {
      if (_effectiveFocusNode.hasFocus) {
        AppHaptics.selectionClick();
      }
      ref
          .read(appTextFieldUiProvider(_params).notifier)
          .setFocused(_effectiveFocusNode.hasFocus);
    }
  }

  void _handleTextChange() {
    final hasText = _effectiveController.text.isNotEmpty;
    final currentShow = ref.read(appTextFieldUiProvider(_params)).showClear;
    if (hasText != currentShow) {
      ref.read(appTextFieldUiProvider(_params).notifier).setShowClear(hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(appTextFieldUiProvider(_params));
    final isFocused = uiState.isFocused;
    final obscureText = uiState.obscureText;
    final showClear = uiState.showClear;

    final accent = widget.accentColor ?? context.primaryAccent;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final radius = widget.borderRadius ?? AppRadius.chip;

    final Color borderColor = !widget.enabled
        ? context.cardBorderColor.withValues(alpha: 0.5)
        : hasError
        ? AppColors.error
        : isFocused
        ? accent
        : context.cardBorderColor;

    final Color backgroundColor = widget.enabled
        ? context.cardBackgroundColor
        : context.cardBackgroundColor.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style:
                widget.labelStyle ??
                AppTextStyles.labelSmall(
                  context,
                  color: hasError
                      ? AppColors.error
                      : isFocused
                      ? accent
                      : context.textMutedColor,
                ),
          ),
          SizedBox(height: 5.h),
        ],
        // Single outer container governing geometry, surface, and focus halo
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor,
              width: isFocused
                  ? AppSizes.borderWidthFocused
                  : AppSizes.borderWidth,
            ),
            boxShadow: isFocused && widget.enabled
                ? [
                    BoxShadow(
                      color: (hasError ? AppColors.error : accent).withValues(
                        alpha: 0.22,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : const [],
          ),
          child: Theme(
            // Scope local InputDecorationTheme so global theme OutlineInputBorders
            // cannot bleed inside and create duplicate borders or fills.
            data: Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
              ),
            ),
            child: TextField(
              controller: _effectiveController,
              focusNode: _effectiveFocusNode,
              obscureText: obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              textCapitalization: widget.textCapitalization,
              inputFormatters: widget.inputFormatters,
              textAlign: widget.textAlign,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              onEditingComplete: widget.onEditingComplete,
              onTap: widget.onTap,
              maxLines: widget.isPassword ? 1 : widget.maxLines,
              minLines: widget.minLines,
              maxLength: widget.maxLength,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              autofocus: widget.autofocus,
              style:
                  widget.style ??
                  AppTextStyles.bodyMedium(
                    context,
                    color: widget.enabled
                        ? context.textPrimaryColor
                        : context.textMutedColor,
                  ),
              cursorColor: accent,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                fillColor: AppColors.transparent,
                contentPadding:
                    widget.contentPadding ??
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
                hintText: widget.hintText,
                hintStyle:
                    widget.hintStyle ??
                    AppTextStyles.bodyMedium(
                      context,
                      color: context.textMutedColor,
                    ),
                prefixIcon: widget.prefixIcon != null
                    ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: widget.prefixIcon,
                      )
                    : null,
                prefixIconConstraints: BoxConstraints(
                  minWidth: 40.w,
                  minHeight: 20.w,
                ),
                suffixIcon: _buildSuffixIcon(
                  accent,
                  isFocused: isFocused,
                  obscureText: obscureText,
                  showClear: showClear,
                ),
                suffixIconConstraints: BoxConstraints(
                  minWidth: 40.w,
                  minHeight: 20.w,
                ),
                // Explicitly nullify all internal borders to prevent duplicate outline
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: 4.h),
          Text(
            widget.errorText!,
            style: AppTextStyles.bodySmall(context, color: AppColors.error),
          ),
        ] else if (widget.helperText != null) ...[
          SizedBox(height: 4.h),
          Text(
            widget.helperText!,
            style: AppTextStyles.bodySmall(
              context,
              color: context.textMutedColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon(
    Color accent, {
    required bool isFocused,
    required bool obscureText,
    required bool showClear,
  }) {
    final List<Widget> icons = [];

    // Clear button with haptics
    if (widget.showClearButton &&
        showClear &&
        widget.enabled &&
        !widget.readOnly) {
      icons.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            AppHaptics.selectionClick();
            _effectiveController.clear();
            widget.onChanged?.call('');
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Icon(
              Icons.cancel_rounded,
              size: AppIconSizes.md,
              color: context.textMutedColor,
            ),
          ),
        ),
      );
    }

    // Password visibility toggle with haptics
    if (widget.isPassword) {
      icons.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            AppHaptics.selectionClick();
            ref.read(appTextFieldUiProvider(_params).notifier).toggleObscure();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Icon(
              obscureText
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              size: AppIconSizes.md,
              color: isFocused ? accent : context.textMutedColor,
            ),
          ),
        ),
      );
    } else if (widget.suffixIcon != null) {
      icons.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: widget.suffixIcon!,
        ),
      );
    }

    if (icons.isEmpty) return null;
    if (icons.length == 1) return icons.first;
    return Row(mainAxisSize: MainAxisSize.min, children: icons);
  }
}
