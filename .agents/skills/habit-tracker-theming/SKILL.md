---
name: habit-tracker-theming
description: Guide and patterns for theming, typography, ScreenUtil responsive sizing, and design system components in the Habit Tracker Flutter app.
---

# Habit Tracker Theming & Responsiveness Skill

Use this skill whenever you are:
1. Adding or refactoring UI components, screens, or dialogs.
2. Integrating dynamic themes or customizing color palettes.
3. Handling responsive layout differences between mobile (<768px) and desktop (≥768px).
4. Eliminating hardcoded styling or fixing `ScreenUtil` layout overflows.

---

## 1. Ergonomic Theme Consumption

All theme values are exposed through clean `BuildContext` extension getters in [app_theme.dart](file:///d:/Projects/habit_tracker/lib/core/theme/app_theme.dart):

```dart
import 'package:habit_tracker/core/theme/app_theme.dart';

Widget build(BuildContext context) {
  // Color tokens
  final cardBg = context.cardBackgroundColor;
  final border = context.cardBorderColor;
  final primaryAccent = context.primaryAccent;
  final secondaryAccent = context.secondaryAccent;
  final textPrimary = context.textPrimaryColor;
  final textSecondary = context.textSecondaryColor;
  final textMuted = context.textMutedColor;
  final isDark = context.isDarkMode;
  final palette = context.accentPalette;

  // Typography tokens
  final titleStyle = context.textTheme.titleMedium;
  final bodyStyle = context.textTheme.bodyMedium;
  final labelStyle = context.textTheme.labelSmall;
}
```

### Dynamic Pastel Surfaces & Badges
For soft wellness cards or activity pills:
```dart
// Generates soft pastel tint in light mode and deep ambient tint in dark mode
final surfaceColor = AppColors.pastelSurface(
  accentColor,
  isDark: context.isDarkMode,
  opacity: 0.16,
);

// Chip decoration for selectable routines or filters
final chipBox = AppColors.chipDecoration(
  context,
  isSelected: isSelected,
  accentColor: primaryAccent,
);
```

---

## 2. ScreenUtil Scaling & Responsive Guidelines

### Base Setup
The app design coordinates around an iPhone 14 geometry (`390 × 844`).
- Mobile views: Use `.w`, `.h`, `.sp`, `.r`.
- Tablet / Desktop (`maxWidth >= 768px`): Multi-column layout.

### Preventing Desktop Multi-Column Overflows
When building horizontal rows (like [CalendarStrip](file:///d:/Projects/habit_tracker/lib/features/dashboard/presentation/widgets/calendar_strip.dart) or [ConsistencyChart](file:///d:/Projects/habit_tracker/lib/features/dashboard/presentation/widgets/consistency_chart.dart)):
1. Never use unbounded `.w` on child containers inside multi-column desktop rows. On a 1200px screen, `38.w` becomes `117px`, causing rapid `RenderFlex` overflows.
2. Best practice:
   - Wrap row items in `Expanded`:
     ```dart
     Row(
       children: weekData.map((bar) {
         return Expanded(
           child: Column(
             children: [
               FittedBox(
                 fit: BoxFit.scaleDown,
                 child: Text(bar.label, style: context.textTheme.labelSmall),
               ),
             ],
           ),
         );
       }).toList(),
     )
     ```
   - Or use fixed pixel dimensions for compact controls:
     ```dart
     width: 38,
     height: 38,
     padding: const EdgeInsets.symmetric(vertical: 8),
     ```

---

## 3. Standard Design System Components

Never write raw `ElevatedButton`, `TextField`, or unstyled `AlertDialog`. Always use the design system in `lib/core/widgets/`:

### AppButton
```dart
AppButton(
  text: 'Save Habit',
  leadingIcon: const Icon(Icons.check_rounded),
  variant: AppButtonVariant.primary, // or secondary, outline, ghost, danger
  size: AppButtonSize.md,             // sm (36h), md (46h), lg (54h)
  glow: true,
  isLoading: isSubmitting,
  onPressed: () => _submit(),
)
```

### AppTextField
```dart
AppTextField(
  controller: _titleController,
  labelText: 'HABIT TITLE',
  hintText: 'e.g. 20 Minutes Deep Work',
  showClearButton: true,
  autofocus: true,
  errorText: errorMessage,
)
```

### AppDropdown
```dart
AppDropdown<String>(
  labelText: 'ROUTINE CATEGORY',
  value: selectedCategory,
  items: const [
    AppDropdownItem(value: 'Morning', label: 'Morning Routine'),
    AppDropdownItem(value: 'Evening', label: 'Evening Routine'),
    AppDropdownItem(value: 'Focus', label: 'Focus & Work'),
  ],
  onChanged: (val) => setState(() => selectedCategory = val),
)
```

### AppDialog & Confirm Dialog
```dart
final confirmed = await showAppConfirmDialog(
  context,
  title: 'Delete Habit?',
  message: 'This will erase all past completions and streak history.',
  confirmText: 'Delete',
  isDestructive: true,
);
```

---

## 4. Creating a New Theme Preset

To register a new theme preset:
1. Open [dynamic_theme_model.dart](file:///d:/Projects/habit_tracker/lib/features/themes/data/models/dynamic_theme_model.dart).
2. Define the static instance on `UserThemeModel`:
   ```dart
   static const sunsetGaze = UserThemeModel(
     id: 'sunset_gaze',
     name: 'Sunset Gaze',
     description: 'Warm coral dusk with amber twilight radiance.',
     fontFamily: 'Inter',
     scaffoldBg: Color(0xFF14101A),
     cardBg: Color(0xFF1F1A28),
     cardBorder: Color(0xFF322A40),
     textPrimary: Color(0xFFFFF0F5),
     accentPalette: [
       Color(0xFFFF6B55),
       Color(0xFFFFB84D),
       Color(0xFFE84393),
     ],
     isDark: true,
   );
   ```
3. Add it to `UserThemeModel.builtInPresets`.
4. Run `flutter test test/theme_system_test.dart` to verify palette and brightness compliance.
