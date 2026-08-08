import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'mountain_eagle_ambient.dart';
import 'snow_bunny_ambient.dart';

class AmbientEffectsFactory {
  const AmbientEffectsFactory._();

  static PositionComponent? forLevel({
    required int levelId,
    required Vector2 size,
    double? groundY,
    bool Function()? isActive,
  }) {
    return switch (levelId) {
      4 => SnowBunnyAmbient(
        size: size,
        groundY: groundY ?? size.y * 0.83,
        isActive: isActive,
      ),
      5 => CaveDripsAmbientEffect(size: size),
      7 => MountainPassAmbientEffect(size: size),
      8 => PolarNightStarsEffect(size: size),
      _ => null,
    };
  }

  static PositionComponent? foregroundForLevel({
    required int levelId,
    required Vector2 size,
  }) {
    return switch (levelId) {
      7 => NorthernOceanBlizzardEffect(size: size),
      _ => null,
    };
  }
}

class MountainPassAmbientEffect extends LevelAmbientEffectComponent {
  MountainPassAmbientEffect({required super.size})
    : debugEagleEntryPoint = _eagleEntryPointFor(size),
      debugEaglePerchPoint = _eaglePerchPointFor(size),
      debugEagleExitPoint = _eagleExitPointFor(size),
      debugEagleSize = _eagleSizeFor(size),
      debugEagleCycleInterval = _eagleCycleInterval,
      super(
        children: <Component>[
          MountainPassSnowPlumeEffect(size: size),
          MountainEagleAmbient(
            entryPoint: _eagleEntryPointFor(size),
            perchPoint: _eaglePerchPointFor(size),
            exitPoint: _eagleExitPointFor(size),
            size: _eagleSizeFor(size),
            cycleInterval: _eagleCycleInterval,
            perchDuration: 1.8,
            initialDelay: 0.9,
            flyInDuration: 1.8,
            landingDuration: 0.72,
            takeoffDuration: 1.1,
            flyOutDuration: 1.45,
          ),
        ],
      );

  static const Size _backgroundSourceSize = Size(1672, 941);
  static const Offset _eaglePerchSourceRatio = Offset(0.078, 0.445);
  static const double _eagleCycleInterval = 10.0;

  final Vector2 debugEagleEntryPoint;
  final Vector2 debugEaglePerchPoint;
  final Vector2 debugEagleExitPoint;
  final Vector2 debugEagleSize;
  final double debugEagleCycleInterval;

  static Vector2 _eagleEntryPointFor(Vector2 viewportSize) {
    final eagleSize = _eagleSizeFor(viewportSize);
    final perchPoint = _eaglePerchPointFor(viewportSize);

    return Vector2(
      -eagleSize.x * 1.4,
      perchPoint.y - math.min(viewportSize.x, viewportSize.y) * 0.12,
    );
  }

  static Vector2 _eaglePerchPointFor(Vector2 viewportSize) {
    return _coverPointFromSourceRatio(viewportSize, _eaglePerchSourceRatio);
  }

  static Vector2 _eagleExitPointFor(Vector2 viewportSize) {
    final eagleSize = _eagleSizeFor(viewportSize);
    final perchPoint = _eaglePerchPointFor(viewportSize);

    return Vector2(
      -eagleSize.x * 1.6,
      perchPoint.y - math.min(viewportSize.x, viewportSize.y) * 0.20,
    );
  }

  static Vector2 _coverPointFromSourceRatio(
    Vector2 viewportSize,
    Offset sourceRatio,
  ) {
    final scale = math.max(
      viewportSize.x / _backgroundSourceSize.width,
      viewportSize.y / _backgroundSourceSize.height,
    );
    final drawnWidth = _backgroundSourceSize.width * scale;
    final drawnHeight = _backgroundSourceSize.height * scale;
    final offsetX = (viewportSize.x - drawnWidth) / 2;
    final offsetY = (viewportSize.y - drawnHeight) / 2;

    return Vector2(
      offsetX + _backgroundSourceSize.width * sourceRatio.dx * scale,
      offsetY + _backgroundSourceSize.height * sourceRatio.dy * scale,
    );
  }

  static Vector2 _eagleSizeFor(Vector2 viewportSize) {
    final side = (math.min(viewportSize.x, viewportSize.y) * 0.10)
        .clamp(52.0, 68.0)
        .toDouble();

    return Vector2.all(side);
  }
}

abstract class LevelAmbientEffectComponent extends PositionComponent {
  LevelAmbientEffectComponent({required Vector2 size, super.children})
    : super(size: size, priority: ambientPriority);

  static const int ambientPriority = -900;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  Offset pointFromNormalized(Offset normalized) {
    return Offset(normalized.dx * size.x, normalized.dy * size.y);
  }

  double get viewportUnit => math.min(size.x, size.y);
}

abstract class _CycledAmbientEffectComponent
    extends LevelAmbientEffectComponent {
  _CycledAmbientEffectComponent({
    required super.size,
    required int randomSeed,
    double? initialPause,
  }) : _random = math.Random(randomSeed),
       _pauseRemaining = initialPause ?? 0;

  final math.Random _random;
  double _pauseRemaining;
  double _elapsed = 0;
  bool _isAnimating = false;

  double get cycleDuration;
  double get minimumPause;
  double get maximumPause;

  bool get isAnimating => _isAnimating;

  double get progress {
    if (cycleDuration <= 0) {
      return 1;
    }

    return (_elapsed / cycleDuration).clamp(0.0, 1.0).toDouble();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isAnimating) {
      _elapsed += dt;
      if (_elapsed >= cycleDuration) {
        _isAnimating = false;
        _elapsed = 0;
        onCycleEnd();
        _pauseRemaining = _randomPause();
      }
      return;
    }

    _pauseRemaining -= dt;
    if (_pauseRemaining <= 0) {
      _isAnimating = true;
      _elapsed = 0;
      onCycleStart();
    }
  }

  @protected
  void onCycleStart() {}

  @protected
  void onCycleEnd() {}

  double _randomPause() {
    if (maximumPause <= minimumPause) {
      return minimumPause;
    }

    return minimumPause + _random.nextDouble() * (maximumPause - minimumPause);
  }
}

