import 'package:flutter/material.dart';

import '../models/player_progress.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/back_text_button.dart';
import '../widgets/game_card.dart';
import '../widgets/score_badge.dart';

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
      appBar: AppBar(
        leading: const BackTextButton(),
        title: const Text('Прогресс'),
      ),
      body: DecoratedBox(
        decoration: AppTheme.snowyGradient,
        child: FutureBuilder<PlayerProgress>(
          future: _progressFuture,
          builder: (context, snapshot) {
            final progress = snapshot.data ?? PlayerProgress.initial();

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    GameCard(
                      backgroundColor: AppTheme.frostBlue,
                      child: Column(
                        children: [
                          const Text(
                            'Твои успехи',
                            textAlign: TextAlign.center,
                            style: AppTheme.screenTitleStyle,
                          ),
                          const SizedBox(height: 16),
                          ScoreBadge(score: progress.score),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ProgressTile(
                      symbol: '⌂',
                      title: 'Открытая локация',
                      value: '${progress.unlockedLocation.clamp(1, 10)}/10',
                    ),
                    _ProgressTile(
                      symbol: '×',
                      title: 'Решено примеров',
                      value: progress.solvedExamples.toString(),
                    ),
                    _ProgressTile(
                      symbol: '★',
                      title: 'Пройдено уровней',
                      value: progress.completedLevelIds.length.toString(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({
    required this.symbol,
    required this.title,
    required this.value,
  });

  final String symbol;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GameCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.frostBlue,
              child: Text(
                symbol,
                style: const TextStyle(
                  color: AppTheme.softBlue,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppTheme.deepBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.deepBlue,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
