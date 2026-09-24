import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG contrast ratio between two colors.
double contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + .05) / (darker + .05);
}

void main() {
  group('every palette is readable', () {
    for (final p in FactoryPalette.all) {
      group(p.name, () {
        void atLeast(String pair, double ratio, Color a, Color b) {
          test('$pair is at least $ratio:1', () {
            expect(contrast(a, b), greaterThanOrEqualTo(ratio), reason: pair);
          });
        }

        // Text needs 4.5:1.
        atLeast('ink on night', 4.5, p.ink, p.night);
        atLeast('ink on surface', 4.5, p.ink, p.surface);
        atLeast('ink on surfaceElevated', 4.5, p.ink, p.surfaceElevated);
        atLeast('ink on activeSurface', 4.5, p.ink, p.activeSurface);
        atLeast('mutedInk on night', 4.5, p.mutedInk, p.night);
        atLeast('mutedInk on surface', 4.5, p.mutedInk, p.surface);
        atLeast(
          'mutedInk on surfaceElevated',
          4.5,
          p.mutedInk,
          p.surfaceElevated,
        );
        atLeast('mist on night', 4.5, p.mist, p.night);
        atLeast('mist on surface', 4.5, p.mist, p.surface);
        atLeast('mist on activeSurface', 4.5, p.mist, p.activeSurface);
        atLeast('moon on night', 4.5, p.moon, p.night);
        // Text on a filled button.
        atLeast('night on mist', 4.5, p.night, p.mist);
        atLeast('night on moon', 4.5, p.night, p.moon);
        // The border of the selected card must stand out from it.
        atLeast(
          'activeOutline on activeSurface',
          3,
          p.activeOutline,
          p.activeSurface,
        );
        // Borders are decorative, so they only need to be visible.
        atLeast('outline on night', 2, p.outline, p.night);
      });
    }
  });

  group('the list', () {
    test('ids are unique and not empty', () {
      final ids = FactoryPalette.all.map((p) => p.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, everyElement(isNotEmpty));
    });

    test('names are unique', () {
      final names = FactoryPalette.all.map((p) => p.name).toList();

      expect(names.toSet(), hasLength(names.length));
    });

    test('Capy Night is first and is the default', () {
      expect(FactoryPalette.all.first, FactoryPalette.capyNight);
      expect(FactoryPalette.byId(null), FactoryPalette.capyNight);
    });

    test('an unknown id falls back to Capy Night', () {
      expect(FactoryPalette.byId('gone'), FactoryPalette.capyNight);
      expect(FactoryPalette.byId('amber_ember'), FactoryPalette.amberEmber);
    });

    test('the four shipped palettes keep their ids', () {
      expect(FactoryPalette.all.map((p) => p.id), [
        'capy_night',
        'amber_ember',
        'moss_forest',
        'plum_dusk',
      ]);
    });

    test('Amber Ember has no blue: its blue is never above its red', () {
      for (final c in [
        FactoryPalette.amberEmber.night,
        FactoryPalette.amberEmber.surface,
        FactoryPalette.amberEmber.mist,
        FactoryPalette.amberEmber.moon,
        FactoryPalette.amberEmber.ink,
      ]) {
        expect(c.b, lessThanOrEqualTo(c.r));
      }
    });
  });

  group('the theme carries the palette', () {
    testWidgets('context.palette returns the palette of the theme', (
      tester,
    ) async {
      late FactoryPalette seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: factoryDarkTheme(FactoryPalette.plumDusk),
          home: Builder(
            builder: (context) {
              seen = context.palette;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(seen, FactoryPalette.plumDusk);
    });

    testWidgets('a theme without a palette shows Capy Night', (tester) async {
      late FactoryPalette seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              seen = FactoryPalette.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(seen, FactoryPalette.capyNight);
    });

    test('Material colors follow the palette', () {
      final theme = factoryDarkTheme(FactoryPalette.mossForest);

      expect(theme.scaffoldBackgroundColor, FactoryPalette.mossForest.night);
      expect(theme.colorScheme.primary, FactoryPalette.mossForest.moon);
      expect(theme.colorScheme.surface, FactoryPalette.mossForest.surface);
      expect(theme.cardTheme.color, FactoryPalette.mossForest.surface);
      expect(theme.dividerTheme.color, FactoryPalette.mossForest.divider);
    });

    test('lerp blends the colors and swaps the name halfway', () {
      final mid = FactoryPalette.capyNight.lerp(FactoryPalette.amberEmber, .5);

      expect(
        mid.night,
        Color.lerp(
          FactoryPalette.capyNight.night,
          FactoryPalette.amberEmber.night,
          .5,
        ),
      );
      expect(
        FactoryPalette.capyNight.lerp(FactoryPalette.amberEmber, .2).name,
        'Capy Night',
      );
      expect(
        FactoryPalette.capyNight.lerp(FactoryPalette.amberEmber, .8).name,
        'Amber Ember',
      );
    });

    test('copyWith changes only what it is given', () {
      final copy = FactoryPalette.capyNight.copyWith(mist: Colors.red);

      expect(copy.mist, Colors.red);
      expect(copy.night, FactoryPalette.capyNight.night);
      expect(copy.id, 'capy_night');
    });

    test('the divider is the same white at 8% on every palette', () {
      for (final p in FactoryPalette.all) {
        expect(p.divider, const Color(0x14FFFFFF));
      }
    });
  });
}