class IceRiverAmbientEffect extends _CycledAmbientEffectComponent {
  IceRiverAmbientEffect({required super.size})
    : super(randomSeed: 2002, initialPause: 3.0);

  static const double duration = 32.0;
  static const double minPause = 5.0;
  static const double maxPause = 11.0;
  static const double opacity = 0.30;
  static const double effectScale = 0.016;
  static const double speed = 1.0;
  static const double fadeInDuration = 4.0;
  static const double fadeOutDuration = 5.0;
  static const int particleCount = 5;
  static const Offset startPositionNormalized = Offset(-0.10, 0.60);
  static const Offset endPositionNormalized = Offset(1.10, 0.56);

  static const List<_DriftingFloeSpec> _floes = <_DriftingFloeSpec>[
    _DriftingFloeSpec(
      offset: 0.00,
      yNormalized: 0.57,
      size: 0.78,
      wobble: 0.00,
      drift: 0.00,
    ),
    _DriftingFloeSpec(
      offset: 0.17,
      yNormalized: 0.62,
      size: 0.56,
      wobble: 1.70,
      drift: 0.03,
    ),
    _DriftingFloeSpec(
      offset: 0.36,
      yNormalized: 0.53,
      size: 0.48,
      wobble: 3.10,
      drift: -0.02,
    ),
    _DriftingFloeSpec(
      offset: 0.58,
      yNormalized: 0.66,
      size: 0.86,
      wobble: 4.45,
      drift: 0.04,
    ),
    _DriftingFloeSpec(
      offset: 0.79,
      yNormalized: 0.59,
      size: 0.62,
      wobble: 5.70,
      drift: -0.03,
    ),
  ];

  @override
  double get cycleDuration => IceRiverAmbientEffect.duration / speed;

  @override
  double get minimumPause => IceRiverAmbientEffect.minPause;

  @override
  double get maximumPause => IceRiverAmbientEffect.maxPause;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!isAnimating || size.x <= 0 || size.y <= 0) {
      return;
    }

    final fade = _fadeFor(
      progress,
      duration: duration,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
    );
    if (fade <= 0) {
      return;
    }

    final icePaint = Paint()
      ..color = const Color(0xFFE5F2F6).withValues(alpha: opacity * fade)
      ..style = PaintingStyle.fill;
    final snowPaint = Paint()
      ..color = const Color(0xFFF8FCFF).withValues(alpha: 0.12 * fade)
      ..style = PaintingStyle.fill;
    final shadePaint = Paint()
      ..color = const Color(0xFF9DBEC9).withValues(alpha: 0.08 * fade)
      ..style = PaintingStyle.fill;
    final reflectionPaint = Paint()
      ..color = const Color(0xFFD8EEF4).withValues(alpha: 0.08 * fade)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.35, viewportUnit * 0.0006);

    for (final floe in _floes) {
      final localProgress = (progress + floe.offset) % 1.0;
      final pathProgress = _easeInOutSine(localProgress);
      final x = _lerp(
        startPositionNormalized.dx,
        endPositionNormalized.dx,
        pathProgress,
      );
      final y = _lerp(
        floe.yNormalized,
        floe.yNormalized + floe.drift,
        pathProgress,
      );
      final wobble =
          math.sin((progress * 1.2 + floe.wobble) * math.pi) *
          viewportUnit *
          0.0025;
      final floeSize = viewportUnit * effectScale * floe.size;
      final center = pointFromNormalized(Offset(x, y)) + Offset(0, wobble);

      _drawDistantRiverFloe(
        canvas,
        center,
        floeSize,
        icePaint,
        snowPaint,
        shadePaint,
        reflectionPaint,
      );
    }
  }

  void _drawDistantRiverFloe(
    Canvas canvas,
    Offset center,
    double floeSize,
    Paint icePaint,
    Paint snowPaint,
    Paint shadePaint,
    Paint reflectionPaint,
  ) {
    final width = floeSize * 2.2;
    final height = floeSize * 0.64;
    final bodyPath = Path()
      ..moveTo(center.dx - width * 0.50, center.dy - height * 0.02)
      ..lineTo(center.dx - width * 0.34, center.dy - height * 0.30)
      ..lineTo(center.dx - width * 0.05, center.dy - height * 0.25)
      ..lineTo(center.dx + width * 0.20, center.dy - height * 0.42)
      ..lineTo(center.dx + width * 0.48, center.dy - height * 0.08)
      ..lineTo(center.dx + width * 0.33, center.dy + height * 0.25)
      ..lineTo(center.dx - width * 0.15, center.dy + height * 0.32)
      ..lineTo(center.dx - width * 0.42, center.dy + height * 0.16)
      ..close();
    final snowCapPath = Path()
      ..moveTo(center.dx - width * 0.36, center.dy - height * 0.10)
      ..lineTo(center.dx - width * 0.06, center.dy - height * 0.20)
      ..lineTo(center.dx + width * 0.22, center.dy - height * 0.18)
      ..lineTo(center.dx + width * 0.08, center.dy - height * 0.02)
      ..lineTo(center.dx - width * 0.24, center.dy + height * 0.02)
      ..close();
    final undersidePath = Path()
      ..moveTo(center.dx - width * 0.39, center.dy + height * 0.10)
      ..lineTo(center.dx - width * 0.12, center.dy + height * 0.24)
      ..lineTo(center.dx + width * 0.30, center.dy + height * 0.18)
      ..lineTo(center.dx + width * 0.19, center.dy + height * 0.32)
      ..lineTo(center.dx - width * 0.17, center.dy + height * 0.36)
      ..close();

    canvas.drawPath(bodyPath, icePaint);
    canvas.drawPath(snowCapPath, snowPaint);
    canvas.drawPath(undersidePath, shadePaint);
    canvas.drawLine(
      Offset(center.dx - width * 0.30, center.dy + height * 0.58),
      Offset(center.dx + width * 0.26, center.dy + height * 0.54),
      reflectionPaint,
    );
  }
}

