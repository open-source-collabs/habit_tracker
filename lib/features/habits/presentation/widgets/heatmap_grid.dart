import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_font_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../data/models/habit_model.dart';
import '../providers/heatmap_grid_provider.dart';
import 'habit_extensions.dart';

/// Dynamic 30–90 Day Activity Heatmap Calendar Grid.
/// Renders 10x10 dp rounded day squares with 3px border radius.
/// Completed days illuminate with the habit's dynamic theme/custom accent color,
/// while inactive squares reflect the active theme's card border tint.
class HeatmapGrid extends ConsumerStatefulWidget {
  /// Date-keyed completions ("YYYY-MM-DD" -> true).
  final Map<String, bool> checkIns;

  /// Dynamic illumination color for completed check-ins.
  final Color activeColor;

  /// Initial range in days (typically 30, 60, or 90). Defaults to 90.
  final int initialRangeDays;

  /// Anchor reference date (defaults to DateTime.now()).
  final DateTime? referenceDate;

  /// Optional callback when a day square is tapped.
  final ValueChanged<DateTime>? onDaySelected;

  /// Whether to display the range switcher pills (30D / 60D / 90D).
  final bool showRangeSelector;

  /// Whether to display completion stats summary header.
  final bool showHeader;

  /// Whether to display weekday abbreviations (M, W, F).
  final bool showWeekdayLabels;

  const HeatmapGrid({
    super.key,
    required this.checkIns,
    required this.activeColor,
    this.initialRangeDays = 90,
    this.referenceDate,
    this.onDaySelected,
    this.showRangeSelector = true,
    this.showHeader = true,
    this.showWeekdayLabels = true,
  });

  /// Factory creating [HeatmapGrid] directly from a [HabitModel].
  factory HeatmapGrid.fromHabit({
    Key? key,
    required HabitModel habit,
    required BuildContext context,
    int initialRangeDays = 90,
    DateTime? referenceDate,
    ValueChanged<DateTime>? onDaySelected,
    bool showRangeSelector = true,
    bool showHeader = true,
    bool showWeekdayLabels = true,
  }) {
    return HeatmapGrid(
      key: key,
      checkIns: habit.checkIns,
      activeColor: habit.resolveColor(context),
      initialRangeDays: initialRangeDays,
      referenceDate: referenceDate,
      onDaySelected: onDaySelected,
      showRangeSelector: showRangeSelector,
      showHeader: showHeader,
      showWeekdayLabels: showWeekdayLabels,
    );
  }

  @override
  ConsumerState<HeatmapGrid> createState() => _HeatmapGridState();
}

class _HeatmapGridState extends ConsumerState<HeatmapGrid> {
  late final HeatmapRangeParams _rangeParams = HeatmapRangeParams(
    id: 'heatmap_${identityHashCode(this)}',
    initialDays: widget.initialRangeDays,
  );

