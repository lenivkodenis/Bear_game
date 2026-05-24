import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/map_location.dart';
import '../models/player_progress.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/back_text_button.dart';
import '../widgets/score_badge.dart';
import 'game_screen.dart';

class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({super.key});

  static const routeName = '/map';

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  static const _mapAssetPath = 'assets/images/map/progression_map.png';
  static const _mapAspectRatio = 1672 / 941;

  final ProgressService _progressService = ProgressService();
  late Future<_LocationMapData> _mapDataFuture;

  static const _locations = [
    _MapStop(
      location: MapLocation(id: 1, name: 'Льдина'),
      center: Offset(0.12, 0.33),
      markerCenter: Offset(0.115, 0.315),
      hitboxSize: Size(0.17, 0.12),
      mistCenter: Offset(0.11, 0.25),
      mistSize: Size(0.20, 0.18),
    ),
    _MapStop(
      location: MapLocation(id: 2, name: 'Ледяная река'),
      center: Offset(0.32, 0.35),
      markerCenter: Offset(0.305, 0.345),
      hitboxSize: Size(0.18, 0.12),
      mistCenter: Offset(0.33, 0.24),
      mistSize: Size(0.27, 0.22),
    ),
    _MapStop(
      location: MapLocation(id: 3, name: 'Заснеженный берег'),
      center: Offset(0.50, 0.33),
      markerCenter: Offset(0.485, 0.325),
      hitboxSize: Size(0.20, 0.12),
      mistCenter: Offset(0.50, 0.23),
      mistSize: Size(0.28, 0.22),
    ),
    _MapStop(
      location: MapLocation(id: 4, name: 'Северный лес'),
      center: Offset(0.70, 0.33),
      markerCenter: Offset(0.655, 0.325),
      hitboxSize: Size(0.18, 0.12),
      mistCenter: Offset(0.73, 0.23),
      mistSize: Size(0.30, 0.23),
    ),
    _MapStop(
      location: MapLocation(id: 5, name: 'Ледяная пещера'),
      center: Offset(0.77, 0.58),
      markerCenter: Offset(0.728, 0.575),
      hitboxSize: Size(0.20, 0.12),
      mistCenter: Offset(0.80, 0.47),
      mistSize: Size(0.31, 0.25),
    ),
    _MapStop(
      location: MapLocation(id: 6, name: 'Снежная долина'),
      center: Offset(0.46, 0.61),
      markerCenter: Offset(0.435, 0.608),
      hitboxSize: Size(0.20, 0.12),
      mistCenter: Offset(0.49, 0.49),
      mistSize: Size(0.32, 0.24),
    ),
    _MapStop(
      location: MapLocation(id: 7, name: 'Горный перевал'),
      center: Offset(0.13, 0.60),
      markerCenter: Offset(0.095, 0.585),
      hitboxSize: Size(0.20, 0.12),
      mistCenter: Offset(0.17, 0.49),
      mistSize: Size(0.32, 0.25),
    ),
    _MapStop(
      location: MapLocation(id: 8, name: 'Полярная ночь'),
      center: Offset(0.09, 0.88),
      markerCenter: Offset(0.075, 0.875),
      hitboxSize: Size(0.19, 0.12),
      mistCenter: Offset(0.14, 0.78),
      mistSize: Size(0.30, 0.26),
    ),
    _MapStop(
      location: MapLocation(id: 9, name: 'Северное сияние'),
      center: Offset(0.35, 0.92),
      markerCenter: Offset(0.335, 0.915),
      hitboxSize: Size(0.21, 0.12),
      mistCenter: Offset(0.38, 0.79),
      mistSize: Size(0.32, 0.27),
    ),
    _MapStop(
      location: MapLocation(id: 10, name: 'Северный океан'),
      center: Offset(0.63, 0.90),
      markerCenter: Offset(0.585, 0.895),
      hitboxSize: Size(0.21, 0.12),
      mistCenter: Offset(0.66, 0.79),
      mistSize: Size(0.34, 0.27),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _mapDataFuture = _loadMapData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: AppTheme.nightSnowyGradient,
        child: SafeArea(
          child: FutureBuilder<_LocationMapData>(
            future: _mapDataFuture,
            builder: (context, snapshot) {
              final mapData =
                  snapshot.data ??
                  _LocationMapData.empty(PlayerProgress.initial());

              return Stack(
                children: [
                  Positioned.fill(
                    child: _MapViewport(
                      imagePath: _mapAssetPath,
                      aspectRatio: _mapAspectRatio,
                      stops: _locations,
                      progress: mapData.progress,
                      onOpenLocation: _openLocation,
                    ),
                  ),
                  const Positioned(
                    top: 12,
                    left: 12,
                    child: _GlassPanel(child: BackTextButton()),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _MapHud(progress: mapData.progress),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<_LocationMapData> _loadMapData() async {
    final progress = await _progressService.loadProgress();

    return _LocationMapData(progress: progress);
  }

  void _openLocation(BuildContext context, MapLocation location) {
    Navigator.of(
      context,
    ).pushNamed(GameScreen.routeName, arguments: location.id);
  }
}

class _MapViewport extends StatelessWidget {
  const _MapViewport({
    required this.imagePath,
    required this.aspectRatio,
    required this.stops,
    required this.progress,
    required this.onOpenLocation,
  });

  final String imagePath;
  final double aspectRatio;
  final List<_MapStop> stops;
  final PlayerProgress progress;
  final void Function(BuildContext context, MapLocation location)
  onOpenLocation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;
        final maxMapWidth = math.min(
          constraints.maxWidth - 24,
          (constraints.maxHeight - 24) * aspectRatio,
        );
        final mapWidth = isCompact ? 980.0 : maxMapWidth.clamp(720.0, 1500.0);
        final mapHeight = mapWidth / aspectRatio;
        final map = _IllustratedProgressionMap(
          width: mapWidth,
          height: mapHeight,
          imagePath: imagePath,
          stops: stops,
          progress: progress,
          onOpenLocation: onOpenLocation,
        );

        if (isCompact || mapHeight > constraints.maxHeight) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: map,
            ),
          );
        }

        return Center(child: map);
      },
    );
  }
}

class _IllustratedProgressionMap extends StatelessWidget {
  const _IllustratedProgressionMap({
    required this.width,
    required this.height,
    required this.imagePath,
    required this.stops,
    required this.progress,
    required this.onOpenLocation,
  });

  final double width;
  final double height;
  final String imagePath;
  final List<_MapStop> stops;
  final PlayerProgress progress;
  final void Function(BuildContext context, MapLocation location)
  onOpenLocation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              imagePath,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
          _LockedMapRegionsOverlay(
            stops: stops,
            progress: progress,
            mapSize: Size(width, height),
          ),
          for (final stop in stops)
            _MapHotspot(
              stop: stop,
              progress: progress,
              mapSize: Size(width, height),
              onOpenLocation: onOpenLocation,
            ),
        ],
      ),
    );
  }
}

