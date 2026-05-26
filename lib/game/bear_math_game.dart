import 'dart:convert';
import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import 'components/level_geometry_debug_overlay.dart';
import 'components/obstacle_visual_component.dart';
import 'components/platform_component.dart';
import 'components/player_bear.dart';
import 'components/snowy_background.dart';
import 'components/wise_mentor.dart';
import 'level_geometry.dart';
import 'obstacle_collision.dart';
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
  static final Map<int, LevelGeometryCollider> _calibratedObstacleByLevel =
      <int, LevelGeometryCollider>{};
  static const double _minCalibrationObstacleWidth = 50;
  static const double _maxCalibrationObstacleWidth = 160;
  static const double _minCalibrationObstacleHeight = 20;
  static const double _maxCalibrationObstacleHeight = 70;

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
  bool _obstacleCalibrationEnabled = false;
  bool _groundCalibrationExportPrinted = false;
  bool _obstacleCalibrationExportPrinted = false;
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
    _obstacleCalibrationEnabled = isObstacleCalibrationModeEnabled;
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
    if (_obstacleCalibrationEnabled) {
      _seedObstacleCalibrationValue(_sourceLevelGeometry);
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
    _addObstacleVisuals();

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
          obstacleCalibrationInfo: _obstacleCalibrationEnabled
              ? _buildObstacleCalibrationOverlayInfo
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
    if (_handleObstacleCalibrationKey(event, keysPressed)) {
      return KeyEventResult.handled;
    }

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
    var geometry = _sourceLevelGeometry;
    final calibratedGroundY =
        _calibratedGroundYByLevel[_sourceLevelGeometry.levelId];
    if (_groundCalibrationEnabled && calibratedGroundY != null) {
      geometry = geometry.withMainGroundTopY(calibratedGroundY);
    }

    final calibratedObstacle =
        _calibratedObstacleByLevel[_sourceLevelGeometry.levelId];
    if (_obstacleCalibrationEnabled && calibratedObstacle != null) {
      geometry = geometry.withCalibrationObstacles(<LevelGeometryCollider>[
        _groundLockedObstacle(calibratedObstacle, geometry.mainGround.y),
      ]);
    }

    return geometry;
  }

  void _seedGroundCalibrationValues(List<LevelGeometry> geometries) {
    for (final geometry in geometries) {
      _calibratedGroundYByLevel.putIfAbsent(
        geometry.levelId,
        () => geometry.mainGround.y,
      );
    }
  }

  void _seedObstacleCalibrationValue(LevelGeometry geometry) {
    if (geometry.calibrationObstacles.isEmpty) {
      return;
    }

    _calibratedObstacleByLevel.putIfAbsent(
      geometry.levelId,
      () => _groundLockedObstacle(
        geometry.calibrationObstacles.first,
        geometry.mainGround.y,
      ),
    );
  }

  bool _handleObstacleCalibrationKey(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (!_obstacleCalibrationEnabled ||
        !_sceneReady ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent) ||
        _currentSourceObstacleCandidate == null) {
      return false;
    }

    final key = event.logicalKey;
    final isFineTuning = _isShiftPressed(keysPressed);
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      final step = isFineTuning ? 1.0 : 10.0;
      final runtimeDelta = key == LogicalKeyboardKey.arrowLeft ? -step : step;
      _adjustObstacleCalibrationX(runtimeDelta / _runtimeScaleX);
      return true;
    }

    if (key == LogicalKeyboardKey.keyA || key == LogicalKeyboardKey.keyD) {
      final step = isFineTuning ? 1.0 : 5.0;
      final runtimeDelta = key == LogicalKeyboardKey.keyA ? -step : step;
      _adjustObstacleCalibrationWidth(runtimeDelta / _runtimeScaleX);
      return true;
    }

    if (key == LogicalKeyboardKey.keyW || key == LogicalKeyboardKey.keyS) {
      final step = isFineTuning ? 1.0 : 5.0;
      final runtimeDelta = key == LogicalKeyboardKey.keyW ? step : -step;
      _adjustObstacleCalibrationHeight(runtimeDelta / _runtimeScaleY);
      return true;
    }

    if (key == LogicalKeyboardKey.keyR) {
      _resetObstacleCalibration();
      return true;
    }

    if (key == LogicalKeyboardKey.keyC) {
      _printObstacleCalibrationValues();
      return true;
    }

    return false;
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

  LevelGeometryCollider? get _currentSourceObstacleCandidate {
    final geometry = _currentSourceGeometry;
    if (geometry.calibrationObstacles.isEmpty) {
      return null;
    }

    return geometry.calibrationObstacles.first;
  }

  bool _isShiftPressed(Set<LogicalKeyboardKey> keysPressed) {
    return keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
        keysPressed.contains(LogicalKeyboardKey.shiftRight);
  }

  double get _runtimeScaleX {
    if (size.x == 0) {
      return 1.0;
    }

    return size.x / _sourceLevelGeometry.world.width;
  }

  double get _runtimeScaleY {
    if (size.y == 0) {
      return 1.0;
    }

    return size.y / _sourceLevelGeometry.world.height;
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

  void _adjustObstacleCalibrationX(double sourceDelta) {
    final candidate = _currentSourceObstacleCandidate;
    if (candidate == null) {
      return;
    }

    _setObstacleCalibration(candidate.copyWith(x: candidate.x + sourceDelta));
  }

  void _adjustObstacleCalibrationWidth(double sourceDelta) {
    final candidate = _currentSourceObstacleCandidate;
    if (candidate == null) {
      return;
    }

    _setObstacleCalibration(
      candidate.copyWith(width: candidate.width + sourceDelta),
    );
  }

  void _adjustObstacleCalibrationHeight(double sourceDelta) {
    final candidate = _currentSourceObstacleCandidate;
    if (candidate == null) {
      return;
    }

    _setObstacleCalibration(
      candidate.copyWith(height: candidate.height + sourceDelta),
    );
  }

  void _resetObstacleCalibration() {
    if (_sourceLevelGeometry.calibrationObstacles.isEmpty) {
      return;
    }

    _setObstacleCalibration(_sourceLevelGeometry.calibrationObstacles.first);
  }

  void _setObstacleCalibration(LevelGeometryCollider candidate) {
    final lockedCandidate = _boundedGroundLockedObstacle(
      candidate,
      _currentSourceGroundTopY,
    );
    _calibratedObstacleByLevel[_sourceLevelGeometry.levelId] = lockedCandidate;
    _obstacleCalibrationExportPrinted = false;
    levelGeometry = _currentSourceGeometry.scaledTo(size);
  }

  double get _currentSourceGroundTopY {
    final calibratedGroundY =
        _calibratedGroundYByLevel[_sourceLevelGeometry.levelId];
    if (_groundCalibrationEnabled && calibratedGroundY != null) {
      return calibratedGroundY;
    }

    return _sourceLevelGeometry.mainGround.y;
  }

  LevelGeometryCollider _boundedGroundLockedObstacle(
    LevelGeometryCollider candidate,
    double groundTopY,
  ) {
    final width = candidate.width
        .clamp(_minCalibrationObstacleWidth, _maxCalibrationObstacleWidth)
        .toDouble();
    final height = candidate.height
        .clamp(_minCalibrationObstacleHeight, _maxCalibrationObstacleHeight)
        .toDouble();
    final maxX = math.max(0.0, _sourceLevelGeometry.world.width - width);
    final x = candidate.x.clamp(0.0, maxX).toDouble();

    return candidate.copyWith(
      x: x,
      y: groundTopY - height,
      width: width,
      height: height,
    );
  }

  LevelGeometryCollider _groundLockedObstacle(
    LevelGeometryCollider candidate,
    double groundTopY,
  ) {
    return candidate.copyWith(y: groundTopY - candidate.height);
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

  ObstacleCalibrationOverlayInfo? _buildObstacleCalibrationOverlayInfo() {
    final candidate = _currentSourceObstacleCandidate;
    if (candidate == null) {
      return null;
    }

    return ObstacleCalibrationOverlayInfo(
      levelId: _sourceLevelGeometry.levelId,
      levelName: currentLevel?.locationName ?? currentLevel?.title,
      groundTopY: _currentSourceGroundTopY,
      candidate: candidate,
      exportPrinted: _obstacleCalibrationExportPrinted,
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

  void _printObstacleCalibrationValues() {
    final candidate = _currentSourceObstacleCandidate;
    if (candidate == null) {
      return;
    }

    final values = <String, Object>{
      'id': candidate.id,
      'x': _jsonNumber(candidate.x),
      'y': _jsonNumber(candidate.y),
      'width': _jsonNumber(candidate.width),
      'height': _jsonNumber(candidate.height),
      'groundTopY': _jsonNumber(_currentSourceGroundTopY),
      'formula': 'y = groundTopY - height',
    };
    final json = const JsonEncoder.withIndent('  ').convert(values);
    debugPrint('Obstacle calibration preview:\n$json');
    _obstacleCalibrationExportPrinted = true;
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
    if (_sceneReady) {
      _updatePlayerActiveGround();
    }
    final previousPlayerRect = _sceneReady ? _playerRect : null;
    super.update(dt);

    if (!_sceneReady) {
      return;
    }

    if (previousPlayerRect != null) {
      _resolveObstacleCollisions(previousPlayerRect);
    }

    if (!_mentorDialogWasShown && player.distance(mentor) < 92) {
      _mentorDialogWasShown = true;
      _mentorDialogOpen = true;
      player.stopMoving();
      player.startInteracting();
      overlays.add(mentorDialogOverlay);
    }
  }

  Rect get _playerRect {
    return Rect.fromLTWH(
      player.position.x,
      player.position.y,
      player.size.x,
      player.size.y,
    );
  }

  void _resolveObstacleCollisions(Rect previousPlayerRect) {
    if (levelGeometry.obstacleColliders.isEmpty) {
      return;
    }

    final currentRect = _playerRect;
    final obstacleRects = _obstacleRects;
    final landingObstacle = findObstacleTopLanding(
      previousPlayerRect: previousPlayerRect,
      futurePlayerRect: currentRect,
      obstacleRects: obstacleRects,
    );
    if (landingObstacle != null) {
      player.landOnSurface(landingObstacle.top);
      return;
    }

    final resolvedRect = resolveObstacleSideCollision(
      previousPlayerRect: previousPlayerRect,
      futurePlayerRect: currentRect,
      obstacleRects: obstacleRects,
      minX: 0,
      maxX: size.x - player.size.x,
    );
    if (resolvedRect.left != player.position.x) {
      player.position.x = resolvedRect.left;
    }
  }

  void _addObstacleVisuals() {
    for (final obstacle in levelGeometry.obstacleColliders) {
      add(
        ObstacleVisualComponent(
          position: obstacle.position,
          size: obstacle.size,
        ),
      );
    }
  }

  void _updatePlayerActiveGround() {
    final supportObstacle = findObstacleTopSupport(
      playerRect: _playerRect,
      obstacleRects: _obstacleRects,
    );
    if (supportObstacle == null) {
      player.setActiveGroundY(levelGeometry.mainGround.y);
      return;
    }

    player.setActiveGroundY(supportObstacle.top);
  }

  List<Rect> get _obstacleRects {
    return levelGeometry.obstacleColliders
        .map(
          (obstacle) => Rect.fromLTWH(
            obstacle.x,
            obstacle.y,
            obstacle.width,
            obstacle.height,
          ),
        )
        .toList(growable: false);
  }
}
