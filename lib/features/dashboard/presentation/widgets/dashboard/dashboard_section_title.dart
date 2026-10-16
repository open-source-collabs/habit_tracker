import 'package:flutter/material.dart';

import '../../../../../core/theme/app_font_sizes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../habits/presentation/providers/habit_provider.dart';

/// Small-caps caption above the habits feed: "ACTIVE HABITS", or
/// "ARCHIVED HABITS" while the archived filter is selected.
class DashboardSectionTitle extends StatelessWidget {
  final String activeFilter;

  const DashboardSectionTitle({super.key, required this.activeFilter});

  @override
  Widget build(BuildContext context) {
    return Text(
      activeFilter == kArchivedHabitsFilter
          ? 'ARCHIVED HABITS'
          : 'ACTIVE HABITS',
      style: context.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        fontSize: AppFontSizes.micro,
        color: context.textMutedColor,
      ),
    );
  }
}
