import 'package:flutter/widgets.dart';

/// Layout breakpoints in logical pixels (never scaled).
abstract final class AppBreakpoints {
  /// At and above this width the app switches to the multi-column Bento layout
  /// and renders mobile design units 1:1.
  static const double desktop = 768.0;

  static bool isDesktopWidth(double width) => width >= desktop;
}

extension AppBreakpointsContext on BuildContext {
  /// Whether the current viewport uses the desktop/web Bento layout.
  bool get isDesktop =>
      AppBreakpoints.isDesktopWidth(MediaQuery.sizeOf(this).width);
}
