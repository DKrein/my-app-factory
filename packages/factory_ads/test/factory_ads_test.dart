import 'package:factory_ads/factory_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdmobTestUnits', () {
    test('contains valid test ad unit IDs', () {
      expect(AdmobTestUnits.androidBanner, contains('ca-app-pub-3940256099942544'));
      expect(AdmobTestUnits.androidInterstitial, contains('ca-app-pub-3940256099942544'));
      expect(AdmobTestUnits.androidRewarded, contains('ca-app-pub-3940256099942544'));
      expect(AdmobTestUnits.iosBanner, contains('ca-app-pub-3940256099942544'));
    });
  });

  group('AdPlacement', () {
    test('equality and properties', () {
      const p1 = AdPlacement('test_banner');
      const p2 = AdPlacement('test_banner');
      const p3 = AdPlacement('other');

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
      expect(p1.toString(), contains('test_banner'));
    });
  });

  group('AdsPolicy', () {
    test('AlwaysShowAdsPolicy allows all placements', () {
      const policy = AlwaysShowAdsPolicy();
      expect(policy.canShow(AdPlacement.bannerHome), isTrue);
      expect(policy.canShow(AdPlacement.interstitialAfterAction), isTrue);
    });

    test('DisabledAdsPolicy blocks all placements', () {
      const policy = DisabledAdsPolicy();
      expect(policy.canShow(AdPlacement.bannerHome), isFalse);
      expect(policy.canShow(AdPlacement.interstitialAfterAction), isFalse);
    });

    test('CustomAdsPolicy evaluates predicate', () {
      var removeAds = false;
      final policy = CustomAdsPolicy((placement) => !removeAds);

      expect(policy.canShow(AdPlacement.bannerHome), isTrue);

      removeAds = true;
      expect(policy.canShow(AdPlacement.bannerHome), isFalse);
    });
  });

  group('PreviewAdsGateway', () {
    test('initialization works', () async {
      final gateway = PreviewAdsGateway();
      expect(gateway.isInitialized, isFalse);

      final result = await gateway.initialize();
      expect(result, isA<Object>());
      expect(gateway.isInitialized, isTrue);
    });

    test('showInterstitial respects policy', () async {
      final gateway = PreviewAdsGateway();

      final blocked = await gateway.showInterstitial(
        adUnitId: AdmobTestUnits.androidInterstitial,
        placement: AdPlacement.interstitialAfterAction,
        policy: const DisabledAdsPolicy(),
      );
      expect(blocked, isFalse);
      expect(gateway.shownInterstitials, isEmpty);

      final allowed = await gateway.showInterstitial(
        adUnitId: AdmobTestUnits.androidInterstitial,
        placement: AdPlacement.interstitialAfterAction,
        policy: const AlwaysShowAdsPolicy(),
      );
      expect(allowed, isTrue);
      expect(gateway.shownInterstitials, contains(AdPlacement.interstitialAfterAction));
    });

    testWidgets('FactoryBannerAd builds properly with PreviewAdsGateway', (tester) async {
      final gateway = PreviewAdsGateway();

      // When policy allows
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FactoryBannerAd(
              gateway: gateway,
              adUnitId: AdmobTestUnits.androidBanner,
              placement: AdPlacement.bannerHome,
              policy: const AlwaysShowAdsPolicy(),
            ),
          ),
        ),
      );

      expect(find.text('Preview Ad [banner_home]'), findsOneWidget);

      // When policy blocks
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FactoryBannerAd(
              gateway: gateway,
              adUnitId: AdmobTestUnits.androidBanner,
              placement: AdPlacement.bannerHome,
              policy: const DisabledAdsPolicy(),
              fallback: const Text('No Ads'),
            ),
          ),
        ),
      );

      expect(find.text('Preview Ad [banner_home]'), findsNothing);
      expect(find.text('No Ads'), findsOneWidget);
    });
  });
}
