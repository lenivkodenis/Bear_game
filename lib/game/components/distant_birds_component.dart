import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class DistantBirdsComponent extends PositionComponent {
  DistantBirdsComponent({
    required Vector2 size,
    this.config = DistantBirdsConfig.levelOne,
  }) : _random = math.Random(config.randomSeed),
       super(size: size, priority: config.priority);

  final DistantBirdsConfig config;
  final math.Random _random;

  static const Color _birdColor = Color(0xFF415767);
  static const DistantBirdRoute _primaryRoute = DistantBirdRoute(
    startNormalized: Offset(0.27, 0.37),
    control1Normalized: Offset(0.48, 0.34),
    control2Normalized: Offset(0.76, 0.31),
    endNormalized: Offset(0.99, 0.27),
    color: _birdColor,
  );
  static const DistantBirdRoute _upperRoute = DistantBirdRoute(
    startNormalized: Offset(0.21, 0.31),
    control1Normalized: Offset(0.43, 0.29),
    control2Normalized: Offset(0.72, 0.25),
    endNormalized: Offset(0.98, 0.22),
    color: _birdColor,
  );
  static const DistantBirdRoute _reverseRoute = DistantBirdRoute(
    startNormalized: Offset(0.99, 0.40),
    control1Normalized: Offset(0.76, 0.43),
    control2Normalized: Offset(0.43, 0.39),
    endNormalized: Offset(0.12, 0.34),
    color: Color(0xFF2F4352),
    scaleMultiplier: 0.72,
    opacityMultiplier: 1.15,
  );
  static const DistantBirdRoute _oceanShoreEdgeToEdgeRoute = DistantBirdRoute(
    startNormalized: Offset(-0.08, 0.31),
    control1Normalized: Offset(0.20, 0.25),
    control2Normalized: Offset(0.73, 0.27),
    endNormalized: Offset(1.08, 0.22),
    color: Color(0xFF2D4B5F),
    scaleMultiplier: 0.92,
    opacityMultiplier: 1.08,
  );
  static const DistantBirdRoute _oceanShoreReverseEdgeRoute = DistantBirdRoute(
    startNormalized: Offset(1.08, 0.43),
    control1Normalized: Offset(0.79, 0.38),
    control2Normalized: Offset(0.43, 0.35),
    endNormalized: Offset(-0.10, 0.28),
    color: Color(0xFF344F61),
    scaleMultiplier: 0.82,
    opacityMultiplier: 1.0,
  );
  static const DistantBirdRoute _oceanShoreHorizonRoute = DistantBirdRoute(
    startNormalized: Offset(-0.06, 0.52),
    control1Normalized: Offset(0.18, 0.48),
    control2Normalized: Offset(0.48, 0.36),
    endNormalized: Offset(0.86, 0.25),
    color: Color(0xFF3D5B6D),
    scaleMultiplier: 1.08,
    opacityMultiplier: 0.94,
  );
  static const DistantBirdRoute _oceanShoreFarCoastRoute = DistantBirdRoute(
    startNormalized: Offset(1.04, 0.24),
    control1Normalized: Offset(0.82, 0.20),
    control2Normalized: Offset(0.46, 0.19),
    endNormalized: Offset(0.18, 0.22),
    color: Color(0xFF2C4454),
    scaleMultiplier: 0.7,
    opacityMultiplier: 0.8,
  );
  static const List<DistantBirdRoute> _levelOneRoutes = <DistantBirdRoute>[
    _primaryRoute,
    _upperRoute,
    _reverseRoute,
  ];
  static const List<DistantBirdRoute> _levelThreeRoutes = <DistantBirdRoute>[
    _oceanShoreEdgeToEdgeRoute,
    _oceanShoreReverseEdgeRoute,
    _oceanShoreHorizonRoute,
    _oceanShoreFarCoastRoute,
  ];
  static const List<_DistantBirdSpec> _formation = <_DistantBirdSpec>[
    _DistantBirdSpec(
      offsetX: 0,
      offsetY: 0,
      sizeMultiplier: 1,
      flapPhase: 0.1,
      pathOffset: 0,
      opacityMultiplier: 1,
    ),
    _DistantBirdSpec(
      offsetX: -0.95,
      offsetY: 0.45,
      sizeMultiplier: 0.9,
      flapPhase: 0.55,
      pathOffset: -0.8,
      opacityMultiplier: 0.9,
    ),
    _DistantBirdSpec(
      offsetX: -1.6,
      offsetY: -0.25,
      sizeMultiplier: 0.82,
      flapPhase: 0.8,
      pathOffset: -1.25,
      opacityMultiplier: 0.82,
    ),
    _DistantBirdSpec(
      offsetX: 0.9,
      offsetY: 0.32,
      sizeMultiplier: 0.88,
      flapPhase: 0.32,
      pathOffset: 0.7,
      opacityMultiplier: 0.88,
    ),
    _DistantBirdSpec(
      offsetX: 1.48,
      offsetY: -0.18,
      sizeMultiplier: 0.76,
      flapPhase: 0.68,
      pathOffset: 1.1,
      opacityMultiplier: 0.78,
    ),
    _DistantBirdSpec(
      offsetX: -0.45,
      offsetY: 0.92,
      sizeMultiplier: 0.72,
      flapPhase: 0.24,
      pathOffset: -0.35,
      opacityMultiplier: 0.74,
    ),
    _DistantBirdSpec(
      offsetX: 0.42,
      offsetY: -0.72,
      sizeMultiplier: 0.7,
      flapPhase: 0.92,
      pathOffset: 0.35,
      opacityMultiplier: 0.72,
    ),
  ];

  double _flightElapsed = 0;
  double _pauseRemaining = 0;
  int _routeIndex = 0;
  bool _isFlying = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _pauseRemaining = config.initialPauseBeforeFirstFlight;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isFlying) {
      _flightElapsed += dt;
      if (config.flightProgressForElapsed(_flightElapsed) >= 1) {
        _isFlying = false;
        _flightElapsed = 0;
        _routeIndex = (_routeIndex + 1) % config.routes.length;
        _pauseRemaining = _randomPause();
      }
      return;
    }

    _pauseRemaining -= dt;
    if (_pauseRemaining <= 0) {
      _isFlying = true;
      _flightElapsed = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!_isFlying || size.x <= 0 || size.y <= 0) {
      return;
    }

    final progress = config.flightProgressForElapsed(_flightElapsed);
    final route = config.routes[_routeIndex];
    final opacity = (_opacityFor(progress) * route.opacityMultiplier)
        .clamp(0.0, 1.0)
        .toDouble();
    if (opacity <= 0.005) {
      return;
    }

    final baseSize =
        math.min(size.x, size.y) *
        _lerp(config.startScale, config.endScale, _easeInCubic(progress)) *
        route.scaleMultiplier;
    final formationScale = _lerp(1, 0.36, _easeInCubic(progress));
    final pathOffsetScale = _lerp(0.008, 0.002, progress);

    for (final bird in _formation.take(config.birdCount)) {
      final birdProgress = (progress + bird.pathOffset * pathOffsetScale)
          .clamp(0.0, 1.0)
          .toDouble();
      final pathPoint = _pathPoint(birdProgress, route);
      final pathTangent = _pathTangent(birdProgress, route);
      final center = Offset(pathPoint.dx * size.x, pathPoint.dy * size.y);
      final formationOffset = Offset(
        bird.offsetX * config.formationSpreadX * size.x * formationScale,
        bird.offsetY * config.formationSpreadY * size.y * formationScale,
      );

      _drawBird(
        canvas,
        center + formationOffset,
        baseSize * bird.sizeMultiplier,
        (opacity * bird.opacityMultiplier).clamp(0.0, 1.0).toDouble(),
        bird.flapPhase,
        route.color,
        math.atan2(pathTangent.dy, pathTangent.dx),
      );
    }
  }

  Offset _pathPoint(double t, DistantBirdRoute route) {
    final x = _cubic(
      route.startNormalized.dx,
      route.control1Normalized.dx,
      route.control2Normalized.dx,
      route.endNormalized.dx,
      t,
    );
    final y = _cubic(
      route.startNormalized.dy,
      route.control1Normalized.dy,
      route.control2Normalized.dy,
      route.endNormalized.dy,
      t,
    );

    return Offset(x, y);
  }

  Offset _pathTangent(double t, DistantBirdRoute route) {
    final inv = 1 - t;
    final dx =
        3 *
            inv *
            inv *
            (route.control1Normalized.dx - route.startNormalized.dx) +
        6 *
            inv *
            t *
            (route.control2Normalized.dx - route.control1Normalized.dx) +
        3 * t * t * (route.endNormalized.dx - route.control2Normalized.dx);
    final dy =
        3 *
            inv *
            inv *
            (route.control1Normalized.dy - route.startNormalized.dy) +
        6 *
            inv *
            t *
            (route.control2Normalized.dy - route.control1Normalized.dy) +
        3 * t * t * (route.endNormalized.dy - route.control2Normalized.dy);

    return Offset(dx, dy);
  }

  double _opacityFor(double progress) {
    if (progress < 0.18) {
      return _lerp(
        config.startOpacity,
        config.maxOpacity,
        _easeOutCubic(progress / 0.18),
      );
    }

    final fadeProgress = (progress - 0.18) / 0.82;
    return _lerp(
      config.maxOpacity,
      config.endOpacity,
      _easeInCubic(fadeProgress),
    );
  }

  void _drawBird(
    Canvas canvas,
    Offset center,
    double size,
    double opacity,
    double flapPhase,
    Color color,
    double directionAngle,
  ) {
    final flap =
        math.sin(
          (_flightElapsed * config.flapSpeed + flapPhase) * math.pi * 2,
        ) *
        config.flapAmplitude;
    final wingLift = size * (0.22 + flap);
    final halfSpan = size;
    final bodyLength = size * 0.3;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(0.45, size * 0.12);
    final bodyPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.86)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.4, size * 0.08);
    final path = Path()
      ..moveTo(-halfSpan, -wingLift)
      ..cubicTo(
        -halfSpan * 0.64,
        -wingLift * 1.22,
        -halfSpan * 0.28,
        -wingLift * 0.18,
        0,
        0,
      )
      ..cubicTo(
        halfSpan * 0.28,
        -wingLift * 0.18,
        halfSpan * 0.64,
        -wingLift * 1.16,
        halfSpan,
        -wingLift * 0.94,
      );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(directionAngle);
    canvas.drawLine(
      Offset(-bodyLength * 0.45, 0),
      Offset(bodyLength * 0.55, 0),
      bodyPaint,
    );
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  double _cubic(double a, double b, double c, double d, double t) {
    final inv = 1 - t;
    return inv * inv * inv * a +
        3 * inv * inv * t * b +
        3 * inv * t * t * c +
        t * t * t * d;
  }

  double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  double _easeInCubic(double t) {
    return t * t * t;
  }

  double _easeOutCubic(double t) {
    final inv = 1 - t;
    return 1 - inv * inv * inv;
  }

  double _randomPause() {
    if (config.maxPause <= config.minPause) {
      return config.minPause;
    }

    return config.minPause +
        _random.nextDouble() * (config.maxPause - config.minPause);
  }
}

