import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';

/// Professional text input field adopting active theme typography, surface colors,
/// and border geometry. Features a soft glowing accent halo when focused.
class AppTextField extends StatefulWidget {
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
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final int maxLines;
  final int minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final Color? accentColor;
  final FocusNode? focusNode;

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
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.maxLines = 1,
    this.minLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.accentColor,
    this.focusNode,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late TextEditingController _effectiveController;
  late FocusNode _effectiveFocusNode;
  bool _isFocused = false;
  late bool _obscureText;
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _effectiveController =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _effectiveFocusNode = widget.focusNode ?? FocusNode();

    _obscureText = widget.isPassword || widget.obscureText;
    _showClear = _effectiveController.text.isNotEmpty;

    _effectiveFocusNode.addListener(_handleFocusChanged);
    _effectiveController.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChanged);
    _effectiveController.removeListener(_handleTextChange);
    if (widget.focusNode == null) _effectiveFocusNode.dispose();
    if (widget.controller == null) _effectiveController.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (_effectiveFocusNode.hasFocus != _isFocused) {
      if (_effectiveFocusNode.hasFocus) {
        AppHaptics.selectionClick();
      }
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  void _handleTextChange() {
    final hasText = _effectiveController.text.isNotEmpty;
    if (hasText != _showClear) {
      setState(() {
        _showClear = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? context.primaryAccent;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    final Color borderColor = hasError
        ? AppColors.error
        : _isFocused
            ? accent
            : context.cardBorderColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: AppTextStyles.labelSmall(
              context,
              color: hasError
                  ? AppColors.error
                  : _isFocused
                      ? accent
                      : context.textMutedColor,
            ),
          ),
          SizedBox(height: 6.h),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.6 : 1.2,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: (hasError ? AppColors.error : accent)
                          .withValues(alpha: 0.22),
                      blurRadius: 10.r,
                      offset: Offset(0, 2.h),
                    ),
                  ]
                : const [],
          ),
          child: TextField(
            controller: _effectiveController,
            focusNode: _effectiveFocusNode,
            obscureText: _obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            style: AppTextStyles.bodyMedium(
              context,
              color: context.textPrimaryColor,
            ),
            cursorColor: accent,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
              hintText: widget.hintText,
              hintStyle: AppTextStyles.bodyMedium(
                context,
                color: context.textMutedColor,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: widget.prefixIcon,
                    )
                  : null,
              prefixIconConstraints: BoxConstraints(
                minWidth: 44.w,
                minHeight: 24.h,
              ),
              suffixIcon: _buildSuffixIcon(accent),
              suffixIconConstraints: BoxConstraints(
                minWidth: 44.w,
                minHeight: 24.h,
              ),
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: 6.h),
          Text(
            widget.errorText!,
            style: AppTextStyles.bodySmall(
              context,
              color: AppColors.error,
            ),
          ),
        ] else if (widget.helperText != null) ...[
          SizedBox(height: 6.h),
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

  Widget? _buildSuffixIcon(Color accent) {
    if (widget.isPassword) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selectionClick();
          setState(() => _obscureText = !_obscureText);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Icon(
            _obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 18.sp,
            color: _isFocused ? accent : context.textMutedColor,
          ),
        ),
      );
    }

    if (widget.showClearButton && _showClear) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selectionClick();
          _effectiveController.clear();
          widget.onChanged?.call('');
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Icon(
            Icons.cancel_rounded,
            size: 18.sp,
            color: context.textMutedColor,
          ),
        ),
      );
    }

    if (widget.suffixIcon != null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: widget.suffixIcon,
      );
    }

    return null;
  }
}
