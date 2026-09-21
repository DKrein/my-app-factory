import 'package:factory_ads/factory_ads.dart';
import 'package:factory_audio/factory_audio.dart';
import 'package:factory_billing/factory_billing.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/main.dart';

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
    await tester.pumpAndSettle();

    expect(find.text('Boa noite'), findsOneWidget);
    expect(find.text('Chuva suave'), findsOneWidget);
    expect(find.text('Ondas noturnas'), findsOneWidget);
    expect(find.text('Ruído marrom'), findsOneWidget);
    expect(find.text('Ventilador'), findsOneWidget);

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
    await tester.pumpAndSettle();

    // Tap first favorite icon (favorite_border)
    final favoriteButtons = find.byIcon(Icons.favorite_border);
    expect(favoriteButtons, findsWidgets);
    await tester.tap(favoriteButtons.first);
    await tester.pumpAndSettle();

    // Check that favorite was saved in storage
    final stored = await storage.readString('favorites_sounds_v1');
    expect(stored, contains('Chuva suave'));

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
    await tester.pumpAndSettle();

    expect(find.text('Preview Ad [banner_home]'), findsOneWidget);

    // Open settings
    await tester.tap(find.byIcon(Icons.tune_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Remover Anúncios'), findsOneWidget);

    // Tap purchase button R$ 9,90
    await tester.tap(find.text(r'R$ 9,90'));
    await tester.pumpAndSettle();

    // Entitlement granted
    expect(billing.entitlements.has(FactoryEntitlements.removeAds), isTrue);
    expect(find.text('Versão Premium Ativa'), findsOneWidget);

    // Close settings modal by popping navigator
    final nav = Navigator.of(tester.element(find.text('Configurações')));
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
    await tester.pumpAndSettle();

    // Tap on sound card to open player
    await tester.tap(find.text('Chuva suave'));
    await tester.pumpAndSettle();

    // Player sheet is open and audio is playing
    expect(find.byTooltip('Pausar'), findsOneWidget);
    expect(find.text('Sem timer'), findsOneWidget);

    // Select 15 min timer
    await tester.tap(find.text('15 min'));
    await tester.pump();

    expect(find.textContaining('Desligando em: 15:00'), findsOneWidget);

    // Reset timer
    await tester.tap(find.text('Sem timer'));
    await tester.pump();

    expect(find.textContaining('Desligando em:'), findsNothing);

    // Close player sheet
    final nav = Navigator.of(tester.element(find.text('Chuva suave').last));
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
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chuva suave'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pump();
    }

    Future<void> dismissPlayerSheet(WidgetTester tester) async {
      await tester.tapAt(const Offset(10, 10));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Sem timer'), findsNothing);
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

      await tester.tap(find.text('Tocando agora'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Desligando em: 14:00'), findsOneWidget);

      await tester.tap(find.text('Sem timer'));
      await tester.pump();
    });

    testWidgets('counts down once per second after switching duration', (tester) async {
      await startRainWithTimer(tester, '15 min');
      await tester.pump(const Duration(seconds: 5));

      await tester.tap(find.text('30 min'));
      await tester.pump(const Duration(seconds: 10));

      expect(find.textContaining('Desligando em: 29:50'), findsOneWidget);

      await tester.tap(find.text('Sem timer'));
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
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pumpAndSettle();
      return billing;
    }

    testWidgets('shows the price reported by the store', (tester) async {
      await openSettings(tester, const [
        StoreProduct(
          id: 'sleep_sounds_remove_ads',
          title: 'Remover Anúncios',
          description: 'Sem anúncios',
          price: r'R$ 12,90',
        ),
      ]);

      expect(find.text(r'R$ 12,90'), findsOneWidget);
      expect(find.text(r'R$ 9,90'), findsNothing);
    });

    testWidgets('disables the purchase when the store has no product', (tester) async {
      final billing = await openSettings(tester, const []);

      expect(find.text('Indisponível'), findsOneWidget);

      await tester.tap(find.text('Indisponível'));
      await tester.pumpAndSettle();

      expect(billing.entitlements.has(FactoryEntitlements.removeAds), isFalse);
    });
  });
}