class _LockedMapRegionsOverlay extends StatelessWidget {
  const _LockedMapRegionsOverlay({
    required this.stops,
    required this.progress,
    required this.mapSize,
  });

  final List<_MapStop> stops;
  final PlayerProgress progress;
  final Size mapSize;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final stop in stops)
            if (stop.location.id > progress.unlockedLocation)
              _LockedMapRegion(stop: stop, mapSize: mapSize),
        ],
      ),
    );
  }
}

class _LockedMapRegion extends StatelessWidget {
  const _LockedMapRegion({required this.stop, required this.mapSize});

  final _MapStop stop;
  final Size mapSize;

  @override
  Widget build(BuildContext context) {
    final regionCenter = Offset(
      stop.mistCenter.dx * mapSize.width,
      stop.mistCenter.dy * mapSize.height,
    );
    final regionSize = Size(
      stop.mistSize.width * mapSize.width,
      stop.mistSize.height * mapSize.height,
    );
    final labelCenter = Offset(
      stop.center.dx * mapSize.width,
      stop.center.dy * mapSize.height,
    );
    final labelSize = Size(
      stop.hitboxSize.width * mapSize.width,
      stop.hitboxSize.height * mapSize.height,
    );
    final regionOrigin = Offset(
      regionCenter.dx - regionSize.width / 2,
      regionCenter.dy - regionSize.height / 2,
    );
    final labelClearRect = Rect.fromCenter(
      center: labelCenter - regionOrigin,
      width: labelSize.width * 1.04,
      height: labelSize.height * 0.88,
    );

    return Positioned(
      left: regionCenter.dx - regionSize.width / 2,
      top: regionCenter.dy - regionSize.height / 2,
      width: regionSize.width,
      height: regionSize.height,
      child: _FrozenMistRegion(
        seed: stop.location.id,
        density: stop.location.id >= 8 ? 0.58 : 0.5,
        labelClearRect: labelClearRect,
      ),
    );
  }
}

