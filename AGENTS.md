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
   - ❌ `BorderRadius.circular(10)` when the design system specifies Bento tokens (`16.r`, `20.r`, `24.r`).
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
- **Design Base Size**: `Size(390, 844)` (Mobile 20:9 ratio).
- **Desktop Breakpoint**: `768.0` logical pixels.
  - `< 768px`: Single-column mobile feed with `ListView`.
  - `≥ 768px`: Dual-column Bento grid with `Expanded(flex: 5)` (Left Analytics/Controls) and `Expanded(flex: 6)` (Right Habits Feed).

### Multi-Column Desktop Scaling Rule (CRITICAL)
> **Warning**: When running on desktop/web (e.g. 1200px viewport), `ScreenUtil.scaleWidth` is `1200 / 390 = 3.08x`.
> In a multi-column desktop layout, the left column has only `~450px` available width.
> If UI elements in multi-column rows (such as bar charts, calendar day pills, and fixed cards) use unbounded `.w` or `.sp`, their width balloons 300% and will overflow the column by hundreds of pixels.

**Rules for Widgets in Constrained Columns or Rows:**
1. **Row Items & Bars**:
   - Wrap each item in `Expanded` or use fixed pixel dimensions (`width: 38`, `width: 28`, `height: 120`).
   - Wrap dynamic text labels in `FittedBox(fit: BoxFit.scaleDown, child: Text(...))`.
2. **Carousel Cards**:
   - Provide explicit width and height constraints (e.g. `130.w.clamp(120.0, 150.0)` × `118` height).
3. **Paddings and Radii**:
   - Clamp scaling tokens: `20.r.clamp(16.0, 24.0)` or use constant standard paddings (`const EdgeInsets.all(20)`).

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
