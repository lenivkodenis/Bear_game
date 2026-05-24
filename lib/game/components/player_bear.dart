import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const bool kBearDebugOverlay = false;

const List<String> kBearWalkFrameOrder = [
  'walk_01.png',
  'walk_02.png',
  'walk_03.png',
  'walk_04.png',
  'walk_05.png',
  'walk_06.png',
];

enum BearAnimationState { idle, walking, jumping, interacting, sitting }

class PlayerBear extends PositionComponent with KeyboardHandler {
  PlayerBear({
    required super.position,
    required this.groundY,
    required this.levelWidth,
    List<Rect> solidColliders = const <Rect>[],
  }) : _solidColliders = List<Rect>.unmodifiable(solidColliders),
       super(size: defaultSize, anchor: Anchor.topLeft);

  static const _hitboxWidth = 78.0;
  static const _hitboxHeight = 92.0;
  static final defaultSize = Vector2(_hitboxWidth, _hitboxHeight);
  static const _bearSpritePath =
      'characters/bear_cub/processed/bear_cub_base_5_clean_v2_conservative.png';
  static const _walkSpriteDirectory = 'characters/bear_cub/animations/walk';
  static const String? _jumpSpritePath = null;
  static const String? _sitSpritePath = null;
  static const visualWidth = 112.0;
  static const visualHeight = 96.0;
  static const visualSize = Size(visualWidth, visualHeight);
  static const _walkFrameStepTime = 0.14;
  static const _walkFrameSourceWidth = 359.0;
  static const _walkFrameSourceHeight = 268.0;
  static const _walkVisualHeight = 112.0;
  static const _walkVisualWidth =
      _walkVisualHeight * _walkFrameSourceWidth / _walkFrameSourceHeight;
  static const _walkVisualGroundInset = 10.0;
  static const visualGroundInset = 1.25;
  static const feetToGroundOffset = 90.0;
  static const visualFeetAnchor = Offset(
    _hitboxWidth / 2,
    _hitboxHeight + feetToGroundOffset,
  );
  static const visualOffset = Offset(
    _hitboxWidth / 2 - visualWidth / 2,
    _hitboxHeight + feetToGroundOffset - visualHeight + visualGroundInset,
  );
  static const idleBreathingAmplitude = 0.01;
  static const jumpTiltAmplitude = math.pi / 90;

  static const _moveSpeed = 160.0;
  static const _jumpImpulse = -360.0;
  static const _gravity = 820.0;
  static const _idleCycleSpeed = 2.4;

  final double groundY;
  final double levelWidth;
  final List<Rect> _solidColliders;
  final Vector2 _velocity = Vector2.zero();
  Image? _image;
  Image? _jumpImage;
  Image? _sitImage;
  SpriteAnimationTicker? _walkTicker;
  double _animationTime = 0;
  BearAnimationState? _previousAnimationState;
  bool _facesLeft = false;
  bool _isInteracting = false;
  bool _isSitting = false;
  bool _isGrounded = false;

  bool get _isOnGround {
    if (_solidColliders.isEmpty) {
      return position.y >= groundY - size.y - 0.5;
    }

    return _isGrounded || _hasSupportBelow();
  }

  BearAnimationState get animationState => _animationState;

