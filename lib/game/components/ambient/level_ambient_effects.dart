import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class AmbientEffectsFactory {
  const AmbientEffectsFactory._();

  static LevelAmbientEffectComponent? forLevel({
    required int levelId,
    required Vector2 size,
  }) {
    return switch (levelId) {
      2 => IceRiverAmbientEffect(size: size),
      3 => SnowyShoreSealAmbientEffect(size: size),
      4 => ForestBunnyAmbientEffect(size: size),
      5 => CaveDripsAmbientEffect(size: size),
      6 => SnowValleyWindAmbientEffect(size: size),
      7 => MountainPassSnowPlumeEffect(size: size),
      8 => PolarNightStarsEffect(size: size),
      9 => AuroraWaveEffect(size: size),
      10 => NorthernOceanSplashEffect(size: size),
      _ => null,
    };
  }
}

abstract class LevelAmbientEffectComponent extends PositionComponent {
  LevelAmbientEffectComponent({required Vector2 size})
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
  static const double minPause = 2.0;
  static const double maxPause = 6.0;
  static const double opacity = 0.34;
  static const double effectScale = 0.006;
  static const double speed = 1.0;
  static const double fadeInDuration = 0.10;
  static const double fadeOutDuration = 0.35;
  static const int particleCount = 3;
  static const Offset startPositionNormalized = Offset(0.22, 0.18);
  static const Offset endPositionNormalized = Offset(0.22, 0.38);

  static const List<Offset> _dripStartPositions = <Offset>[
    Offset(0.22, 0.18),
    Offset(0.48, 0.15),
    Offset(0.73, 0.21),
  ];
  static const double _dropDistanceNormalized = 0.20;

  final math.Random _random = math.Random(5005);
  late final List<_DripState> _drips = List<_DripState>.generate(
    _dripStartPositions.length,
    (index) => _DripState(wait: _randomPause() + index * 0.8),
  );

