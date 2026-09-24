import 'package:factory_ads/factory_ads.dart';
import 'package:factory_audio/factory_audio.dart';
import 'package:factory_billing/factory_billing.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sleep_sounds/features/common/starfield_background.dart';
import 'package:sleep_sounds/features/pro/paywall_page.dart';
import 'package:sleep_sounds/features/pro/pro_features.dart';
import 'package:sleep_sounds/features/theme/theme_controller.dart';
import 'package:sleep_sounds/features/theme/theme_picker.dart';
import 'package:sleep_sounds/main.dart';

void main() {
  group('ThemeController', () {
    late MemoryKeyValueStore storage;
    late ThemeController themes;

    setUp(() {
      storage = MemoryKeyValueStore();
      themes = ThemeController(storage);
    });

    test('starts on Capy Night and offers every palette', () {
      expect(themes.selected, FactoryPalette.capyNight);
      expect(themes.options, FactoryPalette.all);
    });

    test('a pick is saved by id and restored', () async {
      themes.select(FactoryPalette.plumDusk);
      await Future<void>.delayed(Duration.zero);

      expect(await storage.readString('theme_v1'), 'plum_dusk');

      final restored = ThemeController(storage);
      await restored.load();

      expect(restored.selected, FactoryPalette.plumDusk);
    });

    test('an id that no longer exists loads as Capy Night', () async {
      await storage.writeString('theme_v1', 'retired_theme');

      await themes.load();

      expect(themes.selected, FactoryPalette.capyNight);
    });

    test('picking the same palette again changes and saves nothing', () {
      var notified = 0;
      themes.addListener(() => notified++);

      themes.select(FactoryPalette.capyNight);

      expect(notified, 0);
    });
  });

  group('ProFeatures.canUseTheme', () {
    test('only Capy Night is free', () {
      final billing = FakeBillingGateway(catalog: sleepSoundsCatalog);
      final pro = ProFeatures(billing.entitlements);

      expect(pro.canUseTheme(FactoryPalette.capyNight), isTrue);
      for (final p in FactoryPalette.all.skip(1)) {
        expect(pro.canUseTheme(p), isFalse, reason: p.name);
      }
    });

    test('Pro can use every palette', () {
      final billing = FakeBillingGateway(catalog: sleepSoundsCatalog)
        ..entitlements.grant([ProFeatures.entitlement]);
      final pro = ProFeatures(billing.entitlements);

      for (final p in FactoryPalette.all) {
        expect(pro.canUseTheme(p), isTrue, reason: p.name);
      }
    });
  });

  group('in the app', () {
    late MemoryKeyValueStore storage;
    late FakeBillingGateway billing;

    Future<void> pumpApp(
      WidgetTester tester, {
      required bool pro,
      String? savedTheme,
    }) async {
      storage = MemoryKeyValueStore();
      if (savedTheme != null) {
        await storage.writeString('theme_v1', savedTheme);
      }
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      billing = FakeBillingGateway(
        catalog: sleepSoundsCatalog,
        initialProducts: [defaultProProduct],
      );
      if (pro) billing.entitlements.grant([ProFeatures.entitlement]);
      await tester.pumpWidget(
        SleepSoundsApp(
          storage: storage,
          createGateway: ({required ownsAudioSession}) => PreviewAudioGateway(),
          ads: PreviewAdsGateway(initialized: true),
          billing: billing,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pumpAndSettle();
    }

    FactoryPalette shown(WidgetTester tester) => tester
        .widget<MaterialApp>(find.byType(MaterialApp))
        .theme!
        .extension<FactoryPalette>()!;

    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pumpAndSettle();
    }

    testWidgets('a new user sees Capy Night', (tester) async {
      await pumpApp(tester, pro: false);

      expect(shown(tester), FactoryPalette.capyNight);
    });

    testWidgets('a Pro user gets the palette they saved', (tester) async {
      await pumpApp(tester, pro: true, savedTheme: 'amber_ember');

      expect(shown(tester), FactoryPalette.amberEmber);
    });

    testWidgets('someone without Pro goes back to Capy Night', (tester) async {
      await pumpApp(tester, pro: false, savedTheme: 'amber_ember');

      expect(shown(tester), FactoryPalette.capyNight);
      expect(await storage.readString('theme_v1'), 'amber_ember');
    });

    testWidgets('losing Pro switches back, and the pick is kept for later', (
      tester,
    ) async {
      await pumpApp(tester, pro: true, savedTheme: 'moss_forest');
      expect(shown(tester), FactoryPalette.mossForest);

      billing.entitlements.revoke(ProFeatures.entitlement);
      await tester.pumpAndSettle();

      expect(shown(tester), FactoryPalette.capyNight);
      expect(await storage.readString('theme_v1'), 'moss_forest');

      billing.entitlements.grant([ProFeatures.entitlement]);
      await tester.pumpAndSettle();

      expect(shown(tester), FactoryPalette.mossForest);
    });

    group('the picker in Settings', () {
      testWidgets('lists the four themes and shows the current one', (
        tester,
      ) async {
        await pumpApp(tester, pro: true);
        await openSettings(tester);

        for (final name in ['Amber Ember', 'Moss Forest', 'Plum Dusk']) {
          expect(find.text(name), findsOneWidget);
        }
        expect(find.text('Capy Night'), findsNWidgets(2));
        expect(find.byIcon(Symbols.check_circle_rounded), findsOneWidget);
      });

      testWidgets('without Pro the extra themes are locked', (tester) async {
        await pumpApp(tester, pro: false);
        await openSettings(tester);

        final locks = find.descendant(
          of: find.byType(ThemePicker),
          matching: find.byIcon(Symbols.lock_rounded),
        );
        expect(locks, findsNWidgets(3));
        expect(
          find.text('Extra themes are part of Sleepy Capy Pro.'),
          findsOneWidget,
        );
      });

      testWidgets(
        'tapping a locked theme opens the paywall and changes nothing',
        (tester) async {
          await pumpApp(tester, pro: false);
          await openSettings(tester);

          await tester.tap(find.text('Plum Dusk'));
          await tester.pumpAndSettle();

          expect(find.byType(PaywallPage), findsOneWidget);
          expect(shown(tester), FactoryPalette.capyNight);
          expect(await storage.readString('theme_v1'), isNull);
        },
      );

      testWidgets('a Pro user picks a theme and it is applied and saved', (
        tester,
      ) async {
        await pumpApp(tester, pro: true);
        await openSettings(tester);

        await tester.tap(find.text('Plum Dusk'));
        await tester.pumpAndSettle();

        expect(shown(tester), FactoryPalette.plumDusk);
        expect(await storage.readString('theme_v1'), 'plum_dusk');
        expect(find.byType(PaywallPage), findsNothing);
        expect(find.byIcon(Symbols.lock_rounded), findsNothing);
      });

      testWidgets('buying Pro from the lock unlocks the themes', (
        tester,
      ) async {
        await pumpApp(tester, pro: false);
        await openSettings(tester);
        await tester.tap(find.text('Moss Forest'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Get Pro'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Moss Forest'));
        await tester.pumpAndSettle();

        expect(shown(tester), FactoryPalette.mossForest);
      });
    });

    testWidgets('Settings draws with the palette, not with fixed colors', (
      tester,
    ) async {
      await pumpApp(tester, pro: true, savedTheme: 'amber_ember');
      await openSettings(tester);

      final card = tester.widget<Container>(
        find
            .ancestor(of: find.text('Theme'), matching: find.byType(Container))
            .first,
      );
      expect(
        (card.decoration! as BoxDecoration).color,
        FactoryPalette.amberEmber.surfaceElevated,
      );
    });

    testWidgets('the stars are white on every theme', (tester) async {
      await pumpApp(tester, pro: true, savedTheme: 'plum_dusk');

      final images = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(StarfieldBackground),
              matching: find.byType(Container),
            ),
          )
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.image)
          .nonNulls;

      expect(images, isNotEmpty);
      for (final image in images) {
        expect(
          image.colorFilter,
          const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        );
      }
    });
  });
}
