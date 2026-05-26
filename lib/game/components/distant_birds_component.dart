import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class DistantBirdsComponent extends PositionComponent {
  DistantBirdsComponent({required Vector2 size}) : super(size: size);

  static const int birdCount = 7;
  static const double flightDuration = 21;
  static const double initialPauseBeforeFirstFlight = 1.5;
  static const double pauseBetweenFlights = 5;

  static const double startScale = 0.014;
  static const double endScale = 0.004;
  static const double startOpacity = 0.207;
  static const double maxOpacity = 0.368;
  static const double endOpacity = 0.017;

  static const double flapAmplitude = 0.12;
  static const double flapSpeed = 0.68;
  static const double formationSpreadX = 0.028;
  static const double formationSpreadY = 0.018;

  static const _DistantBirdRoute _primaryRoute = _DistantBirdRoute(
    startNormalized: Offset(0.27, 0.37),
    control1Normalized: Offset(0.48, 0.34),
    control2Normalized: Offset(0.76, 0.31),
    endNormalized: Offset(0.99, 0.27),
    color: _birdColor,
  );
  static const _DistantBirdRoute _upperRoute = _DistantBirdRoute(
    startNormalized: Offset(0.21, 0.31),
    control1Normalized: Offset(0.43, 0.29),
    control2Normalized: Offset(0.72, 0.25),
    endNormalized: Offset(0.98, 0.22),
    color: _birdColor,
  );
  static const _DistantBirdRoute _reverseRoute = _DistantBirdRoute(
    startNormalized: Offset(0.99, 0.40),
    control1Normalized: Offset(0.76, 0.43),
    control2Normalized: Offset(0.43, 0.39),
    endNormalized: Offset(0.12, 0.34),
    color: Color(0xFF2F4352),
    scaleMultiplier: 0.72,
    opacityMultiplier: 1.15,
  );
  static const List<_DistantBirdRoute> _routes = <_DistantBirdRoute>[
    _primaryRoute,
    _upperRoute,
    _reverseRoute,
  ];

  static const Color _birdColor = Color(0xFF415767);
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
    _pauseRemaining = initialPauseBeforeFirstFlight;
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
      if (_flightElapsed >= flightDuration) {
        _isFlying = false;
        _flightElapsed = 0;
        _routeIndex = (_routeIndex + 1) % _routes.length;
        _pauseRemaining = pauseBetweenFlights;
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

    final progress = (_flightElapsed / flightDuration)
        .clamp(0.0, 1.0)
        .toDouble();
    final route = _routes[_routeIndex];
    final opacity = (_opacityFor(progress) * route.opacityMultiplier)
        .clamp(0.0, 1.0)
        .toDouble();
    if (opacity <= 0.005) {
      return;
    }

    final baseSize =
        math.min(size.x, size.y) *
        _lerp(startScale, endScale, _easeInCubic(progress)) *
        route.scaleMultiplier;
    final formationScale = _lerp(1, 0.36, _easeInCubic(progress));
    final pathOffsetScale = _lerp(0.008, 0.002, progress);

    for (final bird in _formation) {
      final birdProgress = (progress + bird.pathOffset * pathOffsetScale)
          .clamp(0.0, 1.0)
          .toDouble();
      final pathPoint = _pathPoint(birdProgress, route);
      final center = Offset(pathPoint.dx * size.x, pathPoint.dy * size.y);
      final formationOffset = Offset(
        bird.offsetX * formationSpreadX * size.x * formationScale,
        bird.offsetY * formationSpreadY * size.y * formationScale,
      );

      _drawBird(
        canvas,
        center + formationOffset,
        baseSize * bird.sizeMultiplier,
        (opacity * bird.opacityMultiplier).clamp(0.0, 1.0).toDouble(),
        bird.flapPhase,
        route.color,
      );
    }
  }

  Offset _pathPoint(double t, _DistantBirdRoute route) {
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

  double _opacityFor(double progress) {
    if (progress < 0.18) {
      return _lerp(startOpacity, maxOpacity, _easeOutCubic(progress / 0.18));
    }

    final fadeProgress = (progress - 0.18) / 0.82;
    return _lerp(maxOpacity, endOpacity, _easeInCubic(fadeProgress));
  }

  void _drawBird(
    Canvas canvas,
    Offset center,
    double size,
    double opacity,
    double flapPhase,
    Color color,
  ) {
    final flap =
        math.sin((_flightElapsed * flapSpeed + flapPhase) * math.pi * 2) *
        flapAmplitude;
    final wingLift = size * (0.26 + flap);
    final halfSpan = size;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.45, size * 0.13);
    final path = Path()
      ..moveTo(-halfSpan, -wingLift)
      ..lineTo(0, 0)
      ..lineTo(halfSpan, -wingLift * 0.92);

    canvas.save();
    canvas.translate(center.dx, center.dy);
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

class _DistantBirdRoute {
  const _DistantBirdRoute({
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
