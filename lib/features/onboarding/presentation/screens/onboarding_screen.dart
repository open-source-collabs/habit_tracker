import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../habits/data/models/starter_habits.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';

/// First-run flow: welcome & privacy promise, pick starter habits (no fake
/// history), then an in-context request for notification permission.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _pageCount = 3;

  final PageController _pages = PageController();
  final Set<String> _picked = {};
  int _page = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    AppHaptics.selectionClick();
    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish({bool askForReminders = false}) async {
    if (_finishing) return;
    setState(() => _finishing = true);

    if (askForReminders) {
      await ref.read(notificationSettingsProvider.notifier).requestPermission();
    }
    final picked = [
      for (final starter in StarterHabits.all)
        if (_picked.contains(starter.key)) starter,
    ];
    await ref.read(habitListProvider.notifier).completeOnboarding(picked);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back steps through the pages; on the first page it skips onboarding.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_page > 0) {
          _goTo(_page - 1);
        } else {
          _finish();
        }
      },
      child: Scaffold(
        backgroundColor: context.scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppSizes.pageMaxWidth),
              child: Column(
                children: [
                  _TopBar(
                    page: _page,
                    pageCount: _pageCount,
                    onSkip: _finishing ? null : _finish,
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (page) => setState(() => _page = page),
                      children: [
                        _WelcomePage(onNext: () => _goTo(1)),
                        _PickHabitsPage(
                          picked: _picked,
                          onToggle: (key) => setState(() {
                            AppHaptics.selectionClick();
                            _picked.contains(key)
                                ? _picked.remove(key)
                                : _picked.add(key);
                          }),
                          onNext: () => _goTo(2),
                        ),
                        _RemindersPage(
                          busy: _finishing,
                          onAllow: () => _finish(askForReminders: true),
                          onNotNow: _finish,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int page;
  final int pageCount;
  final VoidCallback? onSkip;

  const _TopBar({
    required this.page,
    required this.pageCount,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 8.w, 0),
      child: Row(
        children: [
          Semantics(
            label: 'Step ${page + 1} of $pageCount',
            child: Row(
              children: [
                for (var i = 0; i < pageCount; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: EdgeInsets.only(right: 6.w),
                    width: i == page ? 22.w : 8.w,
                    height: 8.r,
                    decoration: BoxDecoration(
                      color: i == page
                          ? context.primaryAccent
                          : context.cardBorderColor,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          AppButton(
            text: 'Skip',
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            onPressed: onSkip,
          ),
        ],
      ),
    );
  }
}

/// Shared layout: scrollable content with a pinned action area below.
class _PageLayout extends StatelessWidget {
  final List<Widget> children;
  final List<Widget> actions;

  const _PageLayout({required this.children, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: 24.h, bottom: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
          ...actions,
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  final String title;
  final String body;

  const _Headline({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.textPrimaryColor,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          body,
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;

  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      actions: [
        AppButton(text: 'Get started', fullWidth: true, onPressed: onNext),
      ],
      children: [
        Image.asset(
          AppAssets.appLogo,
          width: 80.r,
          height: 80.r,
          semanticLabel: 'Track Free logo',
        ),
        SizedBox(height: 24.h),
        const _Headline(
          title: 'Welcome to Track Free',
          body: 'Build habits one day at a time, with streaks, reminders and '
              'a calm Bento dashboard.',
        ),
        SizedBox(height: 24.h),
        const _Promise(
          icon: Icons.phone_android_rounded,
          title: 'Stays on your device',
          body: 'Your habits are stored locally and work fully offline.',
        ),
        const _Promise(
          icon: Icons.visibility_off_rounded,
          title: 'No account, no tracking',
          body: 'No sign-up, no ads and no analytics.',
        ),
        const _Promise(
          icon: Icons.cloud_rounded,
          title: 'Optional sync',
          body: 'Back up to your own iCloud or Google Drive if you want to.',
        ),
      ],
    );
  }
}

class _Promise extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Promise({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIconSizes.lg, color: context.primaryAccent),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  body,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickHabitsPage extends StatelessWidget {
  final Set<String> picked;
  final ValueChanged<String> onToggle;
  final VoidCallback onNext;

  const _PickHabitsPage({
    required this.picked,
    required this.onToggle,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final count = picked.length;
    return _PageLayout(
      actions: [
        AppButton(
          text: count == 0 ? 'Start from scratch' : 'Add $count & continue',
          fullWidth: true,
          onPressed: onNext,
        ),
      ],
      children: [
        const _Headline(
          title: 'Pick a few to start',
          body: 'Choose any suggestions you like — or none. You can edit them '
              'or add your own anytime.',
        ),
        SizedBox(height: 20.h),
        for (final starter in StarterHabits.all)
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _StarterTile(
              starter: starter,
              selected: picked.contains(starter.key),
              onTap: () => onToggle(starter.key),
            ),
          ),
      ],
    );
  }
}

class _StarterTile extends StatelessWidget {
  final StarterHabit starter;
  final bool selected;
  final VoidCallback onTap;

  const _StarterTile({
    required this.starter,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.accentPalette;
    final accent = palette.isEmpty
        ? context.primaryAccent
        : palette[starter.accentIndex % palette.length];

    return Semantics(
      button: true,
      selected: selected,
      label: starter.title,
      excludeSemantics: true,
      child: AppCard(
        isInteractive: true,
        onTap: onTap,
        padding: EdgeInsets.all(14.r),
        borderColor: selected ? accent : null,
        backgroundColor: selected
            ? AppColors.pastelSurface(accent, isDark: context.isDarkMode)
            : null,
        child: Row(
          children: [
            Text(starter.emoji, style: context.textTheme.headlineSmall),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    starter.title,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    starter.subtitle,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: AppIconSizes.xl,
              color: selected ? accent : context.textMutedColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _RemindersPage extends StatelessWidget {
  final bool busy;
  final VoidCallback onAllow;
  final VoidCallback onNotNow;

  const _RemindersPage({
    required this.busy,
    required this.onAllow,
    required this.onNotNow,
  });

  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      actions: [
        AppButton(
          text: 'Allow reminders',
          fullWidth: true,
          isLoading: busy,
          onPressed: busy ? null : onAllow,
        ),
        SizedBox(height: 8.h),
        AppButton(
          text: 'Not now',
          variant: AppButtonVariant.ghost,
          fullWidth: true,
          onPressed: busy ? null : onNotNow,
        ),
      ],
      children: [
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.pastelSurface(
              context.secondaryAccent,
              isDark: context.isDarkMode,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Icon(
            Icons.notifications_active_rounded,
            size: AppIconSizes.hero,
            color: context.secondaryAccent,
          ),
        ),
        SizedBox(height: 24.h),
        const _Headline(
          title: 'Gentle reminders',
          body: 'Set a time on any habit and Track Free reminds you then. '
              'Reminders are scheduled on your device and work offline. '
              'You can change this anytime in Settings.',
        ),
      ],
    );
  }
}
