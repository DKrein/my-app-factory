import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';

import '../../content/addons.dart';
import 'player_controller.dart';

Future<void> openAddonsSheet(
  BuildContext context,
  PlaybackController playback,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: FactoryColors.surfaceElevated,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (_) => FractionallySizedBox(
    heightFactor: .78,
    child: AddonsSheet(playback: playback),
  ),
);

class AddonsSheet extends StatelessWidget {
  const AddonsSheet({super.key, required this.playback});

  final PlaybackController playback;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: playback,
    builder: (context, _) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FactoryColors.outline,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Add-ons', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'Layer extra sounds under your mix.',
              style: TextStyle(color: FactoryColors.mutedInk),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: addons.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _tile(addons[i]),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _tile(Addon addon) {
    final active = playback.isAddonActive(addon.id);
    return Card(
      color: FactoryColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(addon.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    addon.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Switch(
                  value: active,
                  onChanged: (_) => playback.toggleAddon(addon),
                ),
              ],
            ),
            if (active)
              Row(
                children: [
                  const Icon(
                    Icons.volume_mute,
                    size: 18,
                    color: FactoryColors.mutedInk,
                  ),
                  Expanded(
                    child: Slider(
                      value: playback.addonVolume(addon),
                      onChanged: (v) => playback.setAddonVolume(addon, v),
                    ),
                  ),
                  const Icon(
                    Icons.volume_up,
                    size: 18,
                    color: FactoryColors.mutedInk,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
