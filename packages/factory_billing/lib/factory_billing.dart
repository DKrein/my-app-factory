import 'dart:async';
import 'package:factory_core/factory_core.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Representation of a product available in the store.
final class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.currencyCode,
    this.rawPrice,
  });

  final String id;
  final String title;
  final String description;
  final String price;
  final String? currencyCode;
  final double? rawPrice;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StoreProduct && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'StoreProduct(id: $id, price: $price)';
}

/// Declares which entitlements are granted by a store product.
final class BillingProduct {
  const BillingProduct({
    required this.id,
    required this.entitlements,
    this.title,
    this.description,
  });

  final String id;
  final Set<String> entitlements;
  final String? title;
  final String? description;
}

/// Declarative catalog mapping store products to app entitlements.
final class BillingCatalog {
  const BillingCatalog({required this.products});

  final List<BillingProduct> products;

  Set<String> entitlementsForProduct(String productId) {
    for (final product in products) {
      if (product.id == productId) {
        return product.entitlements;
      }
    }
    return const {};
  }
}

/// Possible states of an in-app purchase flow.
enum PurchaseProgressStatus {
  idle,
  pending,
  purchased,
  restored,
  error,
  canceled,
}

/// Event emitted during the lifecycle of a purchase.
final class PurchaseEvent {
  const PurchaseEvent({
    required this.status,
    this.productId,
    this.errorMessage,
    this.unlockedEntitlements = const {},
  });

  final PurchaseProgressStatus status;
  final String? productId;
  final String? errorMessage;
  final Set<String> unlockedEntitlements;

  @override
  String toString() =>
      'PurchaseEvent(status: $status, productId: $productId, unlocked: $unlockedEntitlements)';
}

/// Holds active entitlements and notifies listeners on change.
class EntitlementStore with ChangeNotifier {
  EntitlementStore({Set<String>? initialEntitlements})
      : _entitlements = Set<String>.from(initialEntitlements ?? const {});

  final Set<String> _entitlements;

  Set<String> get active => Set.unmodifiable(_entitlements);

  bool has(String entitlement) => _entitlements.contains(entitlement);

  bool grant(Iterable<String> entitlements) {
    final initialCount = _entitlements.length;
    _entitlements.addAll(entitlements);
    if (_entitlements.length != initialCount) {
      notifyListeners();
      return true;
    }
    return false;
  }

  bool revoke(String entitlement) {
    final removed = _entitlements.remove(entitlement);
    if (removed) {
      notifyListeners();
    }
    return removed;
  }

  void reset() {
    if (_entitlements.isNotEmpty) {
      _entitlements.clear();
      notifyListeners();
    }
  }
}

/// Boundary for billing and In-App Purchase operations.
abstract interface class BillingGateway {
  Future<AppResult<void>> initialize();
  bool get isAvailable;
  EntitlementStore get entitlements;
  Stream<PurchaseEvent> get purchaseEvents;

  Future<AppResult<List<StoreProduct>>> queryProducts(Set<String> productIds);
  Future<AppResult<void>> buyNonConsumable(StoreProduct product);
  Future<AppResult<void>> restorePurchases();

  void dispose();
}

/// In-memory/mock implementation for tests, offline mode, and UI previews.
final class FakeBillingGateway implements BillingGateway {
  FakeBillingGateway({
    required this.catalog,
    EntitlementStore? entitlements,
    this.isAvailable = true,
    List<StoreProduct>? initialProducts,
  })  : entitlements = entitlements ?? EntitlementStore(),
        _products = List<StoreProduct>.from(initialProducts ?? const []);

  final BillingCatalog catalog;
  @override
  final EntitlementStore entitlements;
  @override
  bool isAvailable;

  final List<StoreProduct> _products;
  final StreamController<PurchaseEvent> _eventsController =
      StreamController<PurchaseEvent>.broadcast();

  final Set<String> _pendingProductPurchases = {};
  final Set<String> _previouslyPurchasedProducts = {};

