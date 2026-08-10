import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const bool kBearDebugOverlay = false;
const bool kBearUseFrameByFrameWalk = true;
const bool kBearUseHardWalkFrames = false;
const bool kBearUseProceduralWalkCarry = false;
const bool useProceduralBearWalkPrototype = false;
const bool forceProceduralWalkDebug = false;
const bool showProceduralWalkDebugOverlay = false;
const bool showProceduralWalkDebugColors = false;
const double kBearProceduralStrideLengthPx = 80.0;
const double kBearProceduralForcedPhaseSpeed = 0.8;
const double kBearProceduralFrontLegSwingPx = 13.0;
const double kBearProceduralHindLegSwingPx = 12.0;
const double kBearProceduralLegLiftPx = 7.0;
const double kBearProceduralBodyBobPx = 2.0;
const double kBearProceduralBodyTiltRadians = math.pi / 120;
const double kBearProceduralIdleReturnSpeed = 6.0;
const double kBearProceduralLegSwingPhase = 0.32;
const Color kBearProceduralProductionFarLegColor = Color(0xFFF1F7FA);
const Color kBearProceduralProductionNearLegColor = Color(0xFFE7F0F5);
const Color kBearProceduralProductionOutlineColor = Color(0xFFB8CDD8);
const Color kBearProceduralProductionPawPadColor = Color(0xFF516A7A);
const Color kBearProceduralDebugFarLegColor = Color(0xFFE1EDF4);
const Color kBearProceduralDebugNearLegColor = Color(0xFF9AB7C7);
const Color kBearProceduralDebugOutlineColor = Color(0xFF587C91);
const Color kBearProceduralDebugPawPadColor = Color(0xFF243F52);

const List<String> kBearWalkFrameOrder = [
  'walk_01.png',
  'walk_02.png',
  'walk_03.png',
  'walk_04.png',
  'walk_05.png',
  'walk_06.png',
];

const String kBearWalkSpriteDirectory =
    'characters/bear_cub/animations/walk_normalized';
const double kBearWalkFrameStepTime = 0.12;
const List<double> kBearWalkFrameStepTimes = [
  0.13,
  0.095,
  0.115,
  0.12,
  0.13,
  0.125,
];
const List<double> kBearWalkFrameVerticalOffsets = [
  0.0,
  -2.4,
  -1.1,
  -0.6,
  -0.3,
  -0.1,
];
final List<String> kBearWalkAssetPaths = List.unmodifiable(
  kBearWalkFrameOrder.map(
    (frameName) => '$kBearWalkSpriteDirectory/$frameName',
  ),
);

@visibleForTesting
double debugAdvanceBearProceduralWalkPhase({
  required double phase,
  required double dt,
  required double deltaX,
  required bool forceTimePhase,
  required bool active,
  double strideLengthPx = kBearProceduralStrideLengthPx,
}) {
  if (!active) {
    return phase % 1.0;
  }
  if (forceTimePhase) {
    return (phase + dt * kBearProceduralForcedPhaseSpeed) % 1.0;
  }
  if (strideLengthPx <= 0) {
    return phase % 1.0;
  }

  return (phase + deltaX.abs() / strideLengthPx) % 1.0;
}

enum BearAnimationState { idle, walk, jump, fall, interacting }

enum BearProceduralLeg { nearFront, farFront, nearHind, farHind }

@visibleForTesting
double debugBearProceduralLegLift({
  required BearProceduralLeg leg,
  required double phase,
  double poseBlend = 1.0,
}) {
  return _proceduralLegPoseForPhase(
    leg: leg,
    phase: phase,
    poseBlend: poseBlend,
  ).lift;
}

class _BearProceduralLegPose {
  const _BearProceduralLegPose({required this.swing, required this.lift});

  final double swing;
  final double lift;
}