class SnowyShoreSealAmbientEffect extends _CycledAmbientEffectComponent {
  SnowyShoreSealAmbientEffect({required super.size})
    : super(randomSeed: 3003, initialPause: 9.0);

  static const double duration = 4.8;
  static const double minPause = 18.0;
  static const double maxPause = 38.0;
  static const double opacity = 0.38;
  static const double effectScale = 0.024;
  static const double speed = 1.0;
  static const double fadeInDuration = 0.8;
  static const double fadeOutDuration = 1.0;
  static const int particleCount = 3;
  static const Offset startPositionNormalized = Offset(0.66, 0.47);
  static const Offset endPositionNormalized = Offset(0.66, 0.45);

  @override
  double get cycleDuration => SnowyShoreSealAmbientEffect.duration;

  @override
  double get minimumPause => SnowyShoreSealAmbientEffect.minPause;

  @override
  double get maximumPause => SnowyShoreSealAmbientEffect.maxPause;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!isAnimating || size.x <= 0 || size.y <= 0) {
      return;
    }

    final p = progress;
    final fade = _fadeFor(
      p,
      duration: duration,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
    );
    if (fade <= 0) {
      return;
    }

    final rise = p < 0.24
        ? _easeOutCubic(p / 0.24)
        : p > 0.66
        ? 1 - _easeInCubic((p - 0.66) / 0.34)
        : 1.0;
    final center = _lerpOffset(
      pointFromNormalized(startPositionNormalized),
      pointFromNormalized(endPositionNormalized),
      rise,
    );
    final headSize = viewportUnit * effectScale;
    final visible = opacity * fade * rise;
    final rippleProgress = p < 0.20 ? p / 0.20 : (p - 0.20) / 0.80;

    _drawRipples(
      canvas,
      Offset(center.dx, pointFromNormalized(startPositionNormalized).dy),
      viewportUnit * 0.032,
      rippleProgress.clamp(0.0, 1.0).toDouble(),
      visible * 0.55,
    );

    if (rise <= 0.02) {
      return;
    }

    final headPaint = Paint()
      ..color = const Color(0xFF435766).withValues(alpha: visible)
      ..style = PaintingStyle.fill;
    final highlightPaint = Paint()
      ..color = const Color(0xFF9FB2BD).withValues(alpha: visible * 0.34)
      ..style = PaintingStyle.fill;
    final eyePaint = Paint()
      ..color = const Color(0xFF13232D).withValues(alpha: visible * 0.78)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: headSize * 1.12,
        height: headSize * 0.82,
      ),
      headPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(-headSize * 0.12, -headSize * 0.10),
        width: headSize * 0.46,
        height: headSize * 0.24,
      ),
      highlightPaint,
    );
    canvas.drawCircle(
      center + Offset(-headSize * 0.20, -headSize * 0.08),
      math.max(0.7, headSize * 0.060),
      eyePaint,
    );
    canvas.drawCircle(
      center + Offset(headSize * 0.20, -headSize * 0.08),
      math.max(0.7, headSize * 0.060),
      eyePaint,
    );
  }
}

class ForestBunnyAmbientEffect extends _CycledAmbientEffectComponent {
  ForestBunnyAmbientEffect({required super.size})
    : super(randomSeed: 4004, initialPause: 12.0);

  static const double duration = 3.4;
  static const double minPause = 20.0;
  static const double maxPause = 40.0;
  static const double opacity = 0.42;
  static const double effectScale = 0.022;
  static const double speed = 1.0;
  static const double fadeInDuration = 0.35;
  static const double fadeOutDuration = 0.85;
  static const int particleCount = 0;
  static const Offset startPositionNormalized = Offset(0.16, 0.63);
  static const Offset endPositionNormalized = Offset(0.57, 0.61);

  bool _leftToRight = true;

  @override
  double get cycleDuration => ForestBunnyAmbientEffect.duration;

  @override
  double get minimumPause => ForestBunnyAmbientEffect.minPause;

  @override
  double get maximumPause => ForestBunnyAmbientEffect.maxPause;

  @override
  void onCycleStart() {
    _leftToRight = _random.nextBool();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!isAnimating || size.x <= 0 || size.y <= 0) {
      return;
    }

    final p = progress;
    final travel = _easeInOutCubic(p);
    final start = _leftToRight
        ? pointFromNormalized(startPositionNormalized)
        : pointFromNormalized(endPositionNormalized);
    final end = _leftToRight
        ? pointFromNormalized(endPositionNormalized)
        : pointFromNormalized(startPositionNormalized);
    final bob = math.sin(p * math.pi * 6) * viewportUnit * 0.006;
    final center = _lerpOffset(start, end, travel) + Offset(0, bob);
    final hideFade = p < 0.72
        ? 1.0
        : 1 - _easeInCubic(((p - 0.72) / 0.28).clamp(0.0, 1.0).toDouble());
    final fade =
        _fadeFor(
          p,
          duration: duration,
          fadeInDuration: fadeInDuration,
          fadeOutDuration: fadeOutDuration,
        ) *
        hideFade;
    final bunnySize =
        viewportUnit * effectScale * (0.82 + math.sin(p * math.pi) * 0.10);
    final alpha = opacity * fade;

