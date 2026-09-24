import 'dart:async';
import 'dart:io';

import 'package:factory_ads/factory_ads.dart';
import 'package:factory_audio/factory_audio.dart';
import 'package:factory_billing/factory_billing.dart';
import 'package:factory_core/factory_core.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/features/pro/pro_features.dart';
import 'package:sleep_sounds/main.dart';

/// An SDK that becomes ready only when the test says so.
final class _GatedAds implements AdsGateway {
  final _gate = Completer<void>();
  final ValueNotifier<bool> _ready = ValueNotifier(false);
  int initializeCalls = 0;

  void open() => _gate.complete();

  @override
  Future<AppResult<void>> initialize() async {
    initializeCalls++;
    await _gate.future;
    _ready.value = true;
    return const Success(null);
  }

  @override
  bool get isInitialized => _ready.value;

  @override
  ValueListenable<bool> get ready => _ready;

  @override
  Widget buildBanner({
    required String adUnitId,
    required AdPlacement placement,
    required AdsPolicy policy,
    Widget? fallback,
    ValueChanged<bool>? onLoadedChanged,
  }) => Text('ad [${placement.id}]');

  @override
  Future<bool> showInterstitial({
    required String adUnitId,
    required AdPlacement placement,
    required AdsPolicy policy,
  }) async => false;
}

/// A store that reports what the user owns while it starts, like Play does.
final class _RestoringBilling implements BillingGateway {
  _RestoringBilling(this._inner, {required this.owns});

  final FakeBillingGateway _inner;
  final bool owns;
  bool initialized = false;

