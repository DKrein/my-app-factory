import 'package:factory_billing/factory_billing.dart';
import 'package:factory_core/factory_core.dart';
import 'package:flutter_test/flutter_test.dart';

const _unlock = 'unlock';

void main() {
  const testCatalog = BillingCatalog(
    products: [
      BillingProduct(
        id: 'app.unlock',
        entitlements: {_unlock},
        title: 'Remover Anúncios',
        description: 'Desative todos os anúncios do aplicativo.',
      ),
    ],
  );

  const testProduct = StoreProduct(
    id: 'app.unlock',
    title: 'Remover Anúncios',
    description: 'Sem anúncios para sempre',
    price: r'R$ 9,90',
  );

  group('BillingCatalog', () {
    test('resolves entitlements for matching product ID', () {
      final entitlements = testCatalog.entitlementsForProduct('app.unlock');
      expect(entitlements, contains(_unlock));

      final unknown = testCatalog.entitlementsForProduct('unknown.product');
      expect(unknown, isEmpty);
    });
  });

  group('EntitlementStore', () {
    test('grants and notifies listeners', () {
      final store = EntitlementStore();
      var notificationCount = 0;
      store.addListener(() => notificationCount++);

      expect(store.has('unlock'), isFalse);

      final granted = store.grant(['unlock']);
      expect(granted, isTrue);
      expect(store.has('unlock'), isTrue);
      expect(notificationCount, equals(1));

      // Granting again should not trigger notification
      final duplicate = store.grant(['unlock']);
      expect(duplicate, isFalse);
      expect(notificationCount, equals(1));
    });

    test('revokes and resets', () {
      final store = EntitlementStore(initialEntitlements: {'unlock'});
      expect(store.has('unlock'), isTrue);

      store.revoke('unlock');
      expect(store.has('unlock'), isFalse);

      store.grant(['feature_1', 'feature_2']);
      expect(store.active.length, equals(2));

      store.reset();
      expect(store.active, isEmpty);
    });
  });

  group('FakeBillingGateway', () {
    test('handles store availability', () async {
      final gateway = FakeBillingGateway(
        catalog: testCatalog,
        isAvailable: false,
        initialProducts: [testProduct],
      );

      final queryResult = await gateway.queryProducts({'app.unlock'});
      expect(queryResult, isA<Failure<List<StoreProduct>>>());

      final buyResult = await gateway.buyNonConsumable(testProduct);
      expect(buyResult, isA<Failure<void>>());
    });

    test('queries available products', () async {
      final gateway = FakeBillingGateway(
        catalog: testCatalog,
        initialProducts: [testProduct],
      );

      final result = await gateway.queryProducts({'app.unlock'});
      expect(result, isA<Success<List<StoreProduct>>>());
      final products = (result as Success<List<StoreProduct>>).value;
      expect(products.length, equals(1));
      expect(products.first.id, equals('app.unlock'));
    });

    test('executes successful non-consumable purchase', () async {
      final gateway = FakeBillingGateway(
        catalog: testCatalog,
        initialProducts: [testProduct],
      );

      final events = <PurchaseEvent>[];
      final subscription = gateway.purchaseEvents.listen(events.add);

      expect(gateway.entitlements.has(_unlock), isFalse);

      final buyResult = await gateway.buyNonConsumable(testProduct);
      expect(buyResult, isA<Success<void>>());

      expect(gateway.entitlements.has(_unlock), isTrue);
      expect(events.length, equals(1));
      expect(events.first.status, equals(PurchaseProgressStatus.purchased));
      expect(events.first.unlockedEntitlements, contains(_unlock));

      await subscription.cancel();
      gateway.dispose();
    });

    test('handles pending purchase scenario and delayed resolution', () async {
      final gateway = FakeBillingGateway(
        catalog: testCatalog,
        initialProducts: [testProduct],
      )..simulatePending = true;

      final events = <PurchaseEvent>[];
      final subscription = gateway.purchaseEvents.listen(events.add);

      await gateway.buyNonConsumable(testProduct);

      // In pending state, entitlement is NOT yet granted
      expect(gateway.entitlements.has(_unlock), isFalse);
      expect(events.last.status, equals(PurchaseProgressStatus.pending));

      // Resolve pending purchase later
      gateway.resolvePendingPurchase('app.unlock');
      await pumpEventQueue();

      expect(gateway.entitlements.has(_unlock), isTrue);
      expect(events.last.status, equals(PurchaseProgressStatus.purchased));

      await subscription.cancel();
      gateway.dispose();
    });

    test('handles purchase error scenario', () async {
      final gateway = FakeBillingGateway(
        catalog: testCatalog,
        initialProducts: [testProduct],
      )
        ..simulateError = true
        ..nextErrorMessage = 'Cartão recusado pelo banco emissor';

      final events = <PurchaseEvent>[];
      final subscription = gateway.purchaseEvents.listen(events.add);

      final result = await gateway.buyNonConsumable(testProduct);
      expect(result, isA<Failure<void>>());
      expect(gateway.entitlements.has(_unlock), isFalse);

      expect(events.length, equals(1));
      expect(events.first.status, equals(PurchaseProgressStatus.error));
      expect(events.first.errorMessage, contains('Cartão recusado'));

      await subscription.cancel();
      gateway.dispose();
    });

    test('restores previously purchased items', () async {
      final gateway = FakeBillingGateway(
        catalog: testCatalog,
        initialProducts: [testProduct],
      );

      // Buy first
      await gateway.buyNonConsumable(testProduct);
      expect(gateway.entitlements.has(_unlock), isTrue);

      // Reset entitlements locally (simulating re-install)
      gateway.entitlements.reset();
      expect(gateway.entitlements.has(_unlock), isFalse);

      final events = <PurchaseEvent>[];
      final subscription = gateway.purchaseEvents.listen(events.add);

      final restoreResult = await gateway.restorePurchases();
      expect(restoreResult, isA<Success<void>>());

      expect(gateway.entitlements.has(_unlock), isTrue);
      expect(events.length, equals(1));
      expect(events.first.status, equals(PurchaseProgressStatus.restored));

      await subscription.cancel();
      gateway.dispose();
    });
  });
}
