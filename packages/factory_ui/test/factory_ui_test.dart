import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FactoryUI tokens', () {
    test('FactoryColors has defined palette', () {
      expect(FactoryColors.night, const Color(0xFF0B1020));
      expect(FactoryColors.surface, const Color(0xFF151C33));
      expect(FactoryColors.moon, const Color(0xFFAFC8FF));
    });

    test('divider is white at 8% opacity', () {
      expect(FactoryColors.divider.a, closeTo(.08, .005));
      expect(FactoryColors.divider.r, 1.0);
    });

    test('FactorySpacing has consistent scale', () {
      expect(FactorySpacing.xs, equals(4.0));
      expect(FactorySpacing.sm, equals(8.0));
      expect(FactorySpacing.md, equals(12.0));
      expect(FactorySpacing.lg, equals(16.0));
      expect(FactorySpacing.xl, equals(24.0));
    });
  });

  group('factoryDarkTheme', () {
    test('dividers share color and a 16 dp inset', () {
      final divider = factoryDarkTheme().dividerTheme;
      expect(divider.color, FactoryColors.divider);
      expect(divider.indent, FactorySpacing.lg);
      expect(divider.endIndent, FactorySpacing.lg);
    });

    test('builds Material 3 dark theme with factory colors', () {
      final theme = factoryDarkTheme();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, FactoryColors.night);
      expect(theme.colorScheme.primary, FactoryColors.moon);
      expect(theme.colorScheme.surface, FactoryColors.surface);
    });
  });
}
