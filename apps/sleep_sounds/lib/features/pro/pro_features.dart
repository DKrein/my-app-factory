import 'package:factory_billing/factory_billing.dart';
import 'package:flutter/foundation.dart';

/// The only place that decides what is Pro. Screens ask this class and never
/// look at the entitlement themselves.
class ProFeatures {
  const ProFeatures(this._entitlements);

  /// Entitlement granted by the one-time Pro purchase.
  static const entitlement = 'pro';

  final EntitlementStore _entitlements;

  /// Fires when the purchase state changes.
  Listenable get changes => _entitlements;

  bool get isPro => _entitlements.has(entitlement);

  bool get showAds => !isPro;
}
