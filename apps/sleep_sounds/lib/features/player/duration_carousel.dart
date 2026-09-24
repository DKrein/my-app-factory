import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';

import 'sleep_duration.dart';

/// Horizontal snapping picker for the sleep timer duration, e.g.
/// `1h  6h  [12h]  24h`. Tapping an item snaps it to the center and commits
/// the selection; dragging snaps to the nearest item on release.
class DurationCarousel extends StatefulWidget {
  const DurationCarousel({
    super.key,
    required this.selectedMinutes,
    required this.onSelected,
  });

  final int selectedMinutes;
  final ValueChanged<int> onSelected;

  @override
  State<DurationCarousel> createState() => _DurationCarouselState();
}

class _DurationCarouselState extends State<DurationCarousel> {
  static const _viewportFraction = 0.2;

  late final PageController _controller = PageController(
    viewportFraction: _viewportFraction,
    initialPage: _indexOf(widget.selectedMinutes),
  );
  late double _page = _controller.initialPage.toDouble();

  int _indexOf(int minutes) {
    final index = sleepDurations.indexWhere((d) => d.minutes == minutes);
    return index == -1
        ? sleepDurations.indexWhere((d) => d.minutes == defaultSleepMinutes)
        : index;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    if (!_controller.position.haveDimensions) return;
    setState(() => _page = _controller.page ?? _page);
  }

  @override
  void didUpdateWidget(covariant DurationCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetIndex = _indexOf(widget.selectedMinutes);
    if (targetIndex != _page.round() &&
        widget.selectedMinutes != oldWidget.selectedMinutes) {
      _controller.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    }
  }

  void _selectPage(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onPageScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView.builder(
    controller: _controller,
    itemCount: sleepDurations.length,
    onPageChanged: (index) => widget.onSelected(sleepDurations[index].minutes),
    itemBuilder: (context, index) {
      final distance = (_page - index).abs();
      final t = (1 - distance).clamp(0.0, 1.0);
      final fontSize = (20 - 3.5 * distance).clamp(12.0, 20.0);
      final color = Color.lerp(FactoryColors.mutedInk, FactoryColors.ink, t)!;
      return Center(
        child: GestureDetector(
          onTap: () => _selectPage(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: FactoryColors.surfaceElevated.withValues(alpha: t * .9),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: FactoryColors.moon.withValues(alpha: .55 * t),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                sleepDurations[index].label,
                style: TextStyle(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: t > .5 ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
