import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

enum _SnowBunnyPhase { waiting, entering, turning, exiting }

class SnowBunnyAmbient extends PositionComponent {
  SnowBunnyAmbient({
    required Vector2 size,
    required double groundY,
    bool Function()? isActive,
  }) : _canAnimate = isActive ?? _alwaysActive,
       _viewportSize = size.clone(),
       _groundYRatio = size.y <= 0 ? _defaultGroundYRatio : groundY / size.y,
       super(
         size: _componentSizeFor(size),
         anchor: Anchor.bottomCenter,
         priority: _priority,
       ) {
    _recalculateLayout();
    _moveForProgress(0);
  }

  static const int _priority = -850;
  static const double _defaultGroundYRatio = 0.83;
  static const double _waitBetweenAppearances = 10.0;
  static const double _initialDelay = 0.75;
  static const double _enterDuration = 0.56;
  static const double _turnDuration = 2.0;
  static const double _exitDuration = 0.56;
  static const double _bottomInsetRatio = 0.18;
  static const String _assetRoot =
      'characters/snow_bunny/animations/hop_turn/alpha';

  static const List<String> _enterFrameNames = <String>[
    'snow_bunny_01_crouch_right.png',
    'snow_bunny_02_push_right.png',
    'snow_bunny_03_jump_right.png',
    'snow_bunny_04_fly_right.png',
    'snow_bunny_05_land_right.png',
  ];
  static const List<String> _turnFrameNames = <String>[
    'snow_bunny_07_turn_pivot.png',
    'snow_bunny_08_crouch_left.png',
  ];
  static const List<String> _exitFrameNames = <String>[
    'snow_bunny_08_crouch_left.png',
    'snow_bunny_09_push_left.png',
    'snow_bunny_10_jump_left.png',
    'snow_bunny_11_fly_left.png',
    'snow_bunny_12_land_left.png',
  ];

  final bool Function() _canAnimate;
  final double _groundYRatio;
  final Paint _paint = Paint()..filterQuality = FilterQuality.high;

  Vector2 _viewportSize;
  List<Sprite> _enterFrames = const <Sprite>[];
  List<Sprite> _turnFrames = const <Sprite>[];
  List<Sprite> _exitFrames = const <Sprite>[];
  _SnowBunnyPhase _phase = _SnowBunnyPhase.waiting;
  double _waitRemaining = _initialDelay;
  double _phaseElapsed = 0;
  double _offscreenX = 0;
  double _visibleX = 0;
  double _groundAnchorY = 0;
  bool _isActive = false;

