import 'package:flutter/material.dart';

import '../models/map_location.dart';
import '../models/player_progress.dart';
import '../services/level_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/game_card.dart';
import '../widgets/location_card.dart';
import '../widgets/score_badge.dart';
import 'game_screen.dart';

class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({super.key});

  static const routeName = '/map';

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  final LevelService _levelService = LevelService();
  final ProgressService _progressService = ProgressService();
  late Future<_LocationMapData> _mapDataFuture;

  static const _locations = [
    MapLocation(id: 1, name: 'Льдина'),
    MapLocation(id: 2, name: 'Ледяная река'),
    MapLocation(id: 3, name: 'Заснеженный берег'),
    MapLocation(id: 4, name: 'Северный лес'),
    MapLocation(id: 5, name: 'Ледяная пещера'),
    MapLocation(id: 6, name: 'Снежная долина'),
    MapLocation(id: 7, name: 'Горный перевал'),
    MapLocation(id: 8, name: 'Полярная ночь'),
    MapLocation(id: 9, name: 'Северное сияние'),
    MapLocation(id: 10, name: 'Северный океан'),
  ];

  @override
  void initState() {
    super.initState();
    _mapDataFuture = _loadMapData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Карта')),
      body: DecoratedBox(
        decoration: AppTheme.snowyGradient,
        child: FutureBuilder<_LocationMapData>(
          future: _mapDataFuture,
          builder: (context, snapshot) {
            final mapData =
                snapshot.data ??
                _LocationMapData.empty(PlayerProgress.initial());

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _locations.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 18),
                        child: GameCard(
                          backgroundColor: AppTheme.frostBlue,
                          child: Column(
                            children: [
                              const Text(
                                'Путь медвежонка домой',
                                textAlign: TextAlign.center,
                                style: AppTheme.screenTitleStyle,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Выбирай открытую локацию и продолжай путешествие',
                                textAlign: TextAlign.center,
                                style: AppTheme.helperStyle,
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  ScoreBadge(
                                    score: mapData.progress.score,
                                    compact: true,
                                  ),
                                  _MapBadge(
                                    icon: Icons.flag_rounded,
                                    label: 'Открыто',
                                    value:
                                        '${mapData.progress.unlockedLocation.clamp(1, 10)}/10',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final location = _locations[index - 1];
                    final isUnlocked =
                        location.id <= mapData.progress.unlockedLocation;
                    final hasLevel = mapData.availableLevelIds.contains(
                      location.id,
                    );
                    final isCompleted = mapData.progress.isLevelCompleted(
                      location.id,
                    );

                    return LocationCard(
                      location: location,
                      isUnlocked: isUnlocked,
                      hasLevel: hasLevel,
                      isCompleted: isCompleted,
                      onTap: isUnlocked
                          ? () => _openLocation(context, location, hasLevel)
                          : null,
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<_LocationMapData> _loadMapData() async {
    final progress = await _progressService.loadProgress();
    final levels = await _levelService.loadLevels();

    return _LocationMapData(
      progress: progress,
      availableLevelIds: levels.map((level) => level.id).toSet(),
    );
  }

  void _openLocation(
    BuildContext context,
    MapLocation location,
    bool hasLevel,
  ) {
    if (!hasLevel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Эта локация скоро откроется')),
      );
      return;
    }

    Navigator.of(
      context,
    ).pushNamed(GameScreen.routeName, arguments: location.id);
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
            Icon(icon, color: AppTheme.gentleGreen),
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

class _LocationMapData {
  const _LocationMapData({
    required this.progress,
    required this.availableLevelIds,
  });

  final PlayerProgress progress;
  final Set<int> availableLevelIds;

  factory _LocationMapData.empty(PlayerProgress progress) {
    return _LocationMapData(progress: progress, availableLevelIds: const {});
  }
}
