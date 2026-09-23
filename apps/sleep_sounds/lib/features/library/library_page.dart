import 'dart:async';

import 'package:factory_ads/factory_ads.dart';
import 'package:factory_billing/factory_billing.dart';
import 'package:factory_core/factory_core.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';

import '../../app_config.g.dart';
import '../../content/sounds.dart';
import '../player/player_controller.dart';
import '../player/player_screen.dart' show openPlayerSheet;

class LibraryPage extends StatefulWidget {
  const LibraryPage({
    super.key,
    required this.playback,
    required this.storage,
    required this.ads,
    required this.billing,
  });

  final PlaybackController playback;
  final KeyValueStore storage;
  final AdsGateway ads;
  final BillingGateway billing;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  static const _favoritesStorageKey = 'favorites_sounds_v1';
  final favorites = <String>{};
  StreamSubscription<PurchaseEvent>? _purchaseSubscription;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _purchaseSubscription = widget.billing.purchaseEvents.listen(_handlePurchaseEvent);
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final raw = await widget.storage.readString(_favoritesStorageKey);
    if (raw != null && raw.isNotEmpty && mounted) {
      setState(() {
        favorites.addAll(
          raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
        );
      });
    }
  }

  Future<void> _toggleFavorite(Sound sound) async {
    setState(() {
      if (favorites.contains(sound.name)) {
        favorites.remove(sound.name);
      } else {
        favorites.add(sound.name);
      }
    });
    await widget.storage.writeString(_favoritesStorageKey, favorites.join(','));
  }

  void _handlePurchaseEvent(PurchaseEvent event) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (event.status) {
      case PurchaseProgressStatus.purchased:
        messenger.showSnackBar(
          const SnackBar(content: Text('Purchase complete! Ads removed.')),
        );
        break;
      case PurchaseProgressStatus.restored:
        messenger.showSnackBar(
          const SnackBar(content: Text('Purchases restored successfully!')),
        );
        break;
      case PurchaseProgressStatus.pending:
        messenger.showSnackBar(
          const SnackBar(content: Text('Processing purchase with Play Store...')),
        );
        break;
      case PurchaseProgressStatus.error:
        messenger.showSnackBar(
          SnackBar(content: Text('Error: ${event.errorMessage ?? "Transaction failed"}')),
        );
        break;
      case PurchaseProgressStatus.canceled:
      case PurchaseProgressStatus.idle:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final adsPolicy = CustomAdsPolicy(
      (placement) => !widget.billing.entitlements.has(FactoryEntitlements.removeAds),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Good night',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                      IconButton(
                        onPressed: _openSettings,
                        icon: const Icon(Icons.tune_outlined),
                        tooltip: 'Settings',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pick a sound and let the day wind down.',
                    style: TextStyle(color: FactoryColors.mutedInk),
                  ),
                  const SizedBox(height: 28),
                  ListenableBuilder(
                    listenable: widget.playback,
                    builder: (context, _) {
                      final selected = widget.playback.sound;
                      return Card(
                        child: ListTile(
                          onTap: selected == null ? null : _openPlayer,
                          leading: CircleAvatar(
                            child: Icon(selected?.icon ?? Icons.nightlight_round),
                          ),
                          title: Text(selected?.name ?? 'Pick a sound'),
                          subtitle: Text(
                            selected == null
                                ? 'Your night starts here'
                                : widget.playback.playing
                                    ? 'Now playing'
                                    : 'Paused',
                          ),
                          trailing: Icon(
                            selected == null
                                ? Icons.arrow_downward
                                : Icons.play_arrow,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'To wind down',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sounds.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: .88,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (_, i) => _card(sounds[i]),
                  ),
                ],
              ),
            ),
            ListenableBuilder(
              listenable: widget.billing.entitlements,
              builder: (context, _) {
                if (widget.billing.entitlements.has(FactoryEntitlements.removeAds)) {
                  return const SizedBox.shrink();
                }
                return FactoryBannerAd(
                  gateway: widget.ads,
                  adUnitId: AppConfig.bannerAdUnitId,
                  placement: AdPlacement.bannerHome,
                  policy: adsPolicy,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Sound sound) {
    final favorite = favorites.contains(sound.name);
    return Card(
      child: InkWell(
        onTap: () {
          widget.playback.play(sound);
          _openPlayer();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _toggleFavorite(sound),
                  icon: Icon(
                    favorite ? Icons.favorite : Icons.favorite_border,
                    color: favorite ? FactoryColors.mist : FactoryColors.mutedInk,
                  ),
                ),
              ),
              Icon(sound.icon, size: 34, color: sound.color),
              const Spacer(),
              Text(sound.name, style: Theme.of(context).textTheme.titleMedium),
              Text(
                sound.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: FactoryColors.mutedInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettings() => showModalBottomSheet<void>(
        context: context,
        backgroundColor: FactoryColors.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => SettingsSheet(billing: widget.billing),
      );

  void _openPlayer() => openPlayerSheet(context, widget.playback);
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key, required this.billing});

  final BillingGateway billing;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  StoreProduct? _product;
  bool _productLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final result = await widget.billing.queryProducts(
      {AppConfig.removeAdsProductId},
    );
    if (!mounted) return;
    setState(() {
      _productLoaded = true;
      if (result is Success<List<StoreProduct>> && result.value.isNotEmpty) {
        _product = result.value.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final billing = widget.billing;
    return ListenableBuilder(
      listenable: billing.entitlements,
      builder: (context, _) {
        final isPremium = billing.entitlements.has(FactoryEntitlements.removeAds);
        final product = _product;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  color: FactoryColors.surface,
                  child: ListTile(
                    leading: Icon(
                      isPremium ? Icons.verified : Icons.lock_outline,
                      color: isPremium ? FactoryColors.mist : FactoryColors.moon,
                    ),
                    title: Text(
                      isPremium ? 'Premium Active' : 'Remove Ads',
                    ),
                    subtitle: Text(
                      isPremium
                          ? 'All ads are turned off.'
                          : 'Enjoy distraction-free sleep sounds.',
                    ),
                    trailing: isPremium
                        ? const Icon(Icons.check, color: FactoryColors.mist)
                        : TextButton(
                            onPressed: product == null
                                ? null
                                : () => billing.buyNonConsumable(product),
                            child: Text(
                              product?.price ??
                                  (_productLoaded ? 'Unavailable' : '...'),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.restore, color: FactoryColors.mutedInk),
                  title: const Text('Restore purchases'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await billing.restorePurchases();
                  },
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.dark_mode_outlined, color: FactoryColors.mutedInk),
                  title: Text('Dark Theme'),
                  subtitle: Text('On by default for nighttime relaxation'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
