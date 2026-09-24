import 'dart:math' as math;

import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';

/// Three bars that dance while [playing] and rest flat otherwise.
class EqualizerBars extends StatefulWidget {
  const EqualizerBars({super.key, required this.playing});

  final bool playing;

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  static const _height = 14.0;
  static const _barWidth = 3.0;
  static const _restingLevel = .3;
  static const _cyclesPerLoop = [2, 3, 1];
  static const _phases = [0.0, .35, .7];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  bool _reduceMotion = false;

  bool get _animating => widget.playing && !_reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (_animating) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _level(int bar) {
    if (!_animating) return _restingLevel;
    final angle =
        2 * math.pi * (_cyclesPerLoop[bar] * _controller.value + _phases[bar]);
    return _restingLevel + (1 - _restingLevel) * (.5 + .5 * math.sin(angle));
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => SizedBox(
        height: _height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 2.5,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: _barWidth,
                height: _height * _level(i),
                decoration: BoxDecoration(
                  color: context.palette.mist,
                  borderRadius: BorderRadius.circular(_barWidth / 2),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