class DistantBirdsConfig {
  const DistantBirdsConfig({
    required this.routes,
    required this.birdCount,
    required this.flightDuration,
    required this.initialPauseBeforeFirstFlight,
    required this.minPause,
    required this.maxPause,
    required this.startScale,
    required this.endScale,
    required this.startOpacity,
    required this.maxOpacity,
    required this.endOpacity,
    required this.flapAmplitude,
    required this.flapSpeed,
    required this.formationSpreadX,
    required this.formationSpreadY,
    required this.randomSeed,
    this.priority = 0,
    this.pathSlowdownPerSegment = 0,
    this.pathSlowdownSegmentCount = 5,
  }) : assert(birdCount > 0),
       assert(flightDuration > 0),
       assert(maxPause >= minPause),
       assert(pathSlowdownPerSegment >= 0),
       assert(pathSlowdownPerSegment < 1),
       assert(pathSlowdownSegmentCount > 0);

  static const double levelOneFlapAmplitude = 0.12;
  static const double levelThreeFlapAmplitude = 0.42;

  static const DistantBirdsConfig levelOne = DistantBirdsConfig(
    routes: DistantBirdsComponent._levelOneRoutes,
    birdCount: 7,
    flightDuration: 21,
    initialPauseBeforeFirstFlight: 1.5,
    minPause: 5,
    maxPause: 5,
    startScale: 0.014,
    endScale: 0.004,
    startOpacity: 0.207,
    maxOpacity: 0.368,
    endOpacity: 0.017,
    flapAmplitude: levelOneFlapAmplitude,
    flapSpeed: 0.68,
    formationSpreadX: 0.028,
    formationSpreadY: 0.018,
    randomSeed: 1001,
  );

