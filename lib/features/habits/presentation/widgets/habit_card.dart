import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../data/models/habit_model.dart';
import '../providers/habit_provider.dart';
import 'habit_extensions.dart';
import '../../../../presentation/widgets/heatmap_grid.dart';

/// Tactile Bento Habit Card adapting dynamically to the active Riverpod theme.
/// Features a 0.96 spring press-down animation, glowing completion shadow,
/// dynamic color badges, and an animated cross-fade check-off button.
class BentoHabitCard extends ConsumerStatefulWidget {
  final HabitModel habit;
  final DateTime date;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BentoHabitCard({
    super.key,
    required this.habit,
    required this.date,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  ConsumerState<BentoHabitCard> createState() => _BentoHabitCardState();
}

class _BentoHabitCardState extends ConsumerState<BentoHabitCard>
    with TickerProviderStateMixin {
  late final AnimationController _cardPressController;
  late final Animation<double> _cardScaleAnimation;

  late final AnimationController _checkPressController;
  late final Animation<double> _checkScaleAnimation;

  @override
  void initState() {
    super.initState();

    // 0.96 Card Spring Animation
    _cardPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 280),
    );

    _cardScaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _cardPressController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
    );

    // Spring Animation for the Check-off Button
    _checkPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _checkScaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(
        parent: _checkPressController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _cardPressController.dispose();
    _checkPressController.dispose();
    super.dispose();
  }

  void _handleToggle() {
    AppHaptics.lightImpact();
    if (widget.onToggle != null) {
      widget.onToggle!();
    } else {
      ref
          .read(habitListProvider.notifier)
          .toggleHabit(widget.habit.id, widget.date);
    }
  }

