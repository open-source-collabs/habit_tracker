import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';

/// Save / Duplicate / Delete controls for the working theme.
///
/// The buttons are themed with [previewTheme] so their design-system tokens
/// (text, border, on-primary colors and font) follow the draft theme the
/// sheet is painted with rather than the currently applied app theme.
class ThemeStudioActionButtons extends StatelessWidget {
  final ThemeData previewTheme;
  final Color activeAccent;
  final bool canDelete;
  final VoidCallback onSave;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const ThemeStudioActionButtons({
    super.key,
    required this.previewTheme,
    required this.activeAccent,
    required this.canDelete,
    required this.onSave,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: previewTheme,
      child: Builder(
        builder: (context) => Column(
          children: [
            AppButton(
              text: 'Save & Apply Theme',
              leadingIcon: const Icon(Icons.palette),
              customColor: activeAccent,
              fullWidth: true,
              onPressed: onSave,
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Duplicate',
                    variant: AppButtonVariant.outline,
                    leadingIcon: Icon(Icons.copy, size: AppIconSizes.sm),
                    fullWidth: true,
                    onPressed: onDuplicate,
                  ),
                ),
                if (canDelete) ...[
                  SizedBox(width: 10.w),
                  Expanded(
                    child: AppButton(
                      text: 'Delete',
                      variant: AppButtonVariant.outline,
                      customColor: context.colorScheme.error,
                      leadingIcon: Icon(
                        Icons.delete_outline,
                        size: AppIconSizes.sm,
                      ),
                      fullWidth: true,
                      onPressed: onDelete,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