_BearProceduralLegPose _proceduralLegPoseForPhase({
  required BearProceduralLeg leg,
  required double phase,
  required double poseBlend,
}) {
  final normalizedBlend = poseBlend.clamp(0.0, 1.0).toDouble();
  final startPhase = switch (leg) {
    BearProceduralLeg.nearFront || BearProceduralLeg.farHind => 0.08,
    BearProceduralLeg.farFront || BearProceduralLeg.nearHind => 0.56,
  };
  final legPhase = (phase - startPhase + 1.0) % 1.0;

  if (legPhase < kBearProceduralLegSwingPhase) {
    final swingProgress = _smoothStepUnit(
      legPhase / kBearProceduralLegSwingPhase,
    );
    return _BearProceduralLegPose(
      swing: _lerpDouble(-1.0, 1.0, swingProgress) * normalizedBlend,
      lift:
          math.sin(swingProgress * math.pi) *
          kBearProceduralLegLiftPx *
          normalizedBlend,
    );
  }

  final plantedProgress = _smoothStepUnit(
    (legPhase - kBearProceduralLegSwingPhase) /
        (1.0 - kBearProceduralLegSwingPhase),
  );
  return _BearProceduralLegPose(
    swing: _lerpDouble(1.0, -1.0, plantedProgress) * normalizedBlend,
    lift: 0,
  );
}

double _smoothStepUnit(double progress) {
  final t = progress.clamp(0.0, 1.0).toDouble();
  return t * t * (3 - 2 * t);
}

