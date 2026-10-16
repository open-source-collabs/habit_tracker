# ScreenUtil & Responsive Layout Guide

## 1. Overview
The Track Free app supports seamless execution across mobile devices (iOS/Android), tablets, desktop platforms (macOS/Windows/Linux), and web browsers.

To achieve this, the codebase combines:
1. `flutter_screenutil` for proportional scaling on mobile viewports.
2. Responsive `LayoutBuilder` breakpoints for multi-column Bento desktop layouts.
3. Clamped scaling boundaries to prevent element ballooning in desktop windows.

---

## 2. ScreenUtil Initialization

In [app.dart](file:///d:/Projects/habit_tracker/lib/app.dart):
```dart
ScreenUtilInit(
  designSize: const Size(390, 844), // iPhone 14 geometry
  minTextAdapt: true,
  splitScreenMode: true,
  builder: (context, child) => MaterialApp(...),
)
```

---

## 3. Responsive Breakpoint: 768px

The [DashboardScreen](file:///d:/Projects/habit_tracker/lib/features/dashboard/presentation/screens/dashboard_screen.dart) delegates rendering according to available width:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth >= 768) {
      return _buildDesktopLayout(...);
    } else {
      return _buildMobileLayout(...);
    }
  },
)
```

### Layout Comparison
```
Mobile (< 768px):
┌──────────────────────────────────────┐
│ AppBar: Greeting + Theme Studio Button│
├──────────────────────────────────────┤
│ 7-Day Calendar Strip                 │
│ Consistency Weekly Score Chart       │
│ Favorite Activities Carousel         │
│ Bento Progress Overview Card         │
│ Routine Filter Chips                 │
│ Habits Feed (Single Column)          │
└──────────────────────────────────────┘

Desktop (≥ 768px):
┌──────────────────────────────────────────────────────────┐
│ AppBar: Greeting + Theme Studio Button                   │
├────────────────────────────┬─────────────────────────────┤
│ Column 1 (Flex 5):         │ Column 2 (Flex 6):          │
│ • Calendar Strip           │ • Routine Filter Chips      │
│ • Consistency Score Chart  │ • Active Habits Header      │
│ • Activities Carousel      │ • Bento Habit Cards Feed    │
│ • Progress Overview Card   │                             │
│ • Streak Champion Hero Tile│                             │
└────────────────────────────┴─────────────────────────────┘
```

---

## 4. Multi-Column Desktop Scaling Rules

### Why Unbounded `.w` Breaks on Desktop
On a 1200px desktop screen, `ScreenUtil.scaleWidth` is `1200 / 390 = 3.08x`.
In a 2-column layout, the left column has only `~450px` of width.
- A widget with `width: 38.w` becomes `117px`.
- 7 days × 117px = `819px` -> Exceeds 450px by `369px` -> **RenderFlex Overflow Crash**!

### The Solution: Clamping & Flex Distribution
1. **For Fixed Grid/Row Items (e.g. `CalendarStrip`, `ConsistencyChart`)**:
   - Wrap each item in `Expanded`:
     ```dart
     Row(
       children: items.map((e) => Expanded(child: ...)).toList(),
     )
     ```
   - Or use fixed pixel values for compact items:
     ```dart
     width: 38,
     height: 38,
     padding: const EdgeInsets.symmetric(vertical: 8),
     ```
2. **For Horizontal Carousels (e.g. `FavoriteActivitiesCarousel`)**:
   - Provide explicit width constraints:
     ```dart
     width: 130.w.clamp(120.0, 150.0),
     height: 118,
     ```
3. **For Text inside Flex Children**:
   - Protect text from overflow using `FittedBox`:
     ```dart
     FittedBox(
       fit: BoxFit.scaleDown,
       child: Text(label, style: context.textTheme.labelSmall),
     )
     ```
4. **For Card Paddings & Radii**:
   - Use `.clamp`: `padding: EdgeInsets.all(20.r.clamp(16.0, 24.0))`
   - Or standard const values: `const EdgeInsets.all(20)`
