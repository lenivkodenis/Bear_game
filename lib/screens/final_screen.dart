import 'package:flutter/material.dart';

import '../models/player_progress.dart';
import '../services/progress_service.dart';
import 'game_screen.dart';
import 'location_map_screen.dart';

class FinalScreen extends StatefulWidget {
  const FinalScreen({super.key});

  static const routeName = '/final';

  @override
  State<FinalScreen> createState() => _FinalScreenState();
}

class _FinalScreenState extends State<FinalScreen> {
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F8FF), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: FutureBuilder<PlayerProgress>(
                future: _progressFuture,
                builder: (context, snapshot) {
                  final progress = snapshot.data ?? PlayerProgress.initial();

                  return ListView(
                    padding: const EdgeInsets.all(24),
                    shrinkWrap: true,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 72,
                        color: Color(0xFF3A8FB7),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Медвежонок нашёл маму',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF17435A),
                            ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Медвежонок прошёл весь путь, помогал новым друзьям, учился считать и стал увереннее. Мама обняла его и сказала, что знания помогли ему найти дорогу домой.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 24),
                      _FinalTile(
                        icon: Icons.star_rounded,
                        title: 'Итоговые очки',
                        value: progress.score.toString(),
                      ),
                      _FinalTile(
                        icon: Icons.map_rounded,
                        title: 'Пройденные уровни',
                        value: progress.completedLevelIds.length.toString(),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            LocationMapScreen.routeName,
                            (route) => route.isFirst,
                          );
                        },
                        icon: const Icon(Icons.map_rounded),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('На карту'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _restartJourney,
                        icon: const Icon(Icons.replay_rounded),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Повторить путь'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _restartJourney() async {
    await _progressService.resetProgress();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      GameScreen.routeName,
      (route) => route.isFirst,
      arguments: 1,
    );
  }
}

class _FinalTile extends StatelessWidget {
  const _FinalTile({
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
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
