import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_theme.dart';

enum _HabitCardAction { edit, archive, delete }

/// The "⋮" overflow menu on a habit card: edit, archive/unarchive, delete.
///
/// Only the actions whose callback is provided are listed. Delete sits below
/// a divider so it's never the item under the thumb by accident.
class HabitCardActionsMenu extends StatelessWidget {
  final bool isArchived;
  final VoidCallback? onEdit;
  final VoidCallback? onArchiveToggle;
  final VoidCallback? onDelete;

  const HabitCardActionsMenu({
    super.key,
    required this.isArchived,
    this.onEdit,
    this.onArchiveToggle,
    this.onDelete,
  });

  void _onSelected(_HabitCardAction action) {
    switch (action) {
      case _HabitCardAction.edit:
        onEdit?.call();
      case _HabitCardAction.archive:
        onArchiveToggle?.call();
      case _HabitCardAction.delete:
        onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSafeActions = onEdit != null || onArchiveToggle != null;

    return PopupMenuButton<_HabitCardAction>(
      tooltip: 'Habit actions',
      icon: Icon(
        Icons.more_vert_rounded,
        size: AppIconSizes.md,
        color: context.textMutedColor,
      ),
      position: PopupMenuPosition.under,
      offset: Offset(0, 4.h),
      constraints: BoxConstraints(minWidth: 176.w, maxWidth: 240.w),
      menuPadding: EdgeInsets.all(6.r),
      color: context.cardBackgroundColor,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: context.cardBorderColor,
          width: AppSizes.borderWidth,
        ),
      ),
      onSelected: _onSelected,
      itemBuilder: (menuContext) => [
        if (onEdit != null)
          _item(
            context,
            _HabitCardAction.edit,
            Icons.edit_rounded,
            'Edit habit',
            context.primaryAccent,
            labelColor: context.textPrimaryColor,
          ),
        if (onArchiveToggle != null)
          _item(
            context,
            _HabitCardAction.archive,
            isArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
            isArchived ? 'Unarchive' : 'Archive',
            context.secondaryAccent,
            labelColor: context.textPrimaryColor,
          ),
        if (onDelete != null) ...[
          if (hasSafeActions) PopupMenuDivider(height: 9.h),
          _item(
            context,
            _HabitCardAction.delete,
            Icons.delete_rounded,
            'Delete',
            context.colorScheme.error,
            labelColor: context.colorScheme.error,
          ),
        ],
      ],
    );
  }

  PopupMenuItem<_HabitCardAction> _item(
    BuildContext context,
    _HabitCardAction value,
    IconData icon,
    String label,
    Color accent, {
    required Color labelColor,
  }) {
    return PopupMenuItem(
      value: value,
      height: 42.w,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Row(
        children: [
          Container(
            width: 28.r,
            height: 28.r,
            decoration: BoxDecoration(
              color: AppColors.pastelSurface(
                accent,
                isDark: context.isDarkMode,
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: AppIconSizes.sm, color: accent),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
