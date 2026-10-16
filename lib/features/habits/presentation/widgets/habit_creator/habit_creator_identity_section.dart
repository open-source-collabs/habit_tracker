import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../themes/presentation/providers/theme_provider.dart';
import '../../../data/models/habit_model.dart';
import '../../providers/habit_creator_form_provider.dart';

/// Title (in the active theme font) and subtitle/notes inputs.
class HabitCreatorIdentitySection extends ConsumerWidget {
  final HabitModel? initialHabit;
  final TextEditingController titleController;
  final TextEditingController subtitleController;

  const HabitCreatorIdentitySection({
    super.key,
    required this.initialHabit,
    required this.titleController,
    required this.subtitleController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTheme = ref.watch(themeProvider).activeTheme;
    final formState = ref.watch(habitCreatorFormProvider(initialHabit));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: titleController,
          labelText: 'HABIT TITLE',
          hintText: 'e.g. 20 Minutes Deep Work',
          autofocus: initialHabit == null,
          showClearButton: true,
          errorText: formState.titleError,
          style: context.textTheme.titleSmall?.copyWith(
            fontFamily: activeTheme.fontFamily,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (val) {
            if (formState.titleError != null && val.trim().isNotEmpty) {
              ref
                  .read(habitCreatorFormProvider(initialHabit).notifier)
                  .clearTitleError();
            }
          },
        ),
        SizedBox(height: 10.h),
        AppTextField(
          controller: subtitleController,
          labelText: 'SUBTITLE / NOTES',
          hintText: 'e.g. Turn off notifications & focus',
          showClearButton: true,
        ),
      ],
    );
  }
}
