import 'package:flutter/material.dart';

import '../models/player_progress.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/game_card.dart';
import '../widgets/primary_game_button.dart';
import '../widgets/score_badge.dart';
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
        decoration: AppTheme.snowyGradient,
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
                      GameCard(
                        child: Column(
                          children: [
                            const _FamilyMark(),
                            const SizedBox(height: 16),
                            Text(
                              'Медвежонок нашёл маму',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.deepBlue,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Медвежонок прошёл весь путь, помогал новым друзьям, учился считать и стал увереннее. Мама обняла его и сказала, что знания помогли ему найти дорогу домой.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.deepBlue,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                ScoreBadge(
                                  score: progress.score,
                                  label: 'Итоговые снежинки',
                                ),
                                _FinalBadge(
                                  symbol: '⌂',
                                  label: 'Уровни',
                                  value: progress.completedLevelIds.length
                                      .toString(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryGameButton(
                        icon: Icons.map_rounded,
                        symbol: '⌂',
                        label: 'На карту',
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            LocationMapScreen.routeName,
                            (route) => route.isFirst,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      PrimaryGameButton(
                        icon: Icons.replay_rounded,
                        symbol: '↺',
                        label: 'Повторить путь',
                        secondary: true,
                        onPressed: _restartJourney,
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

class _FinalBadge extends StatelessWidget {
  const _FinalBadge({
    required this.symbol,
    required this.label,
    required this.value,
  });

  final String symbol;
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
            Text(
              symbol,
              style: const TextStyle(
                color: AppTheme.softBlue,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
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

class _FamilyMark extends StatelessWidget {
  const _FamilyMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      width: 190,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 178,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.frostBlue,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.iceBlue, width: 2),
              ),
            ),
          ),
          const Positioned(left: 36, bottom: 22, child: _BearFace(size: 82)),
          const Positioned(right: 34, bottom: 18, child: _BearFace(size: 58)),
          const Positioned(
            top: 8,
            child: Text(
              '♥',
              style: TextStyle(
                color: AppTheme.warmYellow,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BearFace extends StatelessWidget {
  const _BearFace({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final earSize = size * 0.24;
    final eyeSize = size * 0.07;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Positioned(
            left: size * 0.12,
            top: size * 0.04,
            child: _RoundEar(size: earSize),
          ),
          Positioned(
            right: size * 0.12,
            top: size * 0.04,
            child: _RoundEar(size: earSize),
          ),
          Positioned.fill(
            top: size * 0.08,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.snowWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.iceBlue, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.softShadow,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: size * 0.32,
            top: size * 0.46,
            child: CircleAvatar(
              radius: eyeSize,
              backgroundColor: AppTheme.deepBlue,
            ),
          ),
          Positioned(
            right: size * 0.32,
            top: size * 0.46,
            child: CircleAvatar(
              radius: eyeSize,
              backgroundColor: AppTheme.deepBlue,
            ),
          ),
          Positioned(
            left: size * 0.44,
            top: size * 0.58,
            child: Container(
              width: size * 0.12,
              height: size * 0.08,
              decoration: BoxDecoration(
                color: AppTheme.deepBlue,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundEar extends StatelessWidget {
  const _RoundEar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.frostBlue,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.iceBlue, width: 2),
      ),
    );
  }
}
