import 'package:factory_audio/factory_audio.dart';
import 'package:factory_billing/factory_billing.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/features/library/equalizer_bars.dart';
import 'package:sleep_sounds/features/pro/pro_features.dart';
import 'package:sleep_sounds/main.dart';
import 'package:factory_ads/factory_ads.dart';

void main() {
  for (final scale in [1.0, 1.5, 2.0]) {
    for (final pro in [false, true]) {
      testWidgets(
        'active cards fit on a 360 dp phone at text scale $scale (pro: $pro)',
        (tester) async {
          tester.view.physicalSize = const Size(1080, 2400);
          tester.view.devicePixelRatio = 3;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
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
              storage: MemoryKeyValueStore(),
              createGateway: ({required ownsAudioSession}) =>
                  PreviewAudioGateway(),
              ads: PreviewAdsGateway(initialized: true),
              billing: billing,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 3500));
          await tester.pumpAndSettle();

          for (final name in ['Rain in tent', 'Forest rain', 'Cat purring']) {
            await tester.scrollUntilVisible(
              find.text(name),
              200,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.ensureVisible(find.text(name));
            await tester.pump();
            await tester.tap(find.text(name));
            await tester.pump();
          }

          expect(tester.takeException(), isNull);
          expect(find.byType(EqualizerBars), findsNWidgets(3));
        },
      );
    }
  }
}
