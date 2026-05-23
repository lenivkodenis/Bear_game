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
  bool _showMentorDialog = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_gameWasCreated) {
      return;
    }

    final levelId = ModalRoute.of(context)?.settings.arguments as int? ?? 1;
    _game = BearMathGame(levelId: levelId, onMentorReached: _openMentorDialog);
    _gameWasCreated = true;
  }

  @override
  Widget build(BuildContext context) {
    final game = _game!;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GameWidget<BearMathGame>(game: game),
            Positioned(
              top: 12,
              left: 12,
              child: FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(14),
                ),
                child: const Text(
                  '‹',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
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
            if (_showMentorDialog)
              Positioned.fill(
                child: MentorDialog(
                  game: game,
                  onClose: _closeMentorDialog,
                  onLevelComplete: _openLevelCompleteScreen,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openMentorDialog() {
    if (!mounted) {
      return;
    }

    setState(() => _showMentorDialog = true);
  }

  void _closeMentorDialog() {
    _game?.closeMentorDialog();
    if (!mounted) {
      return;
    }

    setState(() => _showMentorDialog = false);
  }

  void _openLevelCompleteScreen() {
    final game = _game;
    final level = game?.currentLevel;
    if (level == null) {
      return;
    }

    game!.closeMentorDialog();
    _showMentorDialog = false;
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
        solvedQuestions: game.totalQuestions,
      ),
    );
  }
}
