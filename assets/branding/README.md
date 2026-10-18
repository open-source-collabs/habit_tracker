# Track Free brand assets

**Mark: "Bento Check".** A Bento card tile holds a habit checkmark, and a streak spark sits on its top-right corner. Every color comes from `lib/core/theme/app_colors.dart`:

| Element | Token | Hex |
| :--- | :--- | :--- |
| Background | `obsidianTwilight` / `porcelainBg` | `#0F1016` / `#F8F9FD` |
| Tile | `cardSurface` / `porcelainCard` | `#181924` / `#FFFFFF` |
| Outline | `neonLavender` | `#8B5CF6` |
| Checkmark | `neonLavender` → `emeraldMint` | `#8B5CF6` → `#10B981` |
| Spark | `mangoSunrise` | `#FFAE33` |
| Wordmark | Plus Jakarta Sans Bold, `textPrimary` / `textPrimaryLight` | `#F8FAFC` / `#0F172A` |

## Single source of geometry
The mark is drawn on the 108-unit Android adaptive-icon grid in three places, and all three must stay in sync:
- `lib/core/widgets/app_logo.dart`: `AppLogoPainter` (in-app `AppLogo` and every raster icon)
- `android/app/src/main/res/drawable/ic_launcher_{foreground,background,monochrome}.xml`
- the SVG masters in this folder

## Files
| File | Use |
| :--- | :--- |
| `logo_mark.svg` / `logo_mark_dawn.svg` | Full app icon, dark / light |
| `logo_foreground.svg` | Mark only, inside the adaptive safe zone |
| `logo_monochrome.svg` | Single-color silhouette |
| `logo_wordmark.svg` / `logo_wordmark_light.svg` | Horizontal lockup for the website, store graphics and social media (convert text to outlines before print) |
| `png/` | 1024 px exports |
| `store/play_store_icon_512.png` | Google Play listing icon |

## Regenerating platform icons
```bash
flutter test tool/generate_brand_assets.dart
```
This writes the Android legacy mipmaps, the iOS and macOS AppIcon sets, the web icons and favicon, the Windows `app_icon.ico`, and `png/` + `store/`. iOS icons are written as opaque RGB, because the App Store rejects icons with an alpha channel.

## Usage rules
- Keep clear space around the mark of at least ¼ of its width.
- Don't recolor the accents, add text inside the app icon, or stretch or rotate the mark.
- On photos or busy backgrounds, use the monochrome version.
