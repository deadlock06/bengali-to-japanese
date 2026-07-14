// Bhasago — brand theme & design tokens. (v4 design refresh — "Bold Ink")
//
// Brand story update: sumi-ink black canvas; four solid accent inks —
// yellow (attention/current), pink (review/memory), blue (AI/exam),
// green (growth/progress). Color is used as ACCENT on near-black surfaces;
// one statement card per screen, everything else stays quiet.
//
// Psych-STATE colors (flow / struggle / burnout / boredom) are unchanged and
// live in [BhasagoStateColors] — functional, never the resting palette.
//
// Fonts (declare in pubspec.yaml, assets from Google Fonts):
//   Baloo Da 2          — Bengali + display headings
//   Zen Kaku Gothic New — Japanese
//   Archivo             — Latin UI labels
//   Space Grotesk       — numbers / tags (optional)
//
// Usage:  MaterialApp(theme: BhasagoTheme.dark(), ...)

import 'package:flutter/material.dart';

/// Raw brand tokens (v4). Prefer Theme.of(context).colorScheme; use these
/// directly only for brand chrome (logo, splash, the four accent cards).
abstract final class BhasagoColors {
  // Ink darks
  static const bg = Color(0xFF0F0F0F); // app background
  static const surface = Color(0xFF1A1A1A);
  static const surfaceHigh = Color(0xFF242424);
  static const outline = Color(0xFF2E2E2E);

  // Accent inks — solid fills, always with near-black (#111) content on top
  static const yellow = Color(0xFFEFE94B); // current lesson / primary action
  static const pink = Color(0xFFF06EB7); // review / memory
  static const blue = Color(0xFF4D7DF7); // AI examiner / mock exam
  static const green = Color(0xFF35E065); // progress / success / live chart

  // Content-on-accent darks (text/icons placed on the accent fills)
  static const onYellow = Color(0xFF111111);
  static const yellowDim = Color(0xFF3D3B10);
  static const pinkDim = Color(0xFF6B1C44);
  static const blueDim = Color(0xFF0E2A6B);
  static const greenDim = Color(0xFF0B5225);

  static const ink = Color(0xFFF5F5F0); // primary text on dark
  static const inkDim = Color(0xFF8F8F8A); // secondary text
  static const error = Color(0xFFD6357E); // alert error (pink family)
  static const success = Color(0xFF1FA84E); // alert success (green family)

  // Japanese background motif (very low opacity decorative layer)
  static const sun = Color(0xFFD84040); // red sun radial, ~0.3 alpha max
}

/// Functional psych-state colors from 09_UI_STATES — UNCHANGED from v0.1.
abstract final class BhasagoStateColors {
  static const flow = Color(0xFF00C853);
  static const struggle = Color(0xFFFF6D00);
  static const burnout = Color(0xFF2979FF);
  static const boredom = Color(0xFFAA00FF);
}

abstract final class BhasagoTheme {
  // Aliases used by the v4 handoff screens (step6 lesson, curriculum, book).
  // Same values as BhasagoColors — keep in sync.
  static const bg = BhasagoColors.bg;
  static const card = BhasagoColors.surface;
  static const outline = BhasagoColors.outline;
  static const pillOutline = Color(0xFF3A3A3A);
  static const text = BhasagoColors.ink;
  static const muted = BhasagoColors.inkDim;

