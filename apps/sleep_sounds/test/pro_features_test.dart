import 'dart:io';

import 'package:factory_billing/factory_billing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/app_config.g.dart';
import 'package:sleep_sounds/features/pro/pro_features.dart';
import 'package:sleep_sounds/main.dart';

void main() {
  FakeBillingGateway newBilling() => FakeBillingGateway(
    catalog: sleepSoundsCatalog,
    initialProducts: [defaultProProduct],
  );

  test('the Pro SKU grants the pro entitlement', () {
    expect(AppConfig.proProductId, 'sleep_sounds_pro');
    expect(sleepSoundsCatalog.entitlementsForProduct(AppConfig.proProductId), {
      ProFeatures.entitlement,
    });
    expect(ProFeatures.entitlement, 'pro');
  });

  test('app.yaml declares the same product and entitlement as the code', () {
    final yaml = File('app.yaml').readAsStringSync();

    expect(yaml, contains('- id: ${AppConfig.proProductId}'));
    expect(yaml, contains('- ${ProFeatures.entitlement}'));
  });

  test('the store price fallback is US\$ 4.99', () {
    expect(defaultProProduct.price, r'$4.99');
  });

  test('nothing is Pro until the purchase, and ads go away with it', () async {
    final billing = newBilling();
    final pro = ProFeatures(billing.entitlements);
    var notified = 0;
    pro.changes.addListener(() => notified++);

    expect(pro.isPro, isFalse);
    expect(pro.showAds, isTrue);

    await billing.buyNonConsumable(defaultProProduct);

    expect(pro.isPro, isTrue);
    expect(pro.showAds, isFalse);
    expect(notified, greaterThan(0));
  });

  test('a free user keeps one saved mix, Pro any number', () async {
    final billing = newBilling();
    final pro = ProFeatures(billing.entitlements);

    expect(ProFeatures.freeMixLimit, 1);
    expect(pro.canSaveMix(0), isTrue);
    expect(pro.canSaveMix(1), isFalse);
    expect(pro.canSaveMix(5), isFalse);

    await billing.buyNonConsumable(defaultProProduct);

    expect(pro.canSaveMix(1), isTrue);
    expect(pro.canSaveMix(50), isTrue);
  });

  test('only Pro sets individual volumes', () async {
    final billing = newBilling();
    final pro = ProFeatures(billing.entitlements);

    expect(pro.canSetIndividualVolume, isFalse);

    await billing.buyNonConsumable(defaultProProduct);

    expect(pro.canSetIndividualVolume, isTrue);
  });
}
