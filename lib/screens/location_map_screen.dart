import 'package:flutter/material.dart';

import '../models/map_location.dart';
import '../models/player_progress.dart';
import '../services/level_service.dart';
import '../services/progress_service.dart';
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
      body: FutureBuilder<_LocationMapData>(
        future: _mapDataFuture,
        builder: (context, snapshot) {
          final mapData =
              snapshot.data ?? _LocationMapData.empty(PlayerProgress.initial());

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _locations.length,
            itemBuilder: (context, index) {
              final location = _locations[index];
              final isUnlocked =
                  location.id <= mapData.progress.unlockedLocation;
              final hasLevel = mapData.availableLevelIds.contains(location.id);
              final isCompleted = mapData.progress.isLevelCompleted(
                location.id,
              );

              return _LocationCard(
                location: location,
                isUnlocked: isUnlocked,
                hasLevel: hasLevel,
                isCompleted: isCompleted,
                onTap: isUnlocked
                    ? () => _openLocation(context, location, hasLevel)
                    : null,
              );
            },
          );
        },
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

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.isUnlocked,
    required this.hasLevel,
    required this.isCompleted,
    required this.onTap,
  });

  final MapLocation location;
  final bool isUnlocked;
  final bool hasLevel;
  final bool isCompleted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = isUnlocked ? Icons.place_rounded : Icons.lock_rounded;
    final status = !isUnlocked
        ? 'Заблокирована'
        : isCompleted
        ? 'Пройдена'
        : hasLevel
        ? 'Доступна'
        : 'Скоро откроется';

    return Card(
      child: ListTile(
        enabled: isUnlocked,
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isUnlocked
              ? colorScheme.primaryContainer
              : const Color(0xFFE7EEF2),
          child: Icon(
            icon,
            color: isUnlocked
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text('${location.id}. ${location.name}'),
        subtitle: Text(status),
        trailing: isUnlocked
            ? const Icon(Icons.chevron_right_rounded)
            : const Icon(Icons.lock_outline_rounded),
      ),
    );
  }
}
