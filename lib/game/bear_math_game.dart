import 'dart:convert';
import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import 'components/level_geometry_debug_overlay.dart';
import 'components/platform_component.dart';
import 'components/player_bear.dart';
import 'components/snowy_background.dart';
import 'components/wise_mentor.dart';
import 'level_geometry.dart';
import '../models/level.dart';
import '../models/player_progress.dart';
import '../models/question.dart';
import '../models/question_answer_result.dart';
import '../services/game_economy.dart';
import '../services/level_service.dart';
import '../services/progress_service.dart';

class BearMathGame extends FlameGame with HasKeyboardHandlerComponents {
  BearMathGame({required this.levelId});

  static const mentorDialogOverlay = 'mentorDialog';

  final int levelId;
  late PlayerBear player;
  late final WiseMentor mentor;
  late LevelGeometry levelGeometry;

  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  final LevelService _levelService = LevelService();
  final LevelGeometryService _levelGeometryService = LevelGeometryService();
  final ProgressService _progressService = ProgressService();
  static final Map<int, double> _calibratedGroundYByLevel = <int, double>{};

  late final LevelGeometry _sourceLevelGeometry;
  late final PlatformComponent _mainGroundComponent;
  List<LevelGeometry> _sourceGeometries = const <LevelGeometry>[];
  Level? currentLevel;
  PlayerProgress _progress = PlayerProgress.initial();
  int _currentQuestionIndex = 0;
  int _levelSnowflakes = 0;
  bool _mentorDialogWasShown = false;
  bool _mentorDialogOpen = false;
  bool _sceneReady = false;
  bool _groundCalibrationEnabled = false;
  bool _groundCalibrationExportPrinted = false;
  final Set<int> _questionsWithWrongAttempts = <int>{};

  Question? get currentQuestion {
    final level = currentLevel;
    if (level == null || _currentQuestionIndex >= level.questions.length) {
      return null;
    }

    return level.questions[_currentQuestionIndex];
  }

  int get currentQuestionNumber => _currentQuestionIndex + 1;

  int get totalQuestions => currentLevel?.questions.length ?? 0;

  int get levelSnowflakes => _levelSnowflakes;

  bool get isLevelComplete {
    final level = currentLevel;
    return level != null && _currentQuestionIndex >= level.questions.length;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    currentLevel = await _levelService.loadLevel(levelId);
    _progress = await _progressService.loadProgress();
    _currentQuestionIndex = math.min(
      _progress.questionIndexForLevel(levelId),
      currentLevel!.questions.length,
    );
    scoreNotifier.value = _progress.score;

    _groundCalibrationEnabled = isGroundCalibrationModeEnabled;
    _sourceGeometries = _groundCalibrationEnabled
        ? await _levelGeometryService.loadGeometries()
        : const <LevelGeometry>[];
    _sourceLevelGeometry = _groundCalibrationEnabled
        ? _sourceGeometries.firstWhere(
            (geometry) => geometry.levelId == currentLevel!.id,
            orElse: () => throw StateError(
              'Missing level geometry for level id ${currentLevel!.id}.',
            ),
          )
        : await _levelGeometryService.loadLevelGeometry(currentLevel!.id);
    if (_groundCalibrationEnabled) {
      _seedGroundCalibrationValues(_sourceGeometries);
    }

    levelGeometry = _currentSourceGeometry.scaledTo(size);
    final mainGround = levelGeometry.mainGround;
    final groundY = mainGround.y;

    add(SnowyBackground(size: size, assetPath: levelGeometry.backgroundAsset));
    _mainGroundComponent = PlatformComponent(
      position: mainGround.position,
      size: mainGround.size,
    );
    add(_mainGroundComponent);

    final playerSpawn = levelGeometry.playerSpawn.toVector2();
    player = PlayerBear(
      position: Vector2(
        playerSpawn.x,
        playerSpawn.y - PlayerBear.defaultSize.y,
      ),
      groundY: groundY,
      levelWidth: size.x,
    );
    final mentorSpawn = levelGeometry.mentorPosition.toVector2();
    mentor = WiseMentor(
      position: Vector2(
        mentorSpawn.x,
        mentorSpawn.y - WiseMentor.defaultSize.y,
      ),
    );

    add(player);
    add(mentor);
    if (isLevelGeometryDebugOverlayEnabled) {
      add(
        LevelGeometryDebugOverlay(
          geometry: () => levelGeometry,
          player: () => player,
          calibrationInfo: _groundCalibrationEnabled
              ? _buildGroundCalibrationOverlayInfo
              : null,
        ),
      );
    }

    _sceneReady = true;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (_handleGroundCalibrationKey(event, keysPressed)) {
      return KeyEventResult.handled;
    }

    return super.onKeyEvent(event, keysPressed);
  }

