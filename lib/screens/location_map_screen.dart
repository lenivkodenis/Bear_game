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

const _lockedPadlockAssetPath = 'assets/images/map/locked_level_padlock.png';

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
      indicatorCenter: Offset(0.118, 0.335),
      hitboxSize: Size(0.17, 0.12),
    ),
    _MapStop(
      location: MapLocation(id: 2, name: 'Ледяная река'),
      center: Offset(0.32, 0.35),
      indicatorCenter: Offset(0.303, 0.318),
      lockedIndicatorCenter: Offset(0.284, 0.356),
      hitboxSize: Size(0.18, 0.12),
    ),
    _MapStop(
      location: MapLocation(id: 3, name: 'Заснеженный берег'),
      center: Offset(0.50, 0.33),
      indicatorCenter: Offset(0.492, 0.306),
      lockedIndicatorCenter: Offset(0.470, 0.346),
      hitboxSize: Size(0.20, 0.12),
    ),
    _MapStop(
      location: MapLocation(id: 4, name: 'Северный лес'),
      center: Offset(0.70, 0.33),
      indicatorCenter: Offset(0.690, 0.306),
      lockedIndicatorCenter: Offset(0.666, 0.346),
      hitboxSize: Size(0.18, 0.12),
    ),
    _MapStop(
      location: MapLocation(id: 5, name: 'Ледяная пещера'),
      center: Offset(0.77, 0.58),
      indicatorCenter: Offset(0.758, 0.548),
      lockedIndicatorCenter: Offset(0.736, 0.588),
      hitboxSize: Size(0.20, 0.12),
    ),
    _MapStop(
      location: MapLocation(id: 6, name: 'Снежная долина'),
      center: Offset(0.46, 0.61),
      indicatorCenter: Offset(0.446, 0.584),
      lockedIndicatorCenter: Offset(0.420, 0.626),
      hitboxSize: Size(0.20, 0.12),
    ),
    _MapStop(
      location: MapLocation(id: 7, name: 'Горный перевал'),
      center: Offset(0.13, 0.60),
      indicatorCenter: Offset(0.122, 0.565),
      lockedIndicatorCenter: Offset(0.100, 0.606),
      hitboxSize: Size(0.20, 0.12),
    ),
    _MapStop(
      location: MapLocation(id: 8, name: 'Полярная ночь'),
      center: Offset(0.09, 0.88),
      indicatorCenter: Offset(0.079, 0.872),
      lockedIndicatorCenter: Offset(0.056, 0.916),
      hitboxSize: Size(0.19, 0.12),
    ),
    _MapStop(
      location: MapLocation(id: 9, name: 'Северное сияние'),
      center: Offset(0.35, 0.92),
      indicatorCenter: Offset(0.365, 0.864),
      lockedIndicatorCenter: Offset(0.328, 0.934),
      hitboxSize: Size(0.21, 0.12),
    ),
    _MapStop(
      location: MapLocation(id: 10, name: 'Северный океан'),
      center: Offset(0.63, 0.90),
      indicatorCenter: Offset(0.646, 0.844),
      lockedIndicatorCenter: Offset(0.602, 0.900),
      hitboxSize: Size(0.21, 0.12),
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
          currentLocationId: _resolveCurrentLocationId(stops, progress),
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

  int? _resolveCurrentLocationId(
    List<_MapStop> stops,
    PlayerProgress progress,
  ) {
    int? currentLocationId;

    for (final stop in stops) {
      final id = stop.location.id;
      final isUnlocked = id <= progress.unlockedLocation;
      if (isUnlocked && !progress.isLevelCompleted(id)) {
        currentLocationId = id;
      }
    }

    return currentLocationId;
  }
}

class _IllustratedProgressionMap extends StatelessWidget {
  const _IllustratedProgressionMap({
    required this.width,
    required this.height,
    required this.imagePath,
    required this.stops,
    required this.progress,
    required this.currentLocationId,
    required this.onOpenLocation,
  });

  final double width;
  final double height;
  final String imagePath;
  final List<_MapStop> stops;
  final PlayerProgress progress;
  final int? currentLocationId;
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
          for (final stop in stops)
            _MapHotspot(
              stop: stop,
              progress: progress,
              currentLocationId: currentLocationId,
              mapSize: Size(width, height),
              onOpenLocation: onOpenLocation,
            ),
        ],
      ),
    );
  }
}

class _MapHotspot extends StatelessWidget {
  const _MapHotspot({
    required this.stop,
    required this.progress,
    required this.currentLocationId,
    required this.mapSize,
    required this.onOpenLocation,
  });

  final _MapStop stop;
  final PlayerProgress progress;
  final int? currentLocationId;
  final Size mapSize;
  final void Function(BuildContext context, MapLocation location)
  onOpenLocation;

  @override
  Widget build(BuildContext context) {
    final isCompleted = progress.isLevelCompleted(stop.location.id);
    final isUnlocked = stop.location.id <= progress.unlockedLocation;
    final state = !isUnlocked
        ? _MapStopState.locked
        : isCompleted
        ? _MapStopState.completed
        : stop.location.id == currentLocationId
        ? _MapStopState.current
        : _MapStopState.open;
    final center = Offset(
      stop.center.dx * mapSize.width,
      stop.center.dy * mapSize.height,
    );
    final indicatorCenter = Offset(
      _indicatorAnchor(state).dx * mapSize.width,
      _indicatorAnchor(state).dy * mapSize.height,
    );
    final hitbox = Size(
      stop.hitboxSize.width * mapSize.width,
      stop.hitboxSize.height * mapSize.height,
    );
    final indicatorSize = (mapSize.width * 0.052).clamp(42.0, 74.0);

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
          left: indicatorCenter.dx - indicatorSize / 2,
          top: indicatorCenter.dy - indicatorSize / 2,
          width: indicatorSize,
          height: indicatorSize,
          child: IgnorePointer(
            child: _MapStatusIndicator(state: state, size: indicatorSize),
          ),
        ),
      ],
    );
  }

  Offset _indicatorAnchor(_MapStopState state) {
    if (state == _MapStopState.locked) {
      return stop.lockedIndicatorCenter ?? stop.indicatorCenter;
    }

    return stop.indicatorCenter;
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
      _MapStopState.current => _CurrentSnowflakeIndicator(size: size),
      _MapStopState.open => const SizedBox.shrink(),
      _MapStopState.locked => _LockedIndicator(size: size),
    };
  }
}

