import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_dimensions.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';

/// Tactile Bento card container with customizable padding, border radius,
/// optional spring scale on press, and glowing accent shadows.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? glowColor;
  final VoidCallback? onTap;
  final bool isInteractive;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.glowColor,
    this.onTap,
    this.isInteractive = false,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
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

  void _handleTap() {
    if (widget.onTap == null) return;
    AppHaptics.lightImpact();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final double radius = widget.borderRadius ?? 18.r;
    final Color bgColor = widget.backgroundColor ?? context.cardBackgroundColor;
    final Color bColor = widget.borderColor ?? context.cardBorderColor;

    List<BoxShadow> shadows = [];
    if (widget.glowColor != null) {
      shadows = [
        BoxShadow(
          color: widget.glowColor!.withValues(alpha: 0.35),
          blurRadius: 18,
          spreadRadius: 1,
          offset: const Offset(0, 3),
        ),
      ];
    } else {
      shadows = [
        BoxShadow(
          color: context.shadowColor,
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];
    }

    Widget content = Container(
      margin: widget.margin,
      padding: widget.padding ?? EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: bColor, width: AppSizes.borderWidth),
        boxShadow: shadows,
      ),
      child: widget.child,
    );

    if (widget.isInteractive || widget.onTap != null) {
      content = ScaleTransition(
        scale: _scaleAnimation,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _controller.forward(),
          onPointerUp: (_) => _controller.reverse(),
          onPointerCancel: (_) => _controller.reverse(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleTap,
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}