  void startMovingLeft() {
    if (_sceneReady && !_mentorDialogOpen) {
      player.moveLeft();
    }
  }

  void startMovingRight() {
    if (_sceneReady && !_mentorDialogOpen) {
      player.moveRight();
    }
  }

  void stopMoving() {
    if (_sceneReady) {
      player.stopMoving();
    }
  }

  void jump() {
    if (_sceneReady && !_mentorDialogOpen) {
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
    _mentorDialogOpen = false;
    player.stopInteracting();
    overlays.remove(mentorDialogOverlay);
  }

  LevelGeometry get _currentSourceGeometry {
    final calibratedGroundY =
        _calibratedGroundYByLevel[_sourceLevelGeometry.levelId];
    if (!_groundCalibrationEnabled || calibratedGroundY == null) {
      return _sourceLevelGeometry;
    }

    return _sourceLevelGeometry.withMainGroundTopY(calibratedGroundY);
  }

  void _seedGroundCalibrationValues(List<LevelGeometry> geometries) {
    for (final geometry in geometries) {
      _calibratedGroundYByLevel.putIfAbsent(
        geometry.levelId,
        () => geometry.mainGround.y,
      );
    }
  }

  bool _handleGroundCalibrationKey(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (!_groundCalibrationEnabled ||
        !_sceneReady ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return false;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      final step = _isShiftPressed(keysPressed) ? 1.0 : 5.0;
      final runtimeDelta = key == LogicalKeyboardKey.arrowUp ? -step : step;
      _adjustGroundCalibrationByRuntimeDelta(runtimeDelta);
      return true;
    }

    if (key == LogicalKeyboardKey.keyR) {
      _resetGroundCalibration();
      return true;
    }

    if (key == LogicalKeyboardKey.keyC) {
      _printGroundCalibrationValues();
      return true;
    }

    return false;
  }

  bool _isShiftPressed(Set<LogicalKeyboardKey> keysPressed) {
    return keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
        keysPressed.contains(LogicalKeyboardKey.shiftRight);
  }

  void _adjustGroundCalibrationByRuntimeDelta(double runtimeDelta) {
    final scaleY = size.y == 0
        ? 1.0
        : size.y / _sourceLevelGeometry.world.height;
    final currentGroundY =
        _calibratedGroundYByLevel[_sourceLevelGeometry.levelId] ??
        _sourceLevelGeometry.mainGround.y;

    _setGroundCalibrationY(currentGroundY + runtimeDelta / scaleY);
  }

  void _resetGroundCalibration() {
    _setGroundCalibrationY(_sourceLevelGeometry.mainGround.y);
  }

  void _setGroundCalibrationY(double sourceGroundY) {
    final clampedGroundY = sourceGroundY
        .clamp(0, _sourceLevelGeometry.world.height)
        .toDouble();
    _calibratedGroundYByLevel[_sourceLevelGeometry.levelId] = clampedGroundY;
    _groundCalibrationExportPrinted = false;

    levelGeometry = _currentSourceGeometry.scaledTo(size);
    final mainGround = levelGeometry.mainGround;
    _mainGroundComponent.position = mainGround.position;
    _mainGroundComponent.size = mainGround.size;

    final playerX = player.position.x
        .clamp(0, size.x - PlayerBear.defaultSize.x)
        .toDouble();
    player.removeFromParent();
    player = PlayerBear(
      position: Vector2(playerX, mainGround.y - PlayerBear.defaultSize.y),
      groundY: mainGround.y,
      levelWidth: size.x,
    );
    add(player);

    final mentorSpawn = levelGeometry.mentorPosition.toVector2();
    mentor.position = Vector2(
      mentorSpawn.x,
      mentorSpawn.y - WiseMentor.defaultSize.y,
    );
  }

  GroundCalibrationOverlayInfo _buildGroundCalibrationOverlayInfo() {
    final baseGroundY = _sourceLevelGeometry.mainGround.y;
    final calibratedGroundY =
        _calibratedGroundYByLevel[_sourceLevelGeometry.levelId] ?? baseGroundY;

    return GroundCalibrationOverlayInfo(
      levelId: _sourceLevelGeometry.levelId,
      levelName: currentLevel?.locationName ?? currentLevel?.title,
      baseGroundY: baseGroundY,
      calibratedGroundY: calibratedGroundY,
      runtimeGroundY: levelGeometry.mainGround.y,
      exportPrinted: _groundCalibrationExportPrinted,
    );
  }

  void _printGroundCalibrationValues() {
    final values = <String, num>{};
    final geometries = _sourceGeometries.isEmpty
        ? <LevelGeometry>[_sourceLevelGeometry]
        : _sourceGeometries;

    for (final geometry in geometries) {
      final groundY =
          _calibratedGroundYByLevel[geometry.levelId] ?? geometry.mainGround.y;
      values[geometry.exportKey] = _jsonNumber(groundY);
    }

    final json = const JsonEncoder.withIndent('  ').convert(values);
    debugPrint('Ground calibration values:\n$json');
    _groundCalibrationExportPrinted = true;
  }

  num _jsonNumber(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.01) {
      return rounded.toInt();
    }

    return double.parse(value.toStringAsFixed(2));
  }

