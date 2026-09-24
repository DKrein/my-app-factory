import 'package:flutter/material.dart';

enum DrawnIcon { river, stream }

/// Icon of a sound: a Material Symbols glyph, or a drawn one for the sounds
/// the set has no glyph for.
class SoundIcon {
  const SoundIcon.symbol(IconData this.glyph) : drawn = null;
  const SoundIcon.drawn(DrawnIcon this.drawn) : glyph = null;

  final IconData? glyph;
  final DrawnIcon? drawn;

  static const _weight = 300.0;
  static const _strokeWidth = 1.9;

  Widget build(Color color, double size) {
    final glyph = this.glyph;
    if (glyph != null) {
      return Icon(
        glyph,
        color: color,
        size: size,
        weight: _weight,
        fill: 0,
        opticalSize: 24,
      );
    }
    return CustomPaint(
      size: Size.square(size),
      painter: _DrawnIconPainter(drawn!, color),
    );
  }
}

class _DrawnIconPainter extends CustomPainter {
  const _DrawnIconPainter(this.icon, this.color);

  final DrawnIcon icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = SoundIcon._strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (icon) {
      case DrawnIcon.river:
        canvas.drawPath(
          Path()
            ..moveTo(6, 2.5)
            ..cubicTo(1, 8, 13, 9, 8, 14)
            ..cubicTo(5, 17, 6, 20, 9, 21.5),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(17, 2.5)
            ..cubicTo(12, 6, 21, 8, 20, 12)
            ..cubicTo(19, 16, 14, 16, 15, 21.5),
          stroke,
        );
      case DrawnIcon.stream:
        canvas.drawPath(
          Path()
            ..moveTo(2.5, 9)
            ..cubicTo(5, 5.5, 7.5, 5.5, 10, 9)
            ..cubicTo(12.5, 12.5, 15, 12.5, 17.5, 9)
            ..cubicTo(19, 7, 20.5, 7, 21.5, 8),
          stroke,
        );
        final fill = Paint()..color = color;
        canvas.drawCircle(const Offset(6, 18), 2.6, fill);
        canvas.drawCircle(const Offset(13, 19), 2, fill);
        canvas.drawCircle(const Offset(18.5, 17), 1.5, fill);
    }
  }

  @override
  bool shouldRepaint(_DrawnIconPainter old) =>
      old.icon != icon || old.color != color;
}
