import 'package:factory_billing/factory_billing.dart';
import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/features/pro/paywall_page.dart';
import 'package:sleep_sounds/features/pro/pro_features.dart';
import 'package:sleep_sounds/main.dart';

const _storePro = StoreProduct(
  id: 'sleep_sounds_pro',
  title: 'Sleepy Capy Pro',
  description: 'Pro',
  price: r'$3.99',
);

Future<FakeBillingGateway> openPaywall(
  WidgetTester tester, {
  List<StoreProduct> products = const [_storePro],
  void Function(FakeBillingGateway billing)? setUp,
}) async {
  tester.view.physicalSize = const Size(1080, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final billing = FakeBillingGateway(
    catalog: sleepSoundsCatalog,
    initialProducts: products,
  );
  setUp?.call(billing);
  await tester.pumpWidget(
    MaterialApp(
      theme: factoryDarkTheme(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => PaywallPage.open(context, billing),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return billing;
}

void main() {
  testWidgets('lists what Pro adds and the price the store reports', (
    tester,
  ) async {
    await openPaywall(tester);

    expect(find.text('Sleepy Capy Pro'), findsOneWidget);
    expect(
      find.text('One purchase, yours to keep. No subscription.'),
      findsOneWidget,
    );
    expect(find.text('Set the volume of each sound'), findsOneWidget);
    expect(find.text('No ads'), findsOneWidget);
    expect(
      find.text('All 17 sounds, favorites and the timer stay free.'),
      findsOneWidget,
    );
    expect(find.text(r'$3.99 · one-time purchase'), findsOneWidget);
    expect(find.text('Get Pro'), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
  });

  testWidgets('a completed purchase grants Pro and closes the paywall', (
    tester,
  ) async {
    final billing = await openPaywall(tester);

    await tester.tap(find.text('Get Pro'));
    await tester.pumpAndSettle();

    expect(billing.entitlements.has(ProFeatures.entitlement), isTrue);
    expect(find.byType(PaywallPage), findsNothing);
  });

  testWidgets('cancelling leaves the paywall open with nothing to read', (
    tester,
  ) async {
    final billing = await openPaywall(
      tester,
      setUp: (b) => b.simulateCancel = true,
    );

    await tester.tap(find.text('Get Pro'));
    await tester.pumpAndSettle();

    expect(find.byType(PaywallPage), findsOneWidget);
    expect(find.textContaining("didn't go through"), findsNothing);
    expect(find.textContaining('Waiting'), findsNothing);
    expect(billing.entitlements.has(ProFeatures.entitlement), isFalse);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('a failed purchase says so and can be retried', (tester) async {
    final billing = await openPaywall(
      tester,
      setUp: (b) => b.simulateError = true,
    );

    await tester.tap(find.text('Get Pro'));
    await tester.pumpAndSettle();

    expect(
      find.text("The purchase didn't go through. Try again."),
      findsOneWidget,
    );
    expect(billing.entitlements.has(ProFeatures.entitlement), isFalse);

    billing.simulateError = false;
    await tester.tap(find.text('Get Pro'));
    await tester.pumpAndSettle();

    expect(billing.entitlements.has(ProFeatures.entitlement), isTrue);
  });

  testWidgets('a pending purchase waits, then turns Pro on by itself', (
    tester,
  ) async {
    final billing = await openPaywall(
      tester,
      setUp: (b) => b.simulatePending = true,
    );

    await tester.tap(find.text('Get Pro'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Waiting for your payment'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(billing.entitlements.has(ProFeatures.entitlement), isFalse);

    billing.resolvePendingPurchase('sleep_sounds_pro');
    await tester.pumpAndSettle();

    expect(billing.entitlements.has(ProFeatures.entitlement), isTrue);
    expect(find.byType(PaywallPage), findsNothing);
  });

  testWidgets('an unavailable store shows a retry that recovers', (
    tester,
  ) async {
    final billing = await openPaywall(
      tester,
      setUp: (b) => b.isAvailable = false,
    );

    expect(find.textContaining("Can't reach the store"), findsOneWidget);
    expect(find.text('Get Pro'), findsNothing);

    billing.isAvailable = true;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Get Pro'), findsOneWidget);
    expect(find.textContaining("Can't reach the store"), findsNothing);
  });

  testWidgets('a store without the product cannot sell it', (tester) async {
    await openPaywall(tester, products: const []);

    expect(find.textContaining("Can't reach the store"), findsOneWidget);
    expect(find.text('Get Pro'), findsNothing);
  });

  testWidgets('someone who already owns Pro is thanked, not sold to', (
    tester,
  ) async {
    await openPaywall(
      tester,
      setUp: (b) => b.entitlements.grant([ProFeatures.entitlement]),
    );

    expect(find.text('You have Pro'), findsOneWidget);
    expect(find.text('Thank you for supporting Sleepy Capy.'), findsOneWidget);
    expect(find.text('Get Pro'), findsNothing);
    expect(find.text('Restore purchases'), findsNothing);
  });

  group('restoring', () {
    testWidgets('brings Pro back and closes the paywall', (tester) async {
      final billing = await openPaywall(
        tester,
        setUp: (b) async {
          await b.buyNonConsumable(_storePro);
          b.entitlements.revoke(ProFeatures.entitlement);
        },
      );

      await tester.tap(find.text('Restore purchases'));
      await tester.pumpAndSettle();

      expect(billing.entitlements.has(ProFeatures.entitlement), isTrue);
      expect(find.byType(PaywallPage), findsNothing);
    });

    testWidgets('says when there is nothing to restore', (tester) async {
      await openPaywall(tester);

      await tester.tap(find.text('Restore purchases'));
      await tester.pump(const Duration(seconds: 3));

      expect(
        find.text('No earlier Pro purchase was found on this Google account.'),
        findsOneWidget,
      );
    });

    testWidgets('says when the store cannot be checked', (tester) async {
      await openPaywall(tester, setUp: (b) => b.isAvailable = false);

      await tester.tap(find.text('Restore purchases'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("Couldn't check your purchases"),
        findsOneWidget,
      );
    });
  });
}
