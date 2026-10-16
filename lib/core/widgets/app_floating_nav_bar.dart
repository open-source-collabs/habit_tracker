import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_breakpoints.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_font_sizes.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';

/// Single item descriptor for [AppFloatingNavBar].
class AppFloatingNavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String? tooltip;
  final int? badgeCount;

  const AppFloatingNavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.tooltip,
    this.badgeCount,
  });
}

/// Tactile, responsive floating navigation bar with frosted glassmorphism,
/// animated active pill indicator, and an optional elevated central action button.
class AppFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppFloatingNavBarItem> items;
  final VoidCallback? onCenterActionPressed;
  final Widget? centerAction;
  final IconData centerActionIcon;
  final String centerActionTooltip;
  final EdgeInsetsGeometry? margin;
  final double maxWidth;

  const AppFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.onCenterActionPressed,
    this.centerAction,
    this.centerActionIcon = Icons.add_rounded,
    this.centerActionTooltip = 'New Habit',
    this.margin,
    this.maxWidth = 480.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final primaryAccent = context.primaryAccent;
    final isDark = context.isDarkMode;

    final effectiveMargin =
        margin ??
        EdgeInsets.only(
          left: isDesktop ? 24.w : 20.w,
          right: isDesktop ? 24.w : 20.w,
          bottom: isDesktop ? 18.h : 12.h,
        );

    final half = (items.length / 2).ceil();
    final leftItems = items.take(half).toList();
    final rightItems = items.skip(half).toList();

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: effectiveMargin,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: [
                BoxShadow(
                  color: context.shadowColor.withValues(
                    alpha: isDark ? 0.35 : 0.12,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: primaryAccent.withValues(alpha: isDark ? 0.10 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: context.cardBackgroundColor.withValues(
                      alpha: isDark ? 0.82 : 0.88,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: context.cardBorderColor.withValues(alpha: 0.8),
                      width: AppSizes.borderWidth,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Left navigation tabs
                      ...leftItems.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return Expanded(
                          child: _NavBarTabButton(
                            item: item,
                            isSelected: currentIndex == idx,
                            onTap: () => onTap(idx),
                          ),
                        );
                      }),

                      // Center action button (if provided)
                      if (centerAction != null || onCenterActionPressed != null)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.w),
                          child:
                              centerAction ??
                              _CenterActionButton(
                                icon: centerActionIcon,
                                tooltip: centerActionTooltip,
                                onPressed: onCenterActionPressed,
                              ),
                        ),

                      // Right navigation tabs
                      ...rightItems.asMap().entries.map((entry) {
                        final idx = half + entry.key;
                        final item = entry.value;
                        return Expanded(
                          child: _NavBarTabButton(
                            item: item,
                            isSelected: currentIndex == idx,
                            onTap: () => onTap(idx),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tactile interactive tab button with animated active indicator pill.
class _NavBarTabButton extends StatefulWidget {
  final AppFloatingNavBarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarTabButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavBarTabButton> createState() => _NavBarTabButtonState();
}

class _NavBarTabButtonState extends State<_NavBarTabButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTap() {
    AppHaptics.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final primaryAccent = context.primaryAccent;
    final isDark = context.isDarkMode;
    final isSelected = widget.isSelected;
    final item = widget.item;

    final activeSurface = AppColors.pastelSurface(
      primaryAccent,
      isDark: isDark,
      opacity: isDark ? 0.22 : 0.16,
    );

    return Semantics(
      label: item.tooltip ?? item.label,
      selected: isSelected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          _handleTap();
        },
        onTapCancel: () => _pressController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(vertical: 7.h, horizontal: 4.w),
            decoration: BoxDecoration(
              color: isSelected ? activeSurface : AppColors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: isSelected
                    ? primaryAccent.withValues(alpha: 0.35)
                    : AppColors.transparent,
                width: AppSizes.borderWidth,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedScale(
                      scale: isSelected ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                        size: AppIconSizes.lg,
                        color: isSelected
                            ? primaryAccent
                            : context.textMutedColor,
                      ),
                    ),
                    if (item.badgeCount != null && item.badgeCount! > 0)
                      Positioned(
                        right: -8.w,
                        top: -4.h,
                        child: Container(
                          padding: EdgeInsets.all(3.r),
                          decoration: BoxDecoration(
                            color: primaryAccent,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 14.r,
                            minHeight: 14.r,
                          ),
                          child: Text(
                            item.badgeCount! > 99
                                ? '99+'
                                : '${item.badgeCount}',
                            textAlign: TextAlign.center,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: context.onPrimaryColor,
                              fontSize: AppFontSizes.tiny,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 3.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? primaryAccent
                          : context.textMutedColor,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: AppFontSizes.micro,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// High-contrast tactile action pill in [primaryAccent].
class _CenterActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _CenterActionButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  State<_CenterActionButton> createState() => _CenterActionButtonState();
}

class _CenterActionButtonState extends State<_CenterActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    AppHaptics.mediumImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final primaryAccent = context.primaryAccent;

    return Semantics(
      label: widget.tooltip,
      button: true,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            _handlePress();
          },
          onTapCancel: () => _controller.reverse(),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 42.r,
              height: 42.r,
              decoration: BoxDecoration(
                color: primaryAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryAccent.withValues(alpha: 0.40),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: context.onPrimaryColor.withValues(alpha: 0.2),
                  width: AppSizes.borderWidthFocused,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    widget.icon,
                    color: context.onPrimaryColor,
                    size: AppIconSizes.xl,
                  ),
                  SizedBox(
                    width: 0,
                    height: 0,
                    child: OverflowBox(
                      minWidth: 0,
                      maxWidth: 0,
                      minHeight: 0,
                      maxHeight: 0,
                      child: Text(
                        widget.tooltip,
                        style: context.textTheme.labelSmall?.copyWith(
                          fontSize: 0,
                        ),
                      ),
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
