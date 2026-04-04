---
paths:
  - "lib/core/theme.dart"
  - "lib/screens/**"
  - "lib/features/**"
---

# UI Color System

Reference design: `docs/ui/reference/app-theme.webp`

## Design philosophy

- **Android-first, Material Design 3 (Material You)** visual language throughout.
- Calm, premium, trustworthy health-app feel. Not playful, not clinical.
- Dynamic tonal surfaces replace opacity-based elevation — color communicates
  depth, not shadow weight.
- Every screen should feel breathable. When in doubt, add whitespace.
- `useMaterial3: true` must be set in every `ThemeData` call.

## Color system

Never use raw `Color(...)` or `Colors.*` in screen code. Always go through
`AppTheme` or `Theme.of(context).colorScheme` (`cs` below).

Material Design 3 uses a **tonal palette** generated from a single seed color
via `ColorScheme.fromSeed(seedColor: AppTheme.seedColor)`.

| Role                   | Token                                | When to use                                 |
| ---------------------- | ------------------------------------ | ------------------------------------------- |
| Primary accent         | `cs.primary`                         | FABs, filled buttons, active nav indicators |
| Primary container      | `cs.primaryContainer`                | Selected chip fill, hero stat cards         |
| On primary container   | `cs.onPrimaryContainer`              | Text/icons on `primaryContainer`            |
| Secondary              | `cs.secondary`                       | Supporting interactive elements             |
| Secondary container    | `cs.secondaryContainer`              | Nav bar indicator pill, filter chips        |
| On secondary container | `cs.onSecondaryContainer`            | Text/icons on `secondaryContainer`          |
| Tertiary               | `cs.tertiary`                        | Complementary accent (use sparingly)        |
| Tertiary container     | `cs.tertiaryContainer`               | Tertiary highlights                         |
| Period / menstruation  | `AppTheme.periodColor(context)`      | Period days, symptoms, period-related UI    |
| Period background      | `AppTheme.periodLightColor(context)` | Light fill behind period day cells          |
| Predicted cycle        | `AppTheme.predictedColor(context)`   | Predicted period dots, "next period" stats  |
| Fertility              | `AppTheme.fertileColor(context)`     | Fertile window indicators                   |
| Mood                   | `AppTheme.moodColor(context)`        | Mood chips, mood section headers            |
| Sexual activity        | `AppTheme.activityColor(context)`    | Activity logs, dots, sheets                 |
| Log indicator          | `AppTheme.logDotColor(context)`      | Small dot on calendar days with any log     |
| Scaffold background    | `cs.surface`                         | Page backgrounds                            |
| Default card surface   | `cs.surfaceContainer`                | Cards, panels                               |
| Elevated card surface  | `cs.surfaceContainerHigh`            | Bottom sheets, dialogs                      |
| Input fill / top layer | `cs.surfaceContainerHighest`         | Text field fill, top-most surfaces          |
| Dim surface            | `cs.surfaceDim`                      | Overlay scrims, disabled washes             |
| Bright surface         | `cs.surfaceBright`                   | Spotlit content areas                       |
| Primary text           | `cs.onSurface`                       | Body text, titles                           |
| Secondary text         | `cs.onSurfaceVariant`                | Labels, captions, hints, icon tints         |
| Borders (default)      | `cs.outlineVariant`                  | Card borders, chip borders, dividers        |
| Borders (emphasis)     | `cs.outline`                         | Input field outlines, focus rings           |
| Destructive            | `cs.error`                           | Delete buttons, clear-data actions          |
| Destructive container  | `cs.errorContainer`                  | Error highlight backgrounds                 |

**Deprecated — do not use:**
`cs.background`, `cs.onBackground`, `cs.surfaceVariant`.
Migrate to the `surfaceContainer*` family above.

**Hard rule:** If you need a color not in this table, add it to `AppTheme`
first — never inline it.

## Do

- Use `ColorScheme.fromSeed(seedColor: AppTheme.seedColor)` for scheme
  generation.
- Use `Theme.of(context).colorScheme` for all surface/text/border colors.
- Use `AppTheme.*Color(context)` for all domain-specific colors.
- Use `withValues(alpha: ...)` for opacity (not `withOpacity`).
- Support both light and dark mode — `ColorScheme.fromSeed` handles both.

## Don't

- Don't use `Colors.red`, `Colors.purple`, `Colors.pink`, or any `Colors.*`
  in screen code.
- Don't use `cs.background`, `cs.onBackground`, or `cs.surfaceVariant`
  (deprecated in M3).
- Don't hardcode light-mode-only colors — always derive from `colorScheme` or
  `AppTheme` semantic methods.
- Don't use the `Opacity` widget for text dimming — use `cs.onSurfaceVariant`
  or `withValues(alpha: ...)` on the color instead.
