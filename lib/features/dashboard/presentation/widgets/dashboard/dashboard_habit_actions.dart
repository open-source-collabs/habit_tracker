import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/routes/routes.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../habits/data/models/habit_model.dart';
import '../../../../habits/presentation/providers/habit_provider.dart';

/// Edit, archive and delete-with-undo flows for habits on the dashboard.
///
/// Bound to the long-lived dashboard screen's [BuildContext] (not a card's),
/// so the undo snackbar still shows after the card leaves the feed — an
/// archived or deleted habit disappears from the filtered list immediately.
class DashboardHabitActions {
  final BuildContext context;
  final WidgetRef ref;

  const DashboardHabitActions({required this.context, required this.ref});

  /// Opens the habit editor.
  Future<HabitModel?> edit(HabitModel habit) =>
      AppNavigator.toEditHabit(context, habit);

  /// Archives an active habit or restores an archived one, offering undo.
  Future<void> toggleArchived(HabitModel habit) async {
    final archive = !habit.isArchived;
    final notifier = ref.read(habitListProvider.notifier);
    await notifier.setArchived(habit.id, archived: archive);
    if (!context.mounted) return;
    _showUndoSnackBar(
      archive
          ? '"${habit.title}" archived. Its history is kept.'
          : '"${habit.title}" is active again.',
      onUndo: () => notifier.setArchived(habit.id, archived: !archive),
    );
  }

  /// Confirms, then deletes a habit and its history, offering undo.
  Future<void> confirmDelete(HabitModel habit) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete "${habit.title}"?',
      message:
          'This removes the habit and its entire check-in history. '
          'To pause it and keep its history, archive it instead.',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final notifier = ref.read(habitListProvider.notifier);
    final removed = await notifier.deleteHabit(habit.id);
    if (removed == null || !context.mounted) return;
    _showUndoSnackBar(
      '"${habit.title}" deleted.',
      onUndo: () => notifier.restoreHabit(removed.habit, index: removed.index),
    );
  }

  void _showUndoSnackBar(String message, {required VoidCallback onUndo}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(label: 'Undo', onPressed: onUndo),
        ),
      );
  }
}
