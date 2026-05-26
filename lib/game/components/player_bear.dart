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

enum BearAnimationState {
  idle,
  walk,
  jump,
  fall,
  sitDown,
  sitting,
  standUp,
  interacting,
}

class PlayerBear extends PositionComponent with KeyboardHandler {
  PlayerBear({
    required super.position,
    required this.groundY,
    required this.levelWidth,
  }) : _activeGroundY = groundY,
       super(size: defaultSize, anchor: Anchor.topLeft);

  static const _hitboxWidth = 78.0;
  static const _hitboxHeight = 92.0;
  static final defaultSize = Vector2(_hitboxWidth, _hitboxHeight);
  static const _bearSpritePath =
      'characters/bear_cub/processed/bear_cub_base_5_clean_v2_conservative.png';
  static const _walkSpriteDirectory = 'characters/bear_cub/animations/walk';
  static const String? _jumpSpritePath = null;
  // TODO: Replace the idle fallback with the sit_down animation frames.
  static const String? _sitDownSpritePath = null;
  // TODO: Replace the idle fallback with the sitting_idle animation frames.
  static const String? _sittingSpritePath = null;
  // TODO: Replace the idle fallback with the stand_up animation frames.
  static const String? _standUpSpritePath = null;
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
  static const feetToGroundOffset = 0.0;
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
  static const _jumpImpulse = -410.0;
  static const _gravity = 820.0;
  static const _idleCycleSpeed = 2.4;
  static const _idleSitDelay = 3.0;
  static const _sitDownDuration = 0.35;
  static const _standUpDuration = 0.35;

  final double groundY;
  final double levelWidth;
  final Vector2 _velocity = Vector2.zero();
  double _activeGroundY;
  Image? _image;
  Image? _jumpImage;
  Image? _sitDownImage;
  Image? _sittingImage;
  Image? _standUpImage;
  SpriteAnimationTicker? _walkTicker;
  double _animationTime = 0;
  double _idleTimer = 0;
  double _postureStateTime = 0;
  BearAnimationState? _previousAnimationState;
  BearAnimationState _postureState = BearAnimationState.idle;
  bool _facesLeft = false;
  bool _isInteracting = false;
  int _pendingMoveDirection = 0;
  bool _pendingJump = false;

  bool get _isOnGround => position.y >= _activeGroundY - size.y - 0.5;

  BearAnimationState get animationState => _animationState;

  Rect get visualBounds {
    return _toWorldRect(_visualTransform(_animationState).destinationRect);
  }

  double get visualFeetY {
    final state = _animationState;
    final destinationRect = _visualTransform(state).destinationRect;

    return position.y + _visualPivotY(state, destinationRect);
  }