  static const DistantBirdsConfig snowyOceanShore = DistantBirdsConfig(
    routes: DistantBirdsComponent._levelThreeRoutes,
    birdCount: 7,
    flightDuration: 18,
    initialPauseBeforeFirstFlight: 0.5,
    minPause: 2.5,
    maxPause: 6,
    startScale: 0.018,
    endScale: 0.0032,
    startOpacity: 0.2,
    maxOpacity: 0.42,
    endOpacity: 0.004,
    flapAmplitude: levelThreeFlapAmplitude,
    flapSpeed: 1.08,
    formationSpreadX: 0.03,
    formationSpreadY: 0.022,
    randomSeed: 3003,
    priority: -850,
    pathSlowdownPerSegment: 0.05,
  );

  static DistantBirdsConfig? forLevel(int levelId) {
    return switch (levelId) {
      1 => levelOne,
      3 => snowyOceanShore,
      _ => null,
    };
  }

  final List<DistantBirdRoute> routes;
  final int birdCount;
  final double flightDuration;
  final double initialPauseBeforeFirstFlight;
  final double minPause;
  final double maxPause;
  final double startScale;
  final double endScale;
  final double startOpacity;
  final double maxOpacity;
  final double endOpacity;
  final double flapAmplitude;
  final double flapSpeed;
  final double formationSpreadX;
  final double formationSpreadY;
  final int randomSeed;
  final int priority;
  final double pathSlowdownPerSegment;
  final int pathSlowdownSegmentCount;

