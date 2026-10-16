import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../themes/data/models/app_payload_model.dart';
import '../../data/storage/habit_storage.dart';
import '../providers/habit_provider.dart';

/// Shown when stored habit data cannot be read. Saving stays blocked while
/// this is visible, so the user's data is never overwritten without consent.
class DataLoadErrorView extends ConsumerWidget {
  final Object error;

  const DataLoadErrorView({super.key, required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = this.error;
    final isNewerVersion = error is UnsupportedPayloadVersionException ||
        (error is CorruptPayloadException &&
            error.cause is UnsupportedPayloadVersionException);

    final message = isNewerVersion
        ? 'Your data was saved by a newer version of the app. Update the app '
            'to open it. Nothing has been changed.'
        : 'Your saved habits could not be read. Nothing has been overwritten. '
            'You can try again, or start fresh. Starting fresh keeps a copy '
            'of the unreadable data on this device.';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 40,
                  color: context.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  "Couldn't load your habits",
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  text: 'Try again',
                  fullWidth: true,
                  onPressed: () =>
                      ref.read(habitListProvider.notifier).retryLoad(),
                ),
                if (!isNewerVersion) ...[
                  const SizedBox(height: 10),
                  AppButton(
                    text: 'Start fresh',
                    variant: AppButtonVariant.danger,
                    fullWidth: true,
                    onPressed: () => _confirmStartFresh(context, ref),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmStartFresh(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Start fresh?',
      message: 'This starts an empty habit list. A copy of the unreadable '
          'data stays on this device for recovery.',
      confirmText: 'Start fresh',
      isDestructive: true,
    );
    if (confirmed) {
      await ref.read(habitListProvider.notifier).discardUnreadableData();
    }
  }
}
