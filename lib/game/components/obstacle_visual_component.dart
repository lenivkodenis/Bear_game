import 'dart:ui';

import 'package:flame/components.dart';

class ObstacleVisualComponent extends PositionComponent {
  ObstacleVisualComponent({required super.position, required super.size})
    : super(anchor: Anchor.topLeft);

  static const _snowTopColor = Color(0xFFF4FBFF);
  static const _snowShadowColor = Color(0xFFD7ECF6);
  static const _iceBaseColor = Color(0xFF9ED8EA);
  static const _iceShadowColor = Color(0xFF5FAAC8);
  static const _rimColor = Color(0xFFEAF8FF);
  static const _crackColor = Color(0x6684C8DF);
  static const _groundShadowColor = Color(0x550B3142);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final width = size.x;
    final height = size.y;
    if (width <= 0 || height <= 0) {
      return;
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, width, height));

    final bodyPath = Path()
      ..moveTo(0, height)
      ..lineTo(0, height * 0.46)
      ..quadraticBezierTo(width * 0.08, height * 0.14, width * 0.22, 0)
      ..lineTo(width * 0.78, 0)
      ..quadraticBezierTo(width * 0.92, height * 0.14, width, height * 0.46)
      ..lineTo(width, height)
      ..close();

    final bodyPaint = Paint()
      ..shader = Gradient.linear(
        Offset.zero,
        Offset(0, height),
        const [_snowTopColor, _snowShadowColor, _iceBaseColor, _iceShadowColor],
        const [0, 0.34, 0.68, 1],
      );
    canvas.drawPath(bodyPath, bodyPaint);

    final ridgePaint = Paint()
      ..color = _rimColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (height * 0.1).clamp(2.0, 4.0).toDouble()
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(1, ridgePaint.strokeWidth / 2),
      Offset(width - 1, ridgePaint.strokeWidth / 2),
      ridgePaint,
    );

    final outlinePaint = Paint()
      ..color = const Color(0xAA6AAFC6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(bodyPath, outlinePaint);

    final crackPaint = Paint()
      ..color = _crackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(width * 0.28, height * 0.48),
      Offset(width * 0.36, height * 0.72),
      crackPaint,
    );
    canvas.drawLine(
      Offset(width * 0.62, height * 0.42),
      Offset(width * 0.54, height * 0.66),
      crackPaint,
    );

    final groundShadowPaint = Paint()..color = _groundShadowColor;
    canvas.drawOval(
      Rect.fromLTWH(width * 0.04, height * 0.8, width * 0.92, height * 0.18),
      groundShadowPaint,
    );

    canvas.restore();
  }
}
