import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/haptics.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../data/models/habit_model.dart';
import '../../providers/habit_creator_form_provider.dart';
import '../../providers/habit_provider.dart';
import 'habit_creator_accent.dart';

/// Routine group chips, with a toggle into free-text custom group entry.
class HabitCreatorRoutineSection extends ConsumerWidget {
  final HabitModel? initialHabit;
  final TextEditingController customRoutineController;

  const HabitCreatorRoutineSection({
    super.key,
    required this.initialHabit,
    required this.customRoutineController,
  });

  static const List<String> defaultRoutines = [
    'Morning Routine',
    'Health',
    'Focus',
    'Evening Calm',
    'Fitness',
    'General',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userGroups = ref.watch(routineGroupsProvider);
    final formState = ref.watch(habitCreatorFormProvider(initialHabit));
    final formNotifier = ref.read(
      habitCreatorFormProvider(initialHabit).notifier,
    );
    final activeColor = resolveHabitCreatorAccent(context, formState);
    final allGroups = <String>{
      ...defaultRoutines,
      ...userGroups,
    }.where((g) => g != 'All').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('GROUP / ROUTINE', style: AppTextStyles.labelSmall(context)),
            GestureDetector(
              onTap: () {
                AppHaptics.selectionClick();
                formNotifier.toggleCustomRoutine();
              },
              child: Text(
                formState.isCreatingCustomRoutine
                    ? 'Choose from list'
                    : '+ Custom Group',
                style: context.textTheme.labelSmall?.copyWith(
                  color: activeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        if (formState.isCreatingCustomRoutine)
          AppTextField(
            controller: customRoutineController,
            hintText: 'e.g. Evening Wind Down',
            labelText: 'CUSTOM ROUTINE NAME',
            autofocus: true,
          )
        else
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: allGroups.map((group) {
              final isSelected = formState.selectedRoutine == group;
              return GestureDetector(
                onTap: () {
                  AppHaptics.selectionClick();
                  formNotifier.setRoutine(group);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.pastelSurface(
                            activeColor,
                            isDark: context.isDarkMode,
                            opacity: 0.22,
                          )
                        : context.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSelected ? activeColor : context.cardBorderColor,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    group,
                    style: context.textTheme.labelMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? activeColor
                          : context.textPrimaryColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
