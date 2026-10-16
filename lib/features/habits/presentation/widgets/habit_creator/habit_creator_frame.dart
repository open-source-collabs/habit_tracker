import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_theme.dart';

/// Mobile bottom-sheet chrome for the Habit Creator: rounded top surface,
/// drag handle, pinned header/footer and a scrollable form body.
class HabitCreatorBottomSheetFrame extends StatelessWidget {
  final Widget header;
  final Widget body;
  final Widget footer;

  const HabitCreatorBottomSheetFrame({
    super.key,
    required this.header,
    required this.body,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final side = BorderSide(
      color: context.cardBorderColor,
      width: AppSizes.borderWidth,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
        border: Border(top: side, left: side, right: side),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 8.h, bottom: 6.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.textMutedColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.hairline),
              ),
            ),
          ),
          header,
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: body,
            ),
          ),
          footer,
        ],
      ),
    );
  }
}

/// Desktop dialog chrome for the Habit Creator.
///
/// Uses a bare Material [Dialog] rather than `AppDialog`: `AppDialog` imposes
/// its own title/message layout, a 420px max width and fixed Cancel/Confirm
/// buttons, none of which fit the studio's custom header, 580px form and
/// pinned footer. The surface is styled purely from design tokens.
class HabitCreatorDialogFrame extends StatelessWidget {
  final Widget header;
  final Widget body;
  final Widget footer;

  const HabitCreatorDialogFrame({
    super.key,
    required this.header,
    required this.body,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.cardBackgroundColor,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(
          color: context.cardBorderColor,
          width: AppSizes.borderWidth,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppSizes.formDialogMaxWidth,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: body,
              ),
            ),
            footer,
          ],
        ),
      ),
    );
  }
}
