# Dynamic Theme & Styling Architecture Guide

## Overview
The Habit Tracker application utilizes a state-of-the-art dynamic theming system built on Material 3, Riverpod, and custom `ThemeExtension` tokens. It guarantees that **zero hardcoded colors or raw TextStyles** exist anywhere in the presentation layer.

---

## 1. Core Architecture

```
[UserThemeModel] (Serializable Model)
       │
       ▼
[ThemeFactory.createTheme]
       │
       ├──► ThemeData (Material 3 tokens, CardTheme, ColorScheme, TextTheme)
       │
       └──► AppThemeExtension (cardBorder, surfaceElevated, accentPalette)
              │
              ▼
    ThemeExtensionHelper on BuildContext
              │
              ▼
Presentation Widgets (Bento Cards, Carousel, Dialogs, Charts)
```

---

## 2. Key Components

### A. [UserThemeModel](file:///d:/Projects/habit_tracker/lib/features/themes/data/models/dynamic_theme_model.dart)
Represents a customizable theme preset containing:
- `id`, `name`, `description`
- `fontFamily`: Dynamic Google Font (Inter, Plus Jakarta Sans, Outfit, DM Sans, etc.)
- `scaffoldBg`, `cardBg`, `cardBorder`, `textPrimary`
- `accentPalette`: Ordered list of accent colors (`Color(0xFF...)`)
- `isDark`: Boolean brightness indicator

### B. [ThemeFactory](file:///d:/Projects/habit_tracker/lib/core/theme/theme_factory.dart)
Pure factory that transforms a `UserThemeModel` into a complete `ThemeData`:
- Automatically populates `ColorScheme` (`primary`, `secondary`, `error`, `surface`, `onSurface`, `outline`).
- Constructs a geometric `TextTheme` with optical letter-spacing and hierarchy.
- Attaches [AppThemeExtension](file:///d:/Projects/habit_tracker/lib/core/theme/app_theme_extension.dart).
- Applies zero-elevation 24px rounded card geometry (`cardTheme`).

### C. [AppColors](file:///d:/Projects/habit_tracker/lib/core/theme/app_colors.dart)
Defines semantic color constants and dynamic helper functions:
- Accent constants: `neonLavender`, `cyanGlow`, `emeraldMint`, `sunsetCoral`, `electricAmber`.
- `AppColors.pastelSurface(accent, isDark: ...)`: Creates soft watercolor pastels in light mode and ambient tinted surfaces in dark mode.
- `AppColors.chipDecoration(context, isSelected: ...)`: Returns consistent `BoxDecoration` for filter chips and toggles.

### D. [ThemeExtensionHelper](file:///d:/Projects/habit_tracker/lib/core/theme/app_theme.dart)
Extension on `BuildContext` providing ergonomic, null-safe getters:
```dart
context.cardBackgroundColor    // Active card background
context.cardBorderColor        // 1.2px outline color
context.primaryAccent          // First palette accent
context.secondaryAccent        // Second palette accent
context.textPrimaryColor       // Highest-contrast text
context.textSecondaryColor     // Secondary body text
context.textMutedColor         // Subtitles and captions
context.surfaceElevatedColor   // Elevated tile surface
context.isDarkMode             // Boolean dark mode check
context.accentPalette          // Full palette list
```

---

## 3. Typography Hierarchy

Defined in [app_text_styles.dart](file:///d:/Projects/habit_tracker/lib/core/theme/app_text_styles.dart) and [app_font_sizes.dart](file:///d:/Projects/habit_tracker/lib/core/theme/app_font_sizes.dart):

| Role | Size | Usage |
| :--- | :--- | :--- |
| `displayLarge` | 32.sp | Monumental celebratory metrics |
| `displayMedium`| 28.sp | Major counters & streak hero numbers |
| `headlineLarge`| 22.sp | Screen titles |
| `headlineMedium`| 20.sp | Main section headings |
| `titleMedium`  | 16.sp | Card titles & interactive headers |
| `titleSmall`   | 14.sp | Sub-card headings & habit names |
| `bodyMedium`   | 14.sp | Standard readable body text |
| `bodySmall`    | 12.sp | Subtitles & helper hints |
| `labelLarge`   | 14.sp | Primary button action labels |
| `labelMedium`  | 12.sp | Secondary chips & action buttons |
| `labelSmall`   | 11.sp | Uppercase category badges (letter-spaced) |

---

## 4. How to Apply Themes to New Widgets

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:habit_tracker/core/theme/app_theme.dart';

class MyNewFeatureCard extends StatelessWidget {
  const MyNewFeatureCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r.clamp(16.0, 24.0)),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(24.r.clamp(16.0, 24.0)),
        border: Border.all(color: context.cardBorderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HABIT METRICS',
            style: context.textTheme.labelSmall?.copyWith(
              color: context.textMutedColor,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Daily Mindfulness',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
```