    if (alpha <= 0.01) {
      return;
    }

    final bodyPaint = Paint()
      ..color = const Color(0xFFF6FBFF).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    final shadePaint = Paint()
      ..color = const Color(0xFFBED3DE).withValues(alpha: alpha * 0.36)
      ..style = PaintingStyle.fill;
    final eyePaint = Paint()
      ..color = const Color(0xFF3E5967).withValues(alpha: alpha * 0.62)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (!_leftToRight) {
      canvas.scale(-1, 1);
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: bunnySize * 1.28,
        height: bunnySize * 0.70,
      ),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bunnySize * 0.48, -bunnySize * 0.26),
        width: bunnySize * 0.54,
        height: bunnySize * 0.45,
      ),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bunnySize * 0.56, -bunnySize * 0.72),
        width: bunnySize * 0.16,
        height: bunnySize * 0.70,
      ),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bunnySize * 0.35, -bunnySize * 0.70),
        width: bunnySize * 0.14,
        height: bunnySize * 0.62,
      ),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-bunnySize * 0.64, -bunnySize * 0.03),
        width: bunnySize * 0.28,
        height: bunnySize * 0.24,
      ),
      shadePaint,
    );
    canvas.drawCircle(
      Offset(bunnySize * 0.61, -bunnySize * 0.29),
      math.max(0.45, bunnySize * 0.035),
      eyePaint,
    );
    canvas.restore();
  }
}

class CaveDripsAmbientEffect extends LevelAmbientEffectComponent {
  CaveDripsAmbientEffect({required super.size});

  static const double duration = 1.35;
  static const double minPause = 0.8;
  static const double maxPause = 2.8;
  static const double opacity = 0.34;
  static const double effectScale = 0.009;
  static const double rippleScale = 0.039;
  static const double speed = 1.0;
  static const double fadeInDuration = 0.10;
  static const double fadeOutDuration = 0.35;
  static const int particleCount = 3;
  static const Offset startPositionNormalized = Offset(0.22, 0.18);
  static const Offset endPositionNormalized = Offset(0.22, 0.38);
  static const double _backgroundSourceWidth = 1672;
  static const double _backgroundSourceHeight = 941;
  static const Size _backgroundSourceSize = Size(
    _backgroundSourceWidth,
    _backgroundSourceHeight,
  );
  static const Offset _fireBaseSourceNormalized = Offset(
    1071 / _backgroundSourceWidth,
    508 / _backgroundSourceHeight,
  );
  static const _FlickeringFirePainter _firePainter = _FlickeringFirePainter(
    backgroundSourceSize: _backgroundSourceSize,
    baseSourceNormalized: _fireBaseSourceNormalized,
  );
  static const int _waterDripIndex = 2;
  static const Offset _waterDripStartSourceNormalized = Offset(
    650 / _backgroundSourceWidth,
    330 / _backgroundSourceHeight,
  );
  static const Offset _waterDripEndSourceNormalized = Offset(
    650 / _backgroundSourceWidth,
    640 / _backgroundSourceHeight,
  );

  static const List<Offset> _dripStartPositions = <Offset>[
    Offset(0.22, 0.18),
    Offset(0.48, 0.15),
    Offset(0.58, 0.21),
  ];
  static const double _groundYNormalized = 0.68;

  final math.Random _random = math.Random(5005);
  double _fireElapsed = 0;
  late final List<_DripState> _drips = List<_DripState>.generate(
    _dripStartPositions.length,
    (index) => _DripState(wait: _randomPause() + index * 0.35),
  );

  @override
  void update(double dt) {
    super.update(dt);

    _fireElapsed += dt;
    for (final drip in _drips) {
      if (drip.active) {
        drip.elapsed += dt * speed;
        if (drip.elapsed >= duration) {
          drip
            ..active = false
            ..elapsed = 0
            ..wait = _randomPause();
        }
      } else {
        drip.wait -= dt;
        if (drip.wait <= 0) {
          drip
            ..active = true
            ..elapsed = 0;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.x <= 0 || size.y <= 0) {
      return;
    }

    _firePainter.draw(canvas, viewportSize: size, elapsed: _fireElapsed);

    for (var index = 0; index < _drips.length; index += 1) {
      final drip = _drips[index];
      if (!drip.active) {
        continue;
      }

      final p = (drip.elapsed / duration).clamp(0.0, 1.0).toDouble();
      final start = index == _waterDripIndex
          ? _pointFromSourceImage(
              viewportSize: size,
              backgroundSourceSize: _backgroundSourceSize,
              normalized: _waterDripStartSourceNormalized,
            )
          : pointFromNormalized(_dripStartPositions[index]);
      final end = index == _waterDripIndex
          ? _pointFromSourceImage(
              viewportSize: size,
              backgroundSourceSize: _backgroundSourceSize,
              normalized: _waterDripEndSourceNormalized,
            )
          : pointFromNormalized(
              Offset(_dripStartPositions[index].dx, _groundYNormalized),
            );
      final dropAlpha =
          opacity *
          _fadeFor(
            p,
            duration: duration,
            fadeInDuration: fadeInDuration,
            fadeOutDuration: fadeOutDuration,
          );

      if (p < 0.72) {
        final fallProgress = _easeInCubic(p / 0.72);
        final center = _lerpOffset(start, end, fallProgress);
        final dropPaint = Paint()
          ..color = const Color(0xFFAEDCEB).withValues(alpha: dropAlpha)
          ..style = PaintingStyle.fill;
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: viewportUnit * effectScale * 0.70,
            height: viewportUnit * effectScale * 1.20,
          ),
          dropPaint,
        );
      } else {
        final rippleProgress = ((p - 0.72) / 0.28).clamp(0.0, 1.0).toDouble();
        _drawRipples(
          canvas,
          end,
          viewportUnit * rippleScale,
          rippleProgress,
          opacity * (1 - rippleProgress) * 0.62,
        );
      }
    }
  }

