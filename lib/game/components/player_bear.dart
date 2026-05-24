import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/services.dart';

class PlayerBear extends PositionComponent with KeyboardHandler {
  PlayerBear({
    required super.position,
    required this.groundY,
    required this.levelWidth,
  }) : super(size: defaultSize, anchor: Anchor.topLeft);

  static final defaultSize = Vector2(78, 92);
  static const _bearSpritePath =
      'characters/bear_cub/processed/bear_cub_base_5_clean_v2_conservative.png';
  static const _spriteRenderSize = Size(108, 88);
  static const _spriteRenderOffset = Offset(-15, 4);

  static const _moveSpeed = 160.0;
  static const _jumpImpulse = -360.0;
  static const _gravity = 820.0;

  final double groundY;
  final double levelWidth;
  final Vector2 _velocity = Vector2.zero();
  Image? _image;

  bool get _isOnGround => position.y >= groundY - size.y - 0.5;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _image = await Flame.images.load(_bearSpritePath);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _velocity.y += _gravity * dt;
    position += _velocity * dt;

    final groundTop = groundY - size.y;
    if (position.y > groundTop) {
      position.y = groundTop;
      _velocity.y = 0;
    }

    final maxX = levelWidth - size.x;
    position.x = position.x.clamp(0, maxX).toDouble();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final image = _image;
    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        _spriteRenderOffset & _spriteRenderSize,
        Paint()..filterQuality = FilterQuality.high,
      );
      return;
    }

    final furPaint = Paint()..color = const Color(0xFFF8FBFF);
    final outlinePaint = Paint()
      ..color = const Color(0xFFB7CAD6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final detailPaint = Paint()..color = const Color(0xFF233642);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 18, size.x - 16, size.y - 18),
        const Radius.circular(18),
      ),
      furPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 18, size.x - 16, size.y - 18),
        const Radius.circular(18),
      ),
      outlinePaint,
    );

    canvas.drawCircle(const Offset(23, 18), 18, furPaint);
    canvas.drawCircle(const Offset(23, 18), 18, outlinePaint);
    canvas.drawCircle(const Offset(12, 4), 6, furPaint);
    canvas.drawCircle(const Offset(34, 4), 6, furPaint);
    canvas.drawCircle(const Offset(17, 16), 2.5, detailPaint);
    canvas.drawCircle(const Offset(29, 16), 2.5, detailPaint);
    canvas.drawCircle(const Offset(23, 23), 3, detailPaint);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA)) {
      moveLeft();
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD)) {
      moveRight();
    } else {
      stopMoving();
    }

    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.keyW)) {
      jump();
    }

    return true;
  }

  void moveLeft() {
    _velocity.x = -_moveSpeed;
  }

  void moveRight() {
    _velocity.x = _moveSpeed;
  }

  void stopMoving() {
    _velocity.x = 0;
  }

  void jump() {
    if (_isOnGround) {
      _velocity.y = _jumpImpulse;
    }
  }

  @override
  double distance(PositionComponent other) {
    return position.distanceTo(other.position);
  }
}
