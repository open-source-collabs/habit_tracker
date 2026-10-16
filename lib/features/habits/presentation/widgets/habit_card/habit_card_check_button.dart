import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_font_sizes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../data/models/habit_model.dart';
import '../habit_extensions.dart';

/// The round check-off button on a habit card.
///
/// Shows the habit's icon or emoji until it is done, then cross-fades to a
/// check mark on an accent fill. Springs down to 0.88 while pressed.
class HabitCardCheckButton extends StatefulWidget {
  final HabitModel habit;
  final bool isCompleted;
  final Color accentColor;
  final VoidCallback onTap;

  const HabitCardCheckButton({
    super.key,
    required this.habit,
    required this.isCompleted,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<HabitCardCheckButton> createState() => _HabitCardCheckButtonState();
}

class _HabitCardCheckButtonState extends State<HabitCardCheckButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 220),
  );

  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 0.88)
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

  String get _semanticsLabel {
    final title = widget.habit.title;
    if (widget.habit.isArchived) return '$title, archived';
    return '$title, ${widget.isCompleted ? 'done' : 'not done'}';
  }

  String? get _semanticsHint {
    if (widget.habit.isArchived) return null;
    return widget.isCompleted
        ? 'Double tap to undo'
        : 'Double tap to mark done';
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.isCompleted;
    final accent = widget.accentColor;

    return Semantics(
      button: true,
      enabled: !widget.habit.isArchived,
      toggled: isCompleted,
      label: _semanticsLabel,
      hint: _semanticsHint,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) => _pressController.reverse(),
        onTapCancel: () => _pressController.reverse(),
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? accent : AppColors.transparent,
              border: Border.all(
                color: isCompleted
                    ? accent
                    : context.cardBorderColor.withValues(alpha: 0.8),
                width: AppSizes.borderWidthSelected,
              ),
              boxShadow: isCompleted
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.45),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: _buildGlyph(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlyph(BuildContext context) {
    if (widget.isCompleted) {
      return Icon(
        Icons.check_rounded,
        key: const ValueKey('checked'),
        color: AppColors.white,
        size: AppIconSizes.xl,
      );
    }

    final icon = HabitIconRegistry.getIcon(widget.habit.iconCode);
    if (icon != null) {
      return Icon(
        icon,
        key: const ValueKey('unchecked_icon'),
        color: widget.accentColor,
        size: AppIconSizes.lg,
      );
    }

    return Text(
      widget.habit.displayEmoji,
      key: const ValueKey('unchecked'),
      style: context.textTheme.titleLarge?.copyWith(
        fontSize: AppFontSizes.titleLarge,
      ),
    );
  }
}
