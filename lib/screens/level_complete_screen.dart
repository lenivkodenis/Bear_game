import 'package:flutter/material.dart';

import '../models/level_completion_summary.dart';
import '../models/player_progress.dart';
import '../services/progress_service.dart';
import 'location_map_screen.dart';

class LevelCompleteScreen extends StatefulWidget {
  const LevelCompleteScreen({super.key});

  static const routeName = '/level-complete';

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen> {
  final ProgressService _progressService = ProgressService();
  late final Future<PlayerProgress> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _progressService.loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final summary =
        ModalRoute.of(context)?.settings.arguments as LevelCompletionSummary?;

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
              constraints: const BoxConstraints(maxWidth: 520),
              child: FutureBuilder<PlayerProgress>(
                future: _progressFuture,
                builder: (context, snapshot) {
                  final progress = snapshot.data ?? PlayerProgress.initial();
                  final locationName = summary?.locationName ?? 'Льдина';
                  final mentorName = summary?.mentorName ?? 'Морская чайка';
                  final completionText =
                      summary?.completionText ??
                      'Ты справился. Теперь ты знаешь, что таблица умножения помогает считать быстрее и увереннее. Я покажу тебе путь к следующей локации.';
                  final score = summary?.score ?? progress.score;
                  final solvedQuestions =
                      summary?.solvedQuestions ?? progress.currentQuestionIndex;

                  return ListView(
                    padding: const EdgeInsets.all(24),
                    shrinkWrap: true,
                    children: [
                      const Icon(
                        Icons.ac_unit_rounded,
                        size: 72,
                        color: Color(0xFF3A8FB7),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        locationName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF17435A),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mentorName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      _SummaryTile(
                        icon: Icons.star_rounded,
                        title: 'Заработанные очки',
                        value: score.toString(),
                      ),
                      _SummaryTile(
                        icon: Icons.calculate_rounded,
                        title: 'Решённые вопросы',
                        value: solvedQuestions.toString(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        completionText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
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
                          child: Text('К карте'),
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
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
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