  String _formatFrequency(HabitFrequency freq) {
    switch (freq.type) {
      case HabitFrequencyType.daily:
        return 'Daily';
      case HabitFrequencyType.specificWeekdays:
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        if (freq.daysOfWeek.length == 7) return 'Daily';
        if (freq.daysOfWeek.length == 5 &&
            freq.daysOfWeek.contains(1) &&
            freq.daysOfWeek.contains(2) &&
            freq.daysOfWeek.contains(3) &&
            freq.daysOfWeek.contains(4) &&
            freq.daysOfWeek.contains(5)) {
          return 'Weekdays';
        }
        return freq.daysOfWeek.map((d) => days[(d - 1).clamp(0, 6)]).join(', ');
      case HabitFrequencyType.timesPerWeek:
        return '${freq.targetTimesPerWeek}x / wk';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.habit.resolveColor(context);
    final showHeatmap = ref.watch(habitHeatmapExpandedProvider(widget.habit.id));

    final isCompleted = widget.habit.isCompletedOn(widget.date);
    final currentStreak = widget.habit.calculateCurrentStreak(asOf: widget.date);

    return ScaleTransition(
      scale: _cardScaleAnimation,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _cardPressController.forward(),
        onPointerUp: (_) => _cardPressController.reverse(),
        onPointerCancel: (_) => _cardPressController.reverse(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: 14.r.clamp(12.0, 18.0),
              vertical: 12.r.clamp(10.0, 16.0),
            ),
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(20.r.clamp(16.0, 22.0)),
              border: Border.all(
                color: isCompleted
                    ? accentColor
                    : context.cardBorderColor,
                width: 1.2,
              ),
              boxShadow: isCompleted
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.35),
                        blurRadius: 16.r,
                        spreadRadius: 0,
                        offset: Offset(0, 3.h),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: context.shadowColor,
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Spring Check-off Circle
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => _checkPressController.forward(),
                  onTapUp: (_) => _checkPressController.reverse(),
                  onTapCancel: () => _checkPressController.reverse(),
                  onTap: _handleToggle,
                  child: ScaleTransition(
                    scale: _checkScaleAnimation,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: 40.r.clamp(36.0, 44.0),
                      height: 40.r.clamp(36.0, 44.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? accentColor : AppColors.transparent,
                        border: Border.all(
                          color: isCompleted
                              ? accentColor
                              : context.cardBorderColor.withValues(alpha: 0.8),
                          width: 2.0,
                        ),
                        boxShadow: isCompleted
                            ? [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.45),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: isCompleted
                              ? Icon(
                                  Icons.check_rounded,
                                  key: const ValueKey('checked'),
                                  color: AppColors.white,
                                  size: 22.sp,
                                )
                              : (widget.habit.iconCode != null &&
                                      HabitIconRegistry.getIcon(widget.habit.iconCode) != null)
                                  ? Icon(
                                      HabitIconRegistry.getIcon(widget.habit.iconCode)!,
                                      key: const ValueKey('unchecked_icon'),
                                      color: accentColor,
                                      size: 20.sp,
                                    )
                                  : Text(
                                      widget.habit.displayEmoji,
                                      key: const ValueKey('unchecked'),
                                      style: TextStyle(fontSize: 18.sp),
                                    ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w.clamp(10.0, 16.0)),

                // Title, Subtitle, and Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.habit.title,
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: context.textPrimaryColor,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: context.textPrimaryColor
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          if (widget.onEdit != null || widget.onDelete != null)
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                size: 18.sp,
                                color: context.textMutedColor,
                              ),
                              color: context.cardBackgroundColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                side: BorderSide(
                                  color: context.cardBorderColor,
                                  width: 1.2,
                                ),
                              ),
                              onSelected: (val) {
                                if (val == 'edit' && widget.onEdit != null) {
                                  widget.onEdit!();
                                } else if (val == 'delete' &&
                                    widget.onDelete != null) {
                                  widget.onDelete!();
                                }
                              },
                              itemBuilder: (menuContext) => [
                                if (widget.onEdit != null)
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined,
                                            size: 16.sp,
                                            color: context.textPrimaryColor),
                                        SizedBox(width: 8.w),
                                        Text('Edit',
                                            style: context.textTheme.bodyMedium?.copyWith(
                                                color: context.textPrimaryColor)),
                                      ],
                                    ),
                                  ),
                                if (widget.onDelete != null)
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline,
                                            size: 16.sp, color: context.colorScheme.error),
                                        SizedBox(width: 8.w),
                                        Text('Delete',
                                            style: context.textTheme.bodyMedium?.copyWith(
                                                color: context.colorScheme.error)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                      if (widget.habit.subtitle.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          widget.habit.subtitle,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.textSecondaryColor,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                      SizedBox(height: 8.h),

                      // Bento Micro-Pills (Routine, Frequency, Streak)
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 4.h,
                        children: [
                          // Routine Group Pill
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? context.surfaceElevatedColor
                                  : context.cardBorderColor.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              widget.habit.routineGroup,
                              style: context.textTheme.labelSmall?.copyWith(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimaryColor,
                              ),
                            ),
                          ),

                          // Frequency Pill
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? context.surfaceElevatedColor
                                  : context.cardBorderColor.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              _formatFrequency(widget.habit.frequency),
                              style: context.textTheme.labelSmall?.copyWith(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimaryColor,
                              ),
                            ),
                          ),

                          // Streak Fire Badge
                          if (currentStreak > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_fire_department_rounded,
                                    size: 13.sp,
                                    color: accentColor,
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    '$currentStreak days',
                                    style: context.textTheme.labelSmall?.copyWith(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w800,
                                      color: accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Heatmap Toggle Pill
                          GestureDetector(
                            onTap: () {
                              AppHaptics.selectionClick();
                              ref
                                  .read(habitHeatmapExpandedProvider(
                                          widget.habit.id)
                                      .notifier)
                                  .state = !showHeatmap;
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 7.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: showHeatmap
                                    ? accentColor.withValues(alpha: 0.18)
                                    : (context.isDarkMode
                                        ? context.surfaceElevatedColor
                                        : context.cardBorderColor.withValues(alpha: 0.4)),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: showHeatmap
                                      ? accentColor
                                      : AppColors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_view_week_rounded,
                                    size: 11.sp,
                                    color: showHeatmap
                                        ? accentColor
                                        : context.textMutedColor,
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    'Heatmap',
                                    style: context.textTheme.labelSmall?.copyWith(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: showHeatmap
                                          ? accentColor
                                          : context.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Expandable Heatmap Grid
            if (showHeatmap) ...[
              SizedBox(height: 14.h),
              HeatmapGrid(
                checkIns: widget.habit.checkIns,
                activeColor: accentColor,
                initialRangeDays: 60,
                showHeader: false,
                showRangeSelector: true,
              ),
            ],
          ],
        ),
          ),
        ),
      ),
    );
  }
}
