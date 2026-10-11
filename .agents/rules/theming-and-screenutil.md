# Antigravity Rules: Theming, Typography & ScreenUtil Compliance

## Rule Scope
This rule applies to all Dart files under `lib/` and `test/` within the `habit_tracker` project.

---

## 1. Zero Hardcoding Rule

### Rule 1.1: Color Ingestion
- **FORBIDDEN**: Direct use of `Color(0x...)`, `Colors.*` (e.g. `Colors.white`, `Colors.black`, `Colors.grey`, `Colors.red`, `Colors.transparent` for themed backgrounds) in presentation code.
- **ALLOWED EXCEPTIONS**:
  - `lib/core/theme/app_colors.dart` (where palette tokens are defined).
  - Theme preset definitions in `lib/features/themes/data/models/dynamic_theme_model.dart`.
  - Contrasting foreground icons on fully saturated custom accent badges (e.g. `Colors.white` icon on a button whose background is explicitly `primaryAccent`).
- **MANDATORY**:
  - Always obtain colors via `BuildContext` extensions:
    - `context.cardBackgroundColor`
    - `context.cardBorderColor`
    - `context.primaryAccent`
    - `context.secondaryAccent`
    - `context.textPrimaryColor`
    - `context.textSecondaryColor`
    - `context.textMutedColor`
    - `context.surfaceElevatedColor`
    - `context.colorScheme.error`

### Rule 1.2: Typography Ingestion
- **FORBIDDEN**: Direct instantiation of `TextStyle(...)` specifying arbitrary `fontFamily` or `color` in widgets.
- **MANDATORY**:
  - Use `context.textTheme.*` (e.g. `context.textTheme.headlineMedium`, `context.textTheme.titleSmall`, `context.textTheme.labelSmall`) with optional `.copyWith(...)`.
  - Or use `AppTextStyles.*(context)` from `lib/core/theme/app_text_styles.dart`.
  - Always ensure `fontFamily` inherits dynamically from the active theme model.

---

## 2. ScreenUtil & Responsiveness Rule

### Rule 2.1: Base Dimensions
- All design scaling relies on `ScreenUtilInit(designSize: Size(390, 844))`.
- When writing mobile-focused widgets, use:
  - Width: `.w`
  - Height: `.h`
  - Radii / Square: `.r`
  - Font sizes: `.sp` or `AppFontSizes.*`

### Rule 2.2: Multi-Column Desktop Safety
- When designing multi-column desktop layouts (`constraints.maxWidth >= 768`):
  - Do NOT assume a `.w` value reflects fraction of the column. A screen of 1200px width scales `.w` by 3.08x.
  - In horizontal `Row` widgets with fixed item counts (e.g. day pickers, bar charts):
    - Wrap items in `Expanded` or use fixed pixel dimensions (`38`, `28`, `120`).
    - Clamp padding and dimensions: `.w.clamp(min, max)`, `.h.clamp(min, max)`, `.r.clamp(min, max)`.
    - Wrap dynamic labels in `FittedBox(fit: BoxFit.scaleDown, child: ...)`.

---

## 3. Design System Component Rule

### Rule 3.1: Reusable Core Components
- Do NOT build custom buttons, text fields, dropdowns, dialogs, or sheets in feature screens.
- Use the unified design system in `lib/core/widgets/`:
  - `AppButton`, `AppIconButton`
  - `AppTextField`
  - `AppDropdown`
  - `AppDialog`, `showAppConfirmDialog`
  - `AppBottomSheet`, `showAppBottomSheet`
  - `AppBadge`, `AppStreakBadge`
  - `AppCard`
