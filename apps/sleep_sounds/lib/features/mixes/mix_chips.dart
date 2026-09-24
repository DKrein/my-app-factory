import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../player/player_controller.dart';
import 'mix_dialogs.dart';
import 'mix_library.dart';
import 'saved_mix.dart';

/// One chip per saved mix. Tap loads it, long press opens rename and delete.
/// Takes no space when there are no mixes.
class MixChips extends StatelessWidget {
  const MixChips({super.key, required this.library, required this.playback});

  final MixLibrary library;
  final PlaybackController playback;

  static const height = 36.0;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([library, playback]),
    builder: (context, _) {
      final mixes = library.mixes;
      if (mixes.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: mixes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _chip(context, mixes[i]),
          ),
        ),
      );
    },
  );

  Widget _chip(BuildContext context, SavedMix mix) {
    final active = playback.isMix(mix);
    return Material(
      color: active
          ? FactoryColors.activeSurface
          : FactoryColors.surfaceElevated,
      shape: StadiumBorder(
        side: BorderSide(
          color: active ? FactoryColors.activeOutline : FactoryColors.outline,
          width: 1.2,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => playback.applyMix(mix),
        onLongPress: () => showMixMenu(context, library: library, mix: mix),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              const Icon(
                Symbols.queue_music_rounded,
                color: FactoryColors.mist,
                size: 18,
              ),
              Text(
                mix.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
