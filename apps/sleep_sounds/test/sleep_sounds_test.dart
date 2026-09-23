import 'package:factory_ads/factory_ads.dart';
import 'package:factory_audio/factory_audio.dart';
import 'package:factory_billing/factory_billing.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/main.dart';

Future<void> pumpPastSplash(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 3500));
  await tester.pumpAndSettle();
}

// The duration carousel virtualizes items far from the current page, so
// jumping straight to a distant label (e.g. '12h' -> '30min') can tap a
// widget that hasn't been built yet. Step through the adjacent, always-built
// neighbor instead, exactly like a user swiping one position at a time.
const _durationOrder = ['30min', '1h', '6h', '12h', '24h'];

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

void main() {
  testWidgets('SleepSoundsApp renders catalog, title, and initial banner', (tester) async {
    final storage = MemoryKeyValueStore();
    final audio = PreviewAudioGateway();
    final ads = PreviewAdsGateway(initialized: true);
    final billing = FakeBillingGateway(
      catalog: sleepSoundsCatalog,
      initialProducts: [defaultRemoveAdsProduct],
    );

    await tester.pumpWidget(
      SleepSoundsApp(
        storage: storage,
        audio: audio,
        ads: ads,
        billing: billing,
      ),
    );
    await pumpPastSplash(tester);

    expect(find.text('Good night'), findsOneWidget);
    expect(find.text('Soft rain'), findsOneWidget);
    expect(find.text('Night waves'), findsOneWidget);
    expect(find.text('Brown noise'), findsOneWidget);
    expect(find.text('Fan'), findsOneWidget);

    // Initial banner is displayed
    expect(find.text('Preview Ad [banner_home]'), findsOneWidget);
  });

  testWidgets('Favorites persist in KeyValueStore', (tester) async {
    final storage = MemoryKeyValueStore();
    final audio = PreviewAudioGateway();
    final ads = PreviewAdsGateway(initialized: true);
    final billing = FakeBillingGateway(catalog: sleepSoundsCatalog);

    await tester.pumpWidget(
      SleepSoundsApp(
        storage: storage,
        audio: audio,
        ads: ads,
        billing: billing,
      ),
    );
    await pumpPastSplash(tester);

    // Tap first favorite icon (favorite_border)
    final favoriteButtons = find.byIcon(Icons.favorite_border);
    expect(favoriteButtons, findsWidgets);
    await tester.tap(favoriteButtons.first);
    await tester.pumpAndSettle();

    // Check that favorite was saved in storage
    final stored = await storage.readString('favorites_sounds_v1');
    expect(stored, contains('Soft rain'));

    // Icon should now be filled favorite
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('In-App Purchase removes ads immediately', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = MemoryKeyValueStore();
    final audio = PreviewAudioGateway();
    final ads = PreviewAdsGateway(initialized: true);
    final billing = FakeBillingGateway(
      catalog: sleepSoundsCatalog,
      initialProducts: [defaultRemoveAdsProduct],
    );

    await tester.pumpWidget(
      SleepSoundsApp(
        storage: storage,
        audio: audio,
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
    expect(find.text('Remove Ads'), findsOneWidget);

    // Tap purchase button $2.99
    await tester.tap(find.text(r'$2.99'));
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

  testWidgets('Player opens with real timer controls', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = MemoryKeyValueStore();
    final audio = PreviewAudioGateway();
    final ads = PreviewAdsGateway(initialized: true);
    final billing = FakeBillingGateway(catalog: sleepSoundsCatalog);

    await tester.pumpWidget(
      SleepSoundsApp(
        storage: storage,
        audio: audio,
        ads: ads,
        billing: billing,
      ),
    );
    await pumpPastSplash(tester);

    // Tap on sound card to open the full-screen player
    await tester.tap(find.text('Soft rain'));
    await tester.pumpAndSettle();

    // Player is open, audio is playing, and the 12h default timer is running
    expect(find.byTooltip('Close player'), findsOneWidget);
    expect(find.byTooltip('Pause'), findsOneWidget);
    expect(find.text('12h'), findsOneWidget);
    expect(find.textContaining('Stopping in 12h 00m'), findsOneWidget);

    // Select 1h on the duration carousel
    await selectDuration(tester, '12h', '1h');

    expect(find.textContaining('Stopping in 1h 00m'), findsOneWidget);

    // Stop the timer before closing so no ticker outlives the test
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();

    // Close player sheet
    await tester.tap(find.byTooltip('Close player'));
    await tester.pumpAndSettle();
  });

  group('sleep timer', () {
    late PreviewAudioGateway audio;

    setUp(() => audio = PreviewAudioGateway());

    Future<void> startRainWithTimer(WidgetTester tester, String label) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        SleepSoundsApp(
          storage: MemoryKeyValueStore(),
          audio: audio,
          ads: PreviewAdsGateway(initialized: true),
          billing: FakeBillingGateway(catalog: sleepSoundsCatalog),
        ),
      );
      await pumpPastSplash(tester);
      await tester.tap(find.text('Soft rain'));
      await tester.pumpAndSettle();
      await selectDuration(tester, '12h', label);
    }

    Future<void> dismissPlayerSheet(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Close player'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byTooltip('Close player'), findsNothing);
    }

    testWidgets('pauses the audio when it expires with the player closed', (tester) async {
      await startRainWithTimer(tester, '30min');
      await dismissPlayerSheet(tester);

      expect(audio.playingAsset, 'assets/audio/rain.ogg');

      await tester.pump(const Duration(minutes: 30));

      expect(audio.playingAsset, isNull);
    });

    testWidgets('shows the remaining time when the player is reopened', (tester) async {
      await startRainWithTimer(tester, '30min');
      await dismissPlayerSheet(tester);
      await tester.pump(const Duration(seconds: 58));

      await tester.tap(find.text('Now playing'));
      await tester.pump(const Duration(milliseconds: 500));

      // A few hundred ms of sheet-transition animation may tick an extra
      // second or two; assert the ballpark rather than an exact value.
      expect(find.textContaining('Stopping in 29:0'), findsOneWidget);

      // Stop the timer before the test ends so no ticker outlives it
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
    });

    testWidgets('counts down once per second after switching duration', (tester) async {
      await startRainWithTimer(tester, '1h');
      await tester.pump(const Duration(seconds: 5));

      await selectDuration(tester, '1h', '30min');
      await tester.pump(const Duration(seconds: 10));

      expect(find.textContaining('Stopping in 29:50'), findsOneWidget);

      // Stop the timer before the test ends so no ticker outlives it
      await tester.tap(find.byTooltip('Pause'));
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
          audio: PreviewAudioGateway(),
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

      expect(find.text(r'$3.99'), findsOneWidget);
      expect(find.text(r'$2.99'), findsNothing);
    });

    testWidgets('disables the purchase when the store has no product', (tester) async {
      final billing = await openSettings(tester, const []);

      expect(find.text('Unavailable'), findsOneWidget);

      await tester.tap(find.text('Unavailable'));
      await tester.pumpAndSettle();

      expect(billing.entitlements.has(FactoryEntitlements.removeAds), isFalse);
    });
  });
}
