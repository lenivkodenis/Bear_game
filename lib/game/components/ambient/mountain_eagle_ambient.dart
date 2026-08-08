import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

enum MountainEagleAmbientState {
  waiting,
  flyIn,
  landing,
  perchedPause,
  takeoff,
  flyOut,
}

class MountainEagleAmbient extends PositionComponent {
  MountainEagleAmbient({
    required Vector2 entryPoint,
    required Vector2 perchPoint,
    required Vector2 exitPoint,
    required Vector2 size,
    bool spawnFromLeft = true,
    double cycleInterval = defaultCycleInterval,
    double perchDuration = defaultPerchDuration,
    double initialDelay = 0,
    double flyInDuration = defaultFlyInDuration,
    double landingDuration = defaultLandingDuration,
    double takeoffDuration = defaultTakeoffDuration,
    double flyOutDuration = defaultFlyOutDuration,
    int priority = defaultPriority,
    bool Function()? isActive,
  }) : _entryPoint = entryPoint.clone(),
       _perchPoint = perchPoint.clone(),
       _exitPoint = exitPoint.clone(),
       _spawnFromLeft = spawnFromLeft,
       _canAnimate = isActive ?? _alwaysActive,
       _cycleInterval = math.max(0, cycleInterval),
       _perchDuration = math.max(0, perchDuration),
       _initialDelay = math.max(0, initialDelay),
       _waitRemaining = math.max(0, initialDelay),
       _flyInDuration = math.max(0.01, flyInDuration),
       _landingDuration = math.max(0.01, landingDuration),
       _takeoffDuration = math.max(0.01, takeoffDuration),
       _flyOutDuration = math.max(0.01, flyOutDuration),
       super(
         position: entryPoint.clone(),
         size: size,
         anchor: Anchor.bottomCenter,
         priority: priority,
       );

  static const int defaultPriority = -840;
  static const double defaultCycleInterval = 10.0;
  static const double defaultPerchDuration = 1.5;
  static const double defaultFlyInDuration = 1.25;
  static const double defaultLandingDuration = 0.72;
  static const double defaultTakeoffDuration = 0.78;
  static const double defaultFlyOutDuration = 1.18;
  static const String _assetRoot =
      'characters/mountain_eagle/animations/fly_land_takeoff';

  static const List<String> _flyInFrameNames = <String>[
    'mountain_eagle_01_glide.png',
    'mountain_eagle_02_approach.png',
    'mountain_eagle_03_descent.png',
    'mountain_eagle_01_glide.png',
    'mountain_eagle_02_approach.png',
    'mountain_eagle_03_descent.png',
    'mountain_eagle_01_glide.png',
    'mountain_eagle_02_approach.png',
    'mountain_eagle_03_descent.png',
  ];
  static const List<String> _landingFrameNames = <String>[
    'mountain_eagle_04_brake.png',
    'mountain_eagle_05_touchdown.png',
  ];
  static const List<String> _perchFrameNames = <String>[
    'mountain_eagle_06_settle.png',
    'mountain_eagle_07_stand.png',
  ];
  static const List<String> _takeoffFrameNames = <String>[
    'mountain_eagle_08_takeoff_prepare.png',
    'mountain_eagle_09_takeoff_push.png',
    'mountain_eagle_10_takeoff_upstroke.png',
    'mountain_eagle_11_depart.png',
    'mountain_eagle_09_takeoff_push.png',
    'mountain_eagle_10_takeoff_upstroke.png',
    'mountain_eagle_11_depart.png',
    'mountain_eagle_09_takeoff_push.png',
    'mountain_eagle_10_takeoff_upstroke.png',
    'mountain_eagle_11_depart.png',
  ];
  static const List<String> _flyOutFrameNames = <String>[
    'mountain_eagle_10_takeoff_upstroke.png',
    'mountain_eagle_11_depart.png',
    'mountain_eagle_10_takeoff_upstroke.png',
    'mountain_eagle_11_depart.png',
    'mountain_eagle_10_takeoff_upstroke.png',
    'mountain_eagle_11_depart.png',
  ];

  final Vector2 _entryPoint;
  final Vector2 _perchPoint;
  final Vector2 _exitPoint;
  final bool _spawnFromLeft;
  final bool Function() _canAnimate;
  final double _cycleInterval;
  final double _perchDuration;
  final double _initialDelay;
  final double _flyInDuration;
  final double _landingDuration;
  final double _takeoffDuration;
  final double _flyOutDuration;
  final Paint _paint = Paint()..filterQuality = FilterQuality.high;

