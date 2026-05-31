import 'package:flutter/material.dart';

import '../models/player_progress.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/effects/snowfall_overlay.dart';
import '../widgets/game_card.dart';
import '../widgets/score_badge.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  static const routeName = '/progress';

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  static const _backgroundAsset =
      'public/assets/main_screen/main_screen_bear_bg.png';

  final ProgressService _progressService = ProgressService();
  late Future<PlayerProgress> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _progressService.loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.width < 760;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.snowWhite,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        leading: const _SnowBackButton(),
        title: const Text('Прогресс'),
        titleTextStyle: const TextStyle(
          color: AppTheme.snowWhite,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Color(0xB0001026),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _backgroundAsset,
              fit: BoxFit.cover,
              alignment: isCompact
                  ? const Alignment(-0.08, 0)
                  : Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
          if (isCompact)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Image.asset(
                  _backgroundAsset,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          const Positioned.fill(
            child: IgnorePointer(
              child: SnowfallOverlay(intensity: SnowfallIntensity.medium),
            ),
          ),
          FutureBuilder<PlayerProgress>(
            future: _progressFuture,
            builder: (context, snapshot) {
              final progress = snapshot.data ?? PlayerProgress.initial();

              return SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      children: [
                        GameCard(
                          backgroundColor: AppTheme.frostBlue.withValues(
                            alpha: 0.94,
                          ),
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
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SnowBackButton extends StatelessWidget {
  const _SnowBackButton();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Назад',
      child: TextButton(
        onPressed: () => Navigator.of(context).maybePop(),
        child: const Text(
          '‹',
          style: TextStyle(
            color: AppTheme.snowWhite,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1,
            shadows: [
              Shadow(
                color: Color(0xB0001026),
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
          ),
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
