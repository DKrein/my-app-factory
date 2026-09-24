import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../pro/pro_features.dart';
import 'theme_controller.dart';

/// The theme card in Settings: one swatch per palette. A palette that needs
/// Pro shows a lock and, tapped without Pro, calls [onLockedTap].
class ThemePicker extends StatelessWidget {
  const ThemePicker({
    super.key,
    required this.themes,
    required this.pro,
    required this.onLockedTap,
  });

  final ThemeController themes;
  final ProFeatures pro;
  final VoidCallback onLockedTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListenableBuilder(
      listenable: Listenable.merge([themes, pro.changes]),
      builder: (context, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Symbols.palette_rounded, color: palette.mist),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Theme',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  themes.selected.name,
                  style: TextStyle(color: palette.mutedInk),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                for (final option in themes.options)
                  Expanded(child: _swatch(context, option)),
              ],
            ),
            if (!pro.isPro) ...[
              const SizedBox(height: 12),
              Text(
                'Extra themes are part of Sleepy Capy Pro.',
                style: TextStyle(color: palette.mutedInk, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _swatch(BuildContext context, FactoryPalette option) {
    final current = context.palette;
    final selected = themes.selected.id == option.id;
    final locked = !pro.canUseTheme(option);
    return Semantics(
      button: true,
      selected: selected,
      label: locked ? '${option.name}, a Pro theme' : option.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: locked ? onLockedTap : () => themes.select(option),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: .78,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: option.night,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? current.mist : option.outline,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: option.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: option.activeSurface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: option.activeOutline),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      spacing: 3,
                      children: [
                        _dot(option.mist),
                        _dot(option.moon),
                        const Spacer(),
                        if (selected)
                          Icon(
                            Symbols.check_circle_rounded,
                            size: 16,
                            fill: 1,
                            color: option.mist,
                          )
                        else if (locked)
                          Icon(
                            Symbols.lock_rounded,
                            size: 14,
                            fill: 1,
                            color: option.mutedInk,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? current.ink : current.mutedInk,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