  List<Sprite> _flyInFrames = const <Sprite>[];
  List<Sprite> _landingFrames = const <Sprite>[];
  List<Sprite> _perchFrames = const <Sprite>[];
  List<Sprite> _takeoffFrames = const <Sprite>[];
  List<Sprite> _flyOutFrames = const <Sprite>[];
  MountainEagleAmbientState _state = MountainEagleAmbientState.waiting;
  double _phaseElapsed = 0;
  double _waitRemaining;
  bool _isVisible = false;

  MountainEagleAmbientState get state => _state;

  bool get isAnimating =>
      _state != MountainEagleAmbientState.waiting && _isVisible;

  bool get _isLoaded =>
      _flyInFrames.isNotEmpty &&
      _landingFrames.isNotEmpty &&
      _perchFrames.isNotEmpty &&
      _takeoffFrames.isNotEmpty &&
      _flyOutFrames.isNotEmpty;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _flyInFrames = await _loadSprites(_flyInFrameNames);
    _landingFrames = await _loadSprites(_landingFrameNames);
    _perchFrames = await _loadSprites(_perchFrameNames);
    _takeoffFrames = await _loadSprites(_takeoffFrameNames);
    _flyOutFrames = await _loadSprites(_flyOutFrameNames);
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

    if (_state == MountainEagleAmbientState.waiting) {
      _isVisible = false;
      position.setFrom(_entryPoint);
      _waitRemaining -= dt;
      if (_waitRemaining <= 0) {
        _startState(MountainEagleAmbientState.flyIn);
      }
      return;
    }

    _isVisible = true;
    _phaseElapsed += dt;
    final phaseDuration = _durationForState(_state);
    if (_phaseElapsed >= phaseDuration) {
      _moveForCurrentState(1);
      _advanceState();
      return;
    }

