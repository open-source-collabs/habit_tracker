import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Centralized typographic scale using ScreenUtil (.sp) with desktop-safe clamps.
abstract final class AppFontSizes {
  // Display tier: Hero headings, large metrics, milestone banners
  static double get displayLarge => 32.sp;
  static double get displayMedium => 28.sp;
  static double get displaySmall => 24.sp;

  // Headline tier: Screen headers, card section titles
  static double get headlineLarge => 22.sp;
  static double get headlineMedium => 20.sp;
  static double get headlineSmall => 18.sp;

  // Title tier: Card titles, modal headers, dialog titles
  static double get titleLarge => 18.sp;
  static double get titleMedium => 16.sp;
  static double get titleSmall => 14.sp;

  // Body tier: Primary readable text, subtitles, dialog descriptions
  static double get bodyLarge => 16.sp;
  static double get bodyMedium => 14.sp;
  static double get bodySmall => 12.sp;

  // Label & Micro tier: Buttons, badges, tabs, uppercase category pills
  static double get labelLarge => 14.sp;
  static double get labelMedium => 12.sp;
  static double get labelSmall => 11.sp;
  static double get micro => 10.sp;
}