  bool simulatePending = false;
  bool simulateError = false;
  bool simulateCancel = false;
  String? nextErrorMessage;

  @override
  Stream<PurchaseEvent> get purchaseEvents => _eventsController.stream;

  @override
  Future<AppResult<void>> initialize() async => const Success(null);

  @override
  Future<AppResult<List<StoreProduct>>> queryProducts(
    Set<String> productIds,
  ) async {
    if (!isAvailable) {
      return const Failure(
        AppFailure('Loja de aplicativos indisponível no momento.'),
      );
    }
    final matched =
        _products.where((p) => productIds.contains(p.id)).toList();
    return Success(matched);
  }

  @override
  Future<AppResult<void>> buyNonConsumable(StoreProduct product) async {
    if (!isAvailable) {
      const err = Failure<void>(
        AppFailure('Não foi possível conectar à loja de aplicativos.'),
      );
      _eventsController.add(
        PurchaseEvent(
          status: PurchaseProgressStatus.error,
          productId: product.id,
          errorMessage: 'Loja indisponível',
        ),
      );
      return err;
    }

    if (simulateError) {
      final msg = nextErrorMessage ?? 'Simulação de erro na compra';
      _eventsController.add(
        PurchaseEvent(
          status: PurchaseProgressStatus.error,
          productId: product.id,
          errorMessage: msg,
        ),
      );
      return Failure(AppFailure(msg));
    }

    if (simulateCancel) {
      _eventsController.add(
        PurchaseEvent(
          status: PurchaseProgressStatus.canceled,
          productId: product.id,
        ),
      );
      return const Success(null);
    }

    if (simulatePending) {
      _pendingProductPurchases.add(product.id);
      _eventsController.add(
        PurchaseEvent(
          status: PurchaseProgressStatus.pending,
          productId: product.id,
        ),
      );
      return const Success(null);
    }

    final unlocked = catalog.entitlementsForProduct(product.id);
    entitlements.grant(unlocked);
    _previouslyPurchasedProducts.add(product.id);

    _eventsController.add(
      PurchaseEvent(
        status: PurchaseProgressStatus.purchased,
        productId: product.id,
        unlockedEntitlements: unlocked,
      ),
    );

    return const Success(null);
  }

  /// Resolves a previously pending purchase (e.g. approved by parent/bank).
  void resolvePendingPurchase(String productId) {
    if (_pendingProductPurchases.remove(productId)) {
      final unlocked = catalog.entitlementsForProduct(productId);
      entitlements.grant(unlocked);
      _previouslyPurchasedProducts.add(productId);

      _eventsController.add(
        PurchaseEvent(
          status: PurchaseProgressStatus.purchased,
          productId: productId,
          unlockedEntitlements: unlocked,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> restorePurchases() async {
    if (!isAvailable) {
      return const Failure(
        AppFailure('Não foi possível conectar à loja para restaurar compras.'),
      );
    }

    final allUnlocked = <String>{};
    for (final productId in _previouslyPurchasedProducts) {
      final unlocked = catalog.entitlementsForProduct(productId);
      entitlements.grant(unlocked);
      allUnlocked.addAll(unlocked);

      _eventsController.add(
        PurchaseEvent(
          status: PurchaseProgressStatus.restored,
          productId: productId,
          unlockedEntitlements: unlocked,
        ),
      );
    }

    return const Success(null);
  }

  @override
  void dispose() {
    _eventsController.close();
  }
}

/// Production Google Play Billing implementation using `in_app_purchase`.
final class PlayBillingGateway implements BillingGateway {
  PlayBillingGateway({
    required this.catalog,
    InAppPurchase? inAppPurchase,
    EntitlementStore? entitlements,
  })  : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance,
        entitlements = entitlements ?? EntitlementStore();

  final BillingCatalog catalog;
  final InAppPurchase _inAppPurchase;
  @override
  final EntitlementStore entitlements;

  bool _isAvailable = false;
  @override
  bool get isAvailable => _isAvailable;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final StreamController<PurchaseEvent> _eventsController =
      StreamController<PurchaseEvent>.broadcast();

  final Map<String, ProductDetails> _cachedPlatformProducts = {};

  @override
  Stream<PurchaseEvent> get purchaseEvents => _eventsController.stream;

  @override
  Future<AppResult<void>> initialize() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseStreamUpdate,
        onError: (error) {
          _eventsController.add(
            PurchaseEvent(
              status: PurchaseProgressStatus.error,
              errorMessage: error.toString(),
            ),
          );
        },
      );
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure('Erro ao conectar ao serviço de cobrança.', cause: e),
      );
    }
  }

