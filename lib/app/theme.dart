// Bhasago — brand theme & design tokens.
//
// Brand story: "Ai" indigo (藍 / নীল) bridges Bengal's indigo heritage and
// Japanese aizome; Sakura vermilion is the torii gateway to Japan. Sumi-ink
// darks keep the app calm and battery-friendly on budget AMOLED devices.
//
// Colors map to the 09_UI_STATES design system. Psych-STATE colors (flow /
// struggle / burnout / boredom) are functional and live in [BhasagoStateColors];
// the resting brand identity is Ai indigo + Sakura, never a volatile state hue.
//
// Usage:  MaterialApp(theme: BhasagoTheme.dark(), ...)
// Note: pure ColorScheme/shape theming — no custom font family is set here so
// there are no missing-asset risks. To adopt Noto Sans Bengali/JP later, declare
// the fonts in pubspec and pass `fontFamily` into [_textTheme].

import 'package:flutter/material.dart';

/// Raw brand tokens. Prefer reading colors from `Theme.of(context).colorScheme`;
/// use these directly only for brand chrome (logo, splash, state screens).
abstract final class BhasagoColors {
  // Sumi-ink darks
  static const bg = Color(0xFF0E1116); // app background (matches prior build)
  static const surface = Color(0xFF171B22);
  static const surfaceHigh = Color(0xFF212734);
  static const outline = Color(0xFF2E3644);

  // Ai indigo — primary brand
  static const ai = Color(0xFF5B7CFA);
  static const aiBright = Color(0xFF8AA0FF); // primary on dark (contrast-safe)
  static const aiDeep = Color(0xFF29347A); // primaryContainer on dark

  // Sakura vermilion — secondary accent / torii
  static const sakura = Color(0xFFFF6F86);
  static const sakuraDeep = Color(0xFF7A2233);

  // Gold — mastery / rewards (predictable, never a loot surprise)
  static const gold = Color(0xFFFFC24B);

  static const ink = Color(0xFFF3F5FA); // primary text on dark
  static const inkDim = Color(0xFFAAB3C5); // secondary text
  static const error = Color(0xFFFF5370);
}

/// Functional psych-state colors from 09_UI_STATES. Used by state screens, not
/// as the resting brand palette.
abstract final class BhasagoStateColors {
  static const flow = Color(0xFF00C853); // optimal challenge
  static const struggle = Color(0xFFFF6D00); // rising errors — calm, warm
  static const burnout = Color(0xFF2979FF); // fatigue — zero motion
  static const boredom = Color(0xFFAA00FF); // autopilot — playful
}

abstract final class BhasagoTheme {
  static const _radius = 16.0;

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: BhasagoColors.aiBright,
      onPrimary: Color(0xFF0A1230),
      primaryContainer: BhasagoColors.aiDeep,
      onPrimaryContainer: Color(0xFFDDE4FF),
      secondary: BhasagoColors.sakura,
      onSecondary: Color(0xFF3A0710),
      secondaryContainer: BhasagoColors.sakuraDeep,
      onSecondaryContainer: Color(0xFFFFDCE2),
      tertiary: BhasagoColors.gold,
      onTertiary: Color(0xFF3A2A00),
      tertiaryContainer: Color(0xFF5C4200),
      onTertiaryContainer: Color(0xFFFFE6B0),
      error: BhasagoColors.error,
      onError: Color(0xFF3A0510),
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
          borderRadius: BorderRadius.circular(_radius),
          side: const BorderSide(color: BhasagoColors.outline),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48), // spec: touch target >=48dp
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: BhasagoColors.outline),
          foregroundColor: BhasagoColors.ink,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: BhasagoColors.surface,
        indicatorColor: BhasagoColors.aiDeep,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: BhasagoColors.aiBright,
            );
          }
          return const TextStyle(fontSize: 12, color: BhasagoColors.inkDim);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BhasagoColors.surfaceHigh,
        side: const BorderSide(color: BhasagoColors.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: const TextStyle(color: BhasagoColors.ink),
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
          borderRadius: BorderRadius.circular(_radius),
          side: const BorderSide(color: BhasagoColors.outline),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: BhasagoColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_radius)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BhasagoColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BhasagoColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BhasagoColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BhasagoColors.aiBright, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: BhasagoColors.ink),
      displayMedium: base.displayMedium?.copyWith(color: BhasagoColors.ink),
      displaySmall: base.displaySmall?.copyWith(color: BhasagoColors.ink),
      headlineLarge: base.headlineLarge?.copyWith(color: BhasagoColors.ink),
      headlineMedium: base.headlineMedium?.copyWith(color: BhasagoColors.ink),
      headlineSmall: base.headlineSmall?.copyWith(color: BhasagoColors.ink),
      titleLarge: base.titleLarge?.copyWith(color: BhasagoColors.ink, fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(color: BhasagoColors.ink, fontWeight: FontWeight.w500),
      titleSmall: base.titleSmall?.copyWith(color: BhasagoColors.inkDim, fontWeight: FontWeight.w500),
      bodyLarge: base.bodyLarge?.copyWith(color: BhasagoColors.ink),
      bodyMedium: base.bodyMedium?.copyWith(color: BhasagoColors.ink),
      bodySmall: base.bodySmall?.copyWith(color: BhasagoColors.inkDim),
      labelLarge: base.labelLarge?.copyWith(color: BhasagoColors.ink, fontWeight: FontWeight.w500),
      labelMedium: base.labelMedium?.copyWith(color: BhasagoColors.inkDim),
      labelSmall: base.labelSmall?.copyWith(color: BhasagoColors.inkDim),
    );
  }
}
