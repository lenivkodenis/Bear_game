import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'components/platform_component.dart';
import 'components/player_bear.dart';
import 'components/snowy_background.dart';
import 'components/wise_mentor.dart';
import '../models/level.dart';
import '../models/player_progress.dart';
import '../models/question.dart';
import '../models/question_answer_result.dart';
import '../services/level_service.dart';
import '../services/progress_service.dart';

class BearMathGame extends FlameGame with HasKeyboardHandlerComponents {
  BearMathGame();

  static const mentorDialogOverlay = 'mentorDialog';

  late final PlayerBear player;
  late final WiseMentor mentor;

  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  final LevelService _levelService = LevelService();
  final ProgressService _progressService = ProgressService();

  Level? currentLevel;
  PlayerProgress _progress = PlayerProgress.initial();
  int _currentQuestionIndex = 0;
  bool _mentorDialogWasShown = false;
  bool _sceneReady = false;

  Question? get currentQuestion {
    final level = currentLevel;
    if (level == null || _currentQuestionIndex >= level.questions.length) {
      return null;
    }

    return level.questions[_currentQuestionIndex];
  }

  int get currentQuestionNumber => _currentQuestionIndex + 1;

  int get totalQuestions => currentLevel?.questions.length ?? 0;

  bool get isLevelComplete {
    final level = currentLevel;
    return level != null && _currentQuestionIndex >= level.questions.length;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    currentLevel = await _levelService.loadLevel(1);
    _progress = await _progressService.loadProgress();
    _currentQuestionIndex = math.min(
      _progress.currentQuestionIndex,
      currentLevel!.questions.length,
    );
    scoreNotifier.value = _progress.score;

    final groundY = size.y - 88;

    add(SnowyBackground(size: size));
    add(
      PlatformComponent(
        position: Vector2(0, groundY),
        size: Vector2(size.x, 44),
      ),
    );

    player = PlayerBear(
      position: Vector2(72, groundY - PlayerBear.defaultSize.y),
      groundY: groundY,
      levelWidth: size.x,
    );
    mentor = WiseMentor(
      position: Vector2(size.x - 112, groundY - WiseMentor.defaultSize.y),
    );

    add(player);
    add(mentor);

    _sceneReady = true;
  }

  void startMovingLeft() {
    if (_sceneReady) {
      player.moveLeft();
    }
  }

  void startMovingRight() {
    if (_sceneReady) {
      player.moveRight();
    }
  }

  void stopMoving() {
    if (_sceneReady) {
      player.stopMoving();
    }
  }

  void jump() {
    if (_sceneReady) {
      player.jump();
    }
  }

  Future<QuestionAnswerResult> submitAnswer(int selectedAnswer) async {
    final question = currentQuestion;
    if (question == null) {
      return QuestionAnswerResult(
        isCorrect: true,
        message: 'Все задачи этой льдины уже решены.',
        score: _progress.score,
        isLevelComplete: true,
      );
    }

    if (selectedAnswer == question.correctAnswer) {
      return _saveCorrectAnswer(question);
    }

    return _saveWrongAnswer(question);
  }

  void closeMentorDialog() {
    overlays.remove(mentorDialogOverlay);
  }

  Future<QuestionAnswerResult> _saveCorrectAnswer(Question question) async {
    final nextQuestionIndex = _currentQuestionIndex + 1;
    final newScore = _progress.score + question.rewardPoints;
    final levelComplete = nextQuestionIndex >= totalQuestions;

    _progress = _progress.copyWith(
      score: newScore,
      solvedExamples: _progress.solvedExamples + 1,
      currentQuestionIndex: nextQuestionIndex,
      unlockedLocation: levelComplete
          ? math.max(_progress.unlockedLocation, currentLevel!.id)
          : _progress.unlockedLocation,
    );
    _currentQuestionIndex = nextQuestionIndex;
    scoreNotifier.value = newScore;

    await _progressService.saveProgress(_progress);

    return QuestionAnswerResult(
      isCorrect: true,
      message: 'Верно! Медвежонок получает ${question.rewardPoints} очков.',
      score: newScore,
      isLevelComplete: levelComplete,
    );
  }

  Future<QuestionAnswerResult> _saveWrongAnswer(Question question) async {
    final newScore = math.max(0, _progress.score - question.penaltyPoints);
    _progress = _progress.copyWith(score: newScore);
    scoreNotifier.value = newScore;

    await _progressService.saveProgress(_progress);

    return QuestionAnswerResult(
      isCorrect: false,
      message:
          'Пока неверно. -${question.penaltyPoints} очка. Подсказка: ${question.hint}',
      score: newScore,
      isLevelComplete: false,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_sceneReady) {
      return;
    }

    if (!_mentorDialogWasShown && player.distance(mentor) < 92) {
      _mentorDialogWasShown = true;
      player.stopMoving();
      overlays.add(mentorDialogOverlay);
    }
  }
}
