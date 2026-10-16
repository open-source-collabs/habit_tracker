import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';

/// Pinned footer with Cancel and Create/Update actions.
class HabitCreatorFooter extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onSubmit;

  const HabitCreatorFooter({
    super.key,
    required this.isEditing,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        border: Border(
          top: BorderSide(
            color: context.cardBorderColor,
            width: AppSizes.borderWidth,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Cancel',
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.md,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: AppButton(
              text: isEditing ? 'Update Habit' : 'Create Habit',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.md,
              glow: true,
              leadingIcon: const Icon(Icons.check_rounded),
              onPressed: onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}