  double flightProgressForElapsed(double elapsed) {
    if (elapsed <= 0) {
      return 0;
    }
    if (pathSlowdownPerSegment == 0) {
      return (elapsed / flightDuration).clamp(0.0, 1.0).toDouble();
    }

    final segmentDistance = 1 / pathSlowdownSegmentCount;
    var remainingElapsed = elapsed;
    var progress = 0.0;

    for (var segment = 0; segment < pathSlowdownSegmentCount; segment += 1) {
      final speedMultiplier = math
          .pow(1 - pathSlowdownPerSegment, segment)
          .toDouble();
      final segmentDuration =
          flightDuration * segmentDistance / speedMultiplier;

      if (remainingElapsed <= segmentDuration) {
        progress += segmentDistance * remainingElapsed / segmentDuration;
        return progress.clamp(0.0, 1.0).toDouble();
      }

      remainingElapsed -= segmentDuration;
      progress += segmentDistance;
    }

    return 1;
  }
}

class _DistantBirdSpec {
  const _DistantBirdSpec({
    required this.offsetX,
    required this.offsetY,
    required this.sizeMultiplier,
    required this.flapPhase,
    required this.pathOffset,
    required this.opacityMultiplier,
  });

  final double offsetX;
  final double offsetY;
  final double sizeMultiplier;
  final double flapPhase;
  final double pathOffset;
  final double opacityMultiplier;
}

class DistantBirdRoute {
  const DistantBirdRoute({
    required this.startNormalized,
    required this.control1Normalized,
    required this.control2Normalized,
    required this.endNormalized,
    required this.color,
    this.scaleMultiplier = 1,
    this.opacityMultiplier = 1,
  });

  final Offset startNormalized;
  final Offset control1Normalized;
  final Offset control2Normalized;
  final Offset endNormalized;
  final Color color;
  final double scaleMultiplier;
  final double opacityMultiplier;
}