    _moveForCurrentState(_progressForCurrentState);
  }

  @override
  void render(Canvas canvas) {
    if (!_isLoaded || !_isVisible) {
      return;
    }

    final frames = _framesForState(_state);
    if (frames.isEmpty) {
      return;
    }

    final sprite = frames[_frameIndex(frames)];
    if (_facesRight) {
      sprite.render(canvas, size: size, overridePaint: _paint);
      return;
    }

    canvas.save();
    canvas.translate(size.x, 0);
    canvas.scale(-1, 1);
    sprite.render(canvas, size: size, overridePaint: _paint);
    canvas.restore();
  }

  Future<List<Sprite>> _loadSprites(List<String> frameNames) async {
    final sprites = <Sprite>[];
    for (final frameName in frameNames) {
      final image = await Flame.images.load('$_assetRoot/$frameName');
      sprites.add(Sprite(image));
    }

    return sprites;
  }

  void _startState(MountainEagleAmbientState state) {
    _state = state;
    _phaseElapsed = 0;
    _isVisible = state != MountainEagleAmbientState.waiting;
    _moveForCurrentState(0);
  }

  void _advanceState() {
    switch (_state) {
      case MountainEagleAmbientState.waiting:
        _startState(MountainEagleAmbientState.flyIn);
      case MountainEagleAmbientState.flyIn:
        _startState(MountainEagleAmbientState.landing);
      case MountainEagleAmbientState.landing:
        _startState(MountainEagleAmbientState.perchedPause);
      case MountainEagleAmbientState.perchedPause:
        _startState(MountainEagleAmbientState.takeoff);
      case MountainEagleAmbientState.takeoff:
        _startState(MountainEagleAmbientState.flyOut);
      case MountainEagleAmbientState.flyOut:
        _state = MountainEagleAmbientState.waiting;
        _phaseElapsed = 0;
        _waitRemaining = _cycleInterval;
        _isVisible = false;
        position.setFrom(_entryPoint);
    }
  }

  void _resetUntilActive() {
    _state = MountainEagleAmbientState.waiting;
    _phaseElapsed = 0;
    _waitRemaining = _initialDelay;
    _isVisible = false;
    position.setFrom(_entryPoint);
  }

  void _moveForCurrentState(double progress) {
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();

    switch (_state) {
      case MountainEagleAmbientState.waiting:
        position.setFrom(_entryPoint);
      case MountainEagleAmbientState.flyIn:
        final eased = _easeOutCubic(clampedProgress);
        final landingStart = _landingStartPoint;
        position.setFrom(
          _arcPoint(
            start: _entryPoint,
            end: landingStart,
            progress: eased,
            height: size.y * 0.32,
          ),
        );
      case MountainEagleAmbientState.landing:
        final eased = _easeOutCubic(clampedProgress);
        position.setFrom(
          _arcPoint(
            start: _landingStartPoint,
            end: _perchPoint,
            progress: eased,
            height: size.y * 0.10,
          ),
        );
      case MountainEagleAmbientState.perchedPause:
        position.setValues(
          _perchPoint.x,
          _perchPoint.y +
              math.sin(clampedProgress * math.pi * 2) * size.y * 0.012,
        );
      case MountainEagleAmbientState.takeoff:
        final eased = _easeInOutCubic(clampedProgress);
        final liftPoint = _takeoffLiftPoint;
        position.setFrom(_lerpVector(_perchPoint, liftPoint, eased));
      case MountainEagleAmbientState.flyOut:
        final eased = _easeInCubic(clampedProgress);
        position.setFrom(
          _arcPoint(
            start: _takeoffLiftPoint,
            end: _exitPoint,
            progress: eased,
            height: size.y * 0.24,
          ),
        );
    }
  }

  double get _progressForCurrentState {
    final duration = _durationForState(_state);
    if (duration <= 0) {
      return 1;
    }

    return (_phaseElapsed / duration).clamp(0.0, 1.0).toDouble();
  }

  Vector2 get _landingStartPoint {
    final verticalApproach = math.max(size.y * 0.28, 28.0);
    return Vector2(
      _lerp(_entryPoint.x, _perchPoint.x, 0.82),
      _perchPoint.y - verticalApproach,
    );
  }

  Vector2 get _takeoffLiftPoint {
    final verticalLift = math.max(size.y * 0.34, 34.0);
    return Vector2(
      _lerp(_perchPoint.x, _exitPoint.x, 0.16),
      _perchPoint.y - verticalLift,
    );
  }

  bool get _facesRight {
    return switch (_state) {
      MountainEagleAmbientState.waiting => _spawnFromLeft,
      MountainEagleAmbientState.flyIn ||
      MountainEagleAmbientState.landing ||
      MountainEagleAmbientState.perchedPause => _entryPoint.x <= _perchPoint.x,
      MountainEagleAmbientState.takeoff ||
      MountainEagleAmbientState.flyOut => _exitPoint.x >= _perchPoint.x,
    };
  }

  int _frameIndex(List<Sprite> frames) {
    final progress = _progressForCurrentState;
    if (_state == MountainEagleAmbientState.perchedPause) {
      final frame = (_phaseElapsed * 2).floor() % frames.length;
      return frame.clamp(0, frames.length - 1);
    }

    return math.min(frames.length - 1, (progress * frames.length).floor());
  }

  List<Sprite> _framesForState(MountainEagleAmbientState state) {
    return switch (state) {
      MountainEagleAmbientState.waiting => const <Sprite>[],
      MountainEagleAmbientState.flyIn => _flyInFrames,
      MountainEagleAmbientState.landing => _landingFrames,
      MountainEagleAmbientState.perchedPause => _perchFrames,
      MountainEagleAmbientState.takeoff => _takeoffFrames,
      MountainEagleAmbientState.flyOut => _flyOutFrames,
    };
  }

  double _durationForState(MountainEagleAmbientState state) {
    return switch (state) {
      MountainEagleAmbientState.waiting => 0,
      MountainEagleAmbientState.flyIn => _flyInDuration,
      MountainEagleAmbientState.landing => _landingDuration,
      MountainEagleAmbientState.perchedPause => _perchDuration,
      MountainEagleAmbientState.takeoff => _takeoffDuration,
      MountainEagleAmbientState.flyOut => _flyOutDuration,
    };
  }

  static Vector2 _arcPoint({
    required Vector2 start,
    required Vector2 end,
    required double progress,
    required double height,
  }) {
    final point = _lerpVector(start, end, progress);
    point.y -= math.sin(progress * math.pi) * height;
    return point;
  }

  static Vector2 _lerpVector(Vector2 start, Vector2 end, double progress) {
    return Vector2(
      _lerp(start.x, end.x, progress),
      _lerp(start.y, end.y, progress),
    );
  }

  static double _lerp(double start, double end, double progress) {
    return start + (end - start) * progress;
  }

  static double _easeInCubic(double t) {
    return t * t * t;
  }

  static double _easeOutCubic(double t) {
    final inverse = 1 - t;
    return 1 - inverse * inverse * inverse;
  }

  static double _easeInOutCubic(double t) {
    if (t < 0.5) {
      return 4 * t * t * t;
    }

    final inverse = -2 * t + 2;
    return 1 - inverse * inverse * inverse / 2;
  }

  static bool _alwaysActive() => true;
}
