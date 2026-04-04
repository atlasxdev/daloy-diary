---
paths:
  - "lib/screens/**"
  - "lib/features/**"
---

# UI Component Patterns

## Cards

- Border radius: **12dp** (set in `CardTheme` — do not override inline).
- Default elevation: 0 with `surfaceContainer` tonal fill (tonal elevation,
  not shadow).
- Elevated (e.g., featured or interactive): `surfaceContainerHigh`,
  `elevation: 1`, `shadowColor` at 0.08 alpha.
- Always use the `Card` widget — it inherits `CardTheme` automatically.
- Content: left-aligned text, vertically centered leading icons.

## Chips

- Use M3 chip widgets: `FilterChip`, `ChoiceChip`, `InputChip`, `ActionChip`.
  Never build custom chips from `Container`.
- Chip border color: `cs.outlineVariant` (updated M3 spec — not `cs.outline`).
- Selected: `cs.secondaryContainer` fill (or semantic color at 0.15–0.2 alpha
  for domain chips), `cs.secondary` border (1.5dp).
- Unselected: `cs.surfaceContainerHighest` fill, `cs.outlineVariant` border.
- Use `AnimatedContainer` (150ms ease) or M3's built-in chip animation for
  state transitions.

## Buttons

- **Filled** (primary / most important action): `FilledButton` →
  `cs.primary` fill, `cs.onPrimary` text.
- **Filled tonal** (secondary action): `FilledButton.tonal` →
  `cs.secondaryContainer` fill, `cs.onSecondaryContainer` text.
- **Outlined** (low-emphasis): `OutlinedButton` with `cs.outline` border.
- **Text / destructive**: `TextButton` with `cs.error` color.
- **FAB** (floating primary action): `FloatingActionButton` or
  `FloatingActionButton.extended`, `cs.primaryContainer` fill,
  `cs.onPrimaryContainer` icon.
- Full-width form save: `SizedBox(width: double.infinity)` wrapping
  `FilledButton`, 56dp height.

## Calendar day cells

- Shape: circle via `BoxDecoration(shape: BoxShape.circle)`.
- Period day: `AppTheme.periodLightColor` fill, `AppTheme.periodColor` text,
  `titleSmall` weight.
- Selected day: `cs.primary` fill, `cs.onPrimary` text.
- Today (not selected): `cs.primary` border (2dp), no fill, `cs.primary` text.
- Predicted: 4dp dot at bottom-center, `AppTheme.predictedColor`.
- Has logs: 4dp dot at bottom-right, `AppTheme.logDotColor`.
- Has activity: 4dp dot at bottom-left, `AppTheme.activityColor`.

## Bottom sheets

- `showModalBottomSheet` with `useSafeArea: true`,
  `isScrollControlled: true`.
- Top corner radius: **28dp** `BorderRadius.vertical(top: Radius.circular(28))`
  (M3 standard).
- Drag handle: 32×4dp pill, `cs.onSurfaceVariant` at 0.4 alpha.
- Background: `cs.surfaceContainerHigh`.
- Title: `titleLarge`, centered, 24dp top padding after handle.
- Section labels: `titleSmall`, `cs.onSurfaceVariant`, left-aligned.
- Input fields: `TextField(filled: true, fillColor: cs.surfaceContainerHighest)`,
  `BorderRadius.circular(12)`.

## Top App Bars

- **Small** (`AppBar`): `titleLarge` title. Background `cs.surface`; scrolled
  under → `cs.surfaceContainer` tint via `scrolledUnderElevation`.
- **Medium** (`SliverAppBar`, `expandedHeight: 112`): `headlineSmall` when
  expanded → `titleLarge` when collapsed.
- **Large** (`SliverAppBar`, `expandedHeight: 152`): `headlineMedium` when
  expanded → `titleLarge` when collapsed.
- Never hardcode `elevation` on app bars. Use `scrolledUnderElevation` only.
- `centerTitle: false` by default (Android convention). Center only when
  design explicitly requires it.

## Navigation bar

- Always use `NavigationBar` (not `BottomNavigationBar`).
- `indicatorColor: cs.secondaryContainer`.
- `labelBehavior: NavigationDestinationLabelBehavior.alwaysShow`.
- Icon size: 24dp; use filled icon variant for selected destination.
- 3–5 destinations only.

## Navigation rail (tablet / landscape)

- `NavigationRail`, `selectedIconTheme` uses `cs.onSecondaryContainer`.
- `indicatorColor: cs.secondaryContainer`.
- `extended: false` compact; `extended: true` for wide tablet breakpoints.

## Dialogs

- `AlertDialog` only (not custom `Dialog` unless layout demands it).
- Background: `cs.surfaceContainerHigh`, `BorderRadius.circular(28)`.
- Title: `headlineSmall`. Content: `bodyMedium`.
- Actions: `TextButton` (cancel) + `FilledButton` (confirm), right-aligned.

## Snackbars and feedback

- `SnackBar`: `cs.inverseSurface` background, `cs.inverseOnSurface` text.
- Loading: `CircularProgressIndicator` with `cs.primary` stroke.
- Inline success: `Icon(Icons.check_circle_outline, color: cs.primary)` next
  to contextual text — no floating toast for important outcomes.

## Dividers

- `Divider(color: cs.outlineVariant)` — never `cs.outline` for dividers.
- Inside lists: `indent: 16, endIndent: 16` (inset style).
- Between major sections: full-width, 1dp height.

## Section labels

- `Text(label, style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant))`
- If icon is paired: `Row` → `Icon(icon, size: 18, color: semanticColor)` +
  8dp gap + label text.
- Consistent across all log and form screens.

## Do

- Use `AnimatedContainer` or M3 built-in animations for state transitions.
- Use `NavigationBar` (not `BottomNavigationBar`).
- Use `scrolledUnderElevation` for tonal surface lift on scroll — never
  hardcode app bar elevation.
- Use `SliverAppBar` (Large/Medium) on content-heavy screens (Home, Log).
- Use `surfaceContainer*` family for tonal elevation surfaces.

## Don't

- Don't use `BottomNavigationBar` — use `NavigationBar`.
- Don't use `AppBar(elevation: x)` for tonal effects — use
  `scrolledUnderElevation`.
- Don't add heavy drop shadows; M3 uses **tonal color elevation**, not shadows.
- Don't override `CardTheme` shape/elevation inline — the theme handles it.
- Don't use `cs.outline` for chip borders — use `cs.outlineVariant`
  (updated M3 spec).
- Don't overlap the `NavigationBar` with FAB or content — account for
  `NavigationBar` height (80dp) in scaffold padding.
- Don't use `RaisedButton`, `FlatButton`, or `OutlineButton` (M2 deprecated).
- Don't use `TextButton` as a primary action — use `FilledButton`.
