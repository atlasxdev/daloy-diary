---
paths:
  - "lib/screens/**"
  - "lib/features/**"
---

# UI Typography & Layout

## Typography

Use **Material Design 3 type scale** via `Theme.of(context).textTheme`.
Default Android system font is **Roboto**. No custom fonts unless explicitly
approved and added to `AppTheme`.

Never hardcode `TextStyle` font sizes in screen code. Always reference
`textTheme.*` roles.

| M3 Role         | Flutter token    | Size | Weight | Use                                |
| --------------- | ---------------- | ---- | ------ | ---------------------------------- |
| Display Large   | `displayLarge`   | 57   | w400   | Rare; expressive hero moments only |
| Display Medium  | `displayMedium`  | 45   | w400   | Large hero stat numbers            |
| Display Small   | `displaySmall`   | 36   | w400   | Secondary hero numbers             |
| Headline Large  | `headlineLarge`  | 32   | w400   | Page-level screen headers          |
| Headline Medium | `headlineMedium` | 28   | w400   | Section or top-level titles        |
| Headline Small  | `headlineSmall`  | 24   | w400   | Sub-section headings               |
| Title Large     | `titleLarge`     | 22   | w400   | App bar titles, dialog titles      |
| Title Medium    | `titleMedium`    | 16   | w500   | Card titles, list headers          |
| Title Small     | `titleSmall`     | 14   | w500   | Section labels, tab labels         |
| Body Large      | `bodyLarge`      | 16   | w400   | Primary body text, list primary    |
| Body Medium     | `bodyMedium`     | 14   | w400   | Card content, list secondary       |
| Body Small      | `bodySmall`      | 12   | w400   | Timestamps, secondary captions     |
| Label Large     | `labelLarge`     | 14   | w500   | Button text, prominent labels      |
| Label Medium    | `labelMedium`    | 12   | w500   | Chip labels, filter text           |
| Label Small     | `labelSmall`     | 11   | w500   | Badge text, tiny metadata          |

Apply negative letter-spacing (-0.15 to -0.5) only on large display/headline
text for a tighter premium look. Use M3 default tracking on body and label
styles.

## Layout and spacing

Material Design 3 uses an **8dp base grid** (4dp for fine-grained adjustments).

- Scaffold padding: `EdgeInsets.fromLTRB(16, 0, 16, 24)` on scrollable pages.
- Content horizontal margin: 16dp standard; 24dp for comfortable/spacious pages.
- Card margin: 8dp vertical, 0dp horizontal (cards span the padded scaffold).
- Card internal padding: 16dp standard; 20–24dp for spacious contexts.
- Section spacing (between major groups): 24dp.
- Element spacing within a section: 8–12dp.
- Bottom sheets: 24dp horizontal padding, 28dp top drag handle area,
  32dp bottom (plus safe area).
- List item heights: 56dp (one-line), 72dp (two-line), 88dp (three-line).
- `NavigationBar` height: 80dp.
- Small `AppBar`: 64dp. Medium: 112dp. Large: 152dp.

## Do

- Use `Theme.of(context).textTheme` for all typography.

## Don't

- Don't use emoji in UI labels or section headers. Emoji are acceptable in
  notification message content only.
