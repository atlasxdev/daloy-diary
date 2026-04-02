---
description: UI theme and design system rules for all screens and components
paths:
  - "lib/core/theme.dart"
  - "lib/screens/**"
  - "lib/features/**"
---

# UI Theme Rules

All UI work in this project must follow these rules. The source of truth for color values and component config is `lib/core/theme.dart` (`AppTheme`).

Reference design: `docs/ui/reference/app-theme.webp`

## Design philosophy

- Calm, premium, trustworthy health-app feel. Not playful, not clinical.
- Inspired by Apple HIG: system fonts, generous whitespace, flat surfaces, subtle depth.
- Warm and soft — never harsh, never heavy. Think "quiet confidence."
- Every screen should feel breathable. When in doubt, add more whitespace.

## Color system

Never use raw `Color(...)` or `Colors.*` values in screen code. Always go through `AppTheme` or `Theme.of(context).colorScheme`.

| Role | Method / Token | When to use |
|---|---|---|
| Primary accent | `cs.primary` | Buttons, active states, selected tabs |
| Period / menstruation | `AppTheme.periodColor(context)` | Period days, symptoms, period-related UI |
| Period background | `AppTheme.periodLightColor(context)` | Light fill behind period day cells |
| Predicted cycle | `AppTheme.predictedColor(context)` | Predicted period dots, "next period" stats |
| Fertility | `AppTheme.fertileColor(context)` | Fertile window indicators |
| Mood | `AppTheme.moodColor(context)` | Mood chips, mood section headers |
| Sexual activity | `AppTheme.activityColor(context)` | Activity logs, activity dots, activity sheets |
| Log indicator | `AppTheme.logDotColor(context)` | Small dot on calendar days with any log |
| Card background | `cs.surfaceContainerHighest` | Cards, bottom sheets, input fill |
| Scaffold background | `cs.surface` | Page backgrounds |
| Primary text | `cs.onSurface` | Body text, titles |
| Secondary text | `cs.onSurface` at 0.4–0.6 alpha | Labels, captions, hints |
| Borders | `cs.outline` at 0.2–0.3 alpha | Card borders, dividers, input outlines |
| Destructive | `cs.error` | Delete buttons, clear-data actions |

**Hard rule:** If you need a color that doesn't exist in the table above, add it to `AppTheme` first — don't inline it.

## Typography

Use Flutter's default system font (San Francisco on iOS, Roboto on Android). No custom fonts.

| Level | Size | Weight | Use |
|---|---|---|---|
| Nav title | 17 | w600 | App bar titles |
| Section header | 14 | w600 | Section labels in log/settings |
| Body | 14–15 | w400–w500 | Card content, list items |
| Caption | 12–13 | w400–w500 | Timestamps, secondary labels, tab labels |
| Large stat | 28 | w700 | Dashboard numbers (cycle day, days until) |
| Small stat unit | 13 | w400 | "days", "avg" next to large numbers |

Apply negative letter-spacing (-0.2 to -0.5) on bold/large text for a tighter, modern look. Never use positive letter-spacing on body text.

## Layout and spacing

- Scaffold padding: `EdgeInsets.fromLTRB(16, 8, 16, 32)` for scrollable pages.
- Card margin: 16px horizontal, 6px vertical (set in theme — don't override).
- Card internal padding: 16–24px depending on density.
- Section spacing: 24–28px between sections in forms/log screens.
- Element spacing within a section: 8–10px.
- Bottom sheets: 24px horizontal padding, 4px top, 24px bottom.

## Component patterns

### Cards
- Border radius: 18px. Elevation: 1 with low-alpha shadow (`shadow` at 0.08 alpha). No border stroke.
- Always use the `Card` widget — it inherits the theme automatically.
- Content alignment: left-aligned text, top-aligned icons.

### Chips (selectable options)
- Border radius: 20px (pill shape).
- Unselected: `outline` at 0.08 alpha background, transparent border.
- Selected: semantic color at 0.15–0.2 alpha background, solid semantic color border (1.5px).
- Selected text: semantic color, w600. Unselected text: `onSurface`, w400.
- Use `AnimatedContainer` for smooth selection transitions (150ms).

### Buttons
- Filled (primary action): `FilledButton`, theme handles styling.
- Outlined (secondary action): `OutlinedButton`, theme handles styling.
- Text/destructive: `TextButton` with `cs.error` color.
- Full-width for form save buttons: `SizedBox(width: double.infinity)` wrapper.

### Calendar day cells
- Shape: circle (via `BoxDecoration(shape: BoxShape.circle)`).
- Period day: `periodLightColor` fill, `periodColor` text, w600.
- Selected day: solid `periodColor` fill, white text.
- Today (not selected): `periodColor` border (1.5px), no fill.
- Predicted: small dot (5px) at bottom center, `predictedColor`.
- Has logs: small dot (5px) at top-right, `logDotColor`.
- Has sexual activity: small dot (5px) at top-left, `activityColor`.

### Bottom sheets
- 20px rounded top corners, drag handle visible.
- Title: `titleMedium`, w600, centered.
- Section labels: 14px, w600, left-aligned.
- Input fields: filled with `surfaceContainerHighest`, 12px radius, `outline` at 0.2 border.

### Section labels
- Pattern: `Row` with `Icon` (18px, semantic color) + 8px gap + `Text` (14px, w600, `onSurface`).
- Consistent across all log/form screens.

## Do

- Use `Theme.of(context).colorScheme` for all surface/text/border colors.
- Use `AppTheme.*Color(context)` for all domain-specific colors.
- Use `withValues(alpha: ...)` for opacity (not `withOpacity`).
- Support both light and dark mode — test both.
- Keep card elevation at 1 with soft shadow. No border strokes on cards.
- Use `AnimatedContainer` for interactive state changes.

## Don't

- Don't use `Colors.red`, `Colors.purple`, `Colors.pink`, or any `Colors.*` in screen code. Go through the theme.
- Don't add heavy drop shadows or high elevation values.
- Don't use emoji in UI labels or section headers. Emoji are only acceptable in notification message content.
- Don't hardcode light-mode-only colors — always derive from `colorScheme` or `AppTheme` semantic methods.
- Don't override card margin/shape/elevation inline — the theme handles it.
- Don't use `Opacity` widget for text dimming — use alpha on the color instead.