  double _randomPause() {
    return minPause + _random.nextDouble() * (maxPause - minPause);
  }
}

class MountainPassSnowPlumeEffect extends _CycledAmbientEffectComponent {
  MountainPassSnowPlumeEffect({required super.size})
    : super(randomSeed: 7007, initialPause: 8.0);

  static const double duration = 4.8;
  static const double minPause = 12.0;
  static const double maxPause = 28.0;
  static const double opacity = 0.22;
  static const double effectScale = 0.009;
  static const double speed = 1.0;
  static const double fadeInDuration = 0.8;
  static const double fadeOutDuration = 1.6;
  static const int particleCount = 16;
  static const Offset startPositionNormalized = Offset(0.54, 0.42);
  static const Offset endPositionNormalized = Offset(0.74, 0.36);

  static const List<_SnowParticleSpec> _plumeParticles = <_SnowParticleSpec>[
    _SnowParticleSpec(offset: 0.00, yOffset: 0.00, size: 0.65, wave: 0.0),
    _SnowParticleSpec(offset: 0.06, yOffset: -0.20, size: 0.44, wave: 1.2),
    _SnowParticleSpec(offset: 0.12, yOffset: 0.18, size: 0.56, wave: 2.4),
    _SnowParticleSpec(offset: 0.18, yOffset: -0.12, size: 0.42, wave: 3.6),
    _SnowParticleSpec(offset: 0.24, yOffset: 0.28, size: 0.50, wave: 4.8),
    _SnowParticleSpec(offset: 0.30, yOffset: -0.32, size: 0.60, wave: 5.4),
    _SnowParticleSpec(offset: 0.36, yOffset: 0.06, size: 0.48, wave: 6.2),
    _SnowParticleSpec(offset: 0.42, yOffset: 0.22, size: 0.52, wave: 7.6),
    _SnowParticleSpec(offset: 0.48, yOffset: -0.18, size: 0.45, wave: 8.4),
    _SnowParticleSpec(offset: 0.54, yOffset: 0.12, size: 0.58, wave: 9.5),
    _SnowParticleSpec(offset: 0.60, yOffset: -0.26, size: 0.40, wave: 10.1),
    _SnowParticleSpec(offset: 0.66, yOffset: 0.30, size: 0.46, wave: 11.6),
    _SnowParticleSpec(offset: 0.72, yOffset: -0.05, size: 0.54, wave: 12.4),
    _SnowParticleSpec(offset: 0.78, yOffset: 0.20, size: 0.38, wave: 13.2),
    _SnowParticleSpec(offset: 0.84, yOffset: -0.22, size: 0.44, wave: 14.4),
    _SnowParticleSpec(offset: 0.90, yOffset: 0.08, size: 0.50, wave: 15.6),
  ];

  @override
  double get cycleDuration => MountainPassSnowPlumeEffect.duration;

  @override
  double get minimumPause => MountainPassSnowPlumeEffect.minPause;

  @override
  double get maximumPause => MountainPassSnowPlumeEffect.maxPause;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!isAnimating || size.x <= 0 || size.y <= 0) {
      return;
    }

    final fade = _fadeFor(
      progress,
      duration: duration,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
    );
    if (fade <= 0) {
      return;
    }

    final start = pointFromNormalized(startPositionNormalized);
    final end = pointFromNormalized(endPositionNormalized);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFEAF7FF).withValues(alpha: opacity * fade);

    for (final particle in _plumeParticles) {
      final t = (progress * 0.78 + particle.offset * 0.24)
          .clamp(0.0, 1.0)
          .toDouble();
      final spread =
          math.sin((progress + particle.wave) * math.pi * 1.4) *
          viewportUnit *
          0.008;
      final center =
          _lerpOffset(start, end, _easeOutCubic(t)) +
          Offset(
            particle.offset * viewportUnit * 0.055,
            particle.yOffset * viewportUnit * 0.030 + spread,
          );
      final radius = viewportUnit * effectScale * particle.size * (1 + t * 0.6);
      final alpha = opacity * fade * (1 - t * 0.75);
      paint.color = const Color(
        0xFFEAF7FF,
      ).withValues(alpha: alpha.clamp(0.0, opacity).toDouble());
      canvas.drawCircle(center, math.max(0.5, radius), paint);
    }
  }
}

class PolarNightStarsEffect extends LevelAmbientEffectComponent {
  PolarNightStarsEffect({required super.size});

  static const double duration = 1.6;
  static const double minPause = 20.0;
  static const double maxPause = 45.0;
  static const double opacity = 0.48;
  static const double effectScale = 0.012;
  static const double speed = 1.0;
  static const double fadeInDuration = 0.18;
  static const double fadeOutDuration = 0.55;
  static const int particleCount = 7;
  static const Offset startPositionNormalized = Offset(0.10, 0.09);
  static const Offset endPositionNormalized = Offset(0.78, 0.16);
  static const double _backgroundSourceWidth = 1672;
  static const double _backgroundSourceHeight = 941;
  static const Size _backgroundSourceSize = Size(
    _backgroundSourceWidth,
    _backgroundSourceHeight,
  );
  static const Offset _campfireBaseSourceNormalized = Offset(
    365 / _backgroundSourceWidth,
    522 / _backgroundSourceHeight,
  );
  static const _FlickeringFirePainter _campfirePainter = _FlickeringFirePainter(
    backgroundSourceSize: _backgroundSourceSize,
    baseSourceNormalized: _campfireBaseSourceNormalized,
  );

