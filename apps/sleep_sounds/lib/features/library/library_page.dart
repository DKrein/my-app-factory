import 'dart:async';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:factory_ads/factory_ads.dart';
import 'package:factory_billing/factory_billing.dart';
import 'package:factory_core/factory_core.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_config.g.dart';
import '../../content/sounds.dart';
import '../common/starfield_background.dart';
import '../player/player_controller.dart';
import '../player/player_screen.dart' show openPlayerSheet;
import '../reminders/bedtime_reminder.dart';

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
    _purchaseSubscription = widget.billing.purchaseEvents.listen(
      _handlePurchaseEvent,
    );
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
          const SnackBar(
            content: Text('Processing purchase with Play Store...'),
          ),
        );
        break;
      case PurchaseProgressStatus.error:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${event.errorMessage ?? "Transaction failed"}',
            ),
          ),
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
      (placement) =>
          !widget.billing.entitlements.has(FactoryEntitlements.removeAds),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StarfieldBackground(
        child: SafeArea(
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
                              child: Icon(
                                selected?.icon ?? Icons.nightlight_round,
                              ),
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                  if (widget.billing.entitlements.has(
                    FactoryEntitlements.removeAds,
                  )) {
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
                    color: favorite
                        ? FactoryColors.mist
                        : FactoryColors.mutedInk,
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
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: FactoryColors.night,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 1,
      child: SettingsSheet(billing: widget.billing, storage: widget.storage),
    ),
  );

  void _openPlayer() => openPlayerSheet(context, widget.playback);
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({
    super.key,
    required this.billing,
    required this.storage,
  });

  final BillingGateway billing;
  final KeyValueStore storage;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  StoreProduct? _product;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = BedtimeReminderService.defaultTime;

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _loadReminderState();
  }

  Future<void> _loadReminderState() async {
    final (enabled, time) = await bedtimeReminders.readState(widget.storage);
    if (!mounted) return;
    setState(() {
      _reminderEnabled = enabled;
      _reminderTime = time;
    });
  }

  Future<TimeOfDay?> _pickTime() => showTimePicker(
    context: context,
    initialTime: _reminderTime,
    helpText: 'What time?',
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
      child: child!,
    ),
  );

  Future<void> _onReminderToggled(bool value) async {
    if (value) {
      final granted = await bedtimeReminders.requestPermission();
      if (!granted || !mounted) return;
      final picked = await _pickTime();
      if (picked == null) return;
      await bedtimeReminders.schedule(picked);
      await bedtimeReminders.save(widget.storage, enabled: true, time: picked);
      if (!mounted) return;
      setState(() {
        _reminderEnabled = true;
        _reminderTime = picked;
      });
    } else {
      await bedtimeReminders.cancel();
      await bedtimeReminders.save(widget.storage, enabled: false);
      if (!mounted) return;
      setState(() => _reminderEnabled = false);
    }
  }

  Future<void> _changeReminderTime() async {
    if (!_reminderEnabled) return;
    final picked = await _pickTime();
    if (picked == null) return;
    await bedtimeReminders.schedule(picked);
    await bedtimeReminders.save(widget.storage, enabled: true, time: picked);
    if (!mounted) return;
    setState(() => _reminderTime = picked);
  }

  String get _formattedVersion {
    final parts = AppConfig.version.split('+');
    final name = parts.first;
    return parts.length > 1 ? '$name (${parts[1]})' : name;
  }

  // Google's native review popup (requestReview) only ever shows once the
  // app is live on the Play Store and quota-eligible — it silently no-ops
  // otherwise, including for every sideloaded/debug install. Deep-linking to
  // the store listing is what actually works today and after launch alike.
  Future<void> _rateUs() => InAppReview.instance.openStoreListing();

  Future<void> _showBatteryOptimizationDialog() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: FactoryColors.surfaceElevated,
      title: const Text('Battery Optimization'),
      content: const Text(
        'Some Android devices stop background apps to save battery. '
        'We recommend turning OFF battery optimization for our app in '
        'system settings. This will prevent our app from closing or '
        'shutting off during sleep time.\n\n'
        'To do it, follow the steps:\n'
        '1. Tap "Turn Off" below\n'
        '2. Once in the Capy-App settings, tap "Battery"\n'
        '3. Select "Unrestricted"',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            AppSettings.openAppSettings(type: AppSettingsType.settings);
          },
          child: const Text('Turn Off'),
        ),
      ],
    ),
  );

  Future<void> _loadProduct() async {
    final result = await widget.billing.queryProducts({
      AppConfig.removeAdsProductId,
    });
    if (!mounted) return;
    setState(() {
      if (result is Success<List<StoreProduct>> && result.value.isNotEmpty) {
        _product = result.value.first;
      }
    });
  }

  Future<void> _openPrivacyPolicy() =>
      launchUrl(Uri.parse(AppConfig.privacyPolicyUrl));

  Future<void> _sendFeedback() {
    final body = StringBuffer()
      ..writeln('App: ${AppConfig.name} ${AppConfig.version}')
      ..writeln(
        'Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      )
      ..writeln('---')
      ..writeln('Feedback: ');
    return launchUrl(
      Uri(
        scheme: 'mailto',
        path: AppConfig.feedbackEmail,
        query:
            'subject=${Uri.encodeComponent('Sleepy Capy')}'
            '&body=${Uri.encodeComponent(body.toString())}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billing = widget.billing;
    return ListenableBuilder(
      listenable: billing.entitlements,
      builder: (context, _) {
        final isPremium = billing.entitlements.has(
          FactoryEntitlements.removeAds,
        );
        final product = _product;

        return StarfieldBackground(
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 32,
                      ),
                      tooltip: 'Close settings',
                    ),
                    Expanded(
                      child: Text(
                        'Settings',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isPremium)
                          Card(
                            color: FactoryColors.surface,
                            child: ListTile(
                              leading: const Icon(
                                Icons.verified,
                                color: FactoryColors.mist,
                              ),
                              title: const Text('Premium Active'),
                              subtitle: const Text('All ads are turned off.'),
                              trailing: const Icon(
                                Icons.check,
                                color: FactoryColors.mist,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8A4D8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Enjoy the app without ADS ${product?.price ?? r'$2.99'}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF3A2938),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton(
                                  onPressed: product == null
                                      ? null
                                      : () => billing.buyNonConsumable(product),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.white
                                        .withValues(alpha: .5),
                                    foregroundColor: const Color(0xFF3A2938),
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 12,
                                    ),
                                    elevation: 6,
                                    shadowColor: Colors.black45,
                                  ),
                                  child: const Text(
                                    'REMOVE ADS',
                                    style: TextStyle(
                                      color: Color(0xFF3A2938),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: .5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'One-time purchase',
                                  style: TextStyle(
                                    color: const Color(
                                      0xFF3A2938,
                                    ).withValues(alpha: .7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(
                            Icons.restore,
                            color: FactoryColors.mutedInk,
                          ),
                          title: const Text('Restore purchases'),
                          onTap: () async {
                            Navigator.of(context).pop();
                            await billing.restorePurchases();
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.bedtime_outlined,
                            color: FactoryColors.mutedInk,
                          ),
                          title: const Text('Bedtime Reminder'),
                          subtitle: Text(
                            _reminderEnabled
                                ? 'Daily at ${_reminderTime.format(context)}'
                                : 'Off',
                          ),
                          onTap: _reminderEnabled ? _changeReminderTime : null,
                          trailing: Switch(
                            value: _reminderEnabled,
                            onChanged: _onReminderToggled,
                          ),
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.star_outline,
                            color: FactoryColors.mutedInk,
                          ),
                          title: const Text('Rate Us'),
                          onTap: _rateUs,
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.privacy_tip_outlined,
                            color: FactoryColors.mutedInk,
                          ),
                          title: const Text('Privacy Policy'),
                          onTap: _openPrivacyPolicy,
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.mail_outline,
                            color: FactoryColors.mutedInk,
                          ),
                          title: const Text('Send Feedback'),
                          onTap: _sendFeedback,
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.battery_alert_outlined,
                            color: FactoryColors.mutedInk,
                          ),
                          title: const Text('Playback stops unexpectedly?'),
                          onTap: _showBatteryOptimizationDialog,
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.info_outline,
                            color: FactoryColors.mutedInk,
                          ),
                          title: const Text('App Version'),
                          subtitle: Text(_formattedVersion),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
