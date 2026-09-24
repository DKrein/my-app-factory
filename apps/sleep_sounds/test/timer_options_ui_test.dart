import 'package:factory_ads/factory_ads.dart';
import 'package:factory_audio/factory_audio.dart';
import 'package:factory_billing/factory_billing.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sleep_sounds/features/player/timer_options_sheet.dart';
import 'package:sleep_sounds/features/pro/paywall_page.dart';
import 'package:sleep_sounds/features/pro/pro_features.dart';
import 'package:sleep_sounds/main.dart';

void main() {
  late MemoryKeyValueStore storage;

  Future<void> pumpApp(WidgetTester tester, {required bool pro}) async {
    storage = MemoryKeyValueStore();
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
        createGateway: ({required ownsAudioSession}) => PreviewAudioGateway(),
        ads: PreviewAdsGateway(initialized: true),
        billing: billing,
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(GridView), matching: find.text('Rain')),
    );
    await tester.pump();
  }

  final sheetSlider = find.descendant(
    of: find.byType(TimerOptionsSheet),
    matching: find.byType(Slider),
  );

  Finder optionsButton([String tooltip = 'Timer options']) =>
      find.byTooltip(tooltip);

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(optionsButton());
    await tester.pumpAndSettle();
  }

  Future<void> pickFromDropdown(
    WidgetTester tester,
    int index,
    String option,
  ) async {
    await tester.tap(find.byType(DropdownButton<int>).at(index));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  group('without Pro', () {
    testWidgets('the options are visible with a lock and lead to the paywall', (
      tester,
    ) async {
      await pumpApp(tester, pro: false);

      expect(optionsButton('Timer options (Pro)'), findsOneWidget);
      expect(find.byIcon(Symbols.lock_rounded), findsWidgets);
      expect(find.byType(PaywallPage), findsNothing);

      await tester.tap(optionsButton('Timer options (Pro)'));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallPage), findsOneWidget);
      expect(find.byType(TimerOptionsSheet), findsNothing);
    });

    testWidgets('the free timer is unchanged', (tester) async {
      await pumpApp(tester, pro: false);

      expect(find.text('Stopping in 1h 00m'), findsOneWidget);
      expect(find.textContaining('fades'), findsNothing);
    });
  });

  group('with Pro', () {
    testWidgets('the button opens the options, not the paywall', (
      tester,
    ) async {
      await pumpApp(tester, pro: true);

      await openSheet(tester);

      expect(find.byType(TimerOptionsSheet), findsOneWidget);
      expect(find.text('Timer options'), findsWidgets);
      expect(find.byType(PaywallPage), findsNothing);
    });

    testWidgets(
      'the gradual fade is off until turned on, then shows in the status',
      (tester) async {
        await pumpApp(tester, pro: true);
        await openSheet(tester);

        expect(
          find.text('Off: the sound fades in the last 4 s.'),
          findsOneWidget,
        );

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        expect(find.text('Volume lowers over the last 5 min.'), findsOneWidget);

        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();

        expect(
          find.text('Stopping in 1h 00m · fades over the last 5 min'),
          findsOneWidget,
        );
        expect(
          await storage.readString('timer_options_v1'),
          contains('"gradualFade":true'),
        );
      },
    );

    testWidgets('the slider sets how long the fade lasts and is remembered', (
      tester,
    ) async {
      await pumpApp(tester, pro: true);
      await openSheet(tester);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await tester.drag(sheetSlider, const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(find.text('Volume lowers over the last 15 min.'), findsOneWidget);
      expect(
        await storage.readString('timer_options_v1'),
        contains('"fadeMinutes":15'),
      );
    });

    testWidgets('the slider is disabled while the fade is off', (tester) async {
      await pumpApp(tester, pro: true);
      await openSheet(tester);

      expect(tester.widget<Slider>(sheetSlider).onChanged, isNull);
    });

    testWidgets('a custom duration is set and shows in the carousel', (
      tester,
    ) async {
      await pumpApp(tester, pro: true);
      await openSheet(tester);

      await pickFromDropdown(tester, 1, '5 min');
      await tester.tap(find.byKey(const Key('set-custom-duration')));
      await tester.pumpAndSettle();

      expect(find.byType(TimerOptionsSheet), findsNothing);
      expect(find.text('Stopping in 2h 05m'), findsOneWidget);
      expect(find.text('2h 5m'), findsOneWidget);
      expect(
        await storage.readString('timer_options_v1'),
        contains('"customMinutes":125'),
      );
      expect(
        await storage.readString('last_session_v1'),
        contains('"timerMinutes":125'),
      );
    });

    testWidgets('zero hours and zero minutes cannot be set', (tester) async {
      await pumpApp(tester, pro: true);
      await openSheet(tester);

      await pickFromDropdown(tester, 0, '0 h');

      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('set-custom-duration')))
            .onPressed,
        isNull,
      );
    });

    testWidgets(
      'a stop-at time replaces the duration and picking one brings it back',
      (tester) async {
        await pumpApp(tester, pro: true);
        await openSheet(tester);

        await tester.tap(find.byKey(const Key('set-stop-at')));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Stopping at 7:00 AM · in '),
          findsOneWidget,
        );
        expect(find.text('7:00 AM'), findsOneWidget);

        await tester.tap(find.text('12h'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Stopping at'), findsNothing);
        expect(find.text('Stopping in 12h 00m'), findsOneWidget);
      },
    );

    testWidgets('the stop-at time is not saved with the session', (
      tester,
    ) async {
      await pumpApp(tester, pro: true);
      await openSheet(tester);

      await tester.tap(find.byKey(const Key('set-stop-at')));
      await tester.pumpAndSettle();

      final session = await storage.readString('last_session_v1');
      expect(session, contains('"timerMinutes":60'));
    });

    testWidgets('the stop-at option shows how long is left', (tester) async {
      await pumpApp(tester, pro: true);
      await openSheet(tester);

      expect(find.textContaining('in '), findsWidgets);
      expect(find.text('7:00 AM'), findsOneWidget);
    });
  });
}
