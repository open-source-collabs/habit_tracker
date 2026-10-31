import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routes/routes.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import 'providers/app_update_controller.dart';

/// Checks Google Play for a newer version and walks the user through it.
///
/// An automatic check (`manual: false`) is silent unless an update is worth
/// offering. A manual check, from Settings, always tells the user the result.
Future<void> checkForAppUpdate(
  WidgetRef ref, {
  bool manual = false,
  BuildContext? context,
}) async {
  final controller = ref.read(appUpdateControllerProvider.notifier);
  final status = await controller.check(manual: manual);

  switch (status) {
    case AppUpdateStatus.available:
      final state = ref.read(appUpdateControllerProvider);
      if (state.immediate) {
        // High priority: Play's own blocking screen, no extra prompt.
        await controller.startUpdate();
        return;
      }
      if (context != null && !context.mounted) return;
      final dialogContext = context ?? _overlayContext();
      if (dialogContext == null) return;
      final accepted = await showAppConfirmDialog(
        context: dialogContext,
        title: 'Update available',
        message: 'A newer version of Track Free is ready on Google Play. '
            'It downloads in the background, so you can keep using the app.',
        confirmText: 'Update',
        cancelText: 'Later',
        icon: Icon(
          Icons.system_update_rounded,
          color: dialogContext.primaryAccent,
          size: AppIconSizes.xl,
        ),
      );
      if (accepted) {
        await controller.startUpdate();
        if (manual) _showMessage('Downloading the update…');
      } else {
        await controller.dismiss();
      }
    case AppUpdateStatus.upToDate when manual:
      _showMessage("You're on the latest version.");
    case AppUpdateStatus.unsupported when manual:
      _showMessage('Updates for this device are managed by its app store.');
    case AppUpdateStatus.failed when manual:
      _showMessage(
        "Couldn't check for updates. Make sure Track Free was installed from "
        'Google Play and try again.',
      );
    default:
      break;
  }
}

/// Offers to restart into an update that has finished downloading.
void showUpdateReadySnackBar(WidgetRef ref) {
  AppRouter.scaffoldMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Update downloaded. Restart to finish installing.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(days: 1),
        action: SnackBarAction(
          label: 'Restart',
          onPressed: () =>
              ref.read(appUpdateControllerProvider.notifier).installDownloaded(),
        ),
      ),
    );
}

BuildContext? _overlayContext() =>
    AppRouter.navigatorKey.currentState?.overlay?.context;

void _showMessage(String message) {
  AppRouter.scaffoldMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
