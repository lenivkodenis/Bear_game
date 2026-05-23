import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/bear_math_game.dart';
import '../models/level_completion_summary.dart';
import '../widgets/game_controls.dart';
import '../widgets/mentor_dialog.dart';
import '../widgets/score_hud.dart';
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

    final levelId = ModalRoute.of(context)?.settings.arguments as int? ?? 1;
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
    Navigator.of(context).pushReplacementNamed(
      LevelCompleteScreen.routeName,
      arguments: LevelCompletionSummary(
        locationName: level.locationName,
        mentorName: level.mentorName,
        completionText: level.completionText,
        score: game.scoreNotifier.value,
        solvedQuestions: game.totalQuestions,
      ),
    );
  }
}