  BearAnimationState get _animationState {
    if (_isSitting) {
      return BearAnimationState.sitting;
    }
    if (_isInteracting) {
      return BearAnimationState.interacting;
    }
    if (!_isOnGround || _velocity.y.abs() > 0.5) {
      return BearAnimationState.jumping;
    }
    if (_velocity.x.abs() > 0.5) {
      return BearAnimationState.walking;
    }
    return BearAnimationState.idle;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _image = await Flame.images.load(_bearSpritePath);
    _jumpImage = await _loadOptionalStateImage(
      _jumpSpritePath,
      BearAnimationState.jumping,
    );
    _sitImage = await _loadOptionalStateImage(
      _sitSpritePath,
      BearAnimationState.sitting,
    );
    try {
      final walkSprites = <Sprite>[];
      for (final frameName in kBearWalkFrameOrder) {
        final path = '$_walkSpriteDirectory/$frameName';
        walkSprites.add(Sprite(await Flame.images.load(path)));
      }
      final walkAnimation = SpriteAnimation.spriteList(
        walkSprites,
        stepTime: _walkFrameStepTime,
        loop: true,
      );
      _walkTicker = SpriteAnimationTicker(walkAnimation);
    } catch (error) {
      _walkTicker = null;
      // Keep the static bear visible if any walk frame is missing or invalid.
      debugPrint('Failed to load bear walk animation: $error');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _animationTime += dt;
    _velocity.y += _gravity * dt;

    if (_solidColliders.isEmpty) {
      _moveWithFallbackGround(dt);
    } else {
      _moveWithSolidColliders(dt);
    }

    final maxX = levelWidth - size.x;
    position.x = position.x.clamp(0, maxX).toDouble();

    final state = _animationState;
    if (state == BearAnimationState.walking) {
      _walkTicker?.update(dt);
    } else if (_previousAnimationState == BearAnimationState.walking) {
      _walkTicker?.reset();
    }
    _previousAnimationState = state;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final state = _animationState;
    final image = _image;
    final walkTicker = _walkTicker;
    if (image != null) {
      final stateImage = _imageForState(state) ?? image;
      final transform = _visualTransform(state);
      final destinationRect = transform.destinationRect;
      final pivot = Offset(
        destinationRect.left + destinationRect.width / 2,
        _visualPivotY(state, destinationRect),
      );

      canvas.save();
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(transform.rotation);
      canvas.scale(transform.scaleX, transform.scaleY);
      canvas.translate(-pivot.dx, -pivot.dy);
      final paint = Paint()..filterQuality = FilterQuality.high;
      if (state == BearAnimationState.walking && walkTicker != null) {
        walkTicker.getSprite().renderRect(
          canvas,
          destinationRect,
          overridePaint: paint,
        );
      } else {
        canvas.drawImageRect(
          stateImage,
          Rect.fromLTWH(
            0,
            0,
            stateImage.width.toDouble(),
            stateImage.height.toDouble(),
          ),
          destinationRect,
          paint,
        );
      }
      canvas.restore();

      if (kBearDebugOverlay) {
        _renderDebugOverlay(canvas, destinationRect);
      }
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

    if (kBearDebugOverlay) {
      _renderDebugOverlay(canvas, visualOffset & visualSize);
    }
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
    if (_isInteracting || _isSitting) {
      stopMoving();
      return;
    }

    _velocity.x = -_moveSpeed;
    _facesLeft = true;
    _isInteracting = false;
    _isSitting = false;
  }

  void moveRight() {
    if (_isInteracting || _isSitting) {
      stopMoving();
      return;
    }

    _velocity.x = _moveSpeed;
    _facesLeft = false;
    _isInteracting = false;
    _isSitting = false;
  }

  void stopMoving() {
    _velocity.x = 0;
  }

  void jump() {
    if (_isInteracting || _isSitting) {
      stopMoving();
      return;
    }

    if (_isOnGround) {
      _velocity.y = _jumpImpulse;
      _isGrounded = false;
      _walkTicker?.reset();
      _isInteracting = false;
      _isSitting = false;
    }
  }

  void startInteracting() {
    setInteracting(true);
  }

  void stopInteracting() {
    setInteracting(false);
  }

  void setInteracting(bool value) {
    _isInteracting = value;
    if (value) {
      _isSitting = false;
      stopMoving();
    }
  }

  void startSitting() {
    setSitting(true);
  }

  void stopSitting() {
    setSitting(false);
  }

  void setSitting(bool value) {
    _isSitting = value;
    if (value) {
      _isInteracting = false;
      stopMoving();
    }
  }

  Future<Image?> _loadOptionalStateImage(
    String? path,
    BearAnimationState state,
  ) async {
    if (path == null) {
      return null;
    }

    try {
      return await Flame.images.load(path);
    } catch (error) {
      debugPrint('Failed to load bear $state image: $error');
      return null;
    }
  }

  Rect get _hitboxRect => Rect.fromLTWH(position.x, position.y, size.x, size.y);

  void _moveWithFallbackGround(double dt) {
    position += _velocity * dt;

    final groundTop = groundY - size.y;
    if (position.y > groundTop) {
      position.y = groundTop;
      _velocity.y = 0;
    }
  }

  void _moveWithSolidColliders(double dt) {
    _isGrounded = false;

    final horizontalDelta = _velocity.x * dt;
    if (horizontalDelta != 0) {
      position.x += horizontalDelta;
      _resolveHorizontalCollisions(horizontalDelta);
    }

    final verticalDelta = _velocity.y * dt;
    position.y += verticalDelta;
    _resolveVerticalCollisions(verticalDelta);
    _isGrounded = _isGrounded || _hasSupportBelow();
  }

  void _resolveHorizontalCollisions(double horizontalDelta) {
    for (final collider in _solidColliders) {
      if (!_hitboxRect.overlaps(collider)) {
        continue;
      }

      if (horizontalDelta > 0) {
        position.x = collider.left - size.x;
      } else {
        position.x = collider.right;
      }
      _velocity.x = 0;
    }
  }

  void _resolveVerticalCollisions(double verticalDelta) {
    if (verticalDelta == 0) {
      return;
    }

    for (final collider in _solidColliders) {
      if (!_hitboxRect.overlaps(collider)) {
        continue;
      }

      if (verticalDelta > 0) {
        position.y = collider.top - size.y;
        _velocity.y = 0;
        _isGrounded = true;
      } else {
        position.y = collider.bottom;
        _velocity.y = 0;
      }
    }
  }

  bool _hasSupportBelow() {
    const supportTolerance = 1.0;
    final hitbox = _hitboxRect;
    final feetY = hitbox.bottom;

    for (final collider in _solidColliders) {
      final hasHorizontalOverlap =
          hitbox.right > collider.left + supportTolerance &&
          hitbox.left < collider.right - supportTolerance;
      final isStandingOnTop = (feetY - collider.top).abs() <= supportTolerance;

      if (hasHorizontalOverlap && isStandingOnTop) {
        return true;
      }
    }

    return false;
  }

  Image? _imageForState(BearAnimationState state) {
    switch (state) {
      case BearAnimationState.jumping:
        return _jumpImage;
      case BearAnimationState.sitting:
      case BearAnimationState.interacting:
        return _sitImage;
      case BearAnimationState.idle:
      case BearAnimationState.walking:
        return null;
    }
  }

  _BearVisualTransform _visualTransform(BearAnimationState state) {
    final direction = _facesLeft ? -1.0 : 1.0;
    final baseRect = visualOffset & visualSize;

    switch (state) {
      case BearAnimationState.walking:
        return _BearVisualTransform(
          destinationRect: _walkTicker == null
              ? baseRect
              : _walkDestinationRect(),
          scaleX: direction,
          scaleY: 1.0,
          rotation: 0,
        );
      case BearAnimationState.jumping:
        final rising = _velocity.y < 0;
        return _BearVisualTransform(
          destinationRect: baseRect,
          scaleX: direction * (rising ? 0.99 : 1.01),
          scaleY: rising ? 1.018 : 0.988,
          rotation:
              direction * (rising ? -jumpTiltAmplitude : jumpTiltAmplitude),
        );
      case BearAnimationState.sitting:
      case BearAnimationState.interacting:
      case BearAnimationState.idle:
        final breath = math.sin(_animationTime * _idleCycleSpeed);
        return _BearVisualTransform(
          destinationRect: baseRect,
          scaleX: direction * (1.0 + breath * idleBreathingAmplitude * 0.5),
          scaleY: 1.0 + breath * idleBreathingAmplitude,
          rotation: 0,
        );
    }
  }

  Rect _walkDestinationRect() {
    final left = _hitboxWidth / 2 - _walkVisualWidth / 2;
    final bottom = visualFeetAnchor.dy + _walkVisualGroundInset;

    return Rect.fromLTWH(
      left,
      bottom - _walkVisualHeight,
      _walkVisualWidth,
      _walkVisualHeight,
    );
  }

  double _visualPivotY(BearAnimationState state, Rect destinationRect) {
    if (state == BearAnimationState.walking && _walkTicker != null) {
      return destinationRect.bottom - _walkVisualGroundInset;
    }

    return destinationRect.bottom - visualGroundInset;
  }

  void _renderDebugOverlay(Canvas canvas, Rect visualRect) {
    final hitboxPaint = Paint()
      ..color = const Color(0x663B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final visualPaint = Paint()
      ..color = const Color(0x6600C853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final groundPaint = Paint()
      ..color = const Color(0xCCFF1744)
      ..strokeWidth = 1.5;
    final visibleBottomPaint = Paint()
      ..color = const Color(0xCCAA00FF)
      ..strokeWidth = 1.5;
    final feetPaint = Paint()
      ..color = const Color(0xCCFFAB00)
      ..strokeWidth = 1.5;

    final hitbox = Rect.fromLTWH(0, 0, size.x, size.y);
    final groundLine = size.y;
    final visibleBottomLine = visualRect.bottom - visualGroundInset;
    final guideLeft = math.min(hitbox.left, visualRect.left) - 12;
    final guideRight = math.max(hitbox.right, visualRect.right) + 12;

    canvas.drawRect(hitbox, hitboxPaint);
    canvas.drawRect(visualRect, visualPaint);
    canvas.drawLine(
      Offset(guideLeft, groundLine),
      Offset(guideRight, groundLine),
      groundPaint,
    );
    canvas.drawLine(
      Offset(guideLeft, visibleBottomLine),
      Offset(guideRight, visibleBottomLine),
      visibleBottomPaint,
    );
    canvas.drawLine(
      Offset(guideLeft, visualFeetAnchor.dy),
      Offset(guideRight, visualFeetAnchor.dy),
      feetPaint,
    );
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