class _MapHotspot extends StatelessWidget {
  const _MapHotspot({
    required this.stop,
    required this.progress,
    required this.mapSize,
    required this.onOpenLocation,
  });

  final _MapStop stop;
  final PlayerProgress progress;
  final Size mapSize;
  final void Function(BuildContext context, MapLocation location)
  onOpenLocation;

  @override
  Widget build(BuildContext context) {
    final isCompleted = progress.isLevelCompleted(stop.location.id);
    final isUnlocked = stop.location.id <= progress.unlockedLocation;
    final state = isCompleted
        ? _MapStopState.completed
        : isUnlocked
        ? _MapStopState.available
        : _MapStopState.locked;
    final center = Offset(
      stop.center.dx * mapSize.width,
      stop.center.dy * mapSize.height,
    );
    final markerCenter = Offset(
      stop.markerCenter.dx * mapSize.width,
      stop.markerCenter.dy * mapSize.height,
    );
    final hitbox = Size(
      stop.hitboxSize.width * mapSize.width,
      stop.hitboxSize.height * mapSize.height,
    );
    final indicatorSize = switch (state) {
      _MapStopState.available => (mapSize.width * 0.044).clamp(36.0, 58.0),
      _MapStopState.completed => (mapSize.width * 0.046).clamp(38.0, 62.0),
      _MapStopState.locked => (mapSize.width * 0.043).clamp(34.0, 56.0),
    };

    return Stack(
      children: [
        Positioned(
          left: center.dx - hitbox.width / 2,
          top: center.dy - hitbox.height / 2,
          width: hitbox.width,
          height: hitbox.height,
          child: Tooltip(
            message: '${stop.location.id}. ${stop.location.name}',
            child: Semantics(
              button: isUnlocked,
              enabled: isUnlocked,
              label: '${stop.location.id}. ${stop.location.name}',
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: isUnlocked
                    ? () => onOpenLocation(context, stop.location)
                    : null,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        Positioned(
          left: markerCenter.dx - indicatorSize / 2,
          top: markerCenter.dy - indicatorSize / 2,
          width: indicatorSize,
          height: indicatorSize,
          child: IgnorePointer(
            child: _MapStatusIndicator(state: state, size: indicatorSize),
          ),
        ),
      ],
    );
  }
}

class _MapStatusIndicator extends StatelessWidget {
  const _MapStatusIndicator({required this.state, required this.size});

  final _MapStopState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      _MapStopState.completed => _CompletedIndicator(size: size),
      _MapStopState.available => _AvailableIndicator(size: size),
      _MapStopState.locked => _LockedIndicator(size: size),
    };
  }
}

class _CompletedIndicator extends StatelessWidget {
  const _CompletedIndicator({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.snowWhite,
          border: Border.all(color: AppTheme.warmYellow, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.warmYellow.withValues(alpha: 0.36),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: SizedBox.square(
          dimension: size * 0.42,
          child: const Icon(
            Icons.check_rounded,
            color: AppTheme.warmYellow,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _AvailableIndicator extends StatefulWidget {
  const _AvailableIndicator({required this.size});

  final double size;

  @override
  State<_AvailableIndicator> createState() => _AvailableIndicatorState();
}

class _AvailableIndicatorState extends State<_AvailableIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = 0.34 + _pulse.value * 0.16;
        final scale = 0.96 + _pulse.value * 0.05;

        return Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.snowWhite.withValues(alpha: 0.18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.iceBlue.withValues(alpha: glow),
                  blurRadius: widget.size * 0.34,
                  spreadRadius: widget.size * 0.08,
                ),
                BoxShadow(
                  color: AppTheme.gentleGreen.withValues(alpha: 0.26),
                  blurRadius: widget.size * 0.24,
                  spreadRadius: widget.size * 0.03,
                ),
              ],
            ),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.snowWhite.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.iceBlue.withValues(alpha: 0.94),
                    width: 1.6,
                  ),
                ),
                child: SizedBox.square(
                  dimension: widget.size * 0.48,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: AppTheme.softBlue,
                    size: widget.size * 0.30,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LockedIndicator extends StatelessWidget {
  const _LockedIndicator({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.snowWhite.withValues(alpha: 0.82),
          border: Border.all(color: AppTheme.lockedPanel, width: 2),
        ),
        child: SizedBox.square(
          dimension: size * 0.44,
          child: const Icon(
            Icons.lock_rounded,
            color: AppTheme.lockedBlue,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _FrozenMistRegion extends StatelessWidget {
  const _FrozenMistRegion({
    required this.seed,
    required this.density,
    required this.labelClearRect,
  });

  final int seed;
  final double density;
  final Rect labelClearRect;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _OrganicMistClipper(seed: seed, labelClearRect: labelClearRect),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 1.1 + density * 1.2,
          sigmaY: 1.1 + density * 1.2,
        ),
        child: CustomPaint(
          painter: _FrozenMistRegionPainter(
            seed: seed,
            density: density,
            labelClearRect: labelClearRect,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _OrganicMistClipper extends CustomClipper<Path> {
  const _OrganicMistClipper({required this.seed, required this.labelClearRect});

  final int seed;
  final Rect labelClearRect;

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final points = <Offset>[];
    const count = 18;

    for (var i = 0; i < count; i += 1) {
      final angle = math.pi * 2 * i / count;
      final wobble =
          0.82 +
          math.sin(seed * 0.71 + i * 1.37) * 0.10 +
          math.cos(seed * 1.19 + i * 0.83) * 0.08;
      final radiusX = size.width * 0.47 * wobble;
      final radiusY = size.height * 0.43 * (1.04 - (wobble - 0.82) * 0.28);
      points.add(
        center.translate(math.cos(angle) * radiusX, math.sin(angle) * radiusY),
      );
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length; i += 1) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      final control = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, control.dx, control.dy);
    }
    final organicPath = path..close();
    final clearPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          labelClearRect.inflate(size.shortestSide * 0.04),
          Radius.circular(size.shortestSide * 0.12),
        ),
      );

    return Path.combine(PathOperation.difference, organicPath, clearPath);
  }

  @override
  bool shouldReclip(covariant _OrganicMistClipper oldClipper) {
    return oldClipper.seed != seed ||
        oldClipper.labelClearRect != labelClearRect;
  }
}

class _FrozenMistRegionPainter extends CustomPainter {
  const _FrozenMistRegionPainter({
    required this.seed,
    required this.density,
    required this.labelClearRect,
  });

  final int seed;
  final double density;
  final Rect labelClearRect;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final basePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.12, -0.18),
        radius: 0.92,
        colors: [
          AppTheme.snowWhite.withValues(alpha: 0.34 * density),
          AppTheme.frostBlue.withValues(alpha: 0.22 * density),
          AppTheme.iceBlue.withValues(alpha: 0.10 * density),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 0.74, 1.0],
      ).createShader(Offset.zero & size);
    final snowPaint = Paint()
      ..color = AppTheme.snowWhite.withValues(alpha: 0.16 * density)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        size.shortestSide * 0.08,
      );
    final blueMistPaint = Paint()
      ..color = AppTheme.iceBlue.withValues(alpha: 0.10 * density)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        size.shortestSide * 0.10,
      );
    final sparklePaint = Paint()
      ..color = AppTheme.snowWhite.withValues(alpha: 0.38 * density)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;

