import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_font_sizes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../presentation/widgets/data_portability_dialog.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../data/cloud_sync_backend.dart';
import '../providers/sync_controller.dart';

/// Sync tab: optional sync through the user's own iCloud or Google Drive,
/// manual JSON backup, and what's stored on this device.
class SyncTabView extends ConsumerWidget {
  const SyncTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitListProvider).valueOrNull ?? [];
    final checkIns = habits.fold<int>(
      0,
      (sum, h) => sum + h.checkIns.values.where((done) => done).length,
    );

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: context.isDesktop ? 24.w : 16.w,
        vertical: 10.h,
      ),
      children: [
        const _SectionLabel('CLOUD SYNC'),
        SizedBox(height: 8.h),
        const _CloudSyncCard(),
        SizedBox(height: 16.h),
        const _SectionLabel('BACKUP'),
        SizedBox(height: 8.h),
        AppCard(
          isInteractive: true,
          onTap: () => DataPortabilityDialog.show(context),
          padding: EdgeInsets.all(14.r),
          child: Row(
            children: [
              Icon(
                Icons.import_export_rounded,
                color: context.primaryAccent,
                size: AppIconSizes.lg,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export & import',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Your data as one JSON file: copy it anywhere, or '
                      'restore and merge a backup.',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.textMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.textMutedColor),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        const _SectionLabel('ON THIS DEVICE'),
        SizedBox(height: 8.h),
        AppCard(
          padding: EdgeInsets.all(14.r),
          child: Column(
            children: [
              _MetricRow(label: 'Habits', value: '${habits.length}'),
              SizedBox(height: 6.h),
              _MetricRow(label: 'Check-ins', value: '$checkIns'),
              SizedBox(height: 6.h),
              const _MetricRow(label: 'Works offline', value: 'Always'),
            ],
          ),
        ),
        // Safe spacing for floating navbar
        SizedBox(height: 100.h),
      ],
    );
  }
}

class _CloudSyncCard extends ConsumerWidget {
  const _CloudSyncCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncControllerProvider);
    final controller = ref.read(syncControllerProvider.notifier);
    final available = controller.availableProviders;

    return AppCard(
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColors.pastelSurface(
                    context.primaryAccent,
                    isDark: context.isDarkMode,
                    opacity: 0.18,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  sync.isConnected
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  color: context.primaryAccent,
                  size: AppIconSizes.lg,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sync.isConnected
                          ? 'Syncing with ${sync.provider!.label}'
                          : 'Sync is off',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor,
                        fontSize: AppFontSizes.subtitle,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _statusLine(sync),
                      style: context.textTheme.labelSmall?.copyWith(
                        color:
                            sync.status == SyncStatus.error ||
                                sync.status == SyncStatus.needsSignIn
                            ? context.colorScheme.error
                            : context.textMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (!sync.isConnected) ...[
            Text(
              available.isEmpty
                  ? 'Cloud sync isn\'t available on this device. Your data '
                        'stays here; use Export & import to move it.'
                  : 'Optional. Keep a copy in your own cloud so your habits '
                        'follow you to your other devices. There\'s no account '
                        'with us, and we never see your data.',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
            for (final provider in available) ...[
              SizedBox(height: 10.h),
              AppButton(
                text: 'Use ${provider.label}',
                leadingIcon: Icon(
                  provider == CloudProvider.iCloud
                      ? Icons.cloud_rounded
                      : Icons.add_to_drive_rounded,
                ),
                fullWidth: true,
                onPressed: () => controller.connect(provider),
              ),
            ],
          ] else
            Row(
              children: [
                Expanded(
                  child: sync.status == SyncStatus.needsSignIn
                      ? AppButton(
                          text: 'Reconnect',
                          size: AppButtonSize.sm,
                          onPressed: () => controller.connect(sync.provider!),
                        )
                      : AppButton(
                          text: 'Sync now',
                          size: AppButtonSize.sm,
                          leadingIcon: const Icon(Icons.sync_rounded),
                          isLoading: sync.status == SyncStatus.syncing,
                          onPressed: controller.syncNow,
                        ),
                ),
                SizedBox(width: 8.w),
                AppButton(
                  text: 'Turn off',
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => _confirmDisconnect(context, ref),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _statusLine(SyncState sync) {
    if (!sync.isConnected) return 'Your data is only on this device';
    if (sync.message != null &&
        (sync.status == SyncStatus.error ||
            sync.status == SyncStatus.needsSignIn)) {
      return sync.message!;
    }
    final account = sync.accountLabel == null ? '' : '${sync.accountLabel} · ';
    if (sync.status == SyncStatus.syncing) return '${account}Syncing…';
    final last = sync.lastSyncedAt;
    return last == null
        ? '${account}Not synced yet'
        : '${account}Synced ${AppDateFormat.relative(last)}';
  }

  Future<void> _confirmDisconnect(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Turn off sync?',
      message:
          'This device stops syncing. Your data here and the copy in '
          'your cloud are both kept.',
      confirmText: 'Turn off',
    );
    if (confirmed) {
      await ref.read(syncControllerProvider.notifier).disconnect();
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        fontSize: AppFontSizes.labelSmall,
        color: context.textMutedColor,
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: context.textTheme.titleSmall?.copyWith(
            color: context.primaryAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
