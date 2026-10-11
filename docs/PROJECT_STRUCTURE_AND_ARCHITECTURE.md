# Project Structure & Architecture Guide

## 1. Architectural Pattern: Feature-First Clean Architecture

The `habit_tracker` codebase is structured to separate concerns, maximize modularity, and ensure that every feature encapsulates its data, domain, and presentation logic.

```
lib/
├── app.dart                                # Application root, ScreenUtilInit, MaterialApp
├── main.dart                               # Flutter entry point, ProviderScope
│
├── core/                                   # Cross-cutting foundational modules
│   ├── theme/                              # Design tokens, theme factory, typography
│   │   ├── app_colors.dart                 # Accent constants & pastelSurface helpers
│   │   ├── app_font_sizes.dart             # Responsive font scale tokens
│   │   ├── app_text_styles.dart            # Typography roles (display, headline, title, body, label)
│   │   ├── app_theme.dart                  # BuildContext theme extension helper getters
│   │   ├── app_theme_extension.dart        # Custom ThemeData ThemeExtension
│   │   └── theme_factory.dart              # Transforms UserThemeModel -> ThemeData
│   │
│   ├── utils/                              # Utility helpers
│   │   └── haptics.dart                    # AppHaptics (light, medium, heavy, selection)
│   │
│   └── widgets/                            # Universal, reusable Bento design system
│       ├── app_badge.dart                  # AppBadge & AppStreakBadge
│       ├── app_bottom_sheet.dart           # AppBottomSheet & showAppBottomSheet
│       ├── app_button.dart                 # AppButton (spring animated) & AppIconButton
│       ├── app_card.dart                   # AppCard with Bento outline & shadows
│       ├── app_dialog.dart                 # AppDialog & showAppConfirmDialog
│       ├── app_dropdown.dart               # AppDropdown modal picker
│       ├── app_text_field.dart             # AppTextField with clear/password toggles
│       └── widgets.dart                    # Core widgets barrel export
│
└── features/                               # Self-contained business features
    ├── dashboard/                          # Dashboard & Bento overview analytics
    │   └── presentation/
    │       ├── screens/
    │       │   └── dashboard_screen.dart   # Responsive mobile (<768) & desktop (≥768) view
    │       └── widgets/
    │           ├── bento_stats_card.dart   # Progress overview stats tile
    │           ├── calendar_strip.dart     # 7-day interactive date strip
    │           ├── consistency_chart.dart  # Weekly consistency bar chart
    │           └── favorite_activities_carousel.dart # Pastel wellness cards carousel
    │
    ├── habits/                             # Habit lifecycle & tracking
    │   ├── data/
    │   │   ├── models/
    │   │   │   └── habit_model.dart        # HabitModel, HabitFrequency, HabitStatus
    │   │   └── storage/
    │   │       ├── habit_storage.dart      # Abstract repository interface
    │   │       ├── habit_storage_factory.dart # Cross-platform factory
    │   │       ├── io_habit_storage.dart   # Mobile/Desktop JSON storage
    │   │       └── web_habit_storage.dart  # Web LocalStorage implementation
    │   └── presentation/
    │       ├── providers/
    │       │   └── habit_provider.dart     # habitListProvider, stats, active filters
    │       └── widgets/
    │           └── habit_card.dart         # BentoHabitCard with completion interactions
    │
    └── themes/                             # Dynamic theme customization & presets
        ├── data/
        │   └── models/
        │       ├── app_payload_model.dart  # Storage payload model
        │       └── dynamic_theme_model.dart# UserThemeModel & built-in theme presets
        └── presentation/
            ├── providers/
            │   └── theme_provider.dart     # themeProvider (StateNotifier)
            ├── screens/
            │   └── theme_studio_sheet.dart # Theme Studio customization drawer
            └── widgets/
                └── color_picker_dialog.dart# HSV & Palette color picker modal
```

---

## 2. Layer Responsibilities

### Data Layer (`features/*/data/`)
- **Models**: Immutable data transfer objects with JSON serialization (`fromJson`, `toJson`).
- **Storage**: Local-first repository pattern with cross-platform abstractions (`HabitStorage`, `IOHabitStorage`, `WebHabitStorage`).
- **Rules**: Must NEVER import presentation widgets or `BuildContext`.

### Presentation Layer (`features/*/presentation/`)
- **Screens**: Orchestrate layout, responsive adaptation (`LayoutBuilder`), and high-level routing.
- **Widgets**: Self-contained UI components consuming `BuildContext` theme extensions and Riverpod providers.
- **Providers**: State management with `flutter_riverpod` (`StateNotifier`, `Provider`).
- **Rules**: Must NEVER hardcode colors, raw TextStyles, or direct storage calls.

---

## 3. Testing Conventions (`test/`)

Every feature must maintain comprehensive unit and widget tests:
- `bento_habit_card_test.dart`: Card rendering, streak counting, completion haptics, spring animations.
- `design_system_widgets_test.dart`: Complete coverage of all `core/widgets` components.
- `habit_provider_test.dart`: State transitions, creation, completion toggles, streaks.
- `payload_storage_test.dart`: Persistence, backup/restore, serialization integrity.
- `theme_system_test.dart`: Preset loading, theme factory generation, extension tokens.
- `widget_test.dart`: App boot, mobile rendering, and multi-column desktop responsiveness.

**Command to run all tests:**
```bash
flutter test
```
