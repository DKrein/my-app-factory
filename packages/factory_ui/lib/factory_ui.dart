library;

import 'package:flutter/material.dart';

import 'src/palette.dart';

export 'src/about_screen.dart';
export 'src/palette.dart';

abstract final class FactorySpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// The app theme for [palette]. Screens read colors from the palette through
/// `context.palette`; this only wires Material widgets to the same colors.
ThemeData factoryDarkTheme([
  FactoryPalette palette = FactoryPalette.capyNight,
]) {
  final scheme = ColorScheme.dark(
    primary: palette.moon,
    onPrimary: palette.night,
    secondary: palette.mist,
    onSecondary: palette.night,
    surface: palette.surface,
    onSurface: palette.ink,
    outline: palette.outline,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.night,
    extensions: [palette],
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(fontSize: 15),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    dividerTheme: DividerThemeData(
      color: palette.divider,
      thickness: 1,
      space: 1,
      indent: FactorySpacing.lg,
      endIndent: FactorySpacing.lg,
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
  );
}
