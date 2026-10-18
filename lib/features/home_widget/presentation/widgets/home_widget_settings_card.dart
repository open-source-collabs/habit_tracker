import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/home_widget_provider.dart';
import 'add_home_widget_action.dart';
import 'home_widget_preview.dart';

/// Settings → Home screen widget: a live preview and the "Add" action, or a
/// confirmation once the widget is on the home screen.
class HomeWidgetSettingsCard extends ConsumerStatefulWidget {
  const HomeWidgetSettingsCard({super.key});

  @override
  ConsumerState<HomeWidgetSettingsCard> createState() =>
      _HomeWidgetSettingsCardState();
}

class _HomeWidgetSettingsCardState
    extends ConsumerState<HomeWidgetSettingsCard> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // The user may add or remove the widget from the launcher meanwhile.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(homeWidgetStatusProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(homeWidgetStatusProvider).valueOrNull;
    final installed = status?.isInstalled ?? false;

    return AppCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeWidgetPreview(),
          SizedBox(height: 14.h),
          if (installed)
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: AppIconSizes.lg,
                  color: context.primaryAccent,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    status!.installed == 1
                        ? 'On your home screen'
                        : 'On your home screen (${status.installed})',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
                AppButton(
                  text: 'Add another',
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.sm,
                  onPressed: () => addHomeWidget(context, ref),
                ),
              ],
            )
          else ...[
            Text(
              "See today's progress, streak and next habit without opening "
              'the app. It updates as you check habits off.',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
            SizedBox(height: 12.h),
            AppButton(
              text: 'Add to home screen',
              fullWidth: true,
              leadingIcon: Icon(Icons.add_to_home_screen_rounded,
                  size: AppIconSizes.md),
              onPressed: status == null
                  ? null
                  : (status.canPin
                      ? () => addHomeWidget(context, ref)
                      : () => showManualWidgetSteps(context)),
            ),
          ],
        ],
      ),
    );
  }
}
