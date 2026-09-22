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

    // Tap on sound card to open player
    await tester.tap(find.text('Soft rain'));
    await tester.pumpAndSettle();

    // Player sheet is open and audio is playing
    expect(find.byTooltip('Pause'), findsOneWidget);
    expect(find.text('No timer'), findsOneWidget);

    // Select 15 min timer
    await tester.tap(find.text('15 min'));
    await tester.pump();

    expect(find.textContaining('Stopping in: 15:00'), findsOneWidget);

    // Reset timer
    await tester.tap(find.text('No timer'));
    await tester.pump();

    expect(find.textContaining('Stopping in:'), findsNothing);

    // Close player sheet
    final nav = Navigator.of(tester.element(find.text('Soft rain').last));
    nav.pop();
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
      await tester.tap(find.text(label));
      await tester.pump();
    }

    Future<void> dismissPlayerSheet(WidgetTester tester) async {
      await tester.tapAt(const Offset(10, 10));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('No timer'), findsNothing);
    }

    testWidgets('pauses the audio when it expires with the player closed', (tester) async {
      await startRainWithTimer(tester, '15 min');
      await dismissPlayerSheet(tester);

      expect(audio.playingAsset, 'assets/audio/rain.ogg');

      await tester.pump(const Duration(minutes: 15));

      expect(audio.playingAsset, isNull);
    });

    testWidgets('shows the remaining time when the player is reopened', (tester) async {
      await startRainWithTimer(tester, '15 min');
      await dismissPlayerSheet(tester);
      await tester.pump(const Duration(seconds: 58));

      await tester.tap(find.text('Now playing'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Stopping in: 14:00'), findsOneWidget);

      await tester.tap(find.text('No timer'));
      await tester.pump();
    });

    testWidgets('counts down once per second after switching duration', (tester) async {
      await startRainWithTimer(tester, '15 min');
      await tester.pump(const Duration(seconds: 5));

      await tester.tap(find.text('30 min'));
      await tester.pump(const Duration(seconds: 10));

      expect(find.textContaining('Stopping in: 29:50'), findsOneWidget);

      await tester.tap(find.text('No timer'));
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
