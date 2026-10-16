# Antigravity AI Agent Guidelines: Habit Tracker

This document provides system-level instructions, design system mandates, and architectural contracts for all AI agents and developers working on the `habit_tracker` codebase.

---

## 1. Zero Hardcoding Commandments

### 🚫 Prohibited Anti-Patterns
1. **Never use raw color constants in UI/presentation code:**
   - ❌ `Colors.red`, `Colors.white`, `Colors.grey`, `Color(0xFF8B5CF6)`
   - ❌ `Colors.blueAccent`, `Colors.black.withOpacity(0.5)`
2. **Never instantiate raw `TextStyle` with hardcoded font families or arbitrary colors:**
   - ❌ `TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Inter')`
   - ❌ `const TextStyle(fontWeight: FontWeight.bold)`
3. **Never apply arbitrary border radius or elevation:**
   - ❌ `BorderRadius.circular(10)` when the design system specifies Bento tokens (`AppRadius.lg`, `AppRadius.xl`, `AppRadius.card`).
   - ❌ `elevation: 4` (The app uses flat 0 elevation with subtle borders `context.cardBorderColor` and soft ambient blur shadows).

### ✅ Canonical Substitutions
| Need | Canonical Solution |
| :--- | :--- |
| **Card background** | `context.cardBackgroundColor` |
| **Border / Outline** | `context.cardBorderColor` (width: `1.2`) |
| **Primary Theme Accent** | `context.primaryAccent` |
| **Secondary Theme Accent**| `context.secondaryAccent` |
| **Theme Accent Palette** | `context.accentPalette` (`List<Color>`) |
| **Primary Text Color** | `context.textPrimaryColor` |
| **Secondary Text Color** | `context.textSecondaryColor` |
| **Muted/Caption Color** | `context.textMutedColor` |
| **Error / Destructive** | `context.colorScheme.error` |
| **Pastel Accent Surface**| `AppColors.pastelSurface(accentColor, isDark: context.isDarkMode)` |
| **Active/Inactive Chip** | `AppColors.chipDecoration(context, isSelected: ...)` |
| **Typography** | `context.textTheme.*` OR `AppTextStyles.*(context)` |

---

## 2. ScreenUtil & Responsive Architecture

### Core Configurations
- **Design Base Size**: `AppDesign.size` = `Size(390, 844)`. Every dimension is authored in **mobile design units** measured on this artboard.
- **Desktop Breakpoint**: `AppBreakpoints.desktop` (`768.0` logical px). Check it with `context.isDesktop` (or `AppBreakpoints.isDesktopWidth(constraints.maxWidth)` inside a `LayoutBuilder`) — never a raw `>= 768`.
  - `< 768px`: Single-column mobile feed with `ListView`.
  - `≥ 768px`: Dual-column Bento grid with `Expanded(flex: 5)` (Left Analytics/Controls) and `Expanded(flex: 6)` (Right Habits Feed).

### Central Scaling Policy (CRITICAL)
The root widget is `AppScreenUtilInit` (`lib/core/widgets/app_screen_util_init.dart`) — use it in tests too, never a raw `ScreenUtilInit`. It applies `AppDesign.designSizeFor`:
- **Mobile**: scale = screen / artboard, bounded to `[AppDesign.minScale, AppDesign.maxScale]` (0.8–1.15) per axis.
- **Desktop/Web**: scale is exactly **1.0** — design units render 1:1, so Bento columns never balloon.

**Never clamp a scaled value in a widget** (`20.r.clamp(16, 24)` is prohibited — `test/screen_scale_policy_test.dart` enforces it). The bounds live in one place.

