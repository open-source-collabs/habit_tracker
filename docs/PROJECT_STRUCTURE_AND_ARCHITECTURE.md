# Project Structure & Architecture Guide

## 1. Architectural Pattern: Feature-First Clean Architecture

Every feature owns its data, domain and presentation code. Code shared by several features lives in `core/`. There is no top-level `lib/presentation/` or `lib/data/`.

```
lib/
├── app.dart                         # Root: AppScreenUtilInit, MaterialApp, startup (reminders, sync)
├── main.dart                        # Entry point: error handlers, font licenses, ProviderScope
│
├── core/
│   ├── constants/app_links.dart     # Privacy/store/support links (from --dart-define)
│   ├── data/
│   │   ├── app_data_repository.dart # Single writer of the persisted payload (serialized writes,
│   │   │                            #   corruption lock, local-change stream, sync replace)
│   │   └── device_identity.dart     # Random per-install id, written into lastModifiedBy
│   ├── database/                    # SQLite (AppDatabase, schema, DAOs, daily backups, migrations)
│   ├── routes/                      # AppRoutes, AppRouter (onGenerateRoute), AppNavigator
│   ├── services/
│   │   ├── notification_service.dart# flutter_local_notifications + local time zone
│   │   └── reminder_schedule.dart   # Pure reminder planning (slots, stable ids)
│   ├── theme/                       # Tokens, ThemeFactory, AppFonts (6 bundled fonts), AppContrast
│   ├── utils/                       # Haptics, date formatting, CalendarDays (DST-safe), AppErrorLog
│   ├── widgets/                     # Design system: AppButton, AppCard, AppDialog, AppTextField, …
│   └── widgets_kit/                 # Home-screen widget sync & click handling
│
└── features/
    ├── dashboard/                   # Today / Analytics / Themes tabs, Bento widgets
    ├── habits/
    │   ├── data/models/             # HabitModel (check-ins + per-day change times), HabitFrequency,
    │   │                            #   StarterHabits (onboarding suggestions, no history)
    │   ├── data/storage/            # HabitStorage: SQLite (+ mirror backup file), legacy IO, Web
    │   └── presentation/
    │       ├── providers/           # habitListProvider, stats, filters, creator form, heatmap
    │       └── widgets/             # BentoHabitCard, HeatmapGrid, HabitCreatorSheet,
    │                                #   habit_creator/ (sheet sections), DataLoadErrorView
    ├── notifications/               # Reminder & digest settings (sound, haptics), permission banner
    ├── onboarding/                  # First-run flow (welcome, pick starters, reminders) + gate
    ├── settings/                    # Settings, display name, restore backup / delete all,
    │                                #   About (version, links, licenses, diagnostics), privacy policy
    ├── sync/
    │   ├── data/                    # CloudSyncBackend, Google Drive & iCloud backends, prefs
    │   ├── domain/                  # MergeEngine (CRDT-style merge), SyncEngine (one sync pass)
    │   └── presentation/            # SyncController, Sync tab, export/import dialog
    └── themes/
        ├── data/models/             # AppPayloadModel (schema v2 + migrations), UserThemeModel
        ├── data/storage/            # Legacy SharedPreferences theme migration
        └── presentation/            # themeProvider, Theme Studio, color picker
```

## 2. Data flow

```
UI widgets ──watch──▶ feature notifiers (habits, themes, display name)
                            │ update(transform)
                            ▼
                  AppDataRepository ──serialized──▶ HabitStorage (file / localStorage)
                            ▲  │ localChanges
            replaceWith(merge) │
                            │  ▼
                      SyncController ──▶ SyncEngine ──▶ CloudSyncBackend (Drive / iCloud)
```

- **Single source of truth:** `AppDataRepository` holds the one payload, which contains habits, custom themes, the display name and tombstones. Features change only their own part of it.
- **Safety:** if stored data can't be read, storage first tries its backups (three daily snapshots in SQLite, then a JSON mirror file outside the database). If nothing is readable, writes are blocked until the user retries or chooses Start fresh, and a copy of the damaged data is kept. Unreadable pre-SQLite data is reported the same way, never treated as a first run.
- **Failed saves** are published on `AppDataRepository.saveErrors` and shown as a snackbar; the change stays in memory and the next write retries it.
- **First run:** nothing is seeded. `AppDataRepository.hasNeverSaved` triggers onboarding (also after Delete all data).
- **Dates:** day arithmetic goes through `CalendarDays` (calendar days, not 24-hour durations, so streaks survive DST). UI reads "today" from `currentDayProvider`, which rolls over at midnight and on resume.
- **Reminders:** a habit done today has today's reminder skipped; the evening digest is skipped once every habit is done.
- **Schema:** `AppPayloadModel.currentSchemaVersion` plus a migration chain. Data from a newer build is rejected, not silently truncated.

## 3. Layer Responsibilities

### Data Layer (`features/*/data/`, `core/data/`)
- **Models:** immutable, with JSON round-trips (`fromJson`, `toJson`).
- **Storage and backends:** transport only, injectable for tests.
- **Rule:** never import widgets or use `BuildContext`.

### Domain Layer (`features/*/domain/`)
- Pure logic, such as the merge and sync passes. Fully unit-tested.

### Presentation Layer (`features/*/presentation/`)
- **Providers:** Riverpod notifiers. They own side effects such as persistence and reminders, not the widgets.
- **Widgets:** use the design-system tokens and `core/widgets` (see AGENTS.md).
- **Rule:** no hard-coded colors or `TextStyle`s, and no direct storage or SharedPreferences calls.

## 4. Testing Conventions (`test/`)

| File | Covers |
| :--- | :--- |
| `data_safety_test.dart` | Repository write serialization, the corruption lock, failed-save reporting, delete all, no first-run seeding, future dates, `HabitModel` equality |
| `habit_lifecycle_test.dart` | Archive, delete and undo, device id, display name, top habits, dashboard delete flow |
| `reminder_schedule_test.dart` | FNV-1a ids, reminder slots per frequency, next occurrence, notifier reminder sync |
| `sync_test.dart` | Merge (per-day, tombstones, commutativity, idempotency), v1→v2 migration, sync engine, two-device convergence, Drive client, sync controller |
| `payload_storage_test.dart`, `merge_engine_test.dart` | Persistence, backups, serialization, merge |
| `theme_system_test.dart` | Presets, theme factory, persistence and legacy migration |
| `widget_test.dart`, `*_widgets_test.dart`, `*_sheet_test.dart` | UI on mobile and desktop, fresh-install onboarding flow |
| `sqflite_storage_test.dart` | DAOs, daily backup rotation, legacy migration and its fallbacks, mirror-file recovery |
| `calendar_days_test.dart`, `day_rollover_test.dart` | DST-safe day math and streaks, midnight rollover of "today" |
| `accessibility_test.dart` | Tap-target and label guidelines, 2× text size, built-in theme contrast |
| `app_fonts_test.dart`, `settings_about_test.dart` | Font registry and picker, privacy policy screen, app links |

## 5. Known follow-ups

- **Localization:** all UI text is English and inline; adding `flutter_localizations` + ARB files is the next step for other languages.
- **Incremental saves:** every save rewrites the full payload. Fine for typical histories; switch to per-row writes if very large histories become slow.
- **End-to-end tests:** no `integration_test/` yet (on-device reminder delivery, reboot restore, real sync).
- **Backup encryption:** cloud copies rely on Google/Apple account security; there is no extra app-level encryption.

Run everything with:

```bash
flutter analyze && flutter test
```
