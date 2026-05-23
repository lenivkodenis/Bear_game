import 'dart:math' as math;

import 'package:flutter/material.dart';

enum SnowfallIntensity { light, medium, heavy }

enum _SnowDepthLayer { far, middle, front }

class SnowfallOverlay extends StatefulWidget {
  const SnowfallOverlay({super.key, this.intensity = SnowfallIntensity.medium});

  final SnowfallIntensity intensity;

  @override
  State<SnowfallOverlay> createState() => _SnowfallOverlayState();
}

class _SnowfallOverlayState extends State<SnowfallOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_SnowParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    _particles = _SnowParticleFactory.create(widget.intensity);
  }

  @override
  void didUpdateWidget(covariant SnowfallOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intensity != widget.intensity) {
      _particles = _SnowParticleFactory.create(widget.intensity);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.expand(
        child: CustomPaint(
          isComplex: true,
          willChange: true,
          painter: _SnowfallPainter(
            animation: _controller,
            particles: _particles,
            intensity: widget.intensity,
          ),
        ),
      ),
    );
  }
}

class _SnowParticle {
  const _SnowParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.drift,
    required this.phase,
    required this.depthLayer,
  });

  final double x;
  final double y;
  final double radius;
  final double speed;
  final double opacity;
  final double drift;
  final double phase;
  final _SnowDepthLayer depthLayer;
}

class _SnowParticleFactory {
  static List<_SnowParticle> create(SnowfallIntensity intensity) {
    final random = math.Random(20260523 + intensity.index);
    final counts = switch (intensity) {
      SnowfallIntensity.light => const _LayerCounts(
        far: 36,
        middle: 24,
        front: 10,
      ),
      SnowfallIntensity.medium => const _LayerCounts(
        far: 62,
        middle: 40,
        front: 16,
      ),
      SnowfallIntensity.heavy => const _LayerCounts(
        far: 82,
        middle: 54,
        front: 22,
      ),
    };

    return [
      ..._createLayer(random, counts.far, _SnowDepthLayer.far),
      ..._createLayer(random, counts.middle, _SnowDepthLayer.middle),
      ..._createLayer(random, counts.front, _SnowDepthLayer.front),
    ];
  }

  static Iterable<_SnowParticle> _createLayer(
    math.Random random,
    int count,
    _SnowDepthLayer depthLayer,
  ) {
    return List<_SnowParticle>.generate(count, (_) {
      final profile = _LayerProfile.forDepth(depthLayer);

      return _SnowParticle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius:
            profile.minRadius +
            random.nextDouble() * (profile.maxRadius - profile.minRadius),
        speed:
            profile.minSpeed +
            random.nextDouble() * (profile.maxSpeed - profile.minSpeed),
        opacity:
            profile.minOpacity +
            random.nextDouble() * (profile.maxOpacity - profile.minOpacity),
        drift:
            profile.minDrift +
            random.nextDouble() * (profile.maxDrift - profile.minDrift),
        phase: random.nextDouble() * math.pi * 2,
        depthLayer: depthLayer,
      );
    });
  }
}

class _LayerCounts {
  const _LayerCounts({
    required this.far,
    required this.middle,
    required this.front,
  });

  final int far;
  final int middle;
  final int front;
}

class _LayerProfile {
  const _LayerProfile({
    required this.minRadius,
    required this.maxRadius,
    required this.minSpeed,
    required this.maxSpeed,
    required this.minOpacity,
    required this.maxOpacity,
    required this.minDrift,
    required this.maxDrift,
  });

  final double minRadius;
  final double maxRadius;
  final double minSpeed;
  final double maxSpeed;
  final double minOpacity;
  final double maxOpacity;
  final double minDrift;
  final double maxDrift;

  static _LayerProfile forDepth(_SnowDepthLayer depthLayer) {
    return switch (depthLayer) {
      _SnowDepthLayer.far => const _LayerProfile(
        minRadius: 0.75,
        maxRadius: 1.45,
        minSpeed: 0.035,
        maxSpeed: 0.07,
        minOpacity: 0.2,
        maxOpacity: 0.42,
        minDrift: 2,
        maxDrift: 9,
      ),
      _SnowDepthLayer.middle => const _LayerProfile(
        minRadius: 1.25,
        maxRadius: 2.4,
        minSpeed: 0.065,
        maxSpeed: 0.13,
        minOpacity: 0.34,
        maxOpacity: 0.66,
        minDrift: 8,
        maxDrift: 22,
      ),
      _SnowDepthLayer.front => const _LayerProfile(
        minRadius: 2.15,
        maxRadius: 4.2,
        minSpeed: 0.105,
        maxSpeed: 0.19,
        minOpacity: 0.42,
        maxOpacity: 0.76,
        minDrift: 14,
        maxDrift: 34,
      ),
    };
  }
}