### Unit Rules
| Value | Use |
| :--- | :--- |
| Horizontal padding / gaps, widths | `N.w` |
| Vertical whitespace (padding / gaps) | `N.h` |
| Fixed heights of components holding text/icons (buttons, tiles, chips) | `N.w` (stays proportional to text) or `AppSizes.buttonHeight*` |
| `EdgeInsets.all`, square boxes, avatars, dots | `N.r` |
| Corner radii | `AppRadius.*` (`xs 6 · sm 8 · md 12 · chip 14 · lg 16 · xl 20 · card 24 · sheet 28`), else `N.r` |
| Icon sizes | `AppIconSizes.*` (`xs 14 · sm 16 · md 18 · lg 20 · xl 24 · hero 40`), else `N.r` |
| Font sizes | `AppTextStyles.*` / `context.textTheme.*`; overrides via `AppFontSizes.*` |
| Border widths, shadows, opacity, elevation, flex, `AppSizes.minTapTarget` | **Never scaled** (`AppSizes.borderWidth` = 1.2) |
| `ThemeData` (built outside ScreenUtil) | Raw `*Value` constants (`AppRadius.cardValue`, `AppFontSizes.bodyMediumValue`); `ThemeFactory.applyScreenScale` rescales text at runtime |

**Widgets in Constrained Columns or Rows** still need layout protection: wrap row items in `Expanded`, wrap dynamic labels in `FittedBox(fit: BoxFit.scaleDown, ...)`.

**Exception**: `lib/core/widgets_kit/habit_widget_snapshot_view.dart` renders the home-screen widget off-screen to an image and keeps fixed pixel values.

---

## 3. Architecture & Directory Boundaries

The codebase strictly adheres to **Feature-First Clean Architecture**:

```
lib/
├── core/
│   ├── theme/          # AppColors, AppTheme, AppTextStyles, AppFontSizes, ThemeFactory
│   ├── utils/          # Haptic feedback, formatting, date helpers
│   └── widgets/        # Universal design system widgets (AppButton, AppTextField, etc.)
├── features/
│   ├── dashboard/      # DashboardScreen, Bento widgets, ConsistencyChart, CalendarStrip
│   ├── habits/         # HabitModel, HabitStorage, habit providers, HabitCard
│   └── themes/         # DynamicThemeModel, ThemeStudioSheet, ThemeProvider, ColorPicker
└── app.dart            # HabitTrackerApp, ScreenUtilInit, MaterialApp
```

### Prohibited Cross-Layer Violations
- Never place presentation logic or Flutter widgets inside `data/models` or `data/storage`.
- Never access raw `SharedPreferences` directly inside UI widgets; use Riverpod providers (`habitListProvider`, `themeProvider`, `selectedDateProvider`).
- Do not recreate widgets that exist in `lib/core/widgets/`:
  - Buttons: Use [AppButton](file:///d:/Projects/habit_tracker/lib/core/widgets/app_button.dart) or [AppIconButton](file:///d:/Projects/habit_tracker/lib/core/widgets/app_button.dart).
  - Text inputs: Use [AppTextField](file:///d:/Projects/habit_tracker/lib/core/widgets/app_text_field.dart).
  - Dropdowns: Use [AppDropdown](file:///d:/Projects/habit_tracker/lib/core/widgets/app_dropdown.dart).
  - Dialogs: Use [AppDialog](file:///d:/Projects/habit_tracker/lib/core/widgets/app_dialog.dart) or `showAppConfirmDialog`.
  - Bottom Sheets: Use [AppBottomSheet](file:///d:/Projects/habit_tracker/lib/core/widgets/app_bottom_sheet.dart).
  - Badges: Use [AppBadge](file:///d:/Projects/habit_tracker/lib/core/widgets/app_badge.dart) or [AppStreakBadge](file:///d:/Projects/habit_tracker/lib/core/widgets/app_badge.dart).

---

## 4. Verification Protocol

Before completing any task or proposing changes:
1. Run `flutter analyze` — Must return **No issues found!**
2. Run `flutter test` — Must pass all tests (mobile, desktop layout, design system widgets, and storage tests).
3. Confirm zero hardcoded colors or text styles remain in modified files.