  @override
  void update(double dt) {
    super.update(dt);

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

    for (var index = 0; index < _drips.length; index += 1) {
      final drip = _drips[index];
      if (!drip.active) {
        continue;
      }

      final p = (drip.elapsed / duration).clamp(0.0, 1.0).toDouble();
      final start = pointFromNormalized(_dripStartPositions[index]);
      final end = pointFromNormalized(
        _dripStartPositions[index] + const Offset(0, _dropDistanceNormalized),
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
          viewportUnit * 0.026,
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

class SnowValleyWindAmbientEffect extends _CycledAmbientEffectComponent {
  SnowValleyWindAmbientEffect({required super.size})
    : super(randomSeed: 6006, initialPause: 7.0);

  static const double duration = 6.8;
  static const double minPause = 12.0;
  static const double maxPause = 30.0;
  static const double opacity = 0.24;
  static const double effectScale = 0.010;
  static const double speed = 1.0;
  static const double fadeInDuration = 1.2;
  static const double fadeOutDuration = 1.9;
  static const int particleCount = 24;
  static const Offset startPositionNormalized = Offset(-0.08, 0.55);
  static const Offset endPositionNormalized = Offset(1.08, 0.50);

  static const List<_SnowParticleSpec> _particles = <_SnowParticleSpec>[
    _SnowParticleSpec(offset: 0.00, yOffset: -0.20, size: 0.75, wave: 0.0),
    _SnowParticleSpec(offset: 0.04, yOffset: 0.18, size: 0.52, wave: 1.3),
    _SnowParticleSpec(offset: 0.08, yOffset: -0.04, size: 0.60, wave: 2.4),
    _SnowParticleSpec(offset: 0.12, yOffset: 0.28, size: 0.48, wave: 3.2),
    _SnowParticleSpec(offset: 0.16, yOffset: -0.32, size: 0.70, wave: 4.0),
    _SnowParticleSpec(offset: 0.20, yOffset: 0.02, size: 0.56, wave: 5.1),
    _SnowParticleSpec(offset: 0.24, yOffset: 0.22, size: 0.64, wave: 6.2),
    _SnowParticleSpec(offset: 0.28, yOffset: -0.15, size: 0.44, wave: 7.0),
    _SnowParticleSpec(offset: 0.32, yOffset: 0.36, size: 0.62, wave: 8.5),
    _SnowParticleSpec(offset: 0.36, yOffset: -0.28, size: 0.54, wave: 9.1),
    _SnowParticleSpec(offset: 0.40, yOffset: 0.08, size: 0.76, wave: 10.4),
    _SnowParticleSpec(offset: 0.44, yOffset: -0.06, size: 0.50, wave: 11.2),
    _SnowParticleSpec(offset: 0.48, yOffset: 0.30, size: 0.46, wave: 12.3),
    _SnowParticleSpec(offset: 0.52, yOffset: -0.23, size: 0.68, wave: 13.5),
    _SnowParticleSpec(offset: 0.56, yOffset: 0.13, size: 0.58, wave: 14.6),
    _SnowParticleSpec(offset: 0.60, yOffset: 0.35, size: 0.42, wave: 15.8),
    _SnowParticleSpec(offset: 0.64, yOffset: -0.18, size: 0.64, wave: 16.7),
    _SnowParticleSpec(offset: 0.68, yOffset: 0.04, size: 0.54, wave: 17.4),
    _SnowParticleSpec(offset: 0.72, yOffset: 0.24, size: 0.60, wave: 18.1),
    _SnowParticleSpec(offset: 0.76, yOffset: -0.34, size: 0.46, wave: 19.2),
    _SnowParticleSpec(offset: 0.80, yOffset: 0.16, size: 0.72, wave: 20.0),
    _SnowParticleSpec(offset: 0.84, yOffset: -0.10, size: 0.50, wave: 21.4),
    _SnowParticleSpec(offset: 0.88, yOffset: 0.32, size: 0.56, wave: 22.5),
    _SnowParticleSpec(offset: 0.92, yOffset: -0.25, size: 0.48, wave: 23.6),
  ];

  @override
  double get cycleDuration => SnowValleyWindAmbientEffect.duration;

  @override
  double get minimumPause => SnowValleyWindAmbientEffect.minPause;

  @override
  double get maximumPause => SnowValleyWindAmbientEffect.maxPause;

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

    final baseStart = pointFromNormalized(startPositionNormalized);
    final baseEnd = pointFromNormalized(endPositionNormalized);
    final particlePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: opacity * fade)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.4, viewportUnit * 0.0010);

    for (final particle in _particles) {
      final t = ((progress * 1.18) + particle.offset - 0.10)
          .clamp(0.0, 1.0)
          .toDouble();
      final wave =
          math.sin((progress * 2.2 + particle.wave) * math.pi) *
          viewportUnit *
          0.012;
      final center =
          _lerpOffset(baseStart, baseEnd, _easeInOutSine(t)) +
          Offset(0, particle.yOffset * viewportUnit * 0.035 + wave);
      final length = viewportUnit * effectScale * particle.size;
      final alpha = opacity * fade * (1 - (t - 0.5).abs() * 0.7);
      particlePaint.color = const Color(
        0xFFFFFFFF,
      ).withValues(alpha: alpha.clamp(0.0, opacity).toDouble());
      canvas.drawLine(
        Offset(center.dx - length * 0.6, center.dy),
        Offset(center.dx + length * 0.6, center.dy - length * 0.10),
        particlePaint,
      );
    }
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

  static const double duration = 1.25;
  static const double minPause = 20.0;
  static const double maxPause = 45.0;
  static const double opacity = 0.48;
  static const double effectScale = 0.012;
  static const double speed = 1.0;
  static const double fadeInDuration = 0.18;
  static const double fadeOutDuration = 0.55;
  static const int particleCount = 7;
  static const Offset startPositionNormalized = Offset(0.22, 0.17);
  static const Offset endPositionNormalized = Offset(0.52, 0.30);

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
  double _shootingElapsed = 0;
  double _pauseRemaining = 6.0;
  bool _isShooting = false;

  @override
  void update(double dt) {
    super.update(dt);
    _twinkleTime += dt * speed;

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
    final tailOffset = Offset(-viewportUnit * 0.05, -viewportUnit * 0.022);
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

class AuroraWaveEffect extends LevelAmbientEffectComponent {
  AuroraWaveEffect({required super.size});

  static const double duration = 18.0;
  static const double minPause = 0.0;
  static const double maxPause = 0.0;
  static const double opacity = 0.115;
  static const double effectScale = 1.0;
  static const double speed = 0.055;
  static const double fadeInDuration = 3.0;
  static const double fadeOutDuration = 3.0;
  static const int particleCount = 0;
  static const Offset startPositionNormalized = Offset(0.12, 0.20);
  static const Offset endPositionNormalized = Offset(0.92, 0.34);

  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed = (_elapsed + dt * speed) % duration;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.x <= 0 || size.y <= 0) {
      return;
    }

    final p = _elapsed / duration;
    final pulse = 0.55 + math.sin(p * math.pi * 2) * 0.18;
    final drift = math.sin(p * math.pi * 2) * viewportUnit * 0.018;

    _drawAuroraBand(
      canvas,
      verticalOffset: drift,
      alpha: opacity * pulse,
      color: const Color(0xFF77F2B6),
      phase: p,
      thickness: viewportUnit * 0.090,
    );
    _drawAuroraBand(
      canvas,
      verticalOffset: -drift * 0.6 + viewportUnit * 0.025,
      alpha: opacity * pulse * 0.56,
      color: const Color(0xFF85D7FF),
      phase: p + 0.32,
      thickness: viewportUnit * 0.065,
    );
  }

  void _drawAuroraBand(
    Canvas canvas, {
    required double verticalOffset,
    required double alpha,
    required Color color,
    required double phase,
    required double thickness,
  }) {
    final start = pointFromNormalized(startPositionNormalized);
    final end = pointFromNormalized(endPositionNormalized);
    final waveA = math.sin((phase + 0.10) * math.pi * 2) * viewportUnit * 0.025;
    final waveB = math.sin((phase + 0.45) * math.pi * 2) * viewportUnit * 0.028;

    final top = Path()
      ..moveTo(start.dx, start.dy + verticalOffset)
      ..cubicTo(
        size.x * 0.34,
        size.y * 0.13 + verticalOffset + waveA,
        size.x * 0.56,
        size.y * 0.38 + verticalOffset - waveB,
        end.dx,
        end.dy + verticalOffset,
      )
      ..lineTo(end.dx, end.dy + verticalOffset + thickness)
      ..cubicTo(
        size.x * 0.58,
        size.y * 0.39 + verticalOffset + thickness - waveA,
        size.x * 0.30,
        size.y * 0.20 + verticalOffset + thickness + waveB,
        start.dx,
        start.dy + verticalOffset + thickness * 0.55,
      )
      ..close();
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    canvas.drawPath(top, paint);
  }
}

class NorthernOceanSplashEffect extends _CycledAmbientEffectComponent {
  NorthernOceanSplashEffect({required super.size})
    : super(randomSeed: 1010, initialPause: 10.0);

  static const double duration = 3.2;
  static const double minPause = 15.0;
  static const double maxPause = 35.0;
  static const double opacity = 0.33;
  static const double effectScale = 0.019;
  static const double speed = 1.0;
  static const double fadeInDuration = 0.22;
  static const double fadeOutDuration = 1.25;
  static const int particleCount = 5;
  static const Offset startPositionNormalized = Offset(0.64, 0.43);
  static const Offset endPositionNormalized = Offset(0.64, 0.43);

  @override
  double get cycleDuration => NorthernOceanSplashEffect.duration;

  @override
  double get minimumPause => NorthernOceanSplashEffect.minPause;

  @override
  double get maximumPause => NorthernOceanSplashEffect.maxPause;

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

    final center = pointFromNormalized(startPositionNormalized);
    final splashPaint = Paint()
      ..color = const Color(0xFFE7FAFF).withValues(alpha: opacity * fade)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.6, viewportUnit * 0.0013);

    if (p < 0.34) {
      final burst = _easeOutCubic(p / 0.34);
      final height = viewportUnit * effectScale * (0.7 + burst * 0.9);
      for (var i = -2; i <= 2; i += 1) {
        final spread = i * viewportUnit * effectScale * 0.36;
        canvas.drawLine(
          center + Offset(spread * 0.25, 0),
          center +
              Offset(spread, -height * (1 - i.abs() * 0.12)) +
              Offset(0, height * 0.18 * p),
          splashPaint,
        );
      }
    }

    final rippleProgress = p < 0.24
        ? 0.0
        : ((p - 0.24) / 0.76).clamp(0.0, 1.0).toDouble();
    _drawRipples(
      canvas,
      center,
      viewportUnit * 0.034,
      rippleProgress,
      opacity * fade * (1 - rippleProgress * 0.62),
    );
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
