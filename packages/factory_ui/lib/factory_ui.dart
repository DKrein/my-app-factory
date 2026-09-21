library;

import 'package:flutter/material.dart';

abstract final class FactoryColors {
  static const night = Color(0xFF0B1020);
  static const surface = Color(0xFF151C33);
  static const surfaceElevated = Color(0xFF1D2745);
  static const moon = Color(0xFFAFC8FF);
  static const mist = Color(0xFF8ED9C7);
  static const ink = Color(0xFFF4F7FF);
  static const mutedInk = Color(0xFFB8C1D9);
  static const outline = Color(0xFF3B4768);
}

abstract final class FactorySpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

ThemeData factoryDarkTheme() {
  const scheme = ColorScheme.dark(
    primary: FactoryColors.moon,
    onPrimary: FactoryColors.night,
    secondary: FactoryColors.mist,
    onSecondary: FactoryColors.night,
    surface: FactoryColors.surface,
    onSurface: FactoryColors.ink,
    outline: FactoryColors.outline,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: FactoryColors.night,
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(fontSize: 15),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    cardTheme: const CardThemeData(
      color: FactoryColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
  );
}