  static const _radiusCard = 20.0; // v4: cards
  static const _radiusField = 14.0;

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: BhasagoColors.yellow,
      onPrimary: BhasagoColors.onYellow,
      primaryContainer: Color(0xFF4A470F),
      onPrimaryContainer: Color(0xFFF7F3A9),
      secondary: BhasagoColors.pink,
      onSecondary: Color(0xFF111111),
      secondaryContainer: Color(0xFF4A1030),
      onSecondaryContainer: Color(0xFFFBD4EA),
      tertiary: BhasagoColors.green,
      onTertiary: Color(0xFF111111),
      tertiaryContainer: Color(0xFF0B3D20),
      onTertiaryContainer: Color(0xFFC7F5D6),
      error: BhasagoColors.error,
      onError: Color(0xFFFFFFFF),
      surface: BhasagoColors.surface,
      onSurface: BhasagoColors.ink,
      surfaceContainerHighest: BhasagoColors.surfaceHigh,
      onSurfaceVariant: BhasagoColors.inkDim,
      outline: BhasagoColors.outline,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: BhasagoColors.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: BhasagoColors.bg,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: BhasagoColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusCard),
          side: const BorderSide(color: BhasagoColors.outline),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      // v4: all buttons are stadium pills
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48), // spec: touch target >=48dp
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: const StadiumBorder(),
          side: const BorderSide(color: Color(0xFF3A3A3A), width: 1.5),
          foregroundColor: BhasagoColors.ink,
        ),
      ),
      // v4: active destination = ink-white pill, icon+label dark
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0B0B0B),
        indicatorColor: BhasagoColors.ink,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF111111));
          }
          return const IconThemeData(color: BhasagoColors.inkDim);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: BhasagoColors.ink,
            );
          }
          return const TextStyle(fontSize: 12, color: BhasagoColors.inkDim);
        }),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Colors.transparent,
        side: BorderSide(color: Color(0xFF3A3A3A), width: 1.5),
        shape: StadiumBorder(),
        labelStyle: TextStyle(color: BhasagoColors.inkDim),
        // selected chip: ink-white fill, dark label (see styleguide chips)
        selectedColor: BhasagoColors.ink,
        secondaryLabelStyle: TextStyle(
          color: Color(0xFF111111),
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerColor: BhasagoColors.outline,
      textTheme: _textTheme(base.textTheme),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BhasagoColors.surfaceHigh,
        contentTextStyle: const TextStyle(color: BhasagoColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: BhasagoColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusCard),
          side: const BorderSide(color: BhasagoColors.outline),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: BhasagoColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_radiusCard)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BhasagoColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusField),
          borderSide: const BorderSide(color: BhasagoColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusField),
          borderSide: const BorderSide(color: BhasagoColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusField),
          borderSide: const BorderSide(color: BhasagoColors.ink, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // Display = Baloo Da 2 (bn + headings); body inherits platform fallbacks.
  // Requires in pubspec.yaml:
  //   fonts:
  //     - family: Baloo Da 2        (w500..w800)
  //     - family: Zen Kaku Gothic New (w500/w700/w900)  — set via
  //       TextStyle(fontFamily: 'Zen Kaku Gothic New') on Japanese text widgets
  //     - family: Archivo           (w500/w700/w800)
  static TextTheme _textTheme(TextTheme base) {
    const display = 'Baloo Da 2';
    const latin = 'Archivo';
    // JP glyphs are absent from Baloo/Archivo; fall back to the brand JP face
    // app-wide (incl. mixed BN+JP strings) instead of the platform default.
    const jpFallback = ['Zen Kaku Gothic New', 'ZenKakuGothicNew'];
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: BhasagoColors.ink, fontFamily: display, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      displayMedium: base.displayMedium?.copyWith(color: BhasagoColors.ink, fontFamily: display, fontWeight: FontWeight.w800),
      displaySmall: base.displaySmall?.copyWith(color: BhasagoColors.ink, fontFamily: display, fontWeight: FontWeight.w800),
      headlineLarge: base.headlineLarge?.copyWith(color: BhasagoColors.ink, fontFamily: display, fontWeight: FontWeight.w800),
      headlineMedium: base.headlineMedium?.copyWith(color: BhasagoColors.ink, fontFamily: display, fontWeight: FontWeight.w700),
      headlineSmall: base.headlineSmall?.copyWith(color: BhasagoColors.ink, fontFamily: display, fontWeight: FontWeight.w700),
      titleLarge: base.titleLarge?.copyWith(color: BhasagoColors.ink, fontFamily: display, fontWeight: FontWeight.w700),
      titleMedium: base.titleMedium?.copyWith(color: BhasagoColors.ink, fontFamily: display, fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(color: BhasagoColors.inkDim, fontFamily: display, fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(color: BhasagoColors.ink, fontFamily: display),
      bodyMedium: base.bodyMedium?.copyWith(color: BhasagoColors.ink, fontFamily: display),
      bodySmall: base.bodySmall?.copyWith(color: BhasagoColors.inkDim, fontFamily: display),
      labelLarge: base.labelLarge?.copyWith(color: BhasagoColors.ink, fontFamily: latin, fontWeight: FontWeight.w700),
      labelMedium: base.labelMedium?.copyWith(color: BhasagoColors.inkDim, fontFamily: latin),
      labelSmall: base.labelSmall?.copyWith(color: BhasagoColors.inkDim, fontFamily: latin),
    ).apply(fontFamilyFallback: jpFallback);
  }
}