  static const List<_TwinkleSpec> _twinkles = <_TwinkleSpec>[
    _TwinkleSpec(position: Offset(0.12, 0.16), size: 0.50, phase: 0.0),
    _TwinkleSpec(position: Offset(0.28, 0.11), size: 0.40, phase: 1.6),
    _TwinkleSpec(position: Offset(0.46, 0.18), size: 0.44, phase: 2.8),
    _TwinkleSpec(position: Offset(0.63, 0.13), size: 0.38, phase: 4.1),
    _TwinkleSpec(position: Offset(0.80, 0.20), size: 0.48, phase: 5.4),
    _TwinkleSpec(position: Offset(0.36, 0.27), size: 0.34, phase: 6.2),
    _TwinkleSpec(position: Offset(0.72, 0.29), size: 0.36, phase: 7.0),
  ];

  final math.Random _random = math.Random(8008);
  double _twinkleTime = 0;
  double _fireElapsed = 0;
  double _shootingElapsed = 0;
  double _pauseRemaining = 6.0;
  bool _isShooting = false;

  @override
  void update(double dt) {
    super.update(dt);
    _twinkleTime += dt * speed;
    _fireElapsed += dt;

    if (_isShooting) {
      _shootingElapsed += dt * speed;
      if (_shootingElapsed >= duration) {
        _isShooting = false;
        _shootingElapsed = 0;
        _pauseRemaining = _randomPause();
      }
      return;
    }

    _pauseRemaining -= dt;
    if (_pauseRemaining <= 0) {
      _isShooting = true;
      _shootingElapsed = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.x <= 0 || size.y <= 0) {
      return;
    }

    _drawTwinkles(canvas);
    _campfirePainter.draw(canvas, viewportSize: size, elapsed: _fireElapsed);
    if (_isShooting) {
      _drawShootingStar(canvas);
    }
  }

  void _drawTwinkles(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final twinkle in _twinkles) {
      final pulse = 0.5 + math.sin(_twinkleTime * 0.65 + twinkle.phase) * 0.5;
      final alpha = 0.08 + pulse * 0.10;
      paint.color = const Color(0xFFFFFFFF).withValues(alpha: alpha);
      canvas.drawCircle(
        pointFromNormalized(twinkle.position),
        math.max(0.7, viewportUnit * effectScale * twinkle.size * 0.22),
        paint,
      );
    }
  }

  void _drawShootingStar(Canvas canvas) {
    final p = (_shootingElapsed / duration).clamp(0.0, 1.0).toDouble();
    final fade = _fadeFor(
      p,
      duration: duration,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
    );
    final head = _lerpOffset(
      pointFromNormalized(startPositionNormalized),
      pointFromNormalized(endPositionNormalized),
      _easeOutCubic(p),
    );
    final tailOffset = Offset(-viewportUnit * 0.075, -viewportUnit * 0.020);
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: opacity * fade)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.7, viewportUnit * 0.0015);
    final tailPaint = Paint()
      ..color = const Color(0xFFBEE8FF).withValues(alpha: opacity * fade * 0.5)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.45, viewportUnit * 0.0010);

    canvas.drawLine(head + tailOffset, head, tailPaint);
    canvas.drawCircle(
      head,
      math.max(0.7, viewportUnit * effectScale * 0.18),
      paint,
    );
  }

  double _randomPause() {
    return minPause + _random.nextDouble() * (maxPause - minPause);
  }
}

class NorthernOceanBlizzardEffect extends LevelAmbientEffectComponent {
  NorthernOceanBlizzardEffect({required super.size}) {
    priority = 25;
  }

  static const int blizzardParticleCount = 179;
  static const double snowfallSpeedMultiplier = 1.55;
  static const Color _snowBlue = Color(0xFFE9F8FF);
  static const Color _snowWhite = Color(0xFFF7FDFF);

  final List<_BlizzardFlakeSpec> _blizzardFlakes = _buildBlizzardFlakes();
  double _blizzardElapsed = 0;

  int get debugParticleCount => _blizzardFlakes.length;

  @override
  void update(double dt) {
    super.update(dt);
    _blizzardElapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.x <= 0 || size.y <= 0) {
      return;
    }

