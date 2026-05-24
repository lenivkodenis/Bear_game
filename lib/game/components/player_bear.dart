import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/services.dart';

enum BearVisualState { idle, walking, jumping, interacting }

class PlayerBear extends PositionComponent with KeyboardHandler {
  PlayerBear({
    required super.position,
    required this.groundY,
    required this.levelWidth,
  }) : super(size: defaultSize, anchor: Anchor.topLeft);

  static final defaultSize = Vector2(78, 92);
  static const _bearSpritePath =
      'characters/bear_cub/processed/bear_cub_base_5_clean_v2_conservative.png';
  static const visualSize = Size(112, 96);
  static const visualOffset = Offset(-17, 0);
  static const idleBreathingAmplitude = 0.01;
  static const walkBobAmplitude = 3.0;
  static const walkTiltAmplitude = math.pi / 72;
  static const jumpTiltAmplitude = math.pi / 90;

  static const _moveSpeed = 160.0;
  static const _jumpImpulse = -360.0;
  static const _gravity = 820.0;
  static const _walkCycleSpeed = 10.0;
  static const _idleCycleSpeed = 2.4;

  final double groundY;
  final double levelWidth;
  final Vector2 _velocity = Vector2.zero();
  Image? _image;
  double _animationTime = 0;
  bool _facesLeft = false;
  bool _isInteracting = false;

  bool get _isOnGround => position.y >= groundY - size.y - 0.5;

  BearVisualState get _visualState {
    if (_isInteracting) {
      return BearVisualState.interacting;
    }
    if (!_isOnGround) {
      return BearVisualState.jumping;
    }
    if (_velocity.x.abs() > 0.5) {
      return BearVisualState.walking;
    }
    return BearVisualState.idle;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _image = await Flame.images.load(_bearSpritePath);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _animationTime += dt;
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
      final transform = _visualTransform();
      final destinationRect = transform.destinationRect;
      final pivot = Offset(
        destinationRect.left + destinationRect.width / 2,
        destinationRect.bottom,
      );

      canvas.save();
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(transform.rotation);
      canvas.scale(transform.scaleX, transform.scaleY);
      canvas.translate(-pivot.dx, -pivot.dy);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        destinationRect,
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
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
    _facesLeft = true;
    _isInteracting = false;
  }

  void moveRight() {
    _velocity.x = _moveSpeed;
    _facesLeft = false;
    _isInteracting = false;
  }

  void stopMoving() {
    _velocity.x = 0;
  }

  void jump() {
    if (_isOnGround) {
      _velocity.y = _jumpImpulse;
      _isInteracting = false;
    }
  }

  void startInteracting() {
    _isInteracting = true;
  }

  void stopInteracting() {
    _isInteracting = false;
  }

  _BearVisualTransform _visualTransform() {
    final direction = _facesLeft ? -1.0 : 1.0;
    final state = _visualState;
    final baseRect = visualOffset & visualSize;

    switch (state) {
      case BearVisualState.walking:
        final cycle = _animationTime * _walkCycleSpeed;
        final step = math.sin(cycle);
        final bob = -step.abs() * walkBobAmplitude;
        final stretch = math.sin(cycle * 2);
        return _BearVisualTransform(
          destinationRect: baseRect.translate(0, bob),
          scaleX: direction * (1.0 + stretch * 0.006),
          scaleY: 1.0 - stretch * 0.012,
          rotation:
              direction *
              (walkTiltAmplitude * 0.5 + step * walkTiltAmplitude * 0.5),
        );
      case BearVisualState.jumping:
        final rising = _velocity.y < 0;
        return _BearVisualTransform(
          destinationRect: baseRect,
          scaleX: direction * (rising ? 0.99 : 1.01),
          scaleY: rising ? 1.018 : 0.988,
          rotation:
              direction * (rising ? -jumpTiltAmplitude : jumpTiltAmplitude),
        );
      case BearVisualState.interacting:
      case BearVisualState.idle:
        final breath = math.sin(_animationTime * _idleCycleSpeed);
        return _BearVisualTransform(
          destinationRect: baseRect,
          scaleX: direction * (1.0 + breath * idleBreathingAmplitude * 0.5),
          scaleY: 1.0 + breath * idleBreathingAmplitude,
          rotation: 0,
        );
    }
  }

  @override
  double distance(PositionComponent other) {
    return position.distanceTo(other.position);
  }
}

class _BearVisualTransform {
  const _BearVisualTransform({
    required this.destinationRect,
    required this.scaleX,
    required this.scaleY,
    required this.rotation,
  });

  final Rect destinationRect;
  final double scaleX;
  final double scaleY;
  final double rotation;
}
