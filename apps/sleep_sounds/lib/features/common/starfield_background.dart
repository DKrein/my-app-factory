import 'dart:async';

import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';

/// A slow-drifting starfield behind [child], used on the library, player and
/// settings screens for a cozy night-sky feel. The tile is seamless, so the
/// drift loops forever with no visible jump.
///
/// Advances in small discrete steps on a plain [Timer] rather than an
/// [AnimationController]: a continuously-ticking animation would keep a
/// frame perpetually scheduled and make `pumpAndSettle()` hang in every
/// widget test that shows one of these screens. Stepping by a sub-pixel
/// amount several times a second reads as smooth, constant, very slow
/// drift, while still leaving real gaps with nothing scheduled between
/// ticks so tests can settle.
class StarfieldBackground extends StatefulWidget {
  const StarfieldBackground({super.key, required this.child});

  final Widget child;

  @override
  State<StarfieldBackground> createState() => _StarfieldBackgroundState();
}

class _StarfieldBackgroundState extends State<StarfieldBackground> {
  static const _tile = 480.0;
  static const _stepInterval = Duration(milliseconds: 200);
  static const _totalSteps = 1200; // full loop every 4 minutes, ~5 steps/sec

  int _step = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_stepInterval, (_) {
      if (!mounted) return;
      setState(() => _step = (_step + 1) % _totalSteps);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = _step / _totalSteps;
    final size = MediaQuery.sizeOf(context);
    final dx = -(phase * _tile) % _tile - _tile;
    final dy = -(phase * _tile * .5) % _tile - _tile;

    // The starfield paints its own navy fill (rather than an outer
    // ColoredBox) so nothing opaque sits between `widget.child` and whatever
    // Material ancestor it relies on for ListTile ink splashes.
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            alignment: Alignment.topLeft,
            child: Container(
              transform: Matrix4.translationValues(dx, dy, 0),
              width: size.width + _tile * 2,
              height: size.height + _tile * 2,
              decoration: const BoxDecoration(
                color: FactoryColors.night,
                image: DecorationImage(
                  image: AssetImage('assets/branding/starfield.png'),
                  opacity: .65,
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}