  @override
  void didUpdateWidget(covariant HeatmapGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRangeDays != widget.initialRangeDays) {
      ref
          .read(heatmapRangeDaysProvider(_rangeParams).notifier)
          .setDays(widget.initialRangeDays);
    }
  }

  DateTime get _today {
    final refDate = widget.referenceDate ?? DateTime.now();
    return DateTime(refDate.year, refDate.month, refDate.day);
  }

  String _formatDateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _formatTooltipDate(DateTime d) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final w = weekdays[(d.weekday - 1).clamp(0, 6)];
    final m = months[(d.month - 1).clamp(0, 11)];
    return '$w, $m ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final selectedRangeDays = ref.watch(heatmapRangeDaysProvider(_rangeParams));
    final today = _today;
    final startDate = today.subtract(Duration(days: selectedRangeDays - 1));

    // Align to the Monday of the start week
    final startMonday = startDate.subtract(
      Duration(days: startDate.weekday - 1),
    );

    // Count weeks to render
    final totalDaysBetween = today.difference(startMonday).inDays + 1;
    final weekColumns = (totalDaysBetween / 7).ceil();

    // Compute stats within the selected range
    int completedCount = 0;
    for (int i = 0; i < selectedRangeDays; i++) {
      final d = startDate.add(Duration(days: i));
      if (widget.checkIns[_formatDateKey(d)] == true) {
        completedCount++;
      }
    }
    final consistencyPercent = selectedRangeDays > 0
        ? ((completedCount / selectedRangeDays) * 100).round()
        : 0;

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: context.cardBorderColor,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showHeader) ...[
            _buildHeader(
              context,
              completedCount: completedCount,
              totalDays: selectedRangeDays,
              percentage: consistencyPercent,
              selectedRangeDays: selectedRangeDays,
            ),
            SizedBox(height: 8.h),
          ],

          // Heatmap grid container
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showWeekdayLabels) ...[
                  _buildWeekdayLabels(context),
                  SizedBox(width: 6.w),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(weekColumns, (colIdx) {
                    return Padding(
                      padding: EdgeInsets.only(right: 3.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(7, (rowIdx) {
                          final cellDate = startMonday.add(
                            Duration(days: colIdx * 7 + rowIdx),
                          );

                          return Padding(
                            padding: EdgeInsets.only(bottom: 3.h),
                            child: _buildDaySquare(
                              context,
                              date: cellDate,
                              startDate: startDate,
                              today: today,
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          if (widget.showRangeSelector) ...[
            SizedBox(height: 8.h),
            _buildRangeSelector(context, selectedRangeDays: selectedRangeDays),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required int completedCount,
    required int totalDays,
    required int percentage,
    required int selectedRangeDays,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ACTIVITY HEATMAP', style: AppTextStyles.labelSmall(context)),
            SizedBox(height: 2.h),
            Text(
              '$completedCount / $totalDays days completed ($percentage%)',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: AppColors.pastelSurface(
              widget.activeColor,
              isDark: context.isDarkMode,
              opacity: 0.20,
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: widget.activeColor.withValues(alpha: 0.6),
              width: AppSizes.borderWidth,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6.r,
                height: 6.r,
                decoration: BoxDecoration(
                  color: widget.activeColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 5.w),
              Text(
                '$selectedRangeDays Days',
                style: context.textTheme.labelSmall?.copyWith(
                  color: widget.activeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels(BuildContext context) {
    const labels = ['M', '', 'W', '', 'F', '', 'S'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (i) {
        return Container(
          width: 12.w,
          height: 10.r, // Matches 10x10 day square
          margin: EdgeInsets.only(bottom: 3.h),
          alignment: Alignment.center,
          child: Text(
            labels[i],
            style: context.textTheme.labelSmall?.copyWith(
              fontSize: AppFontSizes.nano,
              color: context.textMutedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDaySquare(
    BuildContext context, {
    required DateTime date,
    required DateTime startDate,
    required DateTime today,
  }) {
    // If out of range (before startDate or in the future after today)
    final isBeforeStart = date.isBefore(startDate);
    final isFuture = date.isAfter(today);

    if (isBeforeStart || isFuture) {
      return SizedBox(width: 10.r, height: 10.r);
    }

    final key = _formatDateKey(date);
    final isCompleted = widget.checkIns[key] == true;

    final tooltipText = isCompleted
        ? '${_formatTooltipDate(date)}: Completed ✅'
        : '${_formatTooltipDate(date)}: Incomplete';

    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.hairline),
      color: isCompleted
          ? widget.activeColor
          : context.cardBorderColor.withValues(alpha: 0.35),
      border: Border.all(
        color: isCompleted
            ? widget.activeColor
            : context.cardBorderColor.withValues(alpha: 0.7),
        width: AppSizes.borderWidth,
      ),
      boxShadow: isCompleted
          ? [
              BoxShadow(
                color: widget.activeColor.withValues(alpha: 0.45),
                blurRadius: 3.0,
                spreadRadius: 0,
              ),
            ]
          : null,
    );

    return Tooltip(
      message: tooltipText,
      preferBelow: false,
      verticalOffset: 12.0,
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: context.cardBorderColor,
          width: AppSizes.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      textStyle: context.textTheme.labelSmall?.copyWith(
        color: context.textPrimaryColor,
        fontWeight: FontWeight.w600,
      ),
      child: InkWell(
        onTap: widget.onDaySelected != null
            ? () {
                AppHaptics.selectionClick();
                widget.onDaySelected!(date);
              }
            : null,
        borderRadius: BorderRadius.circular(AppRadius.hairline),
        child: Container(width: 10.r, height: 10.r, decoration: decoration),
      ),
    );
  }

  Widget _buildRangeSelector(
    BuildContext context, {
    required int selectedRangeDays,
  }) {
    const options = [30, 60, 90];

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Range: ',
          style: context.textTheme.labelSmall?.copyWith(
            color: context.textMutedColor,
          ),
        ),
        SizedBox(width: 4.w),
        ...options.map((days) {
          final isSelected = selectedRangeDays == days;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: GestureDetector(
              onTap: () {
                AppHaptics.selectionClick();
                ref
                    .read(heatmapRangeDaysProvider(_rangeParams).notifier)
                    .setDays(days);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.pastelSurface(
                          widget.activeColor,
                          isDark: context.isDarkMode,
                          opacity: 0.22,
                        )
                      : context.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: isSelected
                        ? widget.activeColor
                        : context.cardBorderColor,
                    width: AppSizes.borderWidth,
                  ),
                ),
                child: Text(
                  '${days}D',
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? widget.activeColor
                        : context.textSecondaryColor,
                    fontSize: AppFontSizes.tiny,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
