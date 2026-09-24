import 'package:factory_ads/factory_ads.dart';
import 'package:factory_audio/factory_audio.dart';
import 'package:factory_billing/factory_billing.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sleep_sounds/features/player/player_controller.dart';
import 'package:sleep_sounds/features/pro/paywall_page.dart';
import 'package:sleep_sounds/features/pro/pro_features.dart';
import 'package:sleep_sounds/main.dart';

void main() {
  late List<PreviewAudioGateway> gateways;
  late FakeBillingGateway billing;
  late MemoryKeyValueStore storage;

  Future<void> pumpApp(WidgetTester tester, {required bool pro}) async {
    gateways = [];
    storage = MemoryKeyValueStore();
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
        createGateway: ({required ownsAudioSession}) {
          final gateway = PreviewAudioGateway();
          gateways.add(gateway);
          return gateway;
        },
        ads: PreviewAdsGateway(initialized: true),
        billing: billing,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3500));
    await tester.pumpAndSettle();
  }

  Finder card(String name) =>
      find.descendant(of: find.byType(GridView), matching: find.text(name));

  testWidgets('no volume control until a sound is active', (tester) async {
    await pumpApp(tester, pro: true);

    expect(find.byType(Slider), findsNothing);
    expect(find.byIcon(Symbols.lock_rounded), findsNothing);
  });

  group('with Pro', () {
    testWidgets('an active card has a slider that sets its volume', (
      tester,
    ) async {
      await pumpApp(tester, pro: true);

      await tester.tap(card('Rain'));
      await tester.pump();

      expect(find.byType(Slider), findsOneWidget);
      expect(find.byIcon(Symbols.lock_rounded), findsNothing);
      expect(gateways.single.volume, closeTo(.7, 1e-9));

      await tester.drag(find.byType(Slider), const Offset(-40, 0));
      await tester.pump();

      expect(gateways.single.volume, lessThan(.7));
      expect(gateways.single.volume, greaterThan(0));
      expect(find.byType(PaywallPage), findsNothing);
    });

    testWidgets('letting go saves the volume with the session', (tester) async {
      await pumpApp(tester, pro: true);
      await tester.tap(card('Rain'));
      await tester.pump();

      await tester.drag(find.byType(Slider), const Offset(-40, 0));
      await tester.pump();

      final saved = await storage.readString('last_session_v1');
      expect(saved, contains('"volumes":{"rain":0.'));
    });

    testWidgets('each active card keeps its own volume', (tester) async {
      await pumpApp(tester, pro: true);
      await tester.tap(card('Rain'));
      await tester.tap(card('Waves'));
      await tester.pump();

      expect(find.byType(Slider), findsNWidgets(2));

      await tester.drag(find.byType(Slider).first, const Offset(-40, 0));
      await tester.pump();

      final gainOfQuiet = gateways[0].volume;
      final gainOfFull = gateways[1].volume;
      expect(gainOfQuiet, lessThan(gainOfFull));
    });
  });

  group('without Pro', () {
    testWidgets('the control is visible but locked', (tester) async {
      await pumpApp(tester, pro: false);

      await tester.tap(card('Rain'));
      await tester.pump();

      expect(find.byType(Slider), findsNothing);
      expect(find.byIcon(Symbols.lock_rounded), findsOneWidget);
    });

    testWidgets('tapping the lock opens the paywall and keeps the sound', (
      tester,
    ) async {
      await pumpApp(tester, pro: false);
      await tester.tap(card('Rain'));
      await tester.pump();
      expect(find.byType(PaywallPage), findsNothing);

      await tester.tap(find.byIcon(Symbols.lock_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallPage), findsOneWidget);
      expect(gateways.single.playingAsset, 'assets/audio/rain.ogg');
      expect(
        (await storage.readString('last_session_v1')),
        contains('"soundIds":["rain"]'),
      );
    });

    testWidgets('buying Pro from the lock unlocks the slider', (tester) async {
      await pumpApp(tester, pro: false);
      await tester.tap(card('Rain'));
      await tester.pump();
      await tester.tap(find.byIcon(Symbols.lock_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Pro'));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallPage), findsNothing);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byIcon(Symbols.lock_rounded), findsNothing);
    });

    testWidgets('volumes stay at full without Pro', (tester) async {
      await pumpApp(tester, pro: false);
      await tester.tap(card('Rain'));
      await tester.pump();

      expect(gateways.single.volume, PlaybackController.mixGain(1, 1));
    });
  });
}
