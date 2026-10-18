import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_font_sizes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../data/models/habit_model.dart';
import '../providers/habit_provider.dart';
import 'habit_card/habit_card_actions_menu.dart';
import 'habit_card/habit_card_check_button.dart';
import 'habit_card/habit_card_pills.dart';
import 'habit_extensions.dart';
import 'heatmap_grid.dart';

/// Tactile Bento Habit Card adapting dynamically to the active Riverpod theme.
/// Features a 0.96 spring press-down animation, glowing completion shadow,
/// dynamic color badges, and an animated cross-fade check-off button.
class BentoHabitCard extends ConsumerStatefulWidget {
  final HabitModel habit;
  final DateTime date;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Archives an active habit or unarchives an archived one.
  final VoidCallback? onArchiveToggle;

  const BentoHabitCard({
    super.key,
    required this.habit,
    required this.date,
    this.onToggle,
    this.onEdit,
    this.onDelete,
    this.onArchiveToggle,
  });

  bool get _hasActions =>
      onEdit != null || onDelete != null || onArchiveToggle != null;

  @override
  ConsumerState<BentoHabitCard> createState() => _BentoHabitCardState();
}

class _BentoHabitCardState extends ConsumerState<BentoHabitCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 280),
  );

  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 0.96)
      .animate(
        CurvedAnimation(
          parent: _pressController,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.elasticOut,
        ),
      );

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleToggle() {
    // Archived habits are paused and can't be checked off.
    if (widget.habit.isArchived) return;
    AppHaptics.lightImpact();
    final onToggle = widget.onToggle;
    if (onToggle != null) {
      onToggle();
    } else {
      ref
          .read(habitListProvider.notifier)
          .toggleHabit(widget.habit.id, widget.date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final accentColor = habit.resolveColor(context);
    final showHeatmap = ref.watch(habitHeatmapExpandedProvider(habit.id));
    final isCompleted = habit.isCompletedOn(widget.date);
    final currentStreak = habit.calculateCurrentStreak(asOf: widget.date);

    return Opacity(
      opacity: habit.isArchived ? 0.6 : 1.0,
      child: ScaleTransition(
        scale: _scale,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _pressController.forward(),
          onPointerUp: (_) => _pressController.reverse(),
          onPointerCancel: (_) => _pressController.reverse(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: _decoration(context, accentColor, isCompleted),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HabitCardCheckButton(
                        habit: habit,
                        isCompleted: isCompleted,
                        accentColor: accentColor,
                        onTap: _handleToggle,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildDetails(
                          context,
                          accentColor: accentColor,
                          isCompleted: isCompleted,
                          currentStreak: currentStreak,
                        ),
                      ),
                    ],
                  ),
                  if (showHeatmap) ...[
                    SizedBox(height: 14.h),
                    HeatmapGrid(
                      checkIns: habit.checkIns,
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
      ),
    );
  }

  /// Card surface: accent border and glow when done, soft shadow otherwise.
  BoxDecoration _decoration(
    BuildContext context,
    Color accentColor,
    bool isCompleted,
  ) {
    return BoxDecoration(
      color: context.cardBackgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      border: Border.all(
        color: isCompleted ? accentColor : context.cardBorderColor,
        width: AppSizes.borderWidth,
      ),
      boxShadow: [
        if (isCompleted)
          BoxShadow(
            color: accentColor.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 3),
          )
        else
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
      ],
    );
  }

  /// Title (struck through when done), actions menu, subtitle and pills.
  Widget _buildDetails(
    BuildContext context, {
    required Color accentColor,
    required bool isCompleted,
    required int currentStreak,
  }) {
    final habit = widget.habit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                habit.title,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: context.textPrimaryColor.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
            ),
            HabitCardHeatmapToggle(habit: habit, accentColor: accentColor),
            if (widget._hasActions)
              HabitCardActionsMenu(
                isArchived: habit.isArchived,
                onEdit: widget.onEdit,
                onArchiveToggle: widget.onArchiveToggle,
                onDelete: widget.onDelete,
              ),
          ],
        ),
        if (habit.subtitle.isNotEmpty) ...[
          SizedBox(height: 2.h),
          Text(
            habit.subtitle,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.textSecondaryColor,
              fontSize: AppFontSizes.bodySmall,
            ),
          ),
        ],
        SizedBox(height: 6.h),
        HabitCardPills(
          habit: habit,
          currentStreak: currentStreak,
          accentColor: accentColor,
        ),
      ],
    );
  }
}