  Future<QuestionAnswerResult> _saveCorrectAnswer(Question question) async {
    final hadWrongAttempt = _questionsWithWrongAttempts.contains(
      _currentQuestionIndex,
    );
    final earnedSnowflakes = GameEconomy.snowflakesForCorrectAnswer(
      hadWrongAttempt: hadWrongAttempt,
    );
    final nextQuestionIndex = _currentQuestionIndex + 1;
    final newScore = _progress.score + earnedSnowflakes;
    final levelComplete = nextQuestionIndex >= totalQuestions;
    final questionIndexes = Map<int, int>.of(_progress.currentQuestionIndexes)
      ..[currentLevel!.id] = nextQuestionIndex;
    final completedLevelIds = Set<int>.of(_progress.completedLevelIds);
    if (levelComplete) {
      completedLevelIds.add(currentLevel!.id);
    }

    _progress = _progress.copyWith(
      score: newScore,
      solvedExamples: _progress.solvedExamples + 1,
      currentQuestionIndexes: questionIndexes,
      completedLevelIds: completedLevelIds,
      unlockedLocation: levelComplete
          ? math.max(_progress.unlockedLocation, currentLevel!.id + 1)
          : _progress.unlockedLocation,
    );
    _currentQuestionIndex = nextQuestionIndex;
    _levelSnowflakes += earnedSnowflakes;
    scoreNotifier.value = newScore;

    await _progressService.saveProgress(_progress);

    return QuestionAnswerResult(
      isCorrect: true,
      message: 'Верно! Медвежонок получает $earnedSnowflakes снежинок.',
      score: newScore,
      isLevelComplete: levelComplete,
    );
  }

  Future<QuestionAnswerResult> _saveWrongAnswer(Question question) async {
    _questionsWithWrongAttempts.add(_currentQuestionIndex);

    return QuestionAnswerResult(
      isCorrect: false,
      message: 'Пока неверно. Подсказка: ${question.hint}',
      score: _progress.score,
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
      _mentorDialogOpen = true;
      player.stopMoving();
      player.startInteracting();
      overlays.add(mentorDialogOverlay);
    }
  }
}
