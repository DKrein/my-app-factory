import 'package:factory_ads/factory_ads.dart';
import 'package:factory_audio/factory_audio.dart';
import 'package:factory_billing/factory_billing.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sleep_sounds/features/library/equalizer_bars.dart';
import 'package:sleep_sounds/main.dart';

Future<void> pumpPastSplash(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 3500));
  await tester.pumpAndSettle();
}

// The duration carousel virtualizes items far from the current page, so
// jumping straight to a distant label (e.g. '12h' -> '30m') can tap a
// widget that hasn't been built yet. Step through the adjacent, always-built
// neighbor instead, exactly like a user swiping one position at a time.
const _durationOrder = ['Off', '15m', '30m', '1h', '3h', '6h', '9h', '12h'];

Future<void> selectDuration(WidgetTester tester, String from, String to) async {
  var index = _durationOrder.indexOf(from);
  final target = _durationOrder.indexOf(to);
  final step = target > index ? 1 : -1;
  while (index != target) {
    index += step;
    await tester.tap(find.text(_durationOrder[index]));
    await tester.pumpAndSettle();
  }
}

late List<PreviewAudioGateway> gateways;

Finder soundCard(String name) =>
    find.descendant(of: find.byType(GridView), matching: find.text(name));

PreviewAudioGateway createGateway({required bool ownsAudioSession}) {
  final gateway = PreviewAudioGateway();
  gateways.add(gateway);
  return gateway;
}

Iterable<String> get playingAssets =>
    gateways.map((g) => g.playingAsset).nonNulls;

