import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../habits/data/models/habit_model.dart';
import '../../../../habits/presentation/widgets/habit_card.dart';
import 'dashboard_habit_actions.dart';

/// One habit in the dashboard feed: a [BentoHabitCard] for [date] wired to
/// the shared edit / archive / delete-with-undo [actions].
class DashboardHabitTile extends StatelessWidget {
  final HabitModel habit;
  final DateTime date;
  final DashboardHabitActions actions;

  const DashboardHabitTile({
    super.key,
    required this.habit,
    required this.date,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: BentoHabitCard(
        key: ValueKey(habit.id),
        habit: habit,
        date: date,
        onEdit: habit.isArchived ? null : () => actions.edit(habit),
        onArchiveToggle: () => actions.toggleArchived(habit),
        onDelete: () => actions.confirmDelete(habit),
      ),
    );
  }
}