  bool get _isLoaded =>
      _enterFrames.isNotEmpty &&
      _turnFrames.isNotEmpty &&
      _exitFrames.isNotEmpty;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _enterFrames = await _loadSprites(_enterFrameNames);
    _turnFrames = await _loadSprites(_turnFrameNames);
    _exitFrames = await _loadSprites(_exitFrameNames);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _viewportSize = size.clone();
    this.size = _componentSizeFor(size);
    _recalculateLayout();
    _moveForProgress(_progressForCurrentPhase);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_isLoaded) {
      return;
    }

    if (!_canAnimate()) {
      _resetUntilActive();
      return;
    }
    _isActive = true;

    if (_phase == _SnowBunnyPhase.waiting) {
      _waitRemaining -= dt;
      if (_waitRemaining <= 0) {
        _startPhase(_SnowBunnyPhase.entering);
      }
      return;
    }

    _phaseElapsed += dt;
    if (_phaseElapsed >= _durationForPhase(_phase)) {
      _advancePhase();
      return;
    }

    _moveForProgress(_progressForCurrentPhase);
  }

  @override
  void render(Canvas canvas) {
    if (!_isLoaded || !_isActive || _phase == _SnowBunnyPhase.waiting) {
      return;
    }

    final frames = _framesForPhase(_phase);
    final frameIndex = math.min(
      frames.length - 1,
      (_progressForCurrentPhase * frames.length).floor(),
    );

    frames[frameIndex].render(canvas, size: size, overridePaint: _paint);
  }

  Future<List<Sprite>> _loadSprites(List<String> frameNames) async {
    final sprites = <Sprite>[];
    for (final frameName in frameNames) {
      final image = await Flame.images.load('$_assetRoot/$frameName');
      sprites.add(Sprite(image));
    }

    return sprites;
  }

  void _startPhase(_SnowBunnyPhase phase) {
    _phase = phase;
    _phaseElapsed = 0;
    _moveForProgress(0);
  }

  void _advancePhase() {
    switch (_phase) {
      case _SnowBunnyPhase.waiting:
        _startPhase(_SnowBunnyPhase.entering);
      case _SnowBunnyPhase.entering:
        _startPhase(_SnowBunnyPhase.turning);
      case _SnowBunnyPhase.turning:
        _startPhase(_SnowBunnyPhase.exiting);
      case _SnowBunnyPhase.exiting:
        _phase = _SnowBunnyPhase.waiting;
        _phaseElapsed = 0;
        _waitRemaining = _waitBetweenAppearances;
        _moveForProgress(0);
    }
  }

  void _resetUntilActive() {
    _isActive = false;
    _phase = _SnowBunnyPhase.waiting;
    _phaseElapsed = 0;
    _waitRemaining = _initialDelay;
    _moveForProgress(0);
  }

  void _recalculateLayout() {
    _offscreenX = -size.x * 0.62;
    _visibleX = math.max(size.x * 0.58, _viewportSize.x * 0.13);
    _groundAnchorY =
        _viewportSize.y * _groundYRatio + size.y * _bottomInsetRatio;
  }

  void _moveForProgress(double progress) {
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    final hopHeight = size.y * 0.16;

    switch (_phase) {
      case _SnowBunnyPhase.waiting:
        position.setValues(_offscreenX, _groundAnchorY);
      case _SnowBunnyPhase.entering:
        final eased = _easeOutCubic(clampedProgress);
        position.setValues(
          _lerp(_offscreenX, _visibleX, eased),
          _groundAnchorY - math.sin(clampedProgress * math.pi) * hopHeight,
        );
      case _SnowBunnyPhase.turning:
        position.setValues(
          _visibleX + math.sin(clampedProgress * math.pi * 2) * size.x * 0.015,
          _groundAnchorY,
        );
      case _SnowBunnyPhase.exiting:
        final eased = _easeInCubic(clampedProgress);
        position.setValues(
          _lerp(_visibleX, _offscreenX, eased),
          _groundAnchorY - math.sin(clampedProgress * math.pi) * hopHeight,
        );
    }
  }

  double get _progressForCurrentPhase {
    final duration = _durationForPhase(_phase);
    if (duration <= 0) {
      return 1;
    }

    return (_phaseElapsed / duration).clamp(0.0, 1.0).toDouble();
  }

  List<Sprite> _framesForPhase(_SnowBunnyPhase phase) {
    return switch (phase) {
      _SnowBunnyPhase.waiting => const <Sprite>[],
      _SnowBunnyPhase.entering => _enterFrames,
      _SnowBunnyPhase.turning => _turnFrames,
      _SnowBunnyPhase.exiting => _exitFrames,
    };
  }

  double _durationForPhase(_SnowBunnyPhase phase) {
    return switch (phase) {
      _SnowBunnyPhase.waiting => 0,
      _SnowBunnyPhase.entering => _enterDuration,
      _SnowBunnyPhase.turning => _turnDuration,
      _SnowBunnyPhase.exiting => _exitDuration,
    };
  }

  static Vector2 _componentSizeFor(Vector2 viewportSize) {
    final side = (math.min(viewportSize.x, viewportSize.y) * 0.10)
        .clamp(44.0, 69.0)
        .toDouble();

    return Vector2.all(side);
  }

  static double _lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }

  static double _easeInCubic(double t) {
    return t * t * t;
  }

  static double _easeOutCubic(double t) {
    final inverse = 1 - t;
    return 1 - inverse * inverse * inverse;
  }

  static bool _alwaysActive() => true;
}