void main() {
  // The playing equalizer never settles; a real user with "remove
  // animations" on gets the same static bars.
  setUp(() {
    gateways = [];
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  });
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  testWidgets('SleepSoundsApp renders catalog, title, and initial banner', (
    tester,
  ) async {
    final storage = MemoryKeyValueStore();
    final ads = PreviewAdsGateway(initialized: true);
    final billing = FakeBillingGateway(
      catalog: sleepSoundsCatalog,
      initialProducts: [defaultRemoveAdsProduct],
    );

    await tester.pumpWidget(
      SleepSoundsApp(
        storage: storage,
        createGateway: createGateway,
        ads: ads,
        billing: billing,
      ),
    );
    await pumpPastSplash(tester);

    expect(find.text('Time to capy-nap'), findsOneWidget);
    expect(find.text('Rain'), findsOneWidget);
    expect(find.text('Waves'), findsOneWidget);

    // Initial banner is displayed
    expect(find.text('Preview Ad [banner_home]'), findsOneWidget);
  });

  testWidgets('opens with the last session selected but not playing', (
    tester,
  ) async {
    final storage = MemoryKeyValueStore();
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await storage.writeString(
      'last_session_v1',
      '{"soundIds":["rain"],"timerMinutes":180}',
    );

    await tester.pumpWidget(
      SleepSoundsApp(
        storage: storage,
        createGateway: createGateway,
        ads: PreviewAdsGateway(initialized: true),
        billing: FakeBillingGateway(catalog: sleepSoundsCatalog),
      ),
    );
    await pumpPastSplash(tester);

    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('3h'), findsOneWidget);
    expect(playingAssets, isEmpty);

    await tester.tap(find.byTooltip('Play'));
    await tester.pump();

    expect(playingAssets, hasLength(1));
    expect(find.textContaining('Stopping in 3h 00m'), findsOneWidget);

    await tester.tap(soundCard('Rain'));
    await tester.pump();
  });

  testWidgets('hearts: badge on inactive favorites, button only on active', (
    tester,
  ) async {
    final storage = MemoryKeyValueStore();
    await storage.writeString('favorites_sounds_v2', 'rain');
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      SleepSoundsApp(
        storage: storage,
        createGateway: createGateway,
        ads: PreviewAdsGateway(initialized: true),
        billing: FakeBillingGateway(catalog: sleepSoundsCatalog),
      ),
    );
    await pumpPastSplash(tester);

    expect(find.byIcon(Symbols.favorite_rounded), findsNWidgets(2));
    expect(find.byTooltip('Add to favorites'), findsNothing);
    expect(find.byTooltip('Remove from favorites'), findsNothing);

    await tester.tap(soundCard('Waves'));
    await tester.pump();

    expect(find.byTooltip('Add to favorites'), findsOneWidget);
    expect(find.byIcon(Symbols.favorite_rounded), findsNWidgets(3));

    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pump();

    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    expect(playingAssets, ['assets/audio/waves.ogg']);

    await tester.tap(soundCard('Waves'));
    await tester.pump();
  });

  testWidgets('Favorites persist and the Favorites card plays them all', (
    tester,
  ) async {
    final storage = MemoryKeyValueStore();
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      SleepSoundsApp(
        storage: storage,
        createGateway: createGateway,
        ads: PreviewAdsGateway(initialized: true),
        billing: FakeBillingGateway(catalog: sleepSoundsCatalog),
      ),
    );
    await pumpPastSplash(tester);

    expect(find.byTooltip('Add to favorites'), findsNothing);

    await tester.tap(soundCard('Rain'));
    await tester.pump();
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pump();
    await tester.tap(soundCard('Rain'));
    await tester.tap(soundCard('Rain in tent'));
    await tester.pump();
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pump();
    await tester.tap(soundCard('Rain in tent'));
    await tester.pump();
    expect(playingAssets, isEmpty);

    expect(
      await storage.readString('favorites_sounds_v2'),
      allOf(contains('rain'), contains('rain_tent')),
    );

    await tester.tap(find.text('Favorites'));
    await tester.pump();

    expect(
      playingAssets,
      unorderedEquals(['assets/audio/rain.ogg', 'assets/audio/rain_tent.ogg']),
    );

    await tester.tap(find.text('Favorites'));
    await tester.pump();
    expect(playingAssets, isEmpty);
  });

  group('Favorites row', () {
    Future<void> pumpWithFavorites(
      WidgetTester tester,
      String favorites,
    ) async {
      final storage = MemoryKeyValueStore();
      if (favorites.isNotEmpty) {
        await storage.writeString('favorites_sounds_v2', favorites);
      }
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        SleepSoundsApp(
          storage: storage,
          createGateway: createGateway,
          ads: PreviewAdsGateway(initialized: true),
          billing: FakeBillingGateway(catalog: sleepSoundsCatalog),
        ),
      );
      await pumpPastSplash(tester);
    }

    testWidgets('sits above the grid and lists the favorites', (tester) async {
      await pumpWithFavorites(tester, 'rain,river');

      expect(find.text('Rain · River'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text('Favorites'),
        ),
        findsNothing,
      );
      expect(find.byTooltip('Play favorites'), findsOneWidget);
    });

    testWidgets('plays the favorites, then pauses and resumes', (tester) async {
      await pumpWithFavorites(tester, 'rain,river');

      await tester.tap(find.text('Favorites'));
      await tester.pump();

      expect(
        playingAssets,
        unorderedEquals(['assets/audio/rain.ogg', 'assets/audio/river.ogg']),
      );
      expect(find.byTooltip('Pause favorites'), findsOneWidget);

      await tester.tap(find.text('Favorites'));
      await tester.pump();

      expect(playingAssets, isEmpty);
      expect(find.byTooltip('Play favorites'), findsOneWidget);

      await tester.tap(find.text('Favorites'));
      await tester.pump();

      expect(playingAssets, hasLength(2));

      await tester.tap(soundCard('Rain'));
      await tester.tap(soundCard('River'));
      await tester.pump();
    });

    testWidgets('without favorites it explains how to add one', (tester) async {
      await pumpWithFavorites(tester, '');

      expect(find.text('Start a sound and tap its heart'), findsOneWidget);
      expect(find.byTooltip('Play favorites'), findsNothing);

      await tester.tap(find.text('Favorites'));
      await tester.pump();

      expect(
        find.text('Start a sound and tap its heart to add it to Favorites.'),
        findsOneWidget,
      );
      expect(playingAssets, isEmpty);
    });
  });

  testWidgets('In-App Purchase removes ads immediately', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = MemoryKeyValueStore();
    final ads = PreviewAdsGateway(initialized: true);
    final billing = FakeBillingGateway(
      catalog: sleepSoundsCatalog,
      initialProducts: [defaultRemoveAdsProduct],
    );

    await tester.pumpWidget(
      SleepSoundsApp(
        storage: storage,
        createGateway: createGateway,
        ads: ads,
        billing: billing,
      ),
    );
    await pumpPastSplash(tester);

    expect(find.text('Preview Ad [banner_home]'), findsOneWidget);

    // Open settings
    await tester.tap(find.byIcon(Icons.tune_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.textContaining(r'$2.99'), findsOneWidget);

    // Tap the REMOVE ADS button
    await tester.tap(find.text('REMOVE ADS'));
    await tester.pumpAndSettle();

    // Entitlement granted
    expect(billing.entitlements.has(FactoryEntitlements.removeAds), isTrue);
    expect(find.text('Premium Active'), findsOneWidget);

    // Close settings modal by popping navigator
    final nav = Navigator.of(tester.element(find.text('Settings')));
    nav.pop();
    await tester.pumpAndSettle();

    // Banner is no longer on the screen!
    expect(find.text('Preview Ad [banner_home]'), findsNothing);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      SleepSoundsApp(
        storage: MemoryKeyValueStore(),
        createGateway: createGateway,
        ads: PreviewAdsGateway(initialized: true),
        billing: FakeBillingGateway(catalog: sleepSoundsCatalog),
      ),
    );
    await pumpPastSplash(tester);
  }

  testWidgets('only selected cards show the equalizer', (tester) async {
    await pumpApp(tester);

    expect(find.byType(EqualizerBars), findsNothing);

    await tester.tap(soundCard('Rain'));
    await tester.tap(soundCard('Waves'));
    await tester.pump();

    expect(find.byType(EqualizerBars), findsNWidgets(2));
    expect(
      tester.widget<EqualizerBars>(find.byType(EqualizerBars).first).playing,
      isTrue,
    );

    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();

    expect(
      tester
          .widgetList<EqualizerBars>(find.byType(EqualizerBars))
          .map((b) => b.playing),
      [false, false],
    );

    await tester.tap(soundCard('Rain'));
    await tester.tap(soundCard('Waves'));
    await tester.pump();
    expect(find.byType(EqualizerBars), findsNothing);
  });

  testWidgets('tapping sounds plays them together and each tap toggles one', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Rain'));
    await tester.pump();
    await tester.tap(find.text('Waves'));
    await tester.pump();

    expect(
      playingAssets,
      unorderedEquals(['assets/audio/rain.ogg', 'assets/audio/waves.ogg']),
    );

    await tester.tap(find.text('Rain'));
    await tester.pump();

    expect(playingAssets, ['assets/audio/waves.ogg']);

    await tester.tap(find.text('Waves'));
    await tester.pump();
    expect(playingAssets, isEmpty);
  });

  testWidgets('play/pause button follows the sounds', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Play'));
    await tester.pump();
    expect(find.text('Select a sound to play'), findsOneWidget);

    await tester.tap(find.text('Rain'));
    await tester.pump();
    expect(find.byTooltip('Pause'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(playingAssets, isEmpty);
    expect(find.byTooltip('Play'), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);

    await tester.tap(find.byTooltip('Play'));
    await tester.pump();
    expect(playingAssets, ['assets/audio/rain.ogg']);

    await tester.tap(find.text('Rain'));
    await tester.pump();
    expect(find.byTooltip('Play'), findsOneWidget);
    expect(playingAssets, isEmpty);
  });

  group('sleep timer', () {
    testWidgets('is on the home page and starts with the first sound', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.text('1h'), findsOneWidget);
      expect(find.textContaining('Stopping in'), findsNothing);

      await tester.tap(find.text('Rain'));
      await tester.pump();

      expect(find.textContaining('Stopping in 1h 00m'), findsOneWidget);

      await selectDuration(tester, '1h', '3h');
      expect(find.textContaining('Stopping in 3h 00m'), findsOneWidget);

      await tester.tap(find.text('Rain'));
      await tester.pump();
    });

    testWidgets('pauses every sound when it expires', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Rain'));
      await tester.tap(find.text('Waves'));
      await tester.pump();
      await selectDuration(tester, '1h', '30m');

      expect(playingAssets, hasLength(2));

      await tester.pump(const Duration(minutes: 30));

      expect(playingAssets, isEmpty);
    });

    testWidgets('Off keeps playing with no countdown', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Rain'));
      await tester.pump();
      await selectDuration(tester, '1h', 'Off');

      expect(find.text('Playing'), findsOneWidget);
      expect(find.textContaining('Stopping in'), findsNothing);

      await tester.pump(const Duration(hours: 13));

      expect(playingAssets, hasLength(1));

      await tester.tap(find.text('Rain'));
      await tester.pump();
    });

    testWidgets('counts down once per second after switching duration', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.text('Rain'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));

      await selectDuration(tester, '1h', '30m');
      await tester.pump(const Duration(seconds: 10));

      expect(find.textContaining('Stopping in 29:50'), findsOneWidget);

      await tester.tap(find.text('Rain'));
      await tester.pump();
    });
  });

  group('remove ads price', () {
    Future<BillingGateway> openSettings(
      WidgetTester tester,
      List<StoreProduct> storeProducts,
    ) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final billing = FakeBillingGateway(
        catalog: sleepSoundsCatalog,
        initialProducts: storeProducts,
      );
      await tester.pumpWidget(
        SleepSoundsApp(
          storage: MemoryKeyValueStore(),
          createGateway: createGateway,
          ads: PreviewAdsGateway(initialized: true),
          billing: billing,
        ),
      );
      await pumpPastSplash(tester);
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pumpAndSettle();
      return billing;
    }

    testWidgets('shows the price reported by the store', (tester) async {
      await openSettings(tester, const [
        StoreProduct(
          id: 'sleep_sounds_remove_ads',
          title: 'Remove Ads',
          description: 'No ads',
          price: r'$3.99',
        ),
      ]);

      expect(find.textContaining(r'$3.99'), findsOneWidget);
      expect(find.textContaining(r'$2.99'), findsNothing);
    });

    testWidgets('disables the purchase when the store has no product', (
      tester,
    ) async {
      final billing = await openSettings(tester, const []);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'REMOVE ADS'),
      );
      expect(button.onPressed, isNull);

      await tester.tap(find.text('REMOVE ADS'));
      await tester.pumpAndSettle();

      expect(billing.entitlements.has(FactoryEntitlements.removeAds), isFalse);
    });
  });
}
