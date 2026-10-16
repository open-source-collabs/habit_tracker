import 'package:flutter/painting.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_breakpoints.dart';

/// Mobile design artboard and the single, central ScreenUtil scaling policy.
///
/// Every dimension in the app is authored in mobile design units measured on
/// the [size] artboard (iPhone 14, 390×844). Widgets write those units with
/// `.w` / `.h` / `.r` / `.sp` and never clamp them locally — the bounds below
/// are applied once, here, for the whole app.
abstract final class AppDesign {
  /// The mobile artboard every dimension is measured against.
  static const Size size = Size(390, 844);

  /// Lower scale bound: protects legibility on very small or very short screens.
  static const double minScale = 0.8;

  /// Upper scale bound: stops large phones and foldables from ballooning.
  static const double maxScale = 1.15;

  /// Returns the design size handed to `ScreenUtilInit` for a given [screen].
  ///
  /// - Mobile (< [AppBreakpoints.desktop]): scale follows the screen relative
  ///   to [size], bounded to [[minScale], [maxScale]] on each axis.
  /// - Desktop/Web (≥ [AppBreakpoints.desktop]): scale is exactly 1.0, so
  ///   mobile design units render 1:1 as logical pixels and Bento columns are
  ///   sized by layout, not by a 3× width multiplier.
  static Size designSizeFor(Size screen) {
    if (screen.isEmpty) return size;
    if (AppBreakpoints.isDesktopWidth(screen.width)) return screen;

    final scaleWidth = (screen.width / size.width).clamp(minScale, maxScale);
    final scaleHeight = (screen.height / size.height).clamp(minScale, maxScale);
    return Size(screen.width / scaleWidth, screen.height / scaleHeight);
  }
}

/// Corner radius tokens (mobile design units, scaled with `.r`).
///
/// Use the scaled getters in widgets. The `*Value` constants are the raw
/// design units for contexts built outside `ScreenUtilInit` (e.g. ThemeData).
abstract final class AppRadius {
  static const double hairlineValue = 3;
  static const double xsValue = 6;
  static const double smValue = 8;
  static const double mdValue = 12;
  static const double chipValue = 14;
  static const double lgValue = 16;
  static const double xlValue = 20;
  static const double cardValue = 24;
  static const double sheetValue = 28;

  /// Large enough to fully round any component: stadium/pill shapes.
  static const double pillValue = 999;

  /// 3 — drag handles, heatmap cells, hairline bars
  static double get hairline => hairlineValue.r;

  /// 6 — progress bars, tiny indicators
  static double get xs => xsValue.r;

  /// 8 — small tags, color swatches
  static double get sm => smValue.r;

  /// 12 — icon tiles, compact controls
  static double get md => mdValue.r;

  /// 14 — chips, pills, small buttons
  static double get chip => chipValue.r;

  /// 16 — buttons, list tiles, inner Bento cells
  static double get lg => lgValue.r;

  /// 20 — inputs, secondary cards
  static double get xl => xlValue.r;

  /// 24 — Bento cards, dialogs
  static double get card => cardValue.r;

  /// 28 — bottom sheet top corners
  static double get sheet => sheetValue.r;

  /// Fully rounded ends — floating nav bar, stadium pills. Not scaled.
  static double get pill => pillValue;

  static BorderRadius get cardBorderRadius => BorderRadius.circular(card);
  static BorderRadius get sheetBorderRadius =>
      BorderRadius.vertical(top: Radius.circular(sheet));
}

/// Icon size tokens (mobile design units, scaled with `.r`).
abstract final class AppIconSizes {
  /// 12 — glyphs beside micro labels in dense pills
  static double get xxs => 12.r;

  /// 14 — inline glyphs inside badges and pills
  static double get xs => 14.r;

  /// 16 — dense list and chip icons
  static double get sm => 16.r;

  /// 18 — standard inline icons
  static double get md => 18.r;

  /// 20 — button and nav icons
  static double get lg => 20.r;

  /// 24 — Material default, app bar actions
  static double get xl => 24.r;

  /// 32 — sheet and dialog header icons
  static double get xxl => 32.r;

  /// 40 — empty states and hero illustrations
  static double get hero => 40.r;
}

/// Fixed component dimensions (mobile design units).
abstract final class AppSizes {
  /// Minimum interactive hit target (Material). Never scaled down.
  static const double minTapTarget = 48;

  /// Hairline border width used by Bento cards and inputs. Never scaled.
  static const double borderWidth = 1.2;

  /// Focused input border width. Never scaled.
  static const double borderWidthFocused = 1.6;

  /// Selection rings (chosen swatch, check circle). Never scaled.
  static const double borderWidthSelected = 2;

  static double get buttonHeightSm => 32.w;
  static double get buttonHeightMd => 42.w;
  static double get buttonHeightLg => 48.w;

  /// Max width of bottom sheets and dialogs on wide screens (logical px).
  static const double sheetMaxWidth = 600;
  static const double dialogMaxWidth = 480;

  /// Compact dialogs: confirmations, color picker, error states.
  static const double compactDialogMaxWidth = 420;

  /// Form dialogs on desktop, e.g. the habit creator.
  static const double formDialogMaxWidth = 580;

  /// Readable column for full-screen pages such as Settings.
  static const double pageMaxWidth = 640;
}
