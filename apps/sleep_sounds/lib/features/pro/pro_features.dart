import 'package:factory_billing/factory_billing.dart';
import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/foundation.dart';

/// The only place that decides what is Pro. Screens ask this class and never
/// look at the entitlement themselves.
class ProFeatures {
  const ProFeatures(this._entitlements);

  /// Mixes a free user may keep saved.
  static const freeMixLimit = 1;

  /// Entitlement granted by the one-time Pro purchase.
  static const entitlement = 'pro';

  final EntitlementStore _entitlements;

  /// Fires when the purchase state changes.
  Listenable get changes => _entitlements;

  bool get isPro => _entitlements.has(entitlement);

  bool get showAds => !isPro;

  bool get canSetIndividualVolume => isPro;

  /// Capy Night is free; every other palette is Pro.
  bool canUseTheme(FactoryPalette palette) =>
      isPro || palette.id == FactoryPalette.capyNight.id;

  /// Gradual fade, custom duration and "stop at".
  bool get canUseAdvancedTimer => isPro;

  /// Whether one more mix may be saved when [savedCount] already are.
  bool canSaveMix(int savedCount) => isPro || savedCount < freeMixLimit;
}
