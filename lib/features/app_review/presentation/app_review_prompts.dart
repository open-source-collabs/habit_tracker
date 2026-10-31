import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_links.dart';
import '../../../core/routes/routes.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../habits/data/models/habit_model.dart';
import '../../settings/presentation/widgets/about_links.dart';
import 'providers/review_prompt_service.dart';

enum ReviewAnswer { happy, unhappy, never }

bool _asking = false;

/// Whether the user is on the root dashboard with nothing open over it, so a
/// prompt never interrupts editing, a sheet or another dialog.
bool get _isIdleOnDashboard =>
    AppRouter.navigatorKey.currentState?.canPop() == false;

/// Asks for a store review when the moment is right (see
/// [ReviewPromptService.shouldAsk]). A friendly pre-prompt comes first, so
/// only happy users are sent to the public review sheet.
Future<void> maybeAskForReview(
  WidgetRef ref,
  List<HabitModel> habits,
) async {
  if (_asking) return;
  final service = ref.read(reviewPromptServiceProvider);
  if (!await service.shouldAsk(habits) || !_isIdleOnDashboard) return;

  final context = AppRouter.navigatorKey.currentState?.overlay?.context;
  if (context == null || !context.mounted) return;

  _asking = true;
  try {
    // Counted whether or not it is answered: dismissing is also an answer.
    await service.recordAsked();
    if (!context.mounted) return;
    final answer = await showAppDialog<ReviewAnswer>(
      context: context,
      builder: (ctx) => _ReviewPreDialog(),
    );
    switch (answer) {
      case ReviewAnswer.happy:
        await service.markFinished();
        await service.requestReview();
      case ReviewAnswer.unhappy:
        await _offerFeedback();
      case ReviewAnswer.never:
        await service.markFinished();
      case null:
        break;
    }
  } finally {
    _asking = false;
  }
}

/// Unhappy users are invited to tell us privately instead.
Future<void> _offerFeedback() async {
  final feedback = AppLinks.feedbackEmail;
  final context = AppRouter.navigatorKey.currentState?.overlay?.context;
  if (feedback != null && context != null && context.mounted) {
    await openExternalLink(context, feedback);
    return;
  }
  AppRouter.scaffoldMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text('Thanks for letting us know. We keep improving.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

class _ReviewPreDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppDialog(
      icon: Icon(
        Icons.favorite_rounded,
        color: context.primaryAccent,
        size: AppIconSizes.xl,
      ),
      title: 'Enjoying Track Free?',
      message: 'Your habits are going well. A quick rating on Google Play '
          'helps others find the app.',
      content: Align(
        alignment: Alignment.centerLeft,
        child: AppButton(
          text: "Don't ask again",
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.sm,
          onPressed: () => Navigator.of(context).pop(ReviewAnswer.never),
        ),
      ),
      confirmText: 'Yes, rate it',
      cancelText: 'Not really',
      onConfirm: () => Navigator.of(context).pop(ReviewAnswer.happy),
      onCancel: () => Navigator.of(context).pop(ReviewAnswer.unhappy),
    );
  }
}
