import 'package:factory_ads/factory_ads.dart';
import 'package:factory_audio/factory_audio.dart';
import 'package:factory_billing/factory_billing.dart';
import 'package:factory_core/factory_core.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/main.dart';

final class _FailingAdsGateway implements AdsGateway {
  bool _reported = false;

  @override
  bool get isInitialized => true;

  @override
  Future<AppResult<void>> initialize() async => const Success(null);

  @override
  Widget buildBanner({
    required String adUnitId,
    required AdPlacement placement,
    required AdsPolicy policy,
    Widget? fallback,
    ValueChanged<bool>? onLoadedChanged,
  }) {
    if (!_reported) {
      _reported = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => onLoadedChanged?.call(false),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Future<bool> showInterstitial({
    required String adUnitId,
    required AdPlacement placement,
    required AdsPolicy policy,
  }) async => false;
}

Future<void> pumpApp(
  WidgetTester tester, {
  required AdsGateway ads,
  bool pro = false,
}) async {
  final billing = FakeBillingGateway(
    catalog: sleepSoundsCatalog,
    initialProducts: [defaultProProduct],
  );
  if (pro) {
    await billing.buyNonConsumable(defaultProProduct);
  }
  await tester.pumpWidget(
    SleepSoundsApp(
      storage: MemoryKeyValueStore(),
      createGateway: ({required ownsAudioSession}) => PreviewAudioGateway(),
      ads: ads,
      billing: billing,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 3500));
  await tester.pumpAndSettle();
}

double bottomPadding(WidgetTester tester) =>
    (tester.widget<ListView>(find.byType(ListView).first).padding!
            as EdgeInsets)
        .bottom;

void main() {
  testWidgets('list reserves the banner height once the ad is loaded', (
    tester,
  ) async {
    await pumpApp(tester, ads: PreviewAdsGateway(initialized: true));

    expect(find.text('Preview Ad [banner_home]'), findsOneWidget);
    expect(bottomPadding(tester), 24 + 50);
  });

  testWidgets('no space is reserved when the ad fails to load', (tester) async {
    await pumpApp(tester, ads: _FailingAdsGateway());

    expect(bottomPadding(tester), 24);
  });

  testWidgets('no banner and no reserved space with the purchase active', (
    tester,
  ) async {
    await pumpApp(tester, ads: PreviewAdsGateway(initialized: true), pro: true);

    expect(find.text('Preview Ad [banner_home]'), findsNothing);
    expect(bottomPadding(tester), 24);
  });
}
