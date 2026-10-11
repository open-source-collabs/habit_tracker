import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';
import 'package:habit_tracker/core/theme/app_text_styles.dart';

import '../theme/app_theme.dart';
import '../utils/haptics.dart';

/// Item configuration for [AppDropdown].
class AppDropdownItem<T> {
  final T value;
  final String label;
  final Widget? icon;
  final String? subtitle;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.subtitle,
  });
}

/// Custom styled dropdown selector replacing generic platform spinners.
/// Uses a tactile trigger button with rotating animated chevron and
/// a bottom sheet selection panel matching active theme surfaces.
class AppDropdown<T> extends StatefulWidget {
  final String? labelText;
  final String hintText;
  final T? value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T>? onChanged;
  final Widget? prefixIcon;
  final bool enabled;
  final String? sheetTitle;

  const AppDropdown({
    super.key,
    this.labelText,
    this.hintText = 'Select an option',
    required this.value,
    required this.items,
    required this.onChanged,
    this.prefixIcon,
    this.enabled = true,
    this.sheetTitle,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  bool _isOpen = false;

  AppDropdownItem<T>? get _selectedItem {
    if (widget.value == null) return null;
    try {
      return widget.items.firstWhere((item) => item.value == widget.value);
    } catch (_) {
      return null;
    }
  }

  void _openSelectionSheet() async {
    if (!widget.enabled || widget.onChanged == null) return;
    AppHaptics.selectionClick();
    setState(() => _isOpen = true);

    final selected = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: context.cardBackgroundColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (sheetContext) {
        return _DropdownSelectionSheet<T>(
          title: widget.sheetTitle ?? widget.labelText ?? 'Select Option',
          items: widget.items,
          currentValue: widget.value,
        );
      },
    );

    if (mounted) {
      setState(() => _isOpen = false);
      if (selected != null && selected != widget.value) {
        AppHaptics.selectionClick();
        widget.onChanged?.call(selected);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedItem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: AppTextStyles.labelSmall(
              context,
              color: _isOpen ? context.primaryAccent : context.textMutedColor,
            ),
          ),
          SizedBox(height: 6.h),
        ],
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openSelectionSheet,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: _isOpen
                    ? context.primaryAccent
                    : context.cardBorderColor,
                width: _isOpen ? 1.6 : 1.2,
              ),
              boxShadow: _isOpen
                  ? [
                      BoxShadow(
                        color: context.primaryAccent.withValues(alpha: 0.22),
                        blurRadius: 10.r,
                        offset: Offset(0, 2.h),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              children: [
                if (widget.prefixIcon != null) ...[
                  widget.prefixIcon!,
                  SizedBox(width: 10.w),
                ] else if (selected?.icon != null) ...[
                  selected!.icon!,
                  SizedBox(width: 10.w),
                ],
                Expanded(
                  child: Text(
                    selected?.label ?? widget.hintText,
                    style: selected != null
                        ? AppTextStyles.bodyMedium(
                            context,
                            color: context.textPrimaryColor,
                          )
                        : AppTextStyles.bodyMedium(
                            context,
                            color: context.textMutedColor,
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22.sp,
                    color: _isOpen
                        ? context.primaryAccent
                        : context.textMutedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownSelectionSheet<T> extends StatelessWidget {
  final String title;
  final List<AppDropdownItem<T>> items;
  final T? currentValue;

  const _DropdownSelectionSheet({
    required this.title,
    required this.items,
    required this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 14.h,
          bottom: 24.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40.w,
                height: 4.5.h,
                decoration: BoxDecoration(
                  color: context.cardBorderColor,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headlineSmall(
                    context,
                    color: context.textPrimaryColor,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20.sp,
                    color: context.textMutedColor,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Item List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (context, index) => SizedBox(height: 6.h),
                itemBuilder: (context, idx) {
                  final item = items[idx];
                  final isSelected = item.value == currentValue;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context, item.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.primaryAccent.withValues(alpha: 0.14)
                            : AppColors.transparent,
                        borderRadius: BorderRadius.circular(14.r),
                        border: isSelected
                            ? Border.all(
                                color: context.primaryAccent
                                    .withValues(alpha: 0.35),
                                width: 1.2,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          if (item.icon != null) ...[
                            item.icon!,
                            SizedBox(width: 12.w),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: AppTextStyles.bodyMedium(
                                    context,
                                    color: isSelected
                                        ? context.primaryAccent
                                        : context.textPrimaryColor,
                                  ).copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                if (item.subtitle != null) ...[
                                  SizedBox(height: 2.h),
                                  Text(
                                    item.subtitle!,
                                    style: AppTextStyles.bodySmall(
                                      context,
                                      color: context.textMutedColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              size: 18.sp,
                              color: context.primaryAccent,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
