import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../habits/presentation/providers/habit_provider.dart';

/// "Favorite activities" pastel-tinted wellness card carousel directly from Reference Image 1.
class FavoriteActivitiesCarousel extends ConsumerWidget {
  const FavoriteActivitiesCarousel({super.key});

  static const List<({
    String title,
    String stat,
    IconData icon,
    Color accentColor,
    String routineGroup,
  })> _activities = [
    (
      title: 'Mind Detox',
      stat: '13h logged',
      icon: Icons.psychology_alt_rounded,
      accentColor: AppColors.neonLavender,
      routineGroup: 'Focus',
    ),
    (
      title: 'Gratitude Notes',
      stat: '34 entries',
      icon: Icons.wb_sunny_rounded,
      accentColor: AppColors.cyanGlow,
      routineGroup: 'Evening',
    ),
    (
      title: 'Conscious Breath',
      stat: '34 sessions',
      icon: Icons.spa_rounded,
      accentColor: AppColors.emeraldMint,
      routineGroup: 'Morning',
    ),
    (
      title: 'Strength Training',
      stat: '18 workouts',
      icon: Icons.fitness_center_rounded,
      accentColor: AppColors.sunsetCoral,
      routineGroup: 'Fitness',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(activeRoutineFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Text(
            'Favorite activities',
            style: context.textTheme.titleMedium?.copyWith(
              fontSize: 15.sp.clamp(14.0, 16.0),
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: context.textPrimaryColor,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 94.h.clamp(88.0, 102.0),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _activities.length,
            separatorBuilder: (context, index) =>
                SizedBox(width: 10.w.clamp(8.0, 14.0)),
            itemBuilder: (context, index) {
              final act = _activities[index];
              final isSelected = activeFilter.toLowerCase() == act.routineGroup.toLowerCase();

              // In light theme: soft pastel watercolor tint; in dark theme: ambient blended surface
              final bgColor = AppColors.pastelSurface(
                act.accentColor,
                isDark: context.isDarkMode,
                opacity: 0.16,
              );

              return GestureDetector(
                onTap: () {
                  AppHaptics.selectionClick();
                  final newFilter = isSelected ? 'All' : act.routineGroup;
                  ref.read(activeRoutineFilterProvider.notifier).state = newFilter;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 116.w.clamp(108.0, 130.0),
                  padding: EdgeInsets.all(10.r.clamp(8.0, 12.0)),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(18.r.clamp(14.0, 20.0)),
                    border: Border.all(
                      color: isSelected
                          ? act.accentColor
                          : act.accentColor.withValues(alpha: 0.25),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: act.accentColor.withValues(alpha: 0.35),
                              blurRadius: 10.r,
                              offset: Offset(0, 3.h),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              act.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.titleSmall?.copyWith(
                                fontSize: 12.sp.clamp(11.0, 13.0),
                                fontWeight: FontWeight.w700,
                                color: context.textPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              act.stat,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.labelSmall?.copyWith(
                                fontSize: 9.5.sp.clamp(8.5, 11.0),
                                fontWeight: FontWeight.w600,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w.clamp(2.0, 6.0)),
                          Container(
                            padding: EdgeInsets.all(5.r),
                            decoration: BoxDecoration(
                              color: act.accentColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              act.icon,
                              size: 16.sp.clamp(14.0, 18.0),
                              color: act.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