  @override
  Future<AppResult<void>> initialize() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (owns) _inner.entitlements.grant([ProFeatures.entitlement]);
    initialized = true;
    return const Success(null);
  }

  @override
  bool get isAvailable => _inner.isAvailable;
  @override
  EntitlementStore get entitlements => _inner.entitlements;
  @override
  Stream<PurchaseEvent> get purchaseEvents => _inner.purchaseEvents;
  @override
  Future<AppResult<List<StoreProduct>>> queryProducts(Set<String> ids) =>
      _inner.queryProducts(ids);
  @override
  Future<AppResult<void>> buyNonConsumable(StoreProduct product) =>
      _inner.buyNonConsumable(product);
  @override
  Future<AppResult<void>> restorePurchases() => _inner.restorePurchases();
  @override
  void dispose() => _inner.dispose();
}

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    required AdsGateway ads,
    required BillingGateway billing,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(
      SleepSoundsApp(
        storage: MemoryKeyValueStore(),
        createGateway: ({required ownsAudioSession}) => PreviewAudioGateway(),
        ads: ads,
        billing: billing,
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

  FakeBillingGateway freshStore() => FakeBillingGateway(
    catalog: sleepSoundsCatalog,
    initialProducts: [defaultProProduct],
  );

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.tune_outlined));
    await tester.pumpAndSettle();
  }

  group('the SDK', () {
    testWidgets('starts for a user who is not Pro', (tester) async {
      final ads = PreviewAdsGateway();

      await pumpApp(tester, ads: ads, billing: freshStore());

      expect(ads.isInitialized, isTrue);
    });

    testWidgets('never starts for a Pro user', (tester) async {
      final ads = PreviewAdsGateway();
      final billing = freshStore()
        ..entitlements.grant([ProFeatures.entitlement]);

      await pumpApp(tester, ads: ads, billing: billing);

      expect(ads.isInitialized, isFalse);
      expect(find.textContaining('Preview Ad'), findsNothing);
    });

    testWidgets('waits for the store: what it restores at startup counts', (
      tester,
    ) async {
      final ads = PreviewAdsGateway();
      final billing = _RestoringBilling(freshStore(), owns: true);

      await pumpApp(tester, ads: ads, billing: billing);

      expect(billing.initialized, isTrue);
      expect(ads.isInitialized, isFalse);
    });

    testWidgets('starts once the store says the user is not Pro', (
      tester,
    ) async {
      final ads = PreviewAdsGateway();
      final billing = _RestoringBilling(freshStore(), owns: false);

      await pumpApp(tester, ads: ads, billing: billing);

      expect(billing.initialized, isTrue);
      expect(ads.isInitialized, isTrue);
    });

    testWidgets('a purchase during the session does not start it', (
      tester,
    ) async {
      final ads = PreviewAdsGateway();
      final billing = freshStore()
        ..entitlements.grant([ProFeatures.entitlement]);

      await pumpApp(tester, ads: ads, billing: billing);
      await billing.buyNonConsumable(defaultProProduct);
      await tester.pumpAndSettle();

      expect(ads.isInitialized, isFalse);
    });
  });

  group('banners', () {
    testWidgets('appear only after the SDK is ready', (tester) async {
      final ads = _GatedAds();
      await pumpApp(tester, ads: ads, billing: freshStore());

      expect(ads.initializeCalls, 1);
      expect(find.textContaining('ad ['), findsNothing);

      ads.open();
      await tester.pumpAndSettle();

      expect(find.text('ad [banner_home]'), findsOneWidget);
    });

    testWidgets('one in the grid, one in Settings, none in both at once', (
      tester,
    ) async {
      await pumpApp(
        tester,
        ads: PreviewAdsGateway(initialized: true),
        billing: freshStore(),
      );

      expect(find.text('Preview Ad [banner_home]'), findsOneWidget);
      expect(find.text('Preview Ad [banner_settings]'), findsNothing);

      await openSettings(tester);

      expect(find.text('Preview Ad [banner_settings]'), findsOneWidget);
    });

    testWidgets('are not in Settings for a Pro user', (tester) async {
      final billing = freshStore()
        ..entitlements.grant([ProFeatures.entitlement]);
      await pumpApp(
        tester,
        ads: PreviewAdsGateway(initialized: true),
        billing: billing,
      );

      await openSettings(tester);

      expect(find.textContaining('Preview Ad'), findsNothing);
    });

    testWidgets('leave no gap in Settings when the ad does not load', (
      tester,
    ) async {
      final ads = _GatedAds();
      await pumpApp(tester, ads: ads, billing: freshStore());

      await openSettings(tester);

      expect(find.textContaining('ad ['), findsNothing);
      await tester.ensureVisible(find.text('About'));
      await tester.pump();
      final about = tester.getRect(find.text('About'));
      final screen = tester.getSize(find.byType(MaterialApp));
      expect(about.bottom, lessThan(screen.height));
      expect(tester.takeException(), isNull);
    });
  });

  group('the source', () {
    final source = [
      for (final entity in Directory('lib').listSync(recursive: true))
        if (entity is File && entity.path.endsWith('.dart'))
          (path: entity.path, text: entity.readAsStringSync()),
    ];

    test('never asks for an interstitial or a rewarded ad', () {
      for (final file in source) {
        expect(
          file.text,
          isNot(contains('showInterstitial')),
          reason: file.path,
        );
        expect(file.text, isNot(contains('Rewarded')), reason: file.path);
        expect(file.text, isNot(contains('Interstitial')), reason: file.path);
      }
    });

    test('the manifest keeps the SDK from starting itself at launch', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      final provider = RegExp(
        r'<provider[^>]*MobileAdsInitProvider[^>]*/>',
        dotAll: true,
      ).firstMatch(manifest);

      expect(provider, isNotNull);
      expect(provider!.group(0), contains('tools:node="remove"'));
      expect(manifest, contains('com.google.android.gms.ads.APPLICATION_ID'));
    });

    test('uses only the home and settings banner placements', () {
      final used = <String>{
        for (final file in source)
          for (final match in RegExp(
            r'AdPlacement\.(\w+)',
          ).allMatches(file.text))
            match.group(1)!,
      };

      expect(used, {'bannerHome', 'bannerSettings'});
    });
  });
}
