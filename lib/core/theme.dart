import 'package:flutter/material.dart';

/// App theme following Apple Human Interface Guidelines.
///
/// HIG principles applied:
///   - System font (San Francisco on iOS, Roboto on Android — Flutter default)
///   - Muted, calm color palette — soft rose accent on neutral base
///   - Generous whitespace and padding
///   - Subtle depth through elevation and opacity, not heavy shadows
///   - Full light + dark mode support
///
/// Color roles:
///   primary    → muted rose (accent for buttons, highlights, active states)
///   surface    → off-white / dark gray (card and sheet backgrounds)
///   background → light neutral / near-black (scaffold background)
///   secondary  → warm gray (supporting text and icons)
class AppTheme {
  AppTheme._(); // Prevent instantiation.

  // ── Brand colors ────────────────────────────────────────────
  // These are the raw colors. They get mapped to semantic roles
  // in the ColorScheme below.

  static const _rose = Color(0xFFD4727E);       // Muted rose — primary
  static const _roseLight = Color(0xFFF2D4D7);  // Very light rose — highlights
  static const _roseDark = Color(0xFFB85A65);   // Deeper rose — dark mode primary
  static const _peach = Color(0xFFE8A87C);       // Warm peach — secondary accent
  static const _sage = Color(0xFF8EAA91);        // Muted sage — success/fertility
  static const _lavender = Color(0xFF9B8EC4);    // Soft lavender — mood/activity

  // ── Light theme ─────────────────────────────────────────────

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _rose,
      brightness: Brightness.light,
      primary: _rose,
      onPrimary: Colors.white,
      secondary: _peach,
      surface: const Color(0xFFF9F7F5),      // Warm off-white
      onSurface: const Color(0xFF1C1B1F),    // Near-black text
      surfaceContainerHighest: Colors.white,  // Card backgrounds
      outline: const Color(0xFFD6D3D0),       // Subtle borders
    );

    return _buildTheme(colorScheme);
  }

  // ── Dark theme ──────────────────────────────────────────────

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _rose,
      brightness: Brightness.dark,
      primary: _roseDark,
      onPrimary: Colors.white,
      secondary: _peach,
      surface: const Color(0xFF1C1B1F),          // Near-black
      onSurface: const Color(0xFFE6E1E5),        // Light gray text
      surfaceContainerHighest: const Color(0xFF2B2930), // Card backgrounds
      outline: const Color(0xFF49454F),           // Subtle borders
    );

    return _buildTheme(colorScheme);
  }

  // ── Shared theme builder ────────────────────────────────────

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // ── App bar: flat, no elevation (HIG style) ──
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17, // iOS nav bar title size
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          letterSpacing: -0.4,
        ),
      ),

      // ── Bottom nav: clean, minimal ──
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF1C1B1F)
            : Colors.white,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ── Cards: rounded, subtle elevation ──
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ),

      // ── Buttons ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.4)),
        ),
      ),

      // ── Dividers ──
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.2),
        thickness: 0.5,
      ),

      // ── Bottom sheets: rounded top corners ──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
      ),

      // ── Chips ──
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
      ),

      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? Colors.grey.shade400 : Colors.grey.shade500;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return isDark
              ? Colors.grey.shade800
              : Colors.grey.shade300;
        }),
      ),
    );
  }

  // ── Semantic colors for cycle phases ────────────────────────
  // Used across screens for consistent color-coding.

  static Color periodColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _roseDark
          : _rose;

  static Color periodLightColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _roseDark.withValues(alpha: 0.3)
          : _roseLight;

  static Color predictedColor(BuildContext context) =>
      _peach;

  static Color fertileColor(BuildContext context) =>
      _sage;

  static Color moodColor(BuildContext context) =>
      _lavender;

  static Color logDotColor(BuildContext context) =>
      _sage;
}
