import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_font_sizes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../presentation/widgets/data_portability_dialog.dart';
import '../../../habits/presentation/providers/habit_provider.dart';

/// Sync and Data Portability Tab View providing cloud backup status,
/// export/import capabilities, and synchronization actions.
class SyncTabView extends ConsumerWidget {
  const SyncTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitListProvider).valueOrNull ?? [];
    final primaryAccent = context.primaryAccent;
    final isDesktop = context.isDesktop;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24.w : 16.w,
        vertical: 10.h,
      ),
      children: [
        // Section Header
        Text(
          'CLOUD SYNC & BACKUPS',
          style: context.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: AppFontSizes.labelSmall,
            color: context.textMutedColor,
          ),
        ),
        SizedBox(height: 8.h),

        // Cloud Sync Hub Card
        AppCard(
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.pastelSurface(
                        primaryAccent,
                        isDark: context.isDarkMode,
                        opacity: 0.18,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_sync_rounded,
                      color: primaryAccent,
                      size: 22.r,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cloud Sync Hub',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.textPrimaryColor,
                            fontSize: AppFontSizes.subtitle,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Keep your habits in sync across all devices',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.textMutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              AppButton(
                text: 'Open Sync & Backup Studio',
                leadingIcon: const Icon(Icons.sync_rounded),
                fullWidth: true,
                onPressed: () => DataPortabilityDialog.show(context),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),

        // Supported Providers Status
        Text(
          'SYNC PROVIDERS',
          style: context.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            fontSize: AppFontSizes.labelSmall,
            color: context.textMutedColor,
          ),
        ),
        SizedBox(height: 8.h),

        _ProviderStatusTile(
          icon: Icons.cloud_outlined,
          title: 'Google Drive Sync',
          subtitle: 'Automatic OAuth backup to Google Drive',
          statusLabel: 'Available',
          accentColor: primaryAccent,
          onTap: () => DataPortabilityDialog.show(context),
        ),
        SizedBox(height: 8.h),

        _ProviderStatusTile(
          icon: Icons.cloud_done_rounded,
          title: 'Apple iCloud Sync',
          subtitle:
              defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS
              ? 'Native iCloud ubiquity container active'
              : 'Available on iOS and macOS devices',
          statusLabel:
              defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS
              ? 'Supported'
              : 'Platform Dependent',
          accentColor: context.secondaryAccent,
          onTap: () => DataPortabilityDialog.show(context),
        ),
        SizedBox(height: 10.h),

        // Local Database Stats
        AppCard(
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOCAL DATABASE METRICS',
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  fontSize: AppFontSizes.labelSmall,
                  color: context.textMutedColor,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tracked Habits',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${habits.length}',
                    style: context.textTheme.titleSmall?.copyWith(
                      color: primaryAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Engine Status',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Local-First & Offline Ready',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.textMutedColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Safe spacing for floating navbar
        SizedBox(height: 100.h),
      ],
    );
  }
}

class _ProviderStatusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color accentColor;
  final VoidCallback onTap;

  const _ProviderStatusTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      isInteractive: true,
      onTap: onTap,
      padding: EdgeInsets.all(12.r),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.pastelSurface(
                accentColor,
                isDark: context.isDarkMode,
                opacity: 0.16,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: AppIconSizes.md, color: accentColor),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                    fontSize: AppFontSizes.titleSmall,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.textMutedColor,
                  ),
                ),
              ],
            ),
          ),
          AppBadge(label: statusLabel, color: accentColor),
        ],
      ),
    );
  }
}
