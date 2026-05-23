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
      hitboxSize: Size(0.17, 0.12),
    ),
    _MapStop(
      location: MapLocation(id: 2, name: 'Ледяная река'),
      center: Offset(0.32, 0.35),
      hitboxSize: Size(0.18, 0.12),
    ),
    _MapStop(
      location: MapLocation(id: 3, name: 'Заснеженный берег'),
      center: Offset(0.50, 0.33),
      hitboxSize: Size(0.20, 0.12),
    ),
    _MapStop(
      location: MapLocation(id: 4, name: 'Северный лес'),
      center: Offset(0.70, 0.33),
      hitboxSize: Size(0.18, 0.12),
    ),
    _MapStop(
      location: MapLocation(id: 5, name: 'Ледяная пещера'),
      center: Offset(0.77, 0.58),
      hitboxSize: Size(0.20, 0.12),
    ),
    _MapStop(
      location: MapLocation(id: 6, name: 'Снежная долина'),
      center: Offset(0.46, 0.61),
      hitboxSize: Size(0.20, 0.12),
    ),
    _MapStop(
      location: MapLocation(id: 7, name: 'Горный перевал'),
      center: Offset(0.13, 0.60),
      hitboxSize: Size(0.20, 0.12),
    ),
    _MapStop(
      location: MapLocation(id: 8, name: 'Полярная ночь'),
      center: Offset(0.09, 0.88),
      hitboxSize: Size(0.19, 0.12),
    ),
    _MapStop(
      location: MapLocation(id: 9, name: 'Северное сияние'),
      center: Offset(0.35, 0.92),
      hitboxSize: Size(0.21, 0.12),
    ),
    _MapStop(
      location: MapLocation(id: 10, name: 'Северный океан'),
      center: Offset(0.63, 0.90),
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
                child: state == _MapStopState.locked
                    ? const _LockedFrost()
                    : const SizedBox.expand(),
              ),
            ),
          ),
        ),
        Positioned(
          left: center.dx - indicatorSize / 2,
          top: center.dy - indicatorSize / 2,
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

class _AvailableIndicator extends StatelessWidget {
  const _AvailableIndicator({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.paleYellow, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warmYellow.withValues(alpha: 0.62),
            blurRadius: 22,
            spreadRadius: 7,
          ),
          BoxShadow(
            color: AppTheme.iceBlue.withValues(alpha: 0.5),
            blurRadius: 16,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.snowWhite.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(
            dimension: size * 0.34,
            child: const Icon(
              Icons.play_arrow_rounded,
              color: AppTheme.softBlue,
              size: 19,
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedIndicator extends StatelessWidget {
  const _LockedIndicator({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
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

class _LockedFrost extends StatelessWidget {
  const _LockedFrost();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFEAF8FE).withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.snowWhite.withValues(alpha: 0.38),
              width: 1.2,
            ),
          ),
        ),
      ),
    );
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
    required this.hitboxSize,
  });

  final MapLocation location;
  final Offset center;
  final Size hitboxSize;
}

enum _MapStopState { completed, available, locked }

class _LocationMapData {
  const _LocationMapData({required this.progress});

  final PlayerProgress progress;

  factory _LocationMapData.empty(PlayerProgress progress) {
    return _LocationMapData(progress: progress);
  }
}
