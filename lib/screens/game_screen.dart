import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/bear_math_game.dart';
import '../models/level_completion_summary.dart';
import '../widgets/game_controls.dart';
import '../widgets/mentor_dialog.dart';
import '../widgets/score_hud.dart';
import '../theme/app_theme.dart';
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

bool requiresLandscapeGameViewport(Size size) {
  return usesCompactGameViewport(size) && size.height > size.width;
}

class _GameScreenState extends State<GameScreen> {
  BearMathGame? _game;
  bool _gameWasCreated = false;
  bool _orientationBlocked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_gameWasCreated) {
      return;
    }

    final routeLevelId = ModalRoute.of(context)?.settings.arguments as int?;
    final levelId = routeLevelId ?? _levelIdFromUri(Uri.base) ?? 1;
    _game = BearMathGame(
      levelId: levelId,
      useFixedResolution: usesCompactGameViewport(MediaQuery.sizeOf(context)),
    );
    _gameWasCreated = true;
  }

  @override
  Widget build(BuildContext context) {
    final game = _game!;
    final orientationBlocked = requiresLandscapeGameViewport(
      MediaQuery.sizeOf(context),
    );
    _syncOrientationState(game, orientationBlocked);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GameWidget<BearMathGame>(
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
                  );
                },
              },
            ),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton.filledTonal(
                onPressed: _leaveLevel,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Назад',
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: ScoreHud(scoreListenable: game.scoreNotifier),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: orientationBlocked
                  ? const SizedBox.shrink()
                  : GameControls(
                      onMoveLeftStart: game.startMovingLeft,
                      onMoveRightStart: game.startMovingRight,
                      onMoveEnd: game.stopMoving,
                      onJump: game.jump,
                    ),
            ),
            if (orientationBlocked)
              Positioned.fill(
                child: _LandscapeOrientationPrompt(onBack: _leaveLevel),
              ),
          ],
        ),
      ),
    );
  }

  void _syncOrientationState(BearMathGame game, bool blocked) {
    if (_orientationBlocked == blocked) {
      return;
    }

    _orientationBlocked = blocked;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (blocked) {
        game.stopMoving();
        game.pauseEngine();
      } else {
        game.resumeEngine();
      }
    });
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

class _LandscapeOrientationPrompt extends StatelessWidget {
  const _LandscapeOrientationPrompt({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppTheme.nightSnowyGradient,
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 12,
            child: IconButton.filledTonal(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Назад',
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.screen_rotation_rounded,
                          size: 68,
                          color: AppTheme.softBlue,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Поверни телефон',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppTheme.deepBlue,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'В альбомном режиме весь уровень, препятствия и кнопки управления будут видны целиком.',
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
