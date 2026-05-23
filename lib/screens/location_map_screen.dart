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
  final ProgressService _progressService = ProgressService();
  late Future<_LocationMapData> _mapDataFuture;

  static const _locations = [
    _MapStop(
      location: MapLocation(id: 1, name: 'Льдина'),
      position: Offset(0.14, 0.23),
      accent: Color(0xFF4DBDD7),
      icon: Icons.ac_unit_rounded,
      table: 1,
      mentorName: 'Морская чайка',
    ),
    _MapStop(
      location: MapLocation(id: 2, name: 'Ледяная река'),
      position: Offset(0.33, 0.36),
      accent: Color(0xFF2F9FD0),
      icon: Icons.water_rounded,
      table: 2,
      mentorName: 'Бобёр',
    ),
    _MapStop(
      location: MapLocation(id: 3, name: 'Заснеженный берег'),
      position: Offset(0.53, 0.34),
      accent: Color(0xFF72B8D8),
      icon: Icons.landscape_rounded,
      table: 3,
      mentorName: 'Тюлень',
    ),
    _MapStop(
      location: MapLocation(id: 4, name: 'Северный лес'),
      position: Offset(0.76, 0.31),
      accent: Color(0xFF3E927D),
      icon: Icons.park_rounded,
      table: 4,
      mentorName: 'Сова',
    ),
    _MapStop(
      location: MapLocation(id: 5, name: 'Ледяная пещера'),
      position: Offset(0.80, 0.58),
      accent: Color(0xFF00A8D8),
      icon: Icons.diamond_rounded,
      table: 5,
      mentorName: 'Песец',
    ),
    _MapStop(
      location: MapLocation(id: 6, name: 'Снежная долина'),
      position: Offset(0.50, 0.62),
      accent: Color(0xFF69B6D3),
      icon: Icons.waves_rounded,
      table: 6,
      mentorName: 'Олень',
    ),
    _MapStop(
      location: MapLocation(id: 7, name: 'Горный перевал'),
      position: Offset(0.18, 0.58),
      accent: Color(0xFF748EA4),
      icon: Icons.terrain_rounded,
      table: 7,
      mentorName: 'Горный козлик',
    ),
    _MapStop(
      location: MapLocation(id: 8, name: 'Полярная ночь'),
      position: Offset(0.15, 0.86),
      accent: Color(0xFF284C8E),
      icon: Icons.nightlight_round,
      table: 8,
      mentorName: 'Волк',
    ),
    _MapStop(
      location: MapLocation(id: 9, name: 'Северное сияние'),
      position: Offset(0.39, 0.88),
      accent: Color(0xFF45C6A4),
      icon: Icons.auto_awesome_rounded,
      table: 9,
      mentorName: 'Нарвал',
    ),
    _MapStop(
      location: MapLocation(id: 10, name: 'Северный океан'),
      position: Offset(0.68, 0.86),
      accent: Color(0xFF1C8EB4),
      icon: Icons.sailing_rounded,
      table: 10,
      mentorName: 'Мама-медведица',
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
      appBar: AppBar(
        leading: const BackTextButton(),
        title: const Text('Карта'),
      ),
      body: DecoratedBox(
        decoration: AppTheme.snowyGradient,
        child: FutureBuilder<_LocationMapData>(
          future: _mapDataFuture,
          builder: (context, snapshot) {
            final mapData =
                snapshot.data ??
                _LocationMapData.empty(PlayerProgress.initial());

            return LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 760;
                final mapWidth = isCompact
                    ? 980.0
                    : (constraints.maxWidth - 48).clamp(980.0, 1180.0);
                final mapHeight = mapWidth * 0.58;

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 12 : 24,
                    12,
                    isCompact ? 12 : 24,
                    24,
                  ),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: _MapHeader(progress: mapData.progress),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: mapWidth,
                        height: mapHeight,
                        child: _ProgressionMap(
                          stops: _locations,
                          progress: mapData.progress,
                          onOpenLocation: _openLocation,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
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

class _MapHeader extends StatelessWidget {
  const _MapHeader({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.snowWhite.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.iceBlue.withValues(alpha: 0.75),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.softShadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 14,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Путь медвежонка домой',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.deepBlue,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Открытые точки можно пройти сейчас, закрытые ждут дальше по маршруту.',
                    style: AppTheme.helperStyle.copyWith(
                      color: AppTheme.lockedBlue,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ScoreBadge(score: progress.score, compact: true),
                _MapBadge(
                  icon: Icons.flag_rounded,
                  label: 'Открыто',
                  value: '${progress.unlockedLocation.clamp(1, 10)}/10',
                ),
                _MapBadge(
                  icon: Icons.star_rounded,
                  label: 'Пройдено',
                  value: '${progress.completedLevelIds.length}/10',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressionMap extends StatelessWidget {
  const _ProgressionMap({
    required this.stops,
    required this.progress,
    required this.onOpenLocation,
  });

  final List<_MapStop> stops;
  final PlayerProgress progress;
  final void Function(BuildContext context, MapLocation location)
  onOpenLocation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepBlue.withValues(alpha: 0.22),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _MapArtPainter()),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RoutePainter(
                      stops: stops,
                      unlockedLocation: progress.unlockedLocation,
                    ),
                  ),
                ),
                for (final stop in stops)
                  _buildMarkerPositioned(context, constraints, stop),
                const Positioned(top: 34, right: 34, child: _CompassRose()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMarkerPositioned(
    BuildContext context,
    BoxConstraints constraints,
    _MapStop stop,
  ) {
    final isCompleted = progress.isLevelCompleted(stop.location.id);
    final isUnlocked = stop.location.id <= progress.unlockedLocation;
    final state = isCompleted
        ? _MapStopState.completed
        : isUnlocked
        ? _MapStopState.available
        : _MapStopState.locked;
    final isAvailable = state == _MapStopState.available;
    final width = isAvailable ? 252.0 : 230.0;
    final height = isAvailable ? 104.0 : 96.0;

    return Positioned(
      left: stop.position.dx * constraints.maxWidth - width / 2,
      top: stop.position.dy * constraints.maxHeight - height / 2,
      width: width,
      height: height,
      child: _MapMarker(
        stop: stop,
        state: state,
        onTap: isUnlocked ? () => onOpenLocation(context, stop.location) : null,
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.stop,
    required this.state,
    required this.onTap,
  });

  final _MapStop stop;
  final _MapStopState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isLocked = state == _MapStopState.locked;
    final isCompleted = state == _MapStopState.completed;
    final isAvailable = state == _MapStopState.available;
    final badgeColor = isCompleted
        ? AppTheme.warmYellow
        : isAvailable
        ? stop.accent
        : AppTheme.lockedBlue;
    final plaqueColor = isLocked
        ? const Color(0xFFE7EEF2)
        : const Color(0xFFFFF2D2);
    final foreground = isLocked ? AppTheme.lockedBlue : AppTheme.deepBlue;
    final statusIcon = isCompleted
        ? Icons.check_rounded
        : isLocked
        ? Icons.lock_rounded
        : Icons.play_arrow_rounded;

    Widget marker = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            Positioned(
              left: 35,
              right: 0,
              top: 18,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: plaqueColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isLocked
                        ? AppTheme.lockedPanel
                        : const Color(0xFFC8A873),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.deepBlue.withValues(
                        alpha: isLocked ? 0.06 : 0.18,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(42, 8, 12, 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.location.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(stop.icon, color: badgeColor, size: 15),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '${_statusText(state)}  ×${stop.table}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: foreground.withValues(alpha: 0.75),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor,
                  border: Border.all(
                    color: isLocked
                        ? const Color(0xFFC4D0D6)
                        : const Color(0xFFFFE0A4),
                    width: 3,
                  ),
                  boxShadow: [
                    if (isAvailable)
                      BoxShadow(
                        color: stop.accent.withValues(alpha: 0.5),
                        blurRadius: 22,
                        spreadRadius: 5,
                      ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox.square(
                  dimension: isAvailable ? 64 : 58,
                  child: Center(
                    child: Text(
                      stop.location.id.toString(),
                      style: const TextStyle(
                        color: AppTheme.snowWhite,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: isAvailable ? 48 : 43,
              top: isAvailable ? 2 : 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.snowWhite,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(statusIcon, color: badgeColor, size: 15),
                ),
              ),
            ),
            if (isAvailable)
              Positioned(
                left: 3,
                bottom: -2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.snowWhite,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: stop.accent.withValues(alpha: 0.42),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pets_rounded, color: stop.accent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'текущий шаг',
                          style: TextStyle(
                            color: stop.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (isLocked) {
      marker = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 0.45, sigmaY: 0.45),
        child: Opacity(opacity: 0.72, child: marker),
      );
    }

    return Tooltip(message: stop.mentorName, child: marker);
  }

  String _statusText(_MapStopState state) {
    return switch (state) {
      _MapStopState.completed => 'Пройдено',
      _MapStopState.available => 'Доступно',
      _MapStopState.locked => 'Закрыто',
    };
  }
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.snowWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.iceBlue, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.gentleGreen, size: 22),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.helperStyle.copyWith(fontSize: 11)),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.deepBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompassRose extends StatelessWidget {
  const _CompassRose();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.48,
      child: SizedBox.square(
        dimension: 74,
        child: CustomPaint(painter: _CompassPainter()),
      ),
    );
  }
}

class _MapArtPainter extends CustomPainter {
  const _MapArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final parchment = RRect.fromRectAndRadius(
      rect.deflate(6),
      const Radius.circular(30),
    );

    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF3D6), Color(0xFFEAF8FE), Color(0xFFFFF8EA)],
      ).createShader(rect);
    canvas.drawRRect(parchment, basePaint);

    _drawParchmentEdge(canvas, size);
    _drawMapRegions(canvas, size);
    _drawSnowTexture(canvas, size);
  }

  void _drawParchmentEdge(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFBFDDF0).withValues(alpha: 0.86);
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF8BAFC6).withValues(alpha: 0.32);

    final border = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(10),
      const Radius.circular(28),
    );
    canvas.drawRRect(border, edgePaint);
    canvas.drawRRect(border.deflate(12), innerPaint);

    final cornerPaint = Paint()
      ..color = const Color(0xFFFFF1D0).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(28, 28), 38, cornerPaint);
    canvas.drawCircle(Offset(size.width - 28, 28), 38, cornerPaint);
    canvas.drawCircle(Offset(28, size.height - 28), 38, cornerPaint);
  }

  void _drawMapRegions(Canvas canvas, Size size) {
    _drawWater(canvas, size);
    _drawMountains(canvas, size);
    _drawForest(canvas, size);
    _drawCave(canvas, size);
    _drawPolarNight(canvas, size);
    _drawAurora(canvas, size);
    _drawOcean(canvas, size);
  }

  void _drawWater(Canvas canvas, Size size) {
    final waterPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF34B8D6).withValues(alpha: 0.66),
          const Color(0xFFB8F4FF).withValues(alpha: 0.36),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.42));
    final path = Path()
      ..moveTo(size.width * 0.03, size.height * 0.28)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.08,
        size.width * 0.30,
        size.height * 0.38,
        size.width * 0.44,
        size.height * 0.18,
      )
      ..cubicTo(
        size.width * 0.55,
        size.height * 0.03,
        size.width * 0.62,
        size.height * 0.22,
        size.width * 0.72,
        size.height * 0.12,
      )
      ..lineTo(size.width * 0.78, size.height * 0.22)
      ..cubicTo(
        size.width * 0.64,
        size.height * 0.34,
        size.width * 0.53,
        size.height * 0.30,
        size.width * 0.41,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.60,
        size.width * 0.14,
        size.height * 0.39,
        size.width * 0.03,
        size.height * 0.45,
      )
      ..close();
    canvas.drawPath(path, waterPaint);

    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppTheme.snowWhite.withValues(alpha: 0.45);
    for (var i = 0; i < 7; i += 1) {
      final y = size.height * (0.16 + i * 0.035);
      canvas.drawArc(
        Rect.fromLTWH(size.width * (0.16 + i * 0.055), y, 120, 34),
        0.15,
        math.pi * 0.78,
        false,
        ripplePaint,
      );
    }
  }

  void _drawMountains(Canvas canvas, Size size) {
    final shadow = Paint()..color = const Color(0xFF7D91A3);
    final snow = Paint()..color = AppTheme.snowWhite.withValues(alpha: 0.96);
    final blueSnow = Paint()
      ..color = const Color(0xFFC9E8F5).withValues(alpha: 0.88);

    void mountain(double x, double y, double w, double h) {
      final path = Path()
        ..moveTo(x, y + h)
        ..lineTo(x + w * 0.5, y)
        ..lineTo(x + w, y + h)
        ..close();
      canvas.drawPath(path, shadow);
      final snowCap = Path()
        ..moveTo(x + w * 0.5, y)
        ..lineTo(x + w * 0.28, y + h * 0.48)
        ..lineTo(x + w * 0.47, y + h * 0.34)
        ..lineTo(x + w * 0.58, y + h * 0.56)
        ..lineTo(x + w * 0.72, y + h * 0.46)
        ..close();
      canvas.drawPath(snowCap, snow);
      canvas.drawPath(
        Path()
          ..moveTo(x + w * 0.5, y)
          ..lineTo(x + w * 0.78, y + h)
          ..lineTo(x + w, y + h)
          ..close(),
        blueSnow,
      );
    }

    mountain(size.width * 0.08, size.height * 0.42, 150, 155);
    mountain(size.width * 0.23, size.height * 0.46, 110, 105);
    mountain(size.width * 0.42, size.height * 0.38, 190, 145);
    mountain(size.width * 0.58, size.height * 0.39, 135, 112);
  }

  void _drawForest(Canvas canvas, Size size) {
    final trunkPaint = Paint()..color = const Color(0xFF7A5A3B);
    final treePaint = Paint()..color = const Color(0xFF2D796D);
    final snowPaint = Paint()
      ..color = AppTheme.snowWhite.withValues(alpha: 0.86);

    for (var i = 0; i < 15; i += 1) {
      final x = size.width * (0.67 + (i % 5) * 0.045);
      final y = size.height * (0.16 + (i ~/ 5) * 0.065);
      final scale = 0.78 + (i % 3) * 0.14;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, y + 46 * scale),
          width: 8 * scale,
          height: 28 * scale,
        ),
        trunkPaint,
      );
      for (var tier = 0; tier < 3; tier += 1) {
        final top = y + tier * 18 * scale;
        final path = Path()
          ..moveTo(x, top)
          ..lineTo(x - (28 - tier * 5) * scale, top + 34 * scale)
          ..lineTo(x + (28 - tier * 5) * scale, top + 34 * scale)
          ..close();
        canvas.drawPath(path, treePaint);
        canvas.drawLine(
          Offset(x - (18 - tier * 3) * scale, top + 18 * scale),
          Offset(x + (16 - tier * 3) * scale, top + 15 * scale),
          Paint()
            ..color = snowPaint.color
            ..strokeWidth = 3 * scale
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _drawCave(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.83, size.height * 0.49);
    final cavePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF05D5FF), Color(0xFF0371B8), Color(0xFFBFEAFF)],
      ).createShader(Rect.fromCircle(center: center, radius: 150));
    final cave = Path()
      ..moveTo(center.dx - 122, center.dy + 96)
      ..cubicTo(
        center.dx - 108,
        center.dy - 70,
        center.dx + 110,
        center.dy - 88,
        center.dx + 130,
        center.dy + 92,
      )
      ..close();
    canvas.drawPath(cave, cavePaint);
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(16, 36), width: 92, height: 120),
      Paint()..color = const Color(0xFF0A3761).withValues(alpha: 0.75),
    );
    for (var i = 0; i < 7; i += 1) {
      final x = center.dx - 92 + i * 30;
      canvas.drawLine(
        Offset(x, center.dy - 58),
        Offset(x + 10, center.dy - 8 + (i % 2) * 14),
        Paint()
          ..color = AppTheme.snowWhite.withValues(alpha: 0.78)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawPolarNight(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.04,
      size.height * 0.68,
      size.width * 0.28,
      size.height * 0.25,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(34)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF071A48), Color(0xFF133C7A)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(rect.left + 58, rect.top + 42),
      18,
      Paint()..color = const Color(0xFFFFF0A6),
    );
    canvas.drawCircle(
      Offset(rect.left + 68, rect.top + 35),
      18,
      Paint()..color = const Color(0xFF071A48),
    );
    for (var i = 0; i < 18; i += 1) {
      canvas.drawCircle(
        Offset(
          rect.left + 18 + (i * 37) % rect.width,
          rect.top + 18 + (i * 29) % rect.height,
        ),
        i.isEven ? 2.0 : 1.3,
        Paint()..color = AppTheme.snowWhite.withValues(alpha: 0.82),
      );
    }
  }

  void _drawAurora(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.33,
      size.height * 0.67,
      size.width * 0.28,
      size.height * 0.23,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(36)),
      Paint()..color = const Color(0xFF113E65).withValues(alpha: 0.78),
    );
    for (var i = 0; i < 5; i += 1) {
      final path = Path()
        ..moveTo(rect.left + 35 + i * 36, rect.bottom)
        ..cubicTo(
          rect.left + 20 + i * 32,
          rect.top + 80,
          rect.left + 55 + i * 30,
          rect.top + 42,
          rect.left + 48 + i * 40,
          rect.top + 8,
        );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round
          ..color = Color.lerp(
            const Color(0xFF43F4A4),
            const Color(0xFF8EF7FF),
            i / 5,
          )!.withValues(alpha: 0.62),
      );
    }
  }

  void _drawOcean(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.60,
      size.height * 0.66,
      size.width * 0.33,
      size.height * 0.25,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(34)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF53C7E4), Color(0xFF0F6FA2)],
        ).createShader(rect),
    );
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.snowWhite.withValues(alpha: 0.5);
    for (var i = 0; i < 5; i += 1) {
      canvas.drawArc(
        Rect.fromLTWH(rect.left + 24 + i * 66, rect.top + 56, 72, 24),
        0,
        math.pi,
        false,
        wavePaint,
      );
    }
    final tailPaint = Paint()..color = const Color(0xFF0C456E);
    final tailCenter = Offset(rect.left + rect.width * 0.48, rect.top + 78);
    canvas.drawPath(
      Path()
        ..moveTo(tailCenter.dx, tailCenter.dy)
        ..cubicTo(
          tailCenter.dx - 30,
          tailCenter.dy - 38,
          tailCenter.dx - 60,
          tailCenter.dy - 16,
          tailCenter.dx - 28,
          tailCenter.dy + 10,
        )
        ..cubicTo(
          tailCenter.dx,
          tailCenter.dy + 26,
          tailCenter.dx + 30,
          tailCenter.dy + 26,
          tailCenter.dx + 58,
          tailCenter.dy + 8,
        )
        ..cubicTo(
          tailCenter.dx + 30,
          tailCenter.dy - 18,
          tailCenter.dx + 18,
          tailCenter.dy - 30,
          tailCenter.dx,
          tailCenter.dy,
        ),
      tailPaint,
    );
  }

  void _drawSnowTexture(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.snowWhite.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 80; i += 1) {
      final x = ((i * 97) % 1000) / 1000 * size.width;
      final y = ((i * 173) % 1000) / 1000 * size.height;
      canvas.drawCircle(Offset(x, y), i % 5 == 0 ? 2.2 : 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapArtPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.stops, required this.unlockedLocation});

  final List<_MapStop> stops;
  final int unlockedLocation;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      for (final stop in stops)
        Offset(stop.position.dx * size.width, stop.position.dy * size.height),
    ];

    _drawRoute(canvas, points, const Color(0xFF5F8196), 0.34, -1);
    _drawRoute(
      canvas,
      points,
      AppTheme.softBlue,
      0.88,
      unlockedLocation.clamp(1, stops.length),
    );
  }

  void _drawRoute(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double opacity,
    int unlockedStop,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.2)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < points.length - 1; i += 1) {
      if (unlockedStop > 0 && i + 2 > unlockedStop) {
        break;
      }

      final start = points[i];
      final end = points[i + 1];
      final delta = end - start;
      final distance = delta.distance;
      final normal = distance == 0
          ? Offset.zero
          : Offset(-delta.dy / distance, delta.dx / distance);
      final dotCount = math.max(7, (distance / 24).round());
      final wave = i.isEven ? 18.0 : -18.0;

      for (var dot = 0; dot <= dotCount; dot += 1) {
        final t = dot / dotCount;
        final center =
            Offset.lerp(start, end, t)! + normal * math.sin(t * math.pi) * wave;
        canvas.drawCircle(center, 6.2, glowPaint);
        canvas.drawCircle(center, dot.isEven ? 4.2 : 3.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.unlockedLocation != unlockedLocation ||
        oldDelegate.stops != stops;
  }
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = const Color(0xFF6B573B);
    canvas.drawCircle(center, size.width * 0.42, paint);
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);

    final needlePaint = Paint()..color = const Color(0xFF6B573B);
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, 4)
        ..lineTo(center.dx - 8, center.dy)
        ..lineTo(center.dx, center.dy - 4)
        ..lineTo(center.dx + 8, center.dy)
        ..close(),
      needlePaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, size.height - 4)
        ..lineTo(center.dx - 7, center.dy)
        ..lineTo(center.dx, center.dy + 4)
        ..lineTo(center.dx + 7, center.dy)
        ..close(),
      Paint()..color = const Color(0xFFB89B68),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) => false;
}

class _MapStop {
  const _MapStop({
    required this.location,
    required this.position,
    required this.accent,
    required this.icon,
    required this.table,
    required this.mentorName,
  });

  final MapLocation location;
  final Offset position;
  final Color accent;
  final IconData icon;
  final int table;
  final String mentorName;
}

enum _MapStopState { completed, available, locked }

class _LocationMapData {
  const _LocationMapData({required this.progress});

  final PlayerProgress progress;

  factory _LocationMapData.empty(PlayerProgress progress) {
    return _LocationMapData(progress: progress);
  }
}
