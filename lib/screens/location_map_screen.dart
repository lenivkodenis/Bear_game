import 'package:flutter/material.dart';

import '../models/map_location.dart';
import '../models/player_progress.dart';
import '../services/progress_service.dart';
import 'game_screen.dart';

class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({super.key});

  static const routeName = '/map';

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  final ProgressService _progressService = ProgressService();
  late Future<PlayerProgress> _progressFuture;

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
    _progressFuture = _progressService.loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Карта')),
      body: FutureBuilder<PlayerProgress>(
        future: _progressFuture,
        builder: (context, snapshot) {
          final progress = snapshot.data ?? PlayerProgress.initial();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _locations.length,
            itemBuilder: (context, index) {
              final location = _locations[index];
              final isUnlocked = location.id <= progress.unlockedLocation;
              final isPlayable = location.id == 1;

              return _LocationCard(
                location: location,
                isUnlocked: isUnlocked,
                isPlayable: isPlayable,
                onTap: isUnlocked
                    ? () => _openLocation(context, location, isPlayable)
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  void _openLocation(
    BuildContext context,
    MapLocation location,
    bool isPlayable,
  ) {
    if (!isPlayable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${location.name} открыта. Задания появятся позже.'),
        ),
      );
      return;
    }

    Navigator.of(context).pushNamed(GameScreen.routeName);
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.isUnlocked,
    required this.isPlayable,
    required this.onTap,
  });

  final MapLocation location;
  final bool isUnlocked;
  final bool isPlayable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = isUnlocked ? Icons.place_rounded : Icons.lock_rounded;
    final status = isUnlocked
        ? (isPlayable ? 'Доступна' : 'Открыта')
        : 'Заблокирована';

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
