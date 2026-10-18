import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_dimensions.dart';
import '../../../../habits/data/models/habit_model.dart';
import '../../../../habits/presentation/providers/habit_provider.dart';
import '../../../../habits/presentation/widgets/habit_card.dart';
import '../../../../habits/presentation/widgets/habit_extensions.dart';
import 'dashboard_habit_actions.dart';

/// One habit in the dashboard feed: a [BentoHabitCard] for [date] wired to
/// the shared edit / archive / delete-with-undo [actions]. Scrolls into view
/// and glows briefly when [highlightedHabitIdProvider] names it.
class DashboardHabitTile extends ConsumerStatefulWidget {
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
  ConsumerState<DashboardHabitTile> createState() => _DashboardHabitTileState();
}

class _DashboardHabitTileState extends ConsumerState<DashboardHabitTile> {
  static const Duration _highlightDuration = Duration(milliseconds: 1800);

  bool _highlighted = false;
  Timer? _clearTimer;

  @override
  void initState() {
    super.initState();
    // The feed may be built after the tap was handled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeHighlight(ref.read(highlightedHabitIdProvider));
    });
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }

  void _maybeHighlight(String? id) {
    if (id != widget.habit.id) return;
    ref.read(highlightedHabitIdProvider.notifier).state = null;
    setState(() => _highlighted = true);
    Scrollable.ensureVisible(
      context,
      alignment: 0.2,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    _clearTimer?.cancel();
    _clearTimer = Timer(_highlightDuration, () {
      if (mounted) setState(() => _highlighted = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(highlightedHabitIdProvider, (_, id) => _maybeHighlight(id));
    final habit = widget.habit;
    final actions = widget.actions;
    final accent = habit.resolveColor(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: _highlighted
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.45),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ]
              : const [],
        ),
        child: BentoHabitCard(
          key: ValueKey(habit.id),
          habit: habit,
          date: widget.date,
          onEdit: habit.isArchived ? null : () => actions.edit(habit),
          onArchiveToggle: () => actions.toggleArchived(habit),
          onDelete: () => actions.confirmDelete(habit),
        ),
      ),
    );
  }
}
