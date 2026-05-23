import 'package:flutter/material.dart';

import '../models/level_completion_summary.dart';
import '../models/player_progress.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/game_card.dart';
import '../widgets/primary_game_button.dart';
import '../widgets/score_badge.dart';
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
        decoration: AppTheme.snowyGradient,
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
                      GameCard(
                        child: Column(
                          children: [
                            const _VictoryMark(),
                            const SizedBox(height: 16),
                            Text(
                              locationName,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.deepBlue,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              mentorName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.lockedBlue,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                ScoreBadge(score: score),
                                _SummaryBadge(
                                  icon: Icons.calculate_rounded,
                                  label: 'Вопросы',
                                  value: solvedQuestions.toString(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              completionText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.deepBlue,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryGameButton(
                        icon: Icons.map_rounded,
                        label: 'К карте',
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            LocationMapScreen.routeName,
                            (route) => route.isFirst,
                          );
                        },
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

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.softBlue),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.lockedBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.deepBlue,
                    fontSize: 20,
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

class _VictoryMark extends StatelessWidget {
  const _VictoryMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      width: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 124,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.paleYellow,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppTheme.snowWhite, width: 3),
            ),
          ),
          const Icon(
            Icons.emoji_events_rounded,
            size: 68,
            color: AppTheme.warmYellow,
          ),
          const Positioned(
            top: 8,
            right: 22,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.gentleGreen,
              size: 24,
            ),
          ),
          const Positioned(
            bottom: 10,
            left: 18,
            child: Icon(
              Icons.star_rounded,
              color: AppTheme.warmYellow,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