    _drawSnowfall(canvas);
  }

  static List<_BlizzardFlakeSpec> _buildBlizzardFlakes() {
    final random = math.Random(20260524);
    final flakes = <_BlizzardFlakeSpec>[];

    void addLayer({
      required int count,
      required int layer,
      required double minRadius,
      required double maxRadius,
      required double minSpeed,
      required double maxSpeed,
      required double minOpacity,
      required double maxOpacity,
      required double minDrift,
      required double maxDrift,
    }) {
      for (var index = 0; index < count; index += 1) {
        flakes.add(
          _BlizzardFlakeSpec(
            layer: layer,
            x: random.nextDouble(),
            y: random.nextDouble(),
            phase: random.nextDouble(),
            radius: minRadius + random.nextDouble() * (maxRadius - minRadius),
            speed: minSpeed + random.nextDouble() * (maxSpeed - minSpeed),
            opacity:
                minOpacity + random.nextDouble() * (maxOpacity - minOpacity),
            drift: minDrift + random.nextDouble() * (maxDrift - minDrift),
          ),
        );
      }
    }

    addLayer(
      count: 91,
      layer: 0,
      minRadius: 0.75,
      maxRadius: 1.45,
      minSpeed: 0.065,
      maxSpeed: 0.117,
      minOpacity: 0.2,
      maxOpacity: 0.42,
      minDrift: 2,
      maxDrift: 9,
    );
    addLayer(
      count: 62,
      layer: 1,
      minRadius: 1.25,
      maxRadius: 2.4,
      minSpeed: 0.117,
      maxSpeed: 0.208,
      minOpacity: 0.34,
      maxOpacity: 0.66,
      minDrift: 8,
      maxDrift: 22,
    );
    addLayer(
      count: 26,
      layer: 2,
      minRadius: 2.15,
      maxRadius: 4.2,
      minSpeed: 0.182,
      maxSpeed: 0.325,
      minOpacity: 0.42,
      maxOpacity: 0.76,
      minDrift: 14,
      maxDrift: 34,
    );

    assert(flakes.length == blizzardParticleCount);
    return flakes;
  }

  void _drawSnowfall(Canvas canvas) {
    final canvasSize = Size(size.x, size.y);
    final visibleCounts = _visibleLayerCounts(canvasSize);
    final wind = math.sin(_blizzardElapsed * 0.7) * 7;
    var farCount = 0;
    var middleCount = 0;
    var frontCount = 0;

    for (final flake in _blizzardFlakes) {
      if (!_shouldDrawFlake(
        flake,
        visibleCounts,
        farCount,
        middleCount,
        frontCount,
      )) {
        continue;
      }

      switch (flake.layer) {
        case 0:
          farCount += 1;
        case 1:
          middleCount += 1;
        case _:
          frontCount += 1;
      }

      final layerWeight = _layerWeight(flake.layer);
      final fall =
          (flake.y + _blizzardElapsed * flake.speed * snowfallSpeedMultiplier) %
          1;
      final sway = math.sin(
        _blizzardElapsed * math.pi * 2 * (0.18 + layerWeight * 0.12) +
            flake.phase,
      );
      final diagonalDrift = _blizzardElapsed * flake.drift * 0.1 * layerWeight;
      final x = _wrapHorizontal(
        flake.x * canvasSize.width +
            sway * flake.drift +
            wind * layerWeight +
            diagonalDrift,
        canvasSize.width,
      );
      final y =
          fall * (canvasSize.height + flake.radius * 8) - flake.radius * 4;

      _paintFlake(canvas, Offset(x, y), flake);
    }
  }

  _SnowLayerCounts _visibleLayerCounts(Size size) {
    var farTotal = 0;
    var middleTotal = 0;
    var frontTotal = 0;

    for (final flake in _blizzardFlakes) {
      switch (flake.layer) {
        case 0:
          farTotal += 1;
        case 1:
          middleTotal += 1;
        case _:
          frontTotal += 1;
      }
    }

    return _SnowLayerCounts(
      far: _scaledCount(farTotal, size),
      middle: _scaledCount(middleTotal, size),
      front: _scaledCount(frontTotal, size),
    );
  }

  int _scaledCount(int count, Size size) {
    final shortestSide = math.min(size.width, size.height);
    final scale = shortestSide < 520
        ? 0.78
        : shortestSide < 760
        ? 0.88
        : 1.0;

    return (count * scale).round().clamp(0, count);
  }

  bool _shouldDrawFlake(
    _BlizzardFlakeSpec flake,
    _SnowLayerCounts visibleCounts,
    int farCount,
    int middleCount,
    int frontCount,
  ) {
    return switch (flake.layer) {
      0 => farCount < visibleCounts.far,
      1 => middleCount < visibleCounts.middle,
      _ => frontCount < visibleCounts.front,
    };
  }

  double _layerWeight(int layer) {
    return switch (layer) {
      0 => 0.34,
      1 => 0.72,
      _ => 1.0,
    };
  }

  double _wrapHorizontal(double value, double width) {
    final margin = 40.0;
    final wrapped = (value + margin) % (width + margin * 2);
    return wrapped - margin;
  }

  void _paintFlake(Canvas canvas, Offset center, _BlizzardFlakeSpec flake) {
    final tint = flake.layer == 2 ? _snowWhite : _snowBlue;
    final glowPaint = Paint()
      ..color = tint.withValues(alpha: flake.opacity * 0.34)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, flake.radius * 0.9);
    final corePaint = Paint()
      ..color = tint.withValues(alpha: flake.opacity)
      ..isAntiAlias = true;

    canvas.drawCircle(center, flake.radius * 1.85, glowPaint);
    canvas.drawCircle(center, flake.radius, corePaint);

    if (flake.layer == 2) {
      final highlightPaint = Paint()
        ..color = _snowWhite.withValues(alpha: flake.opacity * 0.28)
        ..strokeWidth = 0.75
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      final sparkleRadius = flake.radius * 1.35;

      canvas.drawLine(
        center.translate(-sparkleRadius, 0),
        center.translate(sparkleRadius, 0),
        highlightPaint,
      );
      canvas.drawLine(
        center.translate(0, -sparkleRadius),
        center.translate(0, sparkleRadius),
        highlightPaint,
      );
    }
  }
}

class _DriftingFloeSpec {
  const _DriftingFloeSpec({
    required this.offset,
    required this.yNormalized,
    required this.size,
    required this.wobble,
    required this.drift,
  });

  final double offset;
  final double yNormalized;
  final double size;
  final double wobble;
  final double drift;
}

class _DripState {
  _DripState({required this.wait});

  double wait;
  double elapsed = 0;
  bool active = false;
}

class _SnowParticleSpec {
  const _SnowParticleSpec({
    required this.offset,
    required this.yOffset,
    required this.size,
    required this.wave,
  });

  final double offset;
  final double yOffset;
  final double size;
  final double wave;
}

class _BlizzardFlakeSpec {
  const _BlizzardFlakeSpec({
    required this.layer,
    required this.x,
    required this.y,
    required this.phase,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.drift,
  });

  final int layer;
  final double x;
  final double y;
  final double phase;
  final double radius;
  final double speed;
  final double opacity;
  final double drift;
}

class _SnowLayerCounts {
  const _SnowLayerCounts({
    required this.far,
    required this.middle,
    required this.front,
  });

  final int far;
  final int middle;
  final int front;
}

class _TwinkleSpec {
  const _TwinkleSpec({
    required this.position,
    required this.size,
    required this.phase,
  });

  final Offset position;
  final double size;
  final double phase;
}

