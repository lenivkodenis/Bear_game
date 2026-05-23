import 'package:flutter/material.dart';

import '../models/player_progress.dart';
import '../services/progress_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  static const routeName = '/progress';

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ProgressService _progressService = ProgressService();
  late Future<PlayerProgress> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _progressService.loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Прогресс')),
      body: FutureBuilder<PlayerProgress>(
        future: _progressFuture,
        builder: (context, snapshot) {
          final progress = snapshot.data ?? PlayerProgress.initial();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _ProgressTile(
                icon: Icons.star_rounded,
                title: 'Очки',
                value: progress.score.toString(),
              ),
              _ProgressTile(
                icon: Icons.map_rounded,
                title: 'Открытая локация',
                value: '${progress.unlockedLocation}/10',
              ),
              _ProgressTile(
                icon: Icons.calculate_rounded,
                title: 'Решено примеров',
                value: progress.solvedExamples.toString(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