  Future<void> _onPurchaseStreamUpdate(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _eventsController.add(
            PurchaseEvent(
              status: PurchaseProgressStatus.pending,
              productId: purchaseDetails.productID,
            ),
          );
          break;

        case PurchaseStatus.error:
          _eventsController.add(
            PurchaseEvent(
              status: PurchaseProgressStatus.error,
              productId: purchaseDetails.productID,
              errorMessage: purchaseDetails.error?.message ??
                  'Erro desconhecido durante a transação.',
            ),
          );
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
          break;

        case PurchaseStatus.canceled:
          _eventsController.add(
            PurchaseEvent(
              status: PurchaseProgressStatus.canceled,
              productId: purchaseDetails.productID,
            ),
          );
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final unlocked =
              catalog.entitlementsForProduct(purchaseDetails.productID);
          entitlements.grant(unlocked);

          final isRestore = purchaseDetails.status == PurchaseStatus.restored;
          _eventsController.add(
            PurchaseEvent(
              status: isRestore
                  ? PurchaseProgressStatus.restored
                  : PurchaseProgressStatus.purchased,
              productId: purchaseDetails.productID,
              unlockedEntitlements: unlocked,
            ),
          );

          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
          break;
      }
    }
  }

  @override
  Future<AppResult<List<StoreProduct>>> queryProducts(
    Set<String> productIds,
  ) async {
    if (!_isAvailable) {
      return const Failure(
        AppFailure('A Google Play Store não está disponível neste dispositivo.'),
      );
    }

    try {
      final response =
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.error != null) {
        return Failure(
          AppFailure(
            response.error!.message,
            cause: response.error,
          ),
        );
      }

      final products = <StoreProduct>[];
      for (final platformProduct in response.productDetails) {
        _cachedPlatformProducts[platformProduct.id] = platformProduct;
        products.add(
          StoreProduct(
            id: platformProduct.id,
            title: platformProduct.title,
            description: platformProduct.description,
            price: platformProduct.price,
            currencyCode: platformProduct.currencyCode,
            rawPrice: platformProduct.rawPrice,
          ),
        );
      }

      return Success(products);
    } catch (e) {
      return Failure(
        AppFailure('Falha ao consultar produtos na Google Play.', cause: e),
      );
    }
  }

  @override
  Future<AppResult<void>> buyNonConsumable(StoreProduct product) async {
    if (!_isAvailable) {
      return const Failure(
        AppFailure('Google Play Store indisponível.'),
      );
    }

    final platformProduct = _cachedPlatformProducts[product.id];
    if (platformProduct == null) {
      return Failure(
        AppFailure('Produto não encontrado ou não consultado previamente.'),
      );
    }

    final purchaseParam = PurchaseParam(productDetails: platformProduct);

    try {
      final success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      if (!success) {
        return const Failure(
          AppFailure('Não foi possível iniciar o fluxo de compra.'),
        );
      }
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure('Erro ao solicitar compra na Google Play.', cause: e),
      );
    }
  }

  @override
  Future<AppResult<void>> restorePurchases() async {
    if (!_isAvailable) {
      return const Failure(
        AppFailure('Google Play Store indisponível para restaurar compras.'),
      );
    }

    try {
      await _inAppPurchase.restorePurchases();
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure('Erro ao restaurar compras.', cause: e),
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _eventsController.close();
  }
}