class _FlickeringFirePainter {
  const _FlickeringFirePainter({
    required this.backgroundSourceSize,
    required this.baseSourceNormalized,
  });

  static const double _flickerMultiplier = 4.0;
  static const double _flameScale = 0.0078;

  final Size backgroundSourceSize;
  final Offset baseSourceNormalized;

  void draw(
    Canvas canvas, {
    required Vector2 viewportSize,
    required double elapsed,
  }) {
    final viewportUnit = math.min(viewportSize.x, viewportSize.y);
    final base = _pointFromSourceImage(
      viewportSize: viewportSize,
      backgroundSourceSize: backgroundSourceSize,
      normalized: baseSourceNormalized,
    );
    final margin = viewportUnit * 0.06;
    if (base.dx < -margin ||
        base.dx > viewportSize.x + margin ||
        base.dy < -margin ||
        base.dy > viewportSize.y + margin) {
      return;
    }

    final baseFlicker =
        math.sin(elapsed * 8.6) * 0.104 +
        math.sin(elapsed * 13.4 + 1.2) * 0.065;
    final flicker = baseFlicker * _flickerMultiplier;
    final sway = math.sin(elapsed * 5.2) * viewportUnit * 0.00072;
    final flameSize = viewportUnit * _flameScale;
    final glowRadius = flameSize * (2.35 + flicker * 2.0);
    final glowCenter = base + Offset(sway * 0.30, -flameSize * 0.85);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFFFFF0A6).withValues(alpha: 0.26),
          const Color(0xFFFFA53D).withValues(alpha: 0.12),
          const Color(0xFFFF7A24).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius))
      ..blendMode = BlendMode.plus;
    canvas.drawCircle(glowCenter, glowRadius, glowPaint);

    final outerHeight = flameSize * (1.55 + flicker);
    final outerWidth = flameSize * (0.78 - flicker * 0.25);
    final outerPaint = Paint()
      ..color = const Color(0xFFFF9B2F).withValues(alpha: 0.62)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.plus;
    canvas.drawPath(
      _flamePath(base, outerWidth, outerHeight, sway),
      outerPaint,
    );

    final innerPaint = Paint()
      ..color = const Color(0xFFFFF2B0).withValues(alpha: 0.78)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.plus;
    canvas.drawPath(
      _flamePath(
        base + Offset(sway * 0.18, -outerHeight * 0.05),
        outerWidth * 0.46,
        outerHeight * 0.68,
        -sway * 0.35,
      ),
      innerPaint,
    );
  }
}

Path _flamePath(Offset base, double width, double height, double sway) {
  return Path()
    ..moveTo(base.dx, base.dy)
    ..cubicTo(
      base.dx - width * 0.85,
      base.dy - height * 0.28,
      base.dx - width * 0.32 + sway,
      base.dy - height * 0.78,
      base.dx + sway,
      base.dy - height,
    )
    ..cubicTo(
      base.dx + width * 0.46 + sway,
      base.dy - height * 0.76,
      base.dx + width * 0.84,
      base.dy - height * 0.28,
      base.dx,
      base.dy,
    );
}

Offset _pointFromSourceImage({
  required Vector2 viewportSize,
  required Size backgroundSourceSize,
  required Offset normalized,
}) {
  final scale = math.max(
    viewportSize.x / backgroundSourceSize.width,
    viewportSize.y / backgroundSourceSize.height,
  );
  final fittedWidth = backgroundSourceSize.width * scale;
  final fittedHeight = backgroundSourceSize.height * scale;
  final offset = Offset(
    (viewportSize.x - fittedWidth) * 0.5,
    (viewportSize.y - fittedHeight) * 0.5,
  );

  return offset +
      Offset(
        normalized.dx * backgroundSourceSize.width * scale,
        normalized.dy * backgroundSourceSize.height * scale,
      );
}

double _fadeFor(
  double progress, {
  required double duration,
  required double fadeInDuration,
  required double fadeOutDuration,
}) {
  final fadeInProgress = duration <= 0 || fadeInDuration <= 0
      ? 1.0
      : (progress * duration / fadeInDuration).clamp(0.0, 1.0).toDouble();
  final fadeOutProgress = duration <= 0 || fadeOutDuration <= 0
      ? 1.0
      : ((1 - progress) * duration / fadeOutDuration)
            .clamp(0.0, 1.0)
            .toDouble();

  return math.min(
    _easeOutCubic(fadeInProgress),
    _easeOutCubic(fadeOutProgress),
  );
}

Offset _lerpOffset(Offset start, Offset end, double t) {
  return Offset(_lerp(start.dx, end.dx, t), _lerp(start.dy, end.dy, t));
}

double _lerp(double start, double end, double t) {
  return start + (end - start) * t;
}

double _easeInCubic(double t) {
  return t * t * t;
}

double _easeOutCubic(double t) {
  final inverse = 1 - t;
  return 1 - inverse * inverse * inverse;
}

double _easeInOutCubic(double t) {
  return t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
}

double _easeInOutSine(double t) {
  return -(math.cos(math.pi * t) - 1) / 2;
}

void _drawRipples(
  Canvas canvas,
  Offset center,
  double maxRadius,
  double progress,
  double opacity,
) {
  if (progress <= 0 || opacity <= 0) {
    return;
  }

  final ripplePaint = Paint()
    ..color = const Color(
      0xFFE8F8FF,
    ).withValues(alpha: (opacity * (1 - progress)).clamp(0.0, 1.0).toDouble())
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(0.45, maxRadius * 0.035);
  final radius = maxRadius * _easeOutCubic(progress);

  canvas.drawOval(
    Rect.fromCenter(center: center, width: radius * 1.7, height: radius * 0.46),
    ripplePaint,
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: center,
      width: radius * 2.45,
      height: radius * 0.62,
    ),
    ripplePaint,
  );
}
