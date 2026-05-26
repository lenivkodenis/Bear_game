import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/bear_math_game.dart';
import '../models/level_completion_summary.dart';
import '../widgets/game_controls.dart';
import '../widgets/mentor_dialog.dart';
import '../widgets/score_hud.dart';
import 'final_screen.dart';
import 'level_complete_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  static const routeName = '/game';

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  BearMathGame? _game;
  bool _gameWasCreated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_gameWasCreated) {
      return;
    }

    final routeLevelId = ModalRoute.of(context)?.settings.arguments as int?;
    final levelId = routeLevelId ?? _levelIdFromUri(Uri.base) ?? 1;
    _game = BearMathGame(levelId: levelId);
    _gameWasCreated = true;
  }

  @override
  Widget build(BuildContext context) {
    final game = _game!;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GameWidget<BearMathGame>(
              game: game,
              overlayBuilderMap: {
                BearMathGame.mentorDialogOverlay: (context, game) {
                  return MentorDialog(
                    game: game,
                    onClose: game.closeMentorDialog,
                    onLevelComplete: _openLevelCompleteScreen,
                  );
                },
              },
            ),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
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
              child: GameControls(
                onMoveLeftStart: game.startMovingLeft,
                onMoveRightStart: game.startMovingRight,
                onMoveEnd: game.stopMoving,
                onJump: game.jump,
              ),
            ),
          ],
        ),
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
      ),
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
