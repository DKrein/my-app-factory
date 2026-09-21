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
}
