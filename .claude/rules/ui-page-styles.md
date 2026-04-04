---
paths:
  - "lib/screens/today_screen.dart"
  - "lib/screens/log_screen.dart"
  - "lib/screens/log_entry_screen.dart"
  - "lib/screens/settings_screen.dart"
  - "lib/screens/calendar_screen.dart"
---

# Page-Specific Styling

## Home screen

- **Large collapsing `SliverAppBar`** (`expandedHeight: 152`, `pinned: true`).
  Expanded: `headlineMedium` title in `cs.onSurface`. Collapsed: `titleLarge`.
  Background shifts from transparent (expanded) to `cs.surfaceContainer`
  (collapsed) via `scrolledUnderElevation`.
- Hero stat card: `cs.primaryContainer` fill, `displayMedium` cycle-day number
  in `cs.onPrimaryContainer`, centered. Use `AppTheme` semantic colors for
  period/fertile overlays.
- Quick-action row: `FilledButton.tonal` with icon + label, 8dp spacing,
  inside a horizontal `SingleChildScrollView`.
- Calendar widget: full-width `Card` (`surfaceContainer`), 16dp internal
  padding.
- Bottom navigation: `NavigationBar` with `indicatorColor: cs.secondaryContainer`.

## Log screen

- **Medium `SliverAppBar`** (`expandedHeight: 112`, `pinned: true`,
  `scrolledUnderElevation: 3`).
- Section groups: `Card` with `surfaceContainerHigh` background, 16dp padding,
  12dp vertical gap between cards.
- Section labels: `titleSmall` (14sp, w500, `cs.onSurfaceVariant`),
  left-aligned. If icon used: 18dp icon + 8dp gap.
- Selectable chips: `FilterChip` or `ChoiceChip`.
  - Selected: `cs.secondaryContainer` fill, `cs.secondary` border (1.5dp).
  - Unselected: `cs.surfaceContainerHighest` fill, `cs.outlineVariant` border.
  - Domain chips (mood, period, activity): semantic color at 0.15–0.2 alpha
    fill, solid semantic border.
- Save / submit: `FilledButton`, `SizedBox(width: double.infinity)`,
  56dp height, pinned above bottom safe area.

## Settings screen

- **Small `AppBar`** (`AppBar`, `scrolledUnderElevation: 0`,
  `cs.surface` background), centered or left-aligned `titleLarge`.
- Group settings into `Card` containers — do **not** use bare `ListTile`
  rows without card grouping.
  - Card: `surfaceContainerHigh`, elevation 0, `BorderRadius.circular(12)`.
- `SwitchListTile.adaptive` for toggles; `ListTile` with
  `trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant)`
  for navigation rows.
- Section headers: `labelLarge` (14sp, w500, `cs.primary`), 16dp left
  indent, 24dp top margin.
- Destructive group: separate `Card` at bottom,
  `cs.errorContainer` background, `cs.onErrorContainer` text,
  `cs.error` icon tint.