double _lerpDouble(double start, double end, double progress) {
  return start + (end - start) * progress;
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
  static const String? _jumpSpritePath = null;
  static const visualAnchor = Anchor.bottomCenter;
  static const visualWidth = 112.0;
  static const visualHeight = 96.0;
  static const visualSize = Size(visualWidth, visualHeight);
  static const _walkFrameStepTime = kBearWalkFrameStepTime;
  static const _walkFrameBlendMaxAlpha = 0.32;
  static const _walkFrameSourceWidth = 359.0;
  static const _walkFrameSourceHeight = 268.0;
  static const _walkFrameOpaqueBottom = 245.0;
  static const _walkVisualHeight = visualHeight;
  static const _walkVisualWidth =
      _walkVisualHeight * _walkFrameSourceWidth / _walkFrameSourceHeight;
  static const _walkVisualGroundInset =
      _walkVisualHeight *
      (_walkFrameSourceHeight - _walkFrameOpaqueBottom) /
      _walkFrameSourceHeight;
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
  static const walkCarryScaleAmplitude = 0.006;
  static const walkCarryTiltAmplitude = math.pi / 240;

  static const _moveSpeed = 160.0;
  static const _jumpImpulse = -410.0;
  static const _gravity = 820.0;
  static const _idleCycleSpeed = 2.4;
  static bool _walkLoadLogged = false;
  static bool _walkReadyLogged = false;
  static bool _walkStateLogged = false;
  static bool _walkFrameCycleLogged = false;
  static int _proceduralWalkLogCount = 0;

  final double groundY;
  final double levelWidth;
  final Vector2 _velocity = Vector2.zero();
  double _activeGroundY;
  Image? _image;
  Image? _jumpImage;
  SpriteAnimationTicker? _walkTicker;
  final Set<int> _debugObservedWalkFrameIndices = <int>{};
  double _animationTime = 0;
  double _proceduralWalkPhase = 0;
  double _lastProceduralDeltaX = 0;
  double _lastProceduralFrontLegSwing = 0;
  double _lastProceduralHindLegSwing = 0;
  double _lastProceduralNearFrontLegLift = 0;
  double _lastProceduralFarFrontLegLift = 0;
  double _lastProceduralNearHindLegLift = 0;
  double _lastProceduralFarHindLegLift = 0;
  double _lastProceduralFarFrontLegSwing = 0;
  double _lastProceduralFarHindLegSwing = 0;
  double _lastProceduralBodyBobY = 0;
  double _lastProceduralBodyTilt = 0;
  double _proceduralWalkPoseBlend = 0;
  double _proceduralDebugLogTime = 0;
  bool _proceduralRenderLegsCalled = false;
  BearAnimationState? _previousAnimationState;
  bool _facesLeft = false;
  bool _isInteracting = false;

  bool get _isOnGround => position.y >= _activeGroundY - size.y - 0.5;

  BearAnimationState get animationState => _animationState;
  double get horizontalVelocityX => _velocity.x;
  Rect get collisionBounds =>
      Rect.fromLTWH(position.x, position.y, size.x, size.y);
  @visibleForTesting
  int? get debugWalkFrameIndex => _walkTicker?.currentIndex;
  @visibleForTesting
  int get debugLoadedWalkFrameCount =>
      _walkTicker?.spriteAnimation.frames.length ?? 0;
  @visibleForTesting
  double get debugProceduralWalkPhase => _proceduralWalkPhase;
  @visibleForTesting
  double get debugProceduralDeltaX => _lastProceduralDeltaX;
  @visibleForTesting
  double get debugProceduralFrontLegSwing => _lastProceduralFrontLegSwing;
  @visibleForTesting
  double get debugProceduralHindLegSwing => _lastProceduralHindLegSwing;
  @visibleForTesting
  double get debugProceduralNearFrontLegLift => _lastProceduralNearFrontLegLift;
  @visibleForTesting
  double get debugProceduralFarFrontLegLift => _lastProceduralFarFrontLegLift;
  @visibleForTesting
  double get debugProceduralNearHindLegLift => _lastProceduralNearHindLegLift;
  @visibleForTesting
  double get debugProceduralFarHindLegLift => _lastProceduralFarHindLegLift;
  @visibleForTesting
  bool get debugProceduralRenderLegsCalled => _proceduralRenderLegsCalled;
  @visibleForTesting
  double get debugProceduralWalkPoseBlend => _proceduralWalkPoseBlend;

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
    if (!kBearUseFrameByFrameWalk) {
      _walkTicker = null;
      return;
    }

    try {
      final uniqueWalkAssetPaths = kBearWalkAssetPaths.toSet();
      if (kDebugMode && !_walkLoadLogged) {
        debugPrint(
          'Bear walk load: frames=${kBearWalkAssetPaths.length}, '
          'unique=${uniqueWalkAssetPaths.length}, '
          'stepTime=$_walkFrameStepTime',
        );
        _walkLoadLogged = true;
        if (uniqueWalkAssetPaths.length != kBearWalkAssetPaths.length) {
          debugPrint('Bear walk load: duplicate asset path detected.');
        }
      }

      final walkSprites = <Sprite>[];
      for (final path in kBearWalkAssetPaths) {
        walkSprites.add(Sprite(await Flame.images.load(path)));
      }
      final walkAnimation = SpriteAnimation(
        List<SpriteAnimationFrame>.generate(
          walkSprites.length,
          (index) => SpriteAnimationFrame(
            walkSprites[index],
            kBearWalkFrameStepTimes[index],
          ),
        ),
        loop: true,
      );
      _walkTicker = SpriteAnimationTicker(walkAnimation);
      if (kDebugMode && !_walkReadyLogged) {
        debugPrint('Bear walk ready: loadedFrames=${walkSprites.length}');
        _walkReadyLogged = true;
      }
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
    final previousX = position.x;
    _velocity.y += _gravity * dt;
    position += _velocity * dt;

    final groundTop = _activeGroundY - size.y;
    if (position.y > groundTop) {
      position.y = groundTop;
      _velocity.y = 0;
    }

    final maxX = levelWidth - size.x;
    position.x = position.x.clamp(0, maxX).toDouble();

    final state = _animationState;
    _updateProceduralWalk(dt, position.x - previousX, state);
    if (state == BearAnimationState.walk) {
      if (kDebugMode && !_walkStateLogged && _walkTicker != null) {
        debugPrint(
          'Bear animation state: walk, '
          'velocityX=${_velocity.x.toStringAsFixed(1)}, '
          'loadedFrames=${_walkTicker?.spriteAnimation.frames.length ?? 0}',
        );
        _walkStateLogged = true;
      }
      _walkTicker?.update(dt);
      _recordWalkFrameIndex();
    } else if (_previousAnimationState == BearAnimationState.walk) {
      _walkTicker?.reset();
    }
    _previousAnimationState = state;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    _proceduralRenderLegsCalled = false;
    final state = _animationState;
    final image = _image;
    final walkTicker = _walkTicker;
    if (image != null) {
      final stateImage = _imageForState(state);
      final transform = _visualTransform(state);
      final destinationRect = transform.destinationRect;
      final shouldRenderProceduralLegs = _shouldRenderProceduralWalkLegs(state);
      final pivot = Offset(
        destinationRect.left + destinationRect.width / 2,
        _visualPivotY(state, destinationRect),
      );
      final paint = Paint()..filterQuality = FilterQuality.high;

      canvas.save();
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(transform.rotation + _proceduralBodyTiltForRender(state));
      canvas.scale(transform.scaleX, transform.scaleY);
      canvas.translate(-pivot.dx, -pivot.dy);
      final proceduralBodyBobY = _proceduralBodyBobForRender(state);
      final proceduralDestinationRect = destinationRect.translate(
        0,
        proceduralBodyBobY,
      );
      if (shouldRenderProceduralLegs) {
        _renderProceduralWalkLegs(
          canvas,
          destinationRect,
          bodyRect: proceduralDestinationRect,
          nearLayer: false,
        );
      }
      if (state == BearAnimationState.walk && walkTicker != null) {
        if (kBearUseHardWalkFrames) {
          _renderSpriteRect(
            canvas,
            sprite: walkTicker.getSprite(),
            destinationRect: _walkDestinationRectForFrame(
              walkTicker.currentIndex,
            ),
            paint: paint,
            cropStaticLegs: shouldRenderProceduralLegs,
          );
        } else {
          _renderWalkTransition(
            canvas,
            proceduralDestinationRect,
            basePaint: paint,
            ticker: walkTicker,
            cropStaticLegs: shouldRenderProceduralLegs,
          );
        }
      } else {
        _drawBearImage(
          canvas,
          stateImage ?? image,
          proceduralDestinationRect,
          paint,
          cropStaticLegs: shouldRenderProceduralLegs,
        );
      }
      if (shouldRenderProceduralLegs) {
        _renderProceduralWalkLegs(
          canvas,
          destinationRect,
          bodyRect: proceduralDestinationRect,
          nearLayer: true,
        );
      }
      canvas.restore();

      if (kBearDebugOverlay || _shouldRenderProceduralDebugInfo) {
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

    if (kBearDebugOverlay || _shouldRenderProceduralDebugInfo) {
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

    _facesLeft = direction < 0;
    _velocity.x = direction * _moveSpeed;
  }

  void stopMoving() {
    _velocity.x = 0;
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

  Image? _imageForState(BearAnimationState state) {
    switch (state) {
      case BearAnimationState.jump:
      case BearAnimationState.fall:
        return _jumpImage;
      case BearAnimationState.interacting:
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
        if (!kBearUseProceduralWalkCarry) {
          return _BearVisualTransform(
            destinationRect: _walkTicker == null
                ? baseRect
                : _walkDestinationRect(),
            scaleX: direction,
            scaleY: 1.0,
            rotation: 0,
          );
        }
        final walkPhase = _walkCyclePhase();
        final strideCarry = math.sin(walkPhase * math.pi * 2);
        final stepPulse = math.sin(walkPhase * math.pi * 4);
        return _BearVisualTransform(
          destinationRect: _walkTicker == null
              ? baseRect
              : _walkDestinationRect(),
          scaleX:
              direction * (1.0 - stepPulse * walkCarryScaleAmplitude * 0.45),
          scaleY: 1.0 + stepPulse * walkCarryScaleAmplitude,
          rotation: direction * strideCarry * walkCarryTiltAmplitude,
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

  Rect _walkDestinationRectForFrame(int frameIndex) {
    final verticalOffset =
        kBearWalkFrameVerticalOffsets[frameIndex
            .clamp(0, kBearWalkFrameVerticalOffsets.length - 1)
            .toInt()];
    return _walkDestinationRect().translate(0, verticalOffset);
  }

  double _walkCyclePhase() {
    final walkTicker = _walkTicker;
    if (walkTicker == null) {
      return 0;
    }

    final cycleDuration = kBearWalkFrameStepTimes.reduce(
      (total, stepTime) => total + stepTime,
    );
    if (cycleDuration <= 0) {
      return 0;
    }

    return (walkTicker.elapsed / cycleDuration) % 1.0;
  }

  double _visualPivotY(BearAnimationState state, Rect destinationRect) {
    if (state == BearAnimationState.walk && _walkTicker != null) {
      return destinationRect.bottom - _walkVisualGroundInset;
    }

    return destinationRect.bottom - visualGroundInset;
  }

  void _performJump() {
    if (_isOnGround) {
      _velocity.y = _jumpImpulse;
      _walkTicker?.reset();
    }
  }

  void _recordWalkFrameIndex() {
    if (!kDebugMode || _walkFrameCycleLogged) {
      return;
    }

    final walkTicker = _walkTicker;
    if (walkTicker == null) {
      return;
    }

    _debugObservedWalkFrameIndices.add(walkTicker.currentIndex);
    if (_debugObservedWalkFrameIndices.length >= kBearWalkFrameOrder.length) {
      debugPrint(
        'Bear walk frame index: observed '
        '${_debugObservedWalkFrameIndices.length}/${kBearWalkFrameOrder.length} '
        'frames, first=${kBearWalkFrameOrder.first}, '
        'last=${kBearWalkFrameOrder.last}',
      );
      _walkFrameCycleLogged = true;
    }
  }

  bool get _shouldRenderProceduralDebugInfo =>
      kDebugMode &&
      useProceduralBearWalkPrototype &&
      showProceduralWalkDebugOverlay;

  bool _shouldUseProceduralWalk(BearAnimationState state) {
    if (!useProceduralBearWalkPrototype || !_isOnGround) {
      return false;
    }
    if (state == BearAnimationState.walk) {
      return true;
    }

    return forceProceduralWalkDebug && state == BearAnimationState.idle;
  }

  bool _shouldRenderProceduralWalkLegs(BearAnimationState state) {
    return useProceduralBearWalkPrototype &&
        _isOnGround &&
        (state == BearAnimationState.walk ||
            (state == BearAnimationState.idle &&
                (forceProceduralWalkDebug || _proceduralWalkPoseBlend > 0.01)));
  }

  void _updateProceduralWalk(
    double dt,
    double deltaX,
    BearAnimationState state,
  ) {
    _lastProceduralDeltaX = deltaX;
    final active = _shouldUseProceduralWalk(state);
    final blendTarget = active ? 1.0 : 0.0;
    final blendStep = (dt * kBearProceduralIdleReturnSpeed).clamp(0.0, 1.0);
    _proceduralWalkPoseBlend =
        _proceduralWalkPoseBlend +
        (blendTarget - _proceduralWalkPoseBlend) * blendStep;
    _proceduralWalkPhase = debugAdvanceBearProceduralWalkPhase(
      phase: _proceduralWalkPhase,
      dt: dt,
      deltaX: deltaX,
      forceTimePhase: forceProceduralWalkDebug,
      active: active,
    );

    final nearFrontPose = _proceduralLegPose(BearProceduralLeg.nearFront);
    final farFrontPose = _proceduralLegPose(BearProceduralLeg.farFront);
    final nearHindPose = _proceduralLegPose(BearProceduralLeg.nearHind);
    final farHindPose = _proceduralLegPose(BearProceduralLeg.farHind);

    _lastProceduralFrontLegSwing = nearFrontPose.swing;
    _lastProceduralHindLegSwing = nearHindPose.swing;
    _lastProceduralFarFrontLegSwing = farFrontPose.swing;
    _lastProceduralFarHindLegSwing = farHindPose.swing;
    _lastProceduralNearFrontLegLift = nearFrontPose.lift;
    _lastProceduralFarFrontLegLift = farFrontPose.lift;
    _lastProceduralNearHindLegLift = nearHindPose.lift;
    _lastProceduralFarHindLegLift = farHindPose.lift;

    final phaseAngle = _proceduralWalkPhase * math.pi * 2;
    _lastProceduralBodyBobY =
        math.sin(phaseAngle * 2) *
        kBearProceduralBodyBobPx *
        _proceduralWalkPoseBlend;
    _lastProceduralBodyTilt =
        math.sin(phaseAngle) *
        kBearProceduralBodyTiltRadians *
        _proceduralWalkPoseBlend;

    if (!_shouldRenderProceduralDebugInfo || _proceduralWalkLogCount >= 4) {
      return;
    }

    _proceduralDebugLogTime += dt;
    if (_proceduralDebugLogTime < 1.0) {
      return;
    }
    _proceduralDebugLogTime = 0;
    _proceduralWalkLogCount += 1;
    debugPrint(
      'Bear procedural walk: '
      'flag=$useProceduralBearWalkPrototype, '
      'force=$forceProceduralWalkDebug, '
      'state=$state, '
      'velocityX=${_velocity.x.toStringAsFixed(1)}, '
      'deltaX=${_lastProceduralDeltaX.toStringAsFixed(2)}, '
      'phase=${_proceduralWalkPhase.toStringAsFixed(2)}, '
      'front=${_lastProceduralFrontLegSwing.toStringAsFixed(2)}, '
      'hind=${_lastProceduralHindLegSwing.toStringAsFixed(2)}, '
      'nfLift=${_lastProceduralNearFrontLegLift.toStringAsFixed(2)}, '
      'fhLift=${_lastProceduralFarHindLegLift.toStringAsFixed(2)}, '
      'renderLegsCalled=$_proceduralRenderLegsCalled',
    );
  }

  _BearProceduralLegPose _proceduralLegPose(BearProceduralLeg leg) {
    return _proceduralLegPoseForPhase(
      leg: leg,
      phase: _proceduralWalkPhase,
      poseBlend: _proceduralWalkPoseBlend,
    );
  }

  double _proceduralBodyBobForRender(BearAnimationState state) {
    if (!useProceduralBearWalkPrototype ||
        !_isOnGround ||
        (state != BearAnimationState.walk &&
            state != BearAnimationState.idle) ||
        _proceduralWalkPoseBlend <= 0.01) {
      return 0;
    }

    return _lastProceduralBodyBobY;
  }

  double _proceduralBodyTiltForRender(BearAnimationState state) {
    if (!useProceduralBearWalkPrototype ||
        !_isOnGround ||
        (state != BearAnimationState.walk &&
            state != BearAnimationState.idle) ||
        _proceduralWalkPoseBlend <= 0.01) {
      return 0;
    }

    return (_facesLeft ? -1 : 1) * _lastProceduralBodyTilt;
  }

  void _renderProceduralWalkLegs(
    Canvas canvas,
    Rect groundRect, {
    required Rect bodyRect,
    required bool nearLayer,
  }) {
    _proceduralRenderLegsCalled = true;
    final frontSwing = nearLayer
        ? _lastProceduralFrontLegSwing
        : _lastProceduralFarFrontLegSwing;
    final hindSwing = nearLayer
        ? _lastProceduralHindLegSwing
        : _lastProceduralFarHindLegSwing;
    final frontLift = nearLayer
        ? _lastProceduralNearFrontLegLift
        : _lastProceduralFarFrontLegLift;
    final hindLift = nearLayer
        ? _lastProceduralNearHindLegLift
        : _lastProceduralFarHindLegLift;
    final color = _proceduralLegColor(nearLayer: nearLayer);
    final outlineColor = _proceduralLegOutlineColor;
    final pawPadColor = _proceduralPawPadColor;
    final strokeWidth = showProceduralWalkDebugColors
        ? (nearLayer ? 12.0 : 9.0)
        : (nearLayer ? 6.0 : 4.5);
    final footWidth = showProceduralWalkDebugColors
        ? (nearLayer ? 19.0 : 15.0)
        : (nearLayer ? 14.0 : 11.0);
    final footHeight = showProceduralWalkDebugColors
        ? (nearLayer ? 8.0 : 6.0)
        : (nearLayer ? 5.5 : 4.5);
    final groundY = groundRect.bottom - visualGroundInset - 2;
    final frontHipX =
        bodyRect.left + bodyRect.width * (nearLayer ? 0.74 : 0.69);
    final hindHipX = bodyRect.left + bodyRect.width * (nearLayer ? 0.29 : 0.35);
    final frontFootX =
        groundRect.left + groundRect.width * (nearLayer ? 0.78 : 0.72);
    final hindFootX =
        groundRect.left + groundRect.width * (nearLayer ? 0.23 : 0.32);

    _drawProceduralLeg(
      canvas,
      hip: Offset(hindHipX, bodyRect.top + (nearLayer ? 62 : 60)),
      neutralFoot: Offset(hindFootX, groundY - hindLift),
      swing: hindSwing,
      swingPx: kBearProceduralHindLegSwingPx,
      strokeWidth: strokeWidth,
      footWidth: footWidth,
      footHeight: footHeight,
      color: color,
      outlineColor: outlineColor,
      pawPadColor: pawPadColor,
    );
    _drawProceduralLeg(
      canvas,
      hip: Offset(frontHipX, bodyRect.top + (nearLayer ? 59 : 60)),
      neutralFoot: Offset(frontFootX, groundY - frontLift),
      swing: frontSwing,
      swingPx: kBearProceduralFrontLegSwingPx,
      strokeWidth: strokeWidth,
      footWidth: footWidth,
      footHeight: footHeight,
      color: color,
      outlineColor: outlineColor,
      pawPadColor: pawPadColor,
    );
  }

  Color _proceduralLegColor({required bool nearLayer}) {
    if (showProceduralWalkDebugColors) {
      return nearLayer
          ? kBearProceduralDebugNearLegColor
          : kBearProceduralDebugFarLegColor;
    }

    return nearLayer
        ? kBearProceduralProductionNearLegColor
        : kBearProceduralProductionFarLegColor;
  }

  Color get _proceduralLegOutlineColor {
    if (showProceduralWalkDebugColors) {
      return kBearProceduralDebugOutlineColor;
    }

    return kBearProceduralProductionOutlineColor;
  }

  Color get _proceduralPawPadColor {
    if (showProceduralWalkDebugColors) {
      return kBearProceduralDebugPawPadColor;
    }

    return kBearProceduralProductionPawPadColor;
  }

  void _drawProceduralLeg(
    Canvas canvas, {
    required Offset hip,
    required Offset neutralFoot,
    required double swing,
    required double swingPx,
    required double strokeWidth,
    required double footWidth,
    required double footHeight,
    required Color color,
    required Color outlineColor,
    required Color pawPadColor,
  }) {
    final foot = neutralFoot.translate(swing * swingPx, 0);
    final knee = Offset(
      (hip.dx + foot.dx) / 2 - swing * 5,
      (hip.dy + foot.dy) / 2 + 6,
    );
    final legPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;
    final path = Path()
      ..moveTo(hip.dx, hip.dy)
      ..quadraticBezierTo(knee.dx, knee.dy, foot.dx, foot.dy);

    canvas.drawPath(path, legPaint);
    final footRect = Rect.fromCenter(
      center: foot.translate(2, 1),
      width: footWidth,
      height: footHeight,
    );
    canvas.drawOval(footRect, Paint()..color = color);
    canvas.drawOval(footRect, outlinePaint);
    if (!showProceduralWalkDebugColors) {
      canvas.drawOval(
        Rect.fromCenter(
          center: foot.translate(3, 2),
          width: footWidth * 0.34,
          height: footHeight * 0.36,
        ),
        Paint()..color = pawPadColor.withValues(alpha: 0.32),
      );
    }
  }

  void _renderWalkTransition(
    Canvas canvas,
    Rect destinationRect, {
    required Paint basePaint,
    required SpriteAnimationTicker ticker,
    required bool cropStaticLegs,
  }) {
    final frames = ticker.spriteAnimation.frames;
    if (frames.length == 1) {
      _renderSpriteRect(
        canvas,
        sprite: ticker.getSprite(),
        destinationRect: destinationRect,
        paint: basePaint,
        cropStaticLegs: cropStaticLegs,
      );
      return;
    }

    final currentIndex = ticker.currentIndex
        .clamp(0, frames.length - 1)
        .toInt();
    final nextIndex = currentIndex == frames.length - 1 ? 0 : currentIndex + 1;
    final currentDestinationRect = _walkDestinationRectForFrame(currentIndex);
    final nextDestinationRect = _walkDestinationRectForFrame(nextIndex);
    final frameProgress = (ticker.clock / ticker.currentFrame.stepTime)
        .clamp(0.0, 1.0)
        .toDouble();

    _renderSoftFrameTransition(
      canvas,
      currentDestinationRect,
      basePaint: basePaint,
      currentSprite: frames[currentIndex].sprite,
      nextSprite: frames[nextIndex].sprite,
      nextDestinationRect: nextDestinationRect,
      blend: _smoothStep(frameProgress),
      maxOverlayAlpha: _walkFrameBlendMaxAlpha,
      cropStaticLegs: cropStaticLegs,
    );
  }

  void _renderSoftFrameTransition(
    Canvas canvas,
    Rect destinationRect, {
    required Paint basePaint,
    required Sprite currentSprite,
    required Sprite nextSprite,
    Rect? nextDestinationRect,
    required double blend,
    required double maxOverlayAlpha,
    required bool cropStaticLegs,
  }) {
    final normalizedBlend = blend.clamp(0.0, 1.0).toDouble();
    final useNextAsBase = normalizedBlend >= 0.5;
    final baseSprite = useNextAsBase ? nextSprite : currentSprite;
    final overlaySprite = useNextAsBase ? currentSprite : nextSprite;
    final overlayDestinationRect = nextDestinationRect ?? destinationRect;
    final baseDestinationRect = useNextAsBase
        ? overlayDestinationRect
        : destinationRect;
    final secondaryDestinationRect = useNextAsBase
        ? destinationRect
        : overlayDestinationRect;
    final overlayProgress = useNextAsBase
        ? (1.0 - normalizedBlend) * 2
        : normalizedBlend * 2;
    final overlayAlpha =
        _smoothStep(overlayProgress.clamp(0.0, 1.0)) * maxOverlayAlpha;

    _renderSpriteRect(
      canvas,
      sprite: baseSprite,
      destinationRect: baseDestinationRect,
      paint: basePaint,
      cropStaticLegs: cropStaticLegs,
    );

    if (overlayAlpha <= 0.01 || identical(baseSprite, overlaySprite)) {
      return;
    }

    final overlayPaint = Paint()
      ..filterQuality = basePaint.filterQuality
      ..color = const Color(0xFFFFFFFF).withValues(alpha: overlayAlpha);
    _renderSpriteRect(
      canvas,
      sprite: overlaySprite,
      destinationRect: secondaryDestinationRect,
      paint: overlayPaint,
      cropStaticLegs: cropStaticLegs,
    );
  }

  void _renderSpriteRect(
    Canvas canvas, {
    required Sprite sprite,
    required Rect destinationRect,
    required Paint paint,
    required bool cropStaticLegs,
  }) {
    if (!cropStaticLegs) {
      sprite.renderRect(canvas, destinationRect, overridePaint: paint);
      return;
    }

    _withStaticLegCrop(canvas, destinationRect, () {
      sprite.renderRect(canvas, destinationRect, overridePaint: paint);
    });
  }

  void _drawBearImage(
    Canvas canvas,
    Image image,
    Rect destinationRect,
    Paint paint, {
    required bool cropStaticLegs,
  }) {
    void draw() {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        destinationRect,
        paint,
      );
    }

    if (!cropStaticLegs) {
      draw();
      return;
    }

    _withStaticLegCrop(canvas, destinationRect, draw);
  }

  void _withStaticLegCrop(
    Canvas canvas,
    Rect destinationRect,
    VoidCallback draw,
  ) {
    final cropBottom = destinationRect.top + destinationRect.height * 0.71;
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        destinationRect.left,
        destinationRect.top,
        destinationRect.right,
        cropBottom,
      ),
    );
    draw();
    canvas.restore();
  }

  double _smoothStep(double progress) {
    final t = progress.clamp(0.0, 1.0).toDouble();
    return t * t * (3 - 2 * t);
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
    if (_shouldRenderProceduralDebugInfo) {
      final builder = ParagraphBuilder(ParagraphStyle(fontSize: 9, maxLines: 8))
        ..pushStyle(TextStyle(color: const Color(0xFF16384A)))
        ..addText(
          'procedural=$useProceduralBearWalkPrototype '
          'force=$forceProceduralWalkDebug\n'
          'state=$_animationState vx=${_velocity.x.toStringAsFixed(1)} '
          'dx=${_lastProceduralDeltaX.toStringAsFixed(2)}\n'
          'phase=${_proceduralWalkPhase.toStringAsFixed(2)} '
          'front=${_lastProceduralFrontLegSwing.toStringAsFixed(2)} '
          'hind=${_lastProceduralHindLegSwing.toStringAsFixed(2)}\n'
          'renderLegsCalled=$_proceduralRenderLegsCalled '
          'stride=$kBearProceduralStrideLengthPx',
        );
      final paragraph = builder.build()
        ..layout(const ParagraphConstraints(width: 230));
      final background = Rect.fromLTWH(2, 2, paragraph.width + 8, 54);
      canvas.drawRRect(
        RRect.fromRectAndRadius(background, const Radius.circular(4)),
        Paint()..color = const Color(0xCCEFF8FC),
      );
      canvas.drawParagraph(paragraph, const Offset(6, 5));
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