  BearAnimationState get _animationState {
    if (_isInteracting) {
      return BearAnimationState.interacting;
    }
    if (_isSeatedOrTransitioning) {
      return _postureState;
    }
    if (!_isOnGround || _velocity.y.abs() > 0.5) {
      return _velocity.y < 0
          ? BearAnimationState.jump
          : BearAnimationState.fall;
    }
    if (_velocity.x.abs() > 0.5) {
      return BearAnimationState.walk;
    }
    return BearAnimationState.idle;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _image = await Flame.images.load(_bearSpritePath);
    _jumpImage = await _loadOptionalStateImage(
      _jumpSpritePath,
      BearAnimationState.jump,
    );
    _sitDownImage = await _loadOptionalStateImage(
      _sitDownSpritePath,
      BearAnimationState.sitDown,
    );
    _sittingImage = await _loadOptionalStateImage(
      _sittingSpritePath,
      BearAnimationState.sitting,
    );
    _standUpImage = await _loadOptionalStateImage(
      _standUpSpritePath,
      BearAnimationState.standUp,
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

    final wasOnGround = _isOnGround;
    _animationTime += dt;
    _velocity.y += _gravity * dt;
    position += _velocity * dt;

    final groundTop = _activeGroundY - size.y;
    if (position.y > groundTop) {
      position.y = groundTop;
      _velocity.y = 0;
    }

    final maxX = levelWidth - size.x;
    position.x = position.x.clamp(0, maxX).toDouble();

    _updatePostureState(dt, wasOnGround: wasOnGround);

    final state = _animationState;
    if (state == BearAnimationState.walk) {
      _walkTicker?.update(dt);
    } else if (_previousAnimationState == BearAnimationState.walk) {
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
      if (state == BearAnimationState.walk && walkTicker != null) {
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
    _requestMove(-1);
  }

  void moveRight() {
    _requestMove(1);
  }

  void _requestMove(int direction) {
    if (_isInteracting) {
      stopMoving();
      return;
    }

    _pendingMoveDirection = direction;
    _facesLeft = direction < 0;
    _idleTimer = 0;
    if (_isSeatedOrTransitioning) {
      _startStandUp();
      return;
    }

    _velocity.x = direction * _moveSpeed;
    _postureState = BearAnimationState.idle;
  }

  void stopMoving() {
    _velocity.x = 0;
    _pendingMoveDirection = 0;
  }

  void setActiveGroundY(double value) {
    _activeGroundY = value;
  }

  void landOnSurface(double surfaceY) {
    _activeGroundY = surfaceY;
    position.y = surfaceY - size.y;
    _velocity.y = 0;
  }

  void jump() {
    if (_isInteracting) {
      stopMoving();
      return;
    }

    _idleTimer = 0;
    if (_isSeatedOrTransitioning) {
      _pendingJump = true;
      _startStandUp();
      return;
    }

    _performJump();
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
      _postureState = BearAnimationState.idle;
      _pendingMoveDirection = 0;
      _pendingJump = false;
      _idleTimer = 0;
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
    if (value) {
      _isInteracting = false;
      _enterSitting();
      stopMoving();
      return;
    }

    _postureState = BearAnimationState.idle;
    _postureStateTime = 0;
    _idleTimer = 0;
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

  Image? _imageForState(BearAnimationState state) {
    switch (state) {
      case BearAnimationState.jump:
      case BearAnimationState.fall:
        return _jumpImage;
      case BearAnimationState.sitDown:
        return _sitDownImage ?? _sittingImage;
      case BearAnimationState.sitting:
        return _sittingImage;
      case BearAnimationState.standUp:
        return _standUpImage ?? _sittingImage;
      case BearAnimationState.interacting:
        return _sittingImage;
      case BearAnimationState.idle:
      case BearAnimationState.walk:
        return null;
    }
  }

  _BearVisualTransform _visualTransform(BearAnimationState state) {
    final direction = _facesLeft ? -1.0 : 1.0;
    final baseRect = visualOffset & visualSize;

    switch (state) {
      case BearAnimationState.walk:
        return _BearVisualTransform(
          destinationRect: _walkTicker == null
              ? baseRect
              : _walkDestinationRect(),
          scaleX: direction,
          scaleY: 1.0,
          rotation: 0,
        );
      case BearAnimationState.jump:
      case BearAnimationState.fall:
        final rising = _velocity.y < 0;
        return _BearVisualTransform(
          destinationRect: baseRect,
          scaleX: direction * (rising ? 0.99 : 1.01),
          scaleY: rising ? 1.018 : 0.988,
          rotation:
              direction * (rising ? -jumpTiltAmplitude : jumpTiltAmplitude),
        );
      case BearAnimationState.sitDown:
        return _seatedTransform(
          direction: direction,
          baseRect: baseRect,
          progress: _sitDownProgress,
        );
      case BearAnimationState.sitting:
        return _seatedTransform(
          direction: direction,
          baseRect: baseRect,
          progress: 1,
        );
      case BearAnimationState.standUp:
        return _seatedTransform(
          direction: direction,
          baseRect: baseRect,
          progress: 1 - _standUpProgress,
        );
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
    if (state == BearAnimationState.walk && _walkTicker != null) {
      return destinationRect.bottom - _walkVisualGroundInset;
    }

    return destinationRect.bottom - visualGroundInset;
  }

  void _updatePostureState(double dt, {required bool wasOnGround}) {
    if (_isInteracting) {
      _idleTimer = 0;
      return;
    }

    switch (_postureState) {
      case BearAnimationState.sitDown:
        _idleTimer = 0;
        _postureStateTime += dt;
        if (_postureStateTime >= _sitDownDuration) {
          _enterSitting();
        }
      case BearAnimationState.sitting:
        _idleTimer = 0;
      case BearAnimationState.standUp:
        _idleTimer = 0;
        _postureStateTime += dt;
        if (_postureStateTime >= _standUpDuration) {
          _finishStandUp();
        }
      case BearAnimationState.idle:
      case BearAnimationState.walk:
      case BearAnimationState.jump:
      case BearAnimationState.fall:
      case BearAnimationState.interacting:
        if (!_canIdleTimerRun(wasOnGround: wasOnGround)) {
          _idleTimer = 0;
          return;
        }

        _idleTimer += dt;
        if (_idleTimer >= _idleSitDelay) {
          _startSitDown();
        }
    }
  }

  bool _canIdleTimerRun({required bool wasOnGround}) {
    return wasOnGround &&
        _isOnGround &&
        _velocity.x.abs() <= 0.5 &&
        _velocity.y.abs() <= 0.5 &&
        !_pendingJump &&
        !_isSeatedOrTransitioning;
  }

  bool get _isSeatedOrTransitioning {
    return _postureState == BearAnimationState.sitDown ||
        _postureState == BearAnimationState.sitting ||
        _postureState == BearAnimationState.standUp;
  }

  void _startSitDown() {
    _postureState = BearAnimationState.sitDown;
    _postureStateTime = 0;
    _idleTimer = 0;
    stopMoving();
  }

  void _enterSitting() {
    _postureState = BearAnimationState.sitting;
    _postureStateTime = 0;
    _idleTimer = 0;
    _pendingMoveDirection = 0;
    _pendingJump = false;
  }

  void _startStandUp() {
    if (_postureState == BearAnimationState.standUp) {
      return;
    }

    _postureState = BearAnimationState.standUp;
    _postureStateTime = 0;
    _idleTimer = 0;
    _velocity.x = 0;
  }

  void _finishStandUp() {
    _postureState = BearAnimationState.idle;
    _postureStateTime = 0;
    final moveDirection = _pendingMoveDirection;
    final shouldJump = _pendingJump;
    _pendingJump = false;

    if (moveDirection != 0) {
      _velocity.x = moveDirection * _moveSpeed;
      _facesLeft = moveDirection < 0;
    } else {
      _velocity.x = 0;
    }

    if (shouldJump) {
      _performJump();
    }
  }

  void _performJump() {
    if (_isOnGround) {
      _velocity.y = _jumpImpulse;
      _walkTicker?.reset();
      _idleTimer = 0;
      _postureState = BearAnimationState.idle;
    }
  }

  double get _sitDownProgress {
    return (_postureStateTime / _sitDownDuration).clamp(0.0, 1.0).toDouble();
  }

  double get _standUpProgress {
    return (_postureStateTime / _standUpDuration).clamp(0.0, 1.0).toDouble();
  }

  _BearVisualTransform _seatedTransform({
    required double direction,
    required Rect baseRect,
    required double progress,
  }) {
    final breath = math.sin(_animationTime * _idleCycleSpeed);
    final seatedScaleX = 1.04;
    final seatedScaleY = 0.92;
    final scaleX = 1.0 + (seatedScaleX - 1.0) * progress;
    final scaleY = 1.0 + (seatedScaleY - 1.0) * progress;
    final verticalOffset = 4.0 * progress;

    return _BearVisualTransform(
      destinationRect: baseRect.translate(0, verticalOffset),
      scaleX: direction * (scaleX + breath * idleBreathingAmplitude * 0.25),
      scaleY: scaleY + breath * idleBreathingAmplitude * 0.5,
      rotation: 0,
    );
  }

  Rect _toWorldRect(Rect localRect) {
    return Rect.fromLTWH(
      position.x + localRect.left,
      position.y + localRect.top,
      localRect.width,
      localRect.height,
    );
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
