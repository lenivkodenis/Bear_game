import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/bear_math_game.dart';
import '../models/level_completion_summary.dart';
import '../services/game_settings_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/game_controls.dart';
import '../widgets/mentor_dialog.dart';
import '../widgets/score_hud.dart';
import 'final_screen.dart';
import 'level_complete_screen.dart';
import 'location_map_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  static const routeName = '/game';

  @override
  State<GameScreen> createState() => _GameScreenState();
}

const double compactGameViewportThreshold = 600;

bool usesCompactGameViewport(Size size) {
  return size.shortestSide < compactGameViewportThreshold;
}

class _GameScreenState extends State<GameScreen> {
  BearMathGame? _game;
  bool _gameWasCreated = false;
  Size? _lastViewportSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final viewportSize = MediaQuery.sizeOf(context);
    final useResponsiveCamera = usesCompactGameViewport(viewportSize);
    if (_gameWasCreated &&
        _game?.useResponsiveCamera == useResponsiveCamera &&
        (useResponsiveCamera || _lastViewportSize == viewportSize)) {
      return;
    }

    _game?.stopMoving();
    final routeLevelId = ModalRoute.of(context)?.settings.arguments as int?;
    final levelId = routeLevelId ?? _levelIdFromUri(Uri.base) ?? 1;
    _game = BearMathGame(
      levelId: levelId,
      useResponsiveCamera: useResponsiveCamera,
    );
    _gameWasCreated = true;
    _lastViewportSize = viewportSize;
  }

  @override
  Widget build(BuildContext context) {
    final game = _game!;
    final viewportSize = MediaQuery.sizeOf(context);
    final useCenteredLandscapeHud =
        viewportSize.width > viewportSize.height && viewportSize.height < 420;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GameWidget<BearMathGame>(
              key: ValueKey<BearMathGame>(game),
              game: game,
              backgroundBuilder: (_) => const SizedBox.expand(
                child: DecoratedBox(decoration: AppTheme.nightSnowyGradient),
              ),
              overlayBuilderMap: {
                BearMathGame.mentorDialogOverlay: (context, game) {
                  return MentorDialog(
                    game: game,
                    onClose: game.closeMentorDialog,
                    onLevelComplete: _openLevelCompleteScreen,
                    onReturnToMap: _returnToMap,
                    onRestartGame: _restartGame,
                  );
                },
              },
            ),
          ),
          Positioned.fill(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                game.sceneReadyNotifier,
                game.mentorDialogOpenNotifier,
              ]),
              builder: (context, _) {
                if (!game.sceneReadyNotifier.value) {
                  return _GameLoadingOverlay(onBack: _leaveLevel);
                }

                if (game.mentorDialogOpenNotifier.value) {
                  return const SizedBox.shrink();
                }

                return SafeArea(
                  minimum: const EdgeInsets.all(8),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 4,
                        left: 4,
                        child: IconButton.filledTonal(
                          onPressed: _leaveLevel,
                          icon: const Icon(Icons.arrow_back_rounded),
                          tooltip: 'Назад',
                        ),
                      ),
                      if (useCenteredLandscapeHud)
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: ScoreHud(
                              scoreListenable: game.scoreNotifier,
                            ),
                          ),
                        )
                      else
                        Positioned(
                          top: 4,
                          right: 4,
                          child: ScoreHud(scoreListenable: game.scoreNotifier),
                        ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: GameControls(
                          onMoveLeftStart: game.startMovingLeft,
                          onMoveRightStart: game.startMovingRight,
                          onMoveEnd: game.stopMoving,
                          onJump: game.jump,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openLevelCompleteScreen() {
    final game = _game;
    final level = game?.currentLevel;
    if (level == null) {
      return;
    }

    game!.closeMentorDialog();
    final routeName = level.id == 10
        ? FinalScreen.routeName
        : LevelCompleteScreen.routeName;

    Navigator.of(context).pushReplacementNamed(
      routeName,
      arguments: LevelCompletionSummary(
        locationName: level.locationName,
        mentorName: level.mentorName,
        completionText: level.completionText,
        score: game.scoreNotifier.value,
        levelSnowflakes: game.levelSnowflakes,
        solvedQuestions: game.totalQuestions,
        levelStatistics: game.levelStatistics,
      ),
    );
  }

  void _leaveLevel() {
    final game = _game;
    if (game != null) {
      game.closeMentorDialog();
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed(LocationMapScreen.routeName);
  }

  void _returnToMap() {
    final game = _game;
    if (game != null) {
      game.closeMentorDialog();
    }

    Navigator.of(context).pushReplacementNamed(LocationMapScreen.routeName);
  }

  Future<void> _restartGame() async {
    _game?.closeMentorDialog();
    await ProgressService().resetProgress();
    await GameSettingsService().confirmProgressResetForCurrentDifficulty();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      GameScreen.routeName,
      (route) => route.isFirst,
      arguments: 1,
    );
  }

  int? _levelIdFromUri(Uri uri) {
    return _parseLevelId(uri.queryParameters['levelId']) ??
        _parseLevelId(_fragmentQueryParameters(uri.fragment)['levelId']);
  }

  int? _parseLevelId(String? value) {
    if (value == null) {
      return null;
    }

    final levelId = int.tryParse(value);
    if (levelId == null || levelId < 1 || levelId > 10) {
      return null;
    }

    return levelId;
  }

  Map<String, String> _fragmentQueryParameters(String fragment) {
    if (fragment.isEmpty) {
      return const <String, String>{};
    }

    final queryStart = fragment.indexOf('?');
    if (queryStart == -1) {
      return const <String, String>{};
    }

    final query = fragment.substring(queryStart + 1);
    if (!query.contains('=')) {
      return const <String, String>{};
    }

    try {
      return Uri.splitQueryString(query);
    } on FormatException {
      return const <String, String>{};
    }
  }
}

class _GameLoadingOverlay extends StatelessWidget {
  const _GameLoadingOverlay({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppTheme.nightSnowyGradient,
      child: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: IconButton.filledTonal(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Назад',
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox.square(
                    dimension: 42,
                    child: CircularProgressIndicator(
                      color: AppTheme.softBlue,
                      strokeWidth: 4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Готовим северное путешествие…',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.deepBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