class _SnowfallPainter extends CustomPainter {
  _SnowfallPainter({
    required Animation<double> animation,
    required this.particles,
    required this.intensity,
  }) : _animation = animation,
       super(repaint: animation);

  final Animation<double> _animation;
  final List<_SnowParticle> particles;
  final SnowfallIntensity intensity;

  static const _snowBlue = Color(0xFFE9F8FF);
  static const _snowWhite = Color(0xFFF7FDFF);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final elapsed = _animation.value;
    final visibleCounts = _visibleLayerCounts(size);
    final wind = math.sin(elapsed * math.pi * 2) * 7;
    var farCount = 0;
    var middleCount = 0;
    var frontCount = 0;

    for (final particle in particles) {
      if (!_shouldDrawParticle(
        particle,
        visibleCounts,
        farCount,
        middleCount,
        frontCount,
      )) {
        continue;
      }
      switch (particle.depthLayer) {
        case _SnowDepthLayer.far:
          farCount += 1;
        case _SnowDepthLayer.middle:
          middleCount += 1;
        case _SnowDepthLayer.front:
          frontCount += 1;
      }

      final layerWeight = _layerWeight(particle.depthLayer);
      final fall = (particle.y + elapsed * particle.speed) % 1;
      final sway = math.sin(
        elapsed * math.pi * 2 * layerWeight + particle.phase,
      );
      final diagonalDrift = elapsed * particle.drift * layerWeight;
      final x = _wrapHorizontal(
        particle.x * size.width +
            sway * particle.drift +
            wind * layerWeight +
            diagonalDrift,
        size.width,
      );
      final y =
          fall * (size.height + particle.radius * 8) - particle.radius * 4;

      final opacity = particle.opacity * _readabilityFade(x, y, size);
      if (opacity <= 0.02) {
        continue;
      }

      _paintFlake(canvas, Offset(x, y), particle, opacity);
    }
  }

  _LayerCounts _visibleLayerCounts(Size size) {
    var farTotal = 0;
    var middleTotal = 0;
    var frontTotal = 0;

    for (final particle in particles) {
      switch (particle.depthLayer) {
        case _SnowDepthLayer.far:
          farTotal += 1;
        case _SnowDepthLayer.middle:
          middleTotal += 1;
        case _SnowDepthLayer.front:
          frontTotal += 1;
      }
    }

    return _LayerCounts(
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
    final intensityScale = switch (intensity) {
      SnowfallIntensity.light => 0.94,
      SnowfallIntensity.medium => 1.0,
      SnowfallIntensity.heavy => 1.0,
    };

    return (count * scale * intensityScale).round().clamp(0, count);
  }

  bool _shouldDrawParticle(
    _SnowParticle particle,
    _LayerCounts visibleCounts,
    int farCount,
    int middleCount,
    int frontCount,
  ) {
    return switch (particle.depthLayer) {
      _SnowDepthLayer.far => farCount < visibleCounts.far,
      _SnowDepthLayer.middle => middleCount < visibleCounts.middle,
      _SnowDepthLayer.front => frontCount < visibleCounts.front,
    };
  }

  double _readabilityFade(double x, double y, Size size) {
    final rightSide = (x / size.width).clamp(0.0, 1.0);
    final menuZone = rightSide > 0.54 ? (rightSide - 0.54) / 0.46 : 0.0;
    final upperZone = y < size.height * 0.72 ? 1.0 : 0.86;

    return (1.0 - menuZone * 0.28) * upperZone;
  }

  double _layerWeight(_SnowDepthLayer depthLayer) {
    return switch (depthLayer) {
      _SnowDepthLayer.far => 0.34,
      _SnowDepthLayer.middle => 0.72,
      _SnowDepthLayer.front => 1.0,
    };
  }

  double _wrapHorizontal(double value, double width) {
    final margin = 40.0;
    final wrapped = (value + margin) % (width + margin * 2);
    return wrapped - margin;
  }

  void _paintFlake(
    Canvas canvas,
    Offset center,
    _SnowParticle particle,
    double opacity,
  ) {
    final tint = particle.depthLayer == _SnowDepthLayer.front
        ? _snowWhite
        : _snowBlue;
    final glowPaint = Paint()
      ..color = tint.withValues(alpha: opacity * 0.34)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.radius * 0.9);
    final corePaint = Paint()
      ..color = tint.withValues(alpha: opacity)
      ..isAntiAlias = true;

    canvas.drawCircle(center, particle.radius * 1.85, glowPaint);
    canvas.drawCircle(center, particle.radius, corePaint);

    if (particle.depthLayer == _SnowDepthLayer.front) {
      final highlightPaint = Paint()
        ..color = _snowWhite.withValues(alpha: opacity * 0.28)
        ..strokeWidth = 0.75
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      final sparkleRadius = particle.radius * 1.35;

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

  @override
  bool shouldRepaint(covariant _SnowfallPainter oldDelegate) {
    return oldDelegate.particles != particles ||
        oldDelegate.intensity != intensity;
  }
}
