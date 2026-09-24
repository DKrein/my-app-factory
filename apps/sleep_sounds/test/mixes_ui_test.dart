import 'package:factory_ads/factory_ads.dart';
import 'package:factory_audio/factory_audio.dart';
import 'package:factory_billing/factory_billing.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/features/mixes/mix_chips.dart';
import 'package:sleep_sounds/features/pro/paywall_page.dart';
import 'package:sleep_sounds/features/pro/pro_features.dart';
import 'package:sleep_sounds/main.dart';

void main() {
  late List<PreviewAudioGateway> gateways;
  late MemoryKeyValueStore storage;

  Future<void> pumpApp(
    WidgetTester tester, {
    bool pro = true,
    String? savedMixes,
  }) async {
    gateways = [];
    storage = MemoryKeyValueStore();
    if (savedMixes != null) {
      await storage.writeString('saved_mixes', savedMixes);
    }
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    final billing = FakeBillingGateway(
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

  Finder chip(String name) =>
      find.descendant(of: find.byType(MixChips), matching: find.text(name));

  Finder saveButton([String tooltip = 'Save mix']) => find.byTooltip(tooltip);

  Future<void> saveCurrentAs(WidgetTester tester, [String? name]) async {
    await tester.tap(saveButton());
    await tester.pumpAndSettle();
    if (name != null) {
      await tester.enterText(find.byType(TextField), name);
      await tester.pump();
    }
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
  }

  const oneMix =
      '{"schema":1,"mixes":[{"name":"Bedtime","volumes":{"waves":0.5,"rain":1.0},"timerMinutes":180}]}';

  testWidgets('with no sounds there is nothing to save, and no chips', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(
      tester
          .widget<IconButton>(
            find.ancestor(of: saveButton(), matching: find.byType(IconButton)),
          )
          .onPressed,
      isNull,
    );
    expect(find.byType(MixChips), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MixChips),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
  });

  testWidgets('saving names the mix "Mix 1" and shows it as a chip', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(card('Rain'));
    await tester.tap(card('Waves'));
    await tester.pump();

    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    expect(find.text('Save mix'), findsWidgets);
    expect(find.widgetWithText(TextField, 'Mix 1'), findsOneWidget);
    expect(find.text('Include timer (1h)'), findsOneWidget);

    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(chip('Mix 1'), findsOneWidget);
    final saved = await storage.readString('saved_mixes');
    expect(saved, contains('"name":"Mix 1"'));
    expect(saved, contains('"timerMinutes":60'));
  });

  testWidgets('the timer can be left out of the mix', (tester) async {
    await pumpApp(tester);
    await tester.tap(card('Rain'));
    await tester.pump();

    await tester.tap(saveButton());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(
      await storage.readString('saved_mixes'),
      isNot(contains('timerMinutes')),
    );
  });

  testWidgets('a name already in use asks for another one', (tester) async {
    await pumpApp(tester, savedMixes: oneMix);
    await tester.tap(card('Rain'));
    await tester.pump();

    await tester.tap(saveButton());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bedtime');
    await tester.pump();

    expect(
      find.text('That name is already used. Pick another.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField), 'Storm night');
    await tester.pump();
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(chip('Storm night'), findsOneWidget);
    expect(chip('Bedtime'), findsOneWidget);
  });

  testWidgets('tapping a chip loads the mix and plays it', (tester) async {
    await pumpApp(tester, savedMixes: oneMix);
    await tester.tap(card('Rain in tent'));
    await tester.pump();

    await tester.tap(chip('Bedtime'));
    await tester.pumpAndSettle();

    final playing = gateways
        .where((g) => g.playingAsset != null)
        .map((g) => g.playingAsset);
    expect(
      playing,
      unorderedEquals(['assets/audio/rain.ogg', 'assets/audio/waves.ogg']),
    );
    expect(find.text('Stopping in 3h 00m'), findsOneWidget);
  });

  group('without Pro', () {
    testWidgets('the first mix can be saved, the second opens the paywall', (
      tester,
    ) async {
      await pumpApp(tester, pro: false);
      await tester.tap(card('Rain'));
      await tester.pump();
      await saveCurrentAs(tester);

      expect(chip('Mix 1'), findsOneWidget);
      expect(saveButton(), findsNothing);
      expect(saveButton('Save mix (Pro)'), findsOneWidget);

      await tester.tap(saveButton('Save mix (Pro)'));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallPage), findsOneWidget);
      expect(find.text('Save mix'), findsNothing);
    });

    testWidgets('loading a saved mix is never locked', (tester) async {
      await pumpApp(tester, pro: false, savedMixes: oneMix);

      await tester.tap(chip('Bedtime'));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallPage), findsNothing);
      expect(gateways.where((g) => g.playingAsset != null), hasLength(2));
    });

    testWidgets('deleting the only mix frees the slot again', (tester) async {
      await pumpApp(tester, pro: false, savedMixes: oneMix);
      await tester.tap(card('Rain'));
      await tester.pump();
      expect(saveButton('Save mix (Pro)'), findsOneWidget);

      await tester.longPress(chip('Bedtime'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(chip('Bedtime'), findsNothing);
      expect(saveButton(), findsOneWidget);
    });
  });

  group('with Pro', () {
    testWidgets('any number of mixes can be saved', (tester) async {
      await pumpApp(tester, savedMixes: oneMix);
      await tester.tap(card('Rain'));
      await tester.pump();

      await saveCurrentAs(tester);
      await saveCurrentAs(tester);

      expect(chip('Bedtime'), findsOneWidget);
      expect(chip('Mix 1'), findsOneWidget);
      expect(chip('Mix 2'), findsOneWidget);
      expect(find.byType(PaywallPage), findsNothing);
    });
  });

  group('renaming', () {
    testWidgets('a long press renames a mix', (tester) async {
      await pumpApp(tester, savedMixes: oneMix);

      await tester.longPress(chip('Bedtime'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Deep sleep');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
      await tester.pumpAndSettle();

      expect(chip('Deep sleep'), findsOneWidget);
      expect(chip('Bedtime'), findsNothing);
    });

    testWidgets('renaming to an existing name is refused', (tester) async {
      await pumpApp(
        tester,
        savedMixes: '{"schema":1,"mixes":[{"name":"A","volumes":{"rain":1.0}},{"name":"B","volumes":{"waves":1.0}}]}',
      );

      await tester.longPress(chip('A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'b');
      await tester.pump();

      expect(
        find.text('That name is already used. Pick another.'),
        findsOneWidget,
      );
    });
  });
}