class _CompletedIndicator extends StatelessWidget {
  const _CompletedIndicator({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final badgeSize = size * 0.58;

    return Center(
      child: Transform.rotate(
        angle: -0.16,
        child: SizedBox.square(
          dimension: badgeSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(badgeSize),
                painter: const _CompletedCrystalPainter(),
              ),
              Icon(
                Icons.done_rounded,
                color: AppTheme.deepBlue,
                size: badgeSize * 0.46,
              ),
              Positioned(
                right: -badgeSize * 0.04,
                top: badgeSize * 0.06,
                child: _SparkleDot(size: badgeSize * 0.18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentSnowflakeIndicator extends StatefulWidget {
  const _CurrentSnowflakeIndicator({required this.size});

  final double size;

  @override
  State<_CurrentSnowflakeIndicator> createState() =>
      _CurrentSnowflakeIndicatorState();
}

class _CurrentSnowflakeIndicatorState extends State<_CurrentSnowflakeIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final shimmer = math.sin(progress * math.pi * 2);
        final pulse = 1 + shimmer * 0.055;

        return Transform.scale(
          scale: pulse,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(widget.size),
                painter: _SnowflakeAuraPainter(progress: progress),
              ),
              Transform.rotate(
                angle: progress * math.pi * 2,
                child: Icon(
                  Icons.ac_unit_rounded,
                  color: AppTheme.snowWhite,
                  size: widget.size * 0.66,
                  shadows: [
                    Shadow(
                      color: AppTheme.deepBlue.withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                    Shadow(
                      color: AppTheme.iceBlue.withValues(alpha: 0.85),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: widget.size * 0.12,
                right: widget.size * 0.15,
                child: Transform.scale(
                  scale: 0.75 + (1 - shimmer.abs()) * 0.45,
                  child: _SparkleDot(size: widget.size * 0.16),
                ),
              ),
            ],
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
    final lockSize = size * 0.70;

    return Center(
      child: SizedBox.square(
        dimension: lockSize,
        child: Image.asset(
          _lockedPadlockAssetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _CompletedCrystalPainter extends CustomPainter {
  const _CompletedCrystalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final gemRect = Rect.fromCircle(center: center, radius: radius * 0.88);

    final glowPaint = Paint()
      ..color = AppTheme.iceBlue.withValues(alpha: 0.52)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius * 0.9, glowPaint);

    final gemPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFDDF7FF), Color(0xFF75CDE7)],
      ).createShader(gemRect);

    final outlinePaint = Paint()
      ..color = AppTheme.snowWhite.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.075;

    final path = Path();
    for (var i = 0; i < 6; i += 1) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, gemPaint);
    canvas.drawPath(path, outlinePaint);

    final facetPaint = Paint()
      ..color = AppTheme.snowWhite.withValues(alpha: 0.44)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i += 1) {
      final angle = -math.pi / 6 + i * math.pi / 3;
      final end =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.74;
      canvas.drawLine(center, end, facetPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompletedCrystalPainter oldDelegate) => false;
}

class _SnowflakeAuraPainter extends CustomPainter {
  const _SnowflakeAuraPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final pulse = 0.5 + math.sin(progress * math.pi * 2) * 0.5;

    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.snowWhite.withValues(alpha: 0.72),
          AppTheme.iceBlue.withValues(alpha: 0.45 + pulse * 0.12),
          AppTheme.softBlue.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius * (0.84 + pulse * 0.05), haloPaint);

    final ringPaint = Paint()
      ..color = AppTheme.snowWhite.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.035;
    canvas.drawCircle(center, radius * (0.59 + pulse * 0.04), ringPaint);

    final rayPaint = Paint()
      ..color = AppTheme.iceBlue.withValues(alpha: 0.82)
      ..strokeWidth = size.shortestSide * 0.024
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-progress * math.pi * 0.8);
    for (var i = 0; i < 6; i += 1) {
      canvas.rotate(math.pi / 3);
      canvas.drawLine(
        Offset(0, -radius * 0.56),
        Offset(0, -radius * 0.73),
        rayPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SnowflakeAuraPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SparkleDot extends StatelessWidget {
  const _SparkleDot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _SparklePainter()),
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = AppTheme.snowWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);

    final glowPaint = Paint()
      ..color = AppTheme.iceBlue.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, size.shortestSide * 0.18, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => false;
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
    required this.indicatorCenter,
    required this.hitboxSize,
    this.lockedIndicatorCenter,
  });

  final MapLocation location;
  final Offset center;
  final Offset indicatorCenter;
  final Offset? lockedIndicatorCenter;
  final Size hitboxSize;
}

enum _MapStopState { completed, current, open, locked }

class _LocationMapData {
  const _LocationMapData({required this.progress});

  final PlayerProgress progress;

  factory _LocationMapData.empty(PlayerProgress progress) {
    return _LocationMapData(progress: progress);
  }
}
