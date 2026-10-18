import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/home_widget_service.dart';
import '../providers/home_widget_provider.dart';

/// Asks the launcher to add the widget (system dialog). Where the launcher
/// can't, explains how to add it by hand. Re-checks the status a moment
/// later, since the dialog doesn't report the user's choice.
Future<void> addHomeWidget(BuildContext context, WidgetRef ref) async {
  final shown = await ref.read(homeWidgetServiceProvider).requestPin();
  if (!context.mounted) return;
  if (!shown) {
    await showManualWidgetSteps(context);
    return;
  }
  for (final delay in const [Duration(seconds: 2), Duration(seconds: 6)]) {
    unawaited(
      Future<void>.delayed(delay, () {
        if (context.mounted) ref.invalidate(homeWidgetStatusProvider);
      }),
    );
  }
}

/// Step-by-step fallback for launchers without the "add widget" dialog.
Future<void> showManualWidgetSteps(BuildContext context) {
  const steps = [
    'Touch and hold an empty spot on your home screen.',
    'Tap “Widgets”.',
    'Find Track Free and drag “Today’s progress” onto the screen.',
  ];
  return showAppBottomSheet<void>(
    context: context,
    builder: (sheetContext) => AppBottomSheet(
      title: 'Add the widget',
      subtitle: 'Your launcher adds widgets from the home screen.',
      child: Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12.r,
                      backgroundColor: sheetContext.primaryAccent,
                      child: Text(
                        '${i + 1}',
                        style: sheetContext.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: sheetContext.onPrimaryColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: sheetContext.textTheme.bodyMedium?.copyWith(
                          color: sheetContext.textPrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
