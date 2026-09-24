import 'dart:async';

import 'package:factory_billing/factory_billing.dart';
import 'package:factory_core/factory_core.dart';
import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_config.g.dart';
import 'pro_features.dart';

enum _Load { loading, ready, failed }

enum _Notice { pending, purchaseFailed, restoreFailed, nothingToRestore }

/// The one screen that sells Pro. It opens from a Pro lock or from Settings,
/// never on its own.
class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key, required this.billing});

  final BillingGateway billing;

  static Future<void> open(BuildContext context, BillingGateway billing) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => PaywallPage(billing: billing),
        ),
      );

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  static const _restoreWait = Duration(seconds: 2);
  static const _features = [
    (Symbols.volume_up_rounded, 'Set the volume of each sound'),
    (Symbols.queue_music_rounded, 'Save as many mixes as you like'),
    (
      Symbols.timer_rounded,
      'Fade out slowly, set any length, or stop at a time',
    ),
    (Symbols.palette_rounded, 'More night themes'),
    (Symbols.ad_off_rounded, 'No ads'),
  ];

  late final ProFeatures _pro = ProFeatures(widget.billing.entitlements);
  StreamSubscription<PurchaseEvent>? _events;
  Timer? _restoreCheck;
  StoreProduct? _product;
  _Load _load = _Load.loading;
  _Notice? _notice;

  @override
  void initState() {
    super.initState();
    _events = widget.billing.purchaseEvents.listen(_onPurchaseEvent);
    _loadProduct();
  }

  @override
  void dispose() {
    _events?.cancel();
    _restoreCheck?.cancel();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() => _load = _Load.loading);
    final result = widget.billing.isAvailable
        ? await widget.billing.queryProducts({AppConfig.proProductId})
        : null;
    if (!mounted) return;
    setState(() {
      if (result is Success<List<StoreProduct>> && result.value.isNotEmpty) {
        _product = result.value.first;
        _load = _Load.ready;
      } else {
        _load = _Load.failed;
      }
    });
  }

  void _onPurchaseEvent(PurchaseEvent event) {
    if (!mounted) return;
    switch (event.status) {
      case PurchaseProgressStatus.purchased:
      case PurchaseProgressStatus.restored:
        _restoreCheck?.cancel();
        Navigator.of(context).maybePop();
      case PurchaseProgressStatus.pending:
        setState(() => _notice = _Notice.pending);
      case PurchaseProgressStatus.error:
        setState(() => _notice = _Notice.purchaseFailed);
      case PurchaseProgressStatus.canceled:
      case PurchaseProgressStatus.idle:
        setState(() => _notice = null);
    }
  }

  Future<void> _buy() async {
    final product = _product;
    if (product == null) return;
    setState(() => _notice = null);
    final result = await widget.billing.buyNonConsumable(product);
    if (result is Failure && mounted) {
      setState(() => _notice = _Notice.purchaseFailed);
    }
  }

  Future<void> _restore() async {
    setState(() => _notice = null);
    final result = await widget.billing.restorePurchases();
    if (!mounted) return;
    if (result is Failure) {
      setState(() => _notice = _Notice.restoreFailed);
      return;
    }
    _restoreCheck?.cancel();
    _restoreCheck = Timer(_restoreWait, () {
      if (mounted) setState(() => _notice = _Notice.nothingToRestore);
    });
  }

  String? get _noticeText => switch (_notice) {
    _Notice.pending => 'Waiting for your payment to go through. Pro turns on by itself when it does.',
    _Notice.purchaseFailed => "The purchase didn't go through. Try again.",
    _Notice.restoreFailed =>
      "Couldn't check your purchases. Check your connection and try again.",
    _Notice.nothingToRestore =>
      'No earlier Pro purchase was found on this Google account.',
    null => null,
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _pro.changes,
    builder: (context, _) => Scaffold(
      backgroundColor: context.palette.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Symbols.close_rounded),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          Text(
            _pro.isPro ? 'You have Pro' : 'Sleepy Capy Pro',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            _pro.isPro
                ? 'Thank you for supporting Sleepy Capy.'
                : 'One purchase, yours to keep. No subscription.',
            style: TextStyle(color: context.palette.mutedInk, fontSize: 16),
          ),
          const SizedBox(height: 24),
          for (final (icon, text) in _features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(icon, color: context.palette.mist, size: 26),
                  const SizedBox(width: 16),
                  Expanded(child: Text(text)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'All 17 sounds, mixing and the timer stay free.',
            style: TextStyle(color: context.palette.mutedInk),
          ),
          const SizedBox(height: 32),
          if (!_pro.isPro) ..._purchaseSection(),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => launchUrl(Uri.parse(AppConfig.privacyPolicyUrl)),
              child: const Text('Privacy Policy'),
            ),
          ),
        ],
      ),
    ),
  );

  List<Widget> _purchaseSection() {
    final product = _product;
    final noticeText = _noticeText;
    return [
      if (_load == _Load.loading)
        const Center(child: CircularProgressIndicator())
      else if (_load == _Load.failed) ...[
        Text(
          "Can't reach the store right now. Check your connection and try again.",
          style: TextStyle(color: context.palette.mutedInk),
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: _loadProduct, child: const Text('Try again')),
      ] else if (product != null) ...[
        Text(
          '${product.price} · one-time purchase',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _notice == _Notice.pending ? null : _buy,
          style: FilledButton.styleFrom(
            backgroundColor: context.palette.mist,
            foregroundColor: context.palette.night,
            disabledBackgroundColor: context.palette.mist.withValues(
              alpha: .25,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Get Pro',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ],
      if (noticeText != null) ...[
        const SizedBox(height: 16),
        Text(noticeText, style: TextStyle(color: context.palette.moon)),
      ],
      const SizedBox(height: 8),
      Center(
        child: TextButton(
          onPressed: _restore,
          child: const Text('Restore purchases'),
        ),
      ),
    ];
  }
}