    canvas.drawRect(Offset.zero & size, basePaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-size.width * 0.10, -size.height * 0.04),
        width: size.width * 0.82,
        height: size.height * 0.48,
      ),
      snowPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(size.width * 0.16, size.height * 0.02),
        width: size.width * 0.64,
        height: size.height * 0.58,
      ),
      blueMistPaint,
    );

    for (var i = 0; i < 10; i += 1) {
      final t = (seed * 37 + i * 19) % 100 / 100.0;
      final u = (seed * 53 + i * 23) % 100 / 100.0;
      final blobCenter = Offset(
        size.width * (0.12 + t * 0.76),
        size.height * (0.16 + u * 0.64),
      );
      final blobWidth = size.width * (0.18 + ((i + seed) % 4) * 0.045);
      final blobHeight = size.height * (0.18 + ((i + seed) % 3) * 0.055);
      canvas.drawOval(
        Rect.fromCenter(
          center: blobCenter,
          width: blobWidth,
          height: blobHeight,
        ),
        i.isEven ? snowPaint : blueMistPaint,
      );
    }

    final driftPaint = Paint()
      ..color = AppTheme.snowWhite.withValues(alpha: 0.18 * density)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.2, size.shortestSide * 0.012)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        size.shortestSide * 0.018,
      );
    for (var i = 0; i < 4; i += 1) {
      final y = size.height * (0.25 + i * 0.14);
      final path = Path()
        ..moveTo(size.width * 0.06, y)
        ..cubicTo(
          size.width * 0.27,
          y - size.height * (0.12 + i * 0.01),
          size.width * 0.54,
          y + size.height * (0.10 - i * 0.01),
          size.width * 0.93,
          y - size.height * 0.03,
        );
      canvas.drawPath(path, driftPaint);
    }

    for (var i = 0; i < 15; i += 1) {
      final t = (seed * 29 + i * 17) % 100 / 100.0;
      final u = (seed * 41 + i * 31) % 100 / 100.0;
      final point = Offset(size.width * t, size.height * u);
      final radius = size.shortestSide * (i.isEven ? 0.014 : 0.009);
      canvas.drawCircle(point, radius, sparklePaint);
      if (i % 4 == 0) {
        canvas.drawLine(
          point.translate(-radius * 1.6, 0),
          point.translate(radius * 1.6, 0),
          sparklePaint,
        );
        canvas.drawLine(
          point.translate(0, -radius * 1.6),
          point.translate(0, radius * 1.6),
          sparklePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FrozenMistRegionPainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.density != density ||
        oldDelegate.labelClearRect != labelClearRect;
  }
}

class _MapHud extends StatelessWidget {
  const _MapHud({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          ScoreBadge(score: progress.score, compact: true),
          _SmallMapBadge(
            icon: Icons.flag_rounded,
            value: '${progress.unlockedLocation.clamp(1, 10)}/10',
          ),
          _SmallMapBadge(
            icon: Icons.check_rounded,
            value: '${progress.completedLevelIds.length}/10',
          ),
        ],
      ),
    );
  }
}

class _SmallMapBadge extends StatelessWidget {
  const _SmallMapBadge({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.snowWhite.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.iceBlue, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.gentleGreen, size: 18),
            const SizedBox(width: 5),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.deepBlue,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.snowWhite.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.snowWhite.withValues(alpha: 0.65),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MapStop {
  const _MapStop({
    required this.location,
    required this.center,
    required this.markerCenter,
    required this.hitboxSize,
    required this.mistCenter,
    required this.mistSize,
  });

  final MapLocation location;
  final Offset center;
  final Offset markerCenter;
  final Size hitboxSize;
  final Offset mistCenter;
  final Size mistSize;
}

enum _MapStopState { completed, available, locked }

class _LocationMapData {
  const _LocationMapData({required this.progress});

  final PlayerProgress progress;

  factory _LocationMapData.empty(PlayerProgress progress) {
    return _LocationMapData(progress: progress);
  }
}
