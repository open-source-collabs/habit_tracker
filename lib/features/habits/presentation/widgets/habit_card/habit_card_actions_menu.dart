import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_theme.dart';

enum _HabitCardAction { edit, archive, delete }

/// The "⋮" overflow menu on a habit card: edit, archive/unarchive, delete.
///
/// Only the actions whose callback is provided are listed.
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
    return PopupMenuButton<_HabitCardAction>(
      tooltip: 'Habit actions',
      icon: Icon(
        Icons.more_vert,
        size: AppIconSizes.md,
        color: context.textMutedColor,
      ),
      color: context.cardBackgroundColor,
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
            Icons.edit_outlined,
            'Edit',
            context.textPrimaryColor,
          ),
        if (onArchiveToggle != null)
          _item(
            context,
            _HabitCardAction.archive,
            isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
            isArchived ? 'Unarchive' : 'Archive',
            context.textPrimaryColor,
          ),
        if (onDelete != null)
          _item(
            context,
            _HabitCardAction.delete,
            Icons.delete_outline,
            'Delete',
            context.colorScheme.error,
          ),
      ],
    );
  }

  PopupMenuItem<_HabitCardAction> _item(
    BuildContext context,
    _HabitCardAction value,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: AppIconSizes.sm, color: color),
          SizedBox(width: 8.w),
          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
