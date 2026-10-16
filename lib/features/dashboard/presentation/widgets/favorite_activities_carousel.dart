import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_font_sizes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../habits/data/models/habit_model.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../habits/presentation/widgets/habit_extensions.dart';

/// The user's strongest active habits, ranked by current streak (then total
/// check-ins). Tapping a card filters the feed to that habit's routine.
final topHabitsProvider = Provider<List<HabitModel>>((ref) {
  final habits = ref.watch(habitListProvider).valueOrNull ?? const [];
  final asOf = ref.watch(selectedDateProvider);

  final ranked =
      habits
          .where((h) => !h.isArchived)
          .map(
            (h) => (
              habit: h,
              streak: h.calculateCurrentStreak(asOf: asOf),
              total: h.checkIns.values.where((done) => done).length,
            ),
          )
          .where((e) => e.total > 0)
          .toList()
        ..sort((a, b) {
          final byStreak = b.streak.compareTo(a.streak);
          return byStreak != 0 ? byStreak : b.total.compareTo(a.total);
        });
  return ranked.take(4).map((e) => e.habit).toList();
});

/// Pastel-tinted carousel of the user's top habits.
class FavoriteActivitiesCarousel extends ConsumerWidget {
  const FavoriteActivitiesCarousel({super.key});

  static String _statLabel(HabitModel habit, DateTime asOf) {
    final streak = habit.calculateCurrentStreak(asOf: asOf);
    if (streak > 0) {
      final unit = habit.frequency.type == HabitFrequencyType.timesPerWeek
          ? (streak == 1 ? 'week' : 'weeks')
          : (streak == 1 ? 'day' : 'days');
      return '$streak $unit streak';
    }
    final total = habit.checkIns.values.where((done) => done).length;
    return '$total check-in${total == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(activeRoutineFilterProvider);
    final asOf = ref.watch(selectedDateProvider);
    final topHabits = ref.watch(topHabitsProvider);
    if (topHabits.isEmpty) return const SizedBox.shrink();

    final activities = topHabits
        .map(
          (h) => (
            title: h.title,
            stat: _statLabel(h, asOf),
            icon: HabitIconRegistry.getIcon(h.iconCode),
            emoji: h.displayEmoji,
            accentColor: h.resolveColor(context),
            routineGroup: h.routineGroup,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Text(
            'Top streaks',
            style: context.textTheme.titleMedium?.copyWith(
              fontSize: AppFontSizes.subtitle,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: context.textPrimaryColor,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 94.w,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: activities.length,
            separatorBuilder: (context, index) => SizedBox(width: 10.w),
            itemBuilder: (context, index) {
              final act = activities[index];
              final isSelected =
                  activeFilter.toLowerCase() == act.routineGroup.toLowerCase();

              // In light theme: soft pastel watercolor tint; in dark theme: ambient blended surface
              final bgColor = AppColors.pastelSurface(
                act.accentColor,
                isDark: context.isDarkMode,
                opacity: 0.16,
              );

              return GestureDetector(
                onTap: () {
                  AppHaptics.selectionClick();
                  final newFilter = isSelected
                      ? kAllHabitsFilter
                      : act.routineGroup;
                  ref.read(activeRoutineFilterProvider.notifier).state =
                      newFilter;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 116.w,
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(18.r),
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
                              blurRadius: 10,
                              offset: const Offset(0, 3),
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
                                fontSize: AppFontSizes.labelMedium,
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
                                fontSize: AppFontSizes.tiny,
                                fontWeight: FontWeight.w600,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Container(
                            padding: EdgeInsets.all(5.r),
                            decoration: BoxDecoration(
                              color: act.accentColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: act.icon != null
                                ? Icon(
                                    act.icon,
                                    size: AppIconSizes.sm,
                                    color: act.accentColor,
                                  )
                                : Text(
                                    act.emoji,
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                          fontSize: AppFontSizes.caption,
                                        ),
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
