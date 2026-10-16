import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_font_sizes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/haptics.dart';
import '../../../../habits/presentation/providers/habit_provider.dart';

/// Horizontally scrolling routine filter chips ("All", each routine,
/// "Archived") driving [activeRoutineFilterProvider].
class DashboardFilterChips extends ConsumerWidget {
  const DashboardFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineGroups = ref.watch(routineGroupsProvider);
    final activeFilter = ref.watch(activeRoutineFilterProvider);
    final primaryAccent = context.primaryAccent;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: routineGroups.map((group) {
          final isSelected = activeFilter.toLowerCase() == group.toLowerCase();

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              label: Text(group),
              selected: isSelected,
              onSelected: (_) {
                AppHaptics.selectionClick();
                ref.read(activeRoutineFilterProvider.notifier).state = group;
              },
              selectedColor: primaryAccent,
              backgroundColor: context.cardBackgroundColor,
              labelStyle: context.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? context.onPrimaryColor
                    : context.textPrimaryColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: AppFontSizes.labelMedium,
              ),
              side: BorderSide(
                color: isSelected ? primaryAccent : context.cardBorderColor,
                width: AppSizes.borderWidth,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
