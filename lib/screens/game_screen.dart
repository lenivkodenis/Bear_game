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
  late final BearMathGame _game;

  @override
  void initState() {
    super.initState();
    _game = BearMathGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GameWidget<BearMathGame>(
              game: _game,
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
              child: ScoreHud(scoreListenable: _game.scoreNotifier),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: GameControls(
                onMoveLeftStart: _game.startMovingLeft,
                onMoveRightStart: _game.startMovingRight,
                onMoveEnd: _game.stopMoving,
                onJump: _game.jump,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLevelCompleteScreen() {
    final level = _game.currentLevel;
    if (level == null) {
      return;
    }

    _game.closeMentorDialog();
    Navigator.of(context).pushReplacementNamed(
      LevelCompleteScreen.routeName,
      arguments: LevelCompletionSummary(
        locationName: level.locationName,
        mentorName: level.mentorName,
        score: _game.scoreNotifier.value,
        solvedQuestions: _game.totalQuestions,
      ),
    );
  }
}
