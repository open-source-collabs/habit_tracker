import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Centralized typographic scale in mobile design units.
///
/// Scaled getters (`.sp`) are bounded by the central `AppDesign` policy, so no
/// call site needs its own clamp. The `*Value` constants are the raw design
/// units used by `ThemeFactory`, which builds outside `ScreenUtilInit`.
abstract final class AppFontSizes {
  static const double displayLargeValue = 32;
  static const double displayMediumValue = 28;
  static const double displaySmallValue = 24;
  static const double headlineLargeValue = 22;
  static const double headlineMediumValue = 20;
  static const double headlineSmallValue = 18;
  static const double titleLargeValue = 18;
  static const double titleMediumValue = 16;
  static const double subtitleValue = 15;
  static const double titleSmallValue = 14;
  static const double bodyLargeValue = 16;
  static const double bodyMediumValue = 14;
  static const double captionValue = 13;
  static const double bodySmallValue = 12;
  static const double labelLargeValue = 14;
  static const double labelMediumValue = 12;
  static const double labelSmallValue = 11;
  static const double microValue = 10;
  static const double tinyValue = 9;
  static const double nanoValue = 8;

  // Display tier: Hero headings, large metrics, milestone banners
  static double get displayLarge => displayLargeValue.sp;
  static double get displayMedium => displayMediumValue.sp;
  static double get displaySmall => displaySmallValue.sp;

  // Headline tier: Screen headers, card section titles
  static double get headlineLarge => headlineLargeValue.sp;
  static double get headlineMedium => headlineMediumValue.sp;
  static double get headlineSmall => headlineSmallValue.sp;

  // Title tier: Card titles, modal headers, dialog titles
  static double get titleLarge => titleLargeValue.sp;
  static double get titleMedium => titleMediumValue.sp;
  static double get subtitle => subtitleValue.sp;
  static double get titleSmall => titleSmallValue.sp;

  // Body tier: Primary readable text, subtitles, dialog descriptions
  static double get bodyLarge => bodyLargeValue.sp;
  static double get bodyMedium => bodyMediumValue.sp;
  static double get caption => captionValue.sp;
  static double get bodySmall => bodySmallValue.sp;

  // Label & Micro tier: Buttons, badges, tabs, uppercase category pills
  static double get labelLarge => labelLargeValue.sp;
  static double get labelMedium => labelMediumValue.sp;
  static double get labelSmall => labelSmallValue.sp;
  static double get micro => microValue.sp;

  // Chart axis ticks and dense heatmap labels only
  static double get tiny => tinyValue.sp;
  static double get nano => nanoValue.sp;
}
