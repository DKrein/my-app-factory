import 'dart:async';

import 'package:factory_billing/factory_billing.dart';
import 'package:factory_core/factory_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

const _unlock = 'unlock';

final _catalog = BillingCatalog(
  products: const [
    BillingProduct(
      id: 'app.unlock',
      entitlements: {_unlock},
      title: 'Unlock',
      description: 'Unlocks everything',
    ),
  ],
);

PurchaseDetails _owned(PurchaseStatus status) => PurchaseDetails(
  productID: 'app.unlock',
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: '',
    source: 'test',
  ),
  transactionDate: null,
  status: status,
);

/// Stands in for Google Play: it reports [owned] only when asked to restore.
class _FakeStore implements InAppPurchase {
  _FakeStore({this.available = true, this.owned = const [], this.throws = false});

  final bool available;
  final List<PurchaseDetails> owned;
  final bool throws;
  int restoreCalls = 0;
  final _stream = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _stream.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restoreCalls++;
    if (throws) throw StateError('store offline');
    if (owned.isNotEmpty) _stream.add(owned);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late List<PurchaseEvent> events;

  PlayBillingGateway gatewayFor(_FakeStore store) {
    final gateway = PlayBillingGateway(catalog: _catalog, inAppPurchase: store);
    events = [];
    gateway.purchaseEvents.listen(events.add);
    return gateway;
  }

  test('what the user owns is unlocked when the app opens', () async {
    final store = _FakeStore(owned: [_owned(PurchaseStatus.restored)]);
    final gateway = gatewayFor(store);

    final result = await gateway.initialize();

    expect(result, isA<Success<void>>());
    expect(store.restoreCalls, 1);
    expect(gateway.entitlements.has(_unlock), isTrue);
  });

  test('the startup restore is silent', () async {
    final gateway = gatewayFor(
      _FakeStore(owned: [_owned(PurchaseStatus.restored)]),
    );

    await gateway.initialize();
    await Future<void>.delayed(Duration.zero);

    expect(events, isEmpty);
  });

  test('a user who owns nothing gets nothing and no message', () async {
    final gateway = gatewayFor(_FakeStore());

    await gateway.initialize();

    expect(gateway.entitlements.has(_unlock), isFalse);
    expect(events, isEmpty);
  });

  test('an unavailable store is not asked to restore', () async {
    final store = _FakeStore(available: false);
    final gateway = gatewayFor(store);

    final result = await gateway.initialize();

    expect(result, isA<Success<void>>());
    expect(store.restoreCalls, 0);
    expect(gateway.isAvailable, isFalse);
  });

  test('a failing restore does not fail the startup', () async {
    final gateway = gatewayFor(_FakeStore(throws: true));

    final result = await gateway.initialize();

    expect(result, isA<Success<void>>());
    expect(gateway.entitlements.has(_unlock), isFalse);
  });

  test('a restore the user asks for afterwards is announced', () async {
    final store = _FakeStore(owned: [_owned(PurchaseStatus.restored)]);
    final gateway = gatewayFor(store);
    await gateway.initialize();

    await gateway.restorePurchases();
    await Future<void>.delayed(Duration.zero);

    expect(events.map((e) => e.status), [PurchaseProgressStatus.restored]);
  });

  test('a purchase made during the session is announced as usual', () async {
    final store = _FakeStore();
    final gateway = gatewayFor(store);
    await gateway.initialize();

    store._stream.add([_owned(PurchaseStatus.purchased)]);
    await Future<void>.delayed(Duration.zero);

    expect(events.map((e) => e.status), [PurchaseProgressStatus.purchased]);
    expect(gateway.entitlements.has(_unlock), isTrue);
  });
}
