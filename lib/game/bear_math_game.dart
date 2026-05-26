import 'dart:convert';
import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import 'components/distant_birds_component.dart';
import 'components/level_geometry_debug_overlay.dart';
import 'components/mentor_visual_component.dart';
import 'components/platform_component.dart';
import 'components/player_bear.dart';
import 'components/snowy_background.dart';
import 'ground_segment_collision.dart';
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
  late final MentorVisualComponent mentor;
  late LevelGeometry levelGeometry;

  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  final LevelService _levelService = LevelService();
  final LevelGeometryService _levelGeometryService = LevelGeometryService();
  final ProgressService _progressService = ProgressService();
  static final Map<int, double> _calibratedGroundYByLevel = <int, double>{};
  static final Map<int, List<LevelGeometryCollider>>
  _calibratedGroundSegmentsByLevel = <int, List<LevelGeometryCollider>>{};
  static final Map<int, List<LevelGeometryCollider>>
  _calibratedObstaclesByLevel = <int, List<LevelGeometryCollider>>{};
  static final Map<int, int> _selectedObstacleIndexByLevel = <int, int>{};
  static const double _minGroundDipWidth = 90;
  static const double _minGroundDipDepth = 10;
  static const double _maxGroundDipDepth = 70;
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
  bool _groundSegmentCalibrationEnabled = false;
  bool _obstacleCalibrationEnabled = false;
  bool _groundCalibrationExportPrinted = false;
  bool _groundSegmentCalibrationExportPrinted = false;
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
    _groundSegmentCalibrationEnabled = isGroundSegmentCalibrationModeEnabled;
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
    if (_groundSegmentCalibrationEnabled) {
      _seedGroundSegmentCalibrationValue(_sourceLevelGeometry);
    }
    if (_obstacleCalibrationEnabled) {
      _seedObstacleCalibrationValue(_sourceLevelGeometry);
    }

    levelGeometry = _currentSourceGeometry.scaledTo(size);
    final mainGround = levelGeometry.mainGround;
    final groundY = mainGround.y;

    add(SnowyBackground(size: size, assetPath: levelGeometry.backgroundAsset));
    if (currentLevel!.id == 1) {
      add(DistantBirdsComponent(size: size));
    }

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
    )..priority = 20;
    final mentorSpawn = levelGeometry.mentorPosition.toVector2();
    mentor = MentorVisualComponent(
      levelId: currentLevel!.id,
      groundPosition: mentorSpawn,
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
          groundSegmentCalibrationInfo: _groundSegmentCalibrationEnabled
              ? _buildGroundSegmentCalibrationOverlayInfo
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
    if (_handleGroundSegmentCalibrationKey(event, keysPressed)) {
      return KeyEventResult.handled;
    }

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

    final calibratedGroundSegments =
        _calibratedGroundSegmentsByLevel[_sourceLevelGeometry.levelId];
    if (_groundSegmentCalibrationEnabled && calibratedGroundSegments != null) {
      geometry = geometry.withGroundColliders(
        _groundLockedGroundSegments(
          calibratedGroundSegments,
          geometry.mainGround.y,
        ),
      );
    }

    final calibratedObstacles =
        _calibratedObstaclesByLevel[_sourceLevelGeometry.levelId];
    if (_obstacleCalibrationEnabled && calibratedObstacles != null) {
      geometry = geometry
          .withObstacleColliders(
            _groundLockedObstacles(calibratedObstacles, geometry.mainGround.y),
          )
          .withCalibrationObstacles(const <LevelGeometryCollider>[]);
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

  void _seedGroundSegmentCalibrationValue(LevelGeometry geometry) {
    if (geometry.groundColliders.length < 3) {
      return;
    }

    _calibratedGroundSegmentsByLevel.putIfAbsent(
      geometry.levelId,
      () => _groundLockedGroundSegments(
        geometry.groundColliders,
        geometry.mainGround.y,
      ),
    );
  }

  void _seedObstacleCalibrationValue(LevelGeometry geometry) {
    final sourceObstacles = geometry.obstacleColliders.isNotEmpty
        ? geometry.obstacleColliders
        : geometry.calibrationObstacles;
    if (sourceObstacles.isEmpty) {
      return;
    }

    _calibratedObstaclesByLevel.putIfAbsent(
      geometry.levelId,
      () => _groundLockedObstacles(sourceObstacles, geometry.mainGround.y),
    );
    _selectedObstacleIndexByLevel.putIfAbsent(geometry.levelId, () => 0);
  }

  bool _handleGroundSegmentCalibrationKey(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (!_groundSegmentCalibrationEnabled ||
        !_sceneReady ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent) ||
        _currentSourceGroundSegments == null) {
      return false;
    }

    final key = event.logicalKey;
    final step = _isShiftPressed(keysPressed) ? 1.0 : 5.0;

    if (key == LogicalKeyboardKey.keyA || key == LogicalKeyboardKey.keyD) {
      final runtimeDelta = key == LogicalKeyboardKey.keyA ? -step : step;
      _adjustGroundDipLeftEdge(runtimeDelta / _runtimeScaleX);
      return true;
    }

    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      final runtimeDelta = key == LogicalKeyboardKey.arrowLeft ? -step : step;
      _adjustGroundDipRightEdge(runtimeDelta / _runtimeScaleX);
      return true;
    }

    if (key == LogicalKeyboardKey.keyW || key == LogicalKeyboardKey.keyS) {
      final runtimeDelta = key == LogicalKeyboardKey.keyW ? -step : step;
      _adjustGroundDipFloorY(runtimeDelta / _runtimeScaleY);
      return true;
    }

    if (key == LogicalKeyboardKey.keyR) {
      _resetGroundSegmentCalibration();
      return true;
    }

    if (key == LogicalKeyboardKey.keyC) {
      _printGroundSegmentCalibrationValues();
      return true;
    }

    return false;
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
    final numberSelection = _obstacleNumberSelection(key);
    if (numberSelection != null) {
      _selectObstacleCalibrationIndex(numberSelection);
      return true;
    }

    if (key == LogicalKeyboardKey.bracketLeft) {
      _selectObstacleCalibrationDelta(-1);
      return true;
    }

    if (key == LogicalKeyboardKey.bracketRight ||
        key == LogicalKeyboardKey.tab) {
      _selectObstacleCalibrationDelta(1);
      return true;
    }

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

  List<LevelGeometryCollider>? get _currentSourceGroundSegments {
    return _calibratedGroundSegmentsByLevel[_sourceLevelGeometry.levelId];
  }

  LevelGeometryCollider? get _currentSourceGroundDipFloor {
    final segments = _currentSourceGroundSegments;
    if (segments == null || segments.length < 3) {
      return null;
    }

    return segments[1];
  }

  LevelGeometryCollider? get _currentSourceObstacleCandidate {
    final obstacles = _currentSourceObstacleCandidates;
    if (obstacles == null || obstacles.isEmpty) {
      return null;
    }

    return obstacles[_selectedObstacleIndex];
  }

  List<LevelGeometryCollider>? get _currentSourceObstacleCandidates {
    return _calibratedObstaclesByLevel[_sourceLevelGeometry.levelId];
  }

  int get _selectedObstacleIndex {
    final obstacles = _currentSourceObstacleCandidates;
    if (obstacles == null || obstacles.isEmpty) {
      return 0;
    }

    final selected =
        _selectedObstacleIndexByLevel[_sourceLevelGeometry.levelId] ?? 0;
    return selected.clamp(0, obstacles.length - 1).toInt();
  }

  bool _isShiftPressed(Set<LogicalKeyboardKey> keysPressed) {
    return keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
        keysPressed.contains(LogicalKeyboardKey.shiftRight);
  }

  int? _obstacleNumberSelection(LogicalKeyboardKey key) {
    const digitKeys = <LogicalKeyboardKey>[
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];
    const numpadKeys = <LogicalKeyboardKey>[
      LogicalKeyboardKey.numpad1,
      LogicalKeyboardKey.numpad2,
      LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.numpad4,
      LogicalKeyboardKey.numpad5,
      LogicalKeyboardKey.numpad6,
      LogicalKeyboardKey.numpad7,
      LogicalKeyboardKey.numpad8,
      LogicalKeyboardKey.numpad9,
    ];

    final digitIndex = digitKeys.indexOf(key);
    if (digitIndex != -1) {
      return digitIndex;
    }

    final numpadIndex = numpadKeys.indexOf(key);
    if (numpadIndex != -1) {
      return numpadIndex;
    }

    return null;
  }

  void _selectObstacleCalibrationDelta(int delta) {
    final obstacles = _currentSourceObstacleCandidates;
    if (obstacles == null || obstacles.isEmpty) {
      return;
    }

    _selectObstacleCalibrationIndex(
      (_selectedObstacleIndex + delta) % obstacles.length,
    );
  }

  void _selectObstacleCalibrationIndex(int index) {
    final obstacles = _currentSourceObstacleCandidates;
    if (obstacles == null || obstacles.isEmpty) {
      return;
    }

    final normalizedIndex = index.clamp(0, obstacles.length - 1).toInt();
    _selectedObstacleIndexByLevel[_sourceLevelGeometry.levelId] =
        normalizedIndex;
    _obstacleCalibrationExportPrinted = false;
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
    )..priority = 20;
    add(player);

    final mentorSpawn = levelGeometry.mentorPosition.toVector2();
    mentor.moveToGroundPosition(mentorSpawn);
  }

  void _adjustGroundDipLeftEdge(double sourceDelta) {
    final segments = _currentSourceGroundSegments;
    if (segments == null || segments.length < 3) {
      return;
    }

    final floor = segments[1];
    _setGroundDip(
      leftEdgeX: floor.x + sourceDelta,
      rightEdgeX: floor.x + floor.width,
      floorY: floor.y,
    );
  }

  void _adjustGroundDipRightEdge(double sourceDelta) {
    final segments = _currentSourceGroundSegments;
    if (segments == null || segments.length < 3) {
      return;
    }

    final floor = segments[1];
    _setGroundDip(
      leftEdgeX: floor.x,
      rightEdgeX: floor.x + floor.width + sourceDelta,
      floorY: floor.y,
    );
  }

  void _adjustGroundDipFloorY(double sourceDelta) {
    final floor = _currentSourceGroundDipFloor;
    if (floor == null) {
      return;
    }

    _setGroundDip(
      leftEdgeX: floor.x,
      rightEdgeX: floor.x + floor.width,
      floorY: floor.y + sourceDelta,
    );
  }

  void _resetGroundSegmentCalibration() {
    _calibratedGroundSegmentsByLevel.remove(_sourceLevelGeometry.levelId);
    _seedGroundSegmentCalibrationValue(_sourceLevelGeometry);
    _groundSegmentCalibrationExportPrinted = false;
    levelGeometry = _currentSourceGeometry.scaledTo(size);
    final mainGround = levelGeometry.mainGround;
    _mainGroundComponent.position = mainGround.position;
    _mainGroundComponent.size = mainGround.size;
  }

  void _setGroundDip({
    required double leftEdgeX,
    required double rightEdgeX,
    required double floorY,
  }) {
    final topY = _sourceLevelGeometry.mainGround.y;
    final worldWidth = _sourceLevelGeometry.world.width;
    final worldHeight = _sourceLevelGeometry.world.height;
    final minLeftEdgeX = 0.0;
    final maxLeftEdgeX = worldWidth - _minGroundDipWidth;
    final leftX = leftEdgeX.clamp(minLeftEdgeX, maxLeftEdgeX).toDouble();
    final minRightEdgeX = leftX + _minGroundDipWidth;
    final rightX = rightEdgeX.clamp(minRightEdgeX, worldWidth).toDouble();
    final minFloorY = topY + _minGroundDipDepth;
    final maxFloorY = math.min(worldHeight - 20, topY + _maxGroundDipDepth);
    final lockedFloorY = floorY.clamp(minFloorY, maxFloorY).toDouble();

    _calibratedGroundSegmentsByLevel[_sourceLevelGeometry.levelId] =
        _buildGroundDipSegments(
          leftEdgeX: leftX,
          rightEdgeX: rightX,
          topY: topY,
          floorY: lockedFloorY,
        );
    _groundSegmentCalibrationExportPrinted = false;
    levelGeometry = _currentSourceGeometry.scaledTo(size);
    final mainGround = levelGeometry.mainGround;
    _mainGroundComponent.position = mainGround.position;
    _mainGroundComponent.size = mainGround.size;
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
    _calibratedObstaclesByLevel.remove(_sourceLevelGeometry.levelId);
    _selectedObstacleIndexByLevel[_sourceLevelGeometry.levelId] = 0;
    _seedObstacleCalibrationValue(_sourceLevelGeometry);
    _obstacleCalibrationExportPrinted = false;
    levelGeometry = _currentSourceGeometry.scaledTo(size);
  }

  void _setObstacleCalibration(LevelGeometryCollider candidate) {
    final obstacles = _currentSourceObstacleCandidates;
    if (obstacles == null || obstacles.isEmpty) {
      return;
    }

    final selectedIndex = _selectedObstacleIndex;
    final lockedCandidate = _boundedGroundLockedObstacle(
      candidate,
      _currentSourceGroundTopY,
    );
    final updatedObstacles = List<LevelGeometryCollider>.of(obstacles);
    updatedObstacles[selectedIndex] = lockedCandidate;
    _calibratedObstaclesByLevel[_sourceLevelGeometry.levelId] =
        updatedObstacles;
    _selectedObstacleIndexByLevel[_sourceLevelGeometry.levelId] = selectedIndex;
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

  List<LevelGeometryCollider> _buildGroundDipSegments({
    required double leftEdgeX,
    required double rightEdgeX,
    required double topY,
    required double floorY,
  }) {
    final worldWidth = _sourceLevelGeometry.world.width;
    final worldHeight = _sourceLevelGeometry.world.height;

    return <LevelGeometryCollider>[
      LevelGeometryCollider(
        id: 'ground_left',
        x: 0,
        y: topY,
        width: leftEdgeX,
        height: worldHeight - topY,
      ),
      LevelGeometryCollider(
        id: 'ground_dip_floor',
        x: leftEdgeX,
        y: floorY,
        width: rightEdgeX - leftEdgeX,
        height: worldHeight - floorY,
      ),
      LevelGeometryCollider(
        id: 'ground_right',
        x: rightEdgeX,
        y: topY,
        width: worldWidth - rightEdgeX,
        height: worldHeight - topY,
      ),
    ];
  }

  List<LevelGeometryCollider> _groundLockedGroundSegments(
    Iterable<LevelGeometryCollider> candidates,
    double groundTopY,
  ) {
    final segments = candidates.toList(growable: false);
    if (segments.length < 3) {
      return segments;
    }

    final floor = segments[1];
    return _buildGroundDipSegments(
      leftEdgeX: floor.x,
      rightEdgeX: floor.x + floor.width,
      topY: groundTopY,
      floorY: floor.y,
    );
  }

  List<LevelGeometryCollider> _groundLockedObstacles(
    Iterable<LevelGeometryCollider> candidates,
    double groundTopY,
  ) {
    return candidates
        .map((candidate) => _groundLockedObstacle(candidate, groundTopY))
        .toList(growable: false);
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

  GroundSegmentCalibrationOverlayInfo?
  _buildGroundSegmentCalibrationOverlayInfo() {
    final segments = _currentSourceGroundSegments;
    if (segments == null || segments.length < 3) {
      return null;
    }

    return GroundSegmentCalibrationOverlayInfo(
      levelId: _sourceLevelGeometry.levelId,
      levelName: currentLevel?.locationName ?? currentLevel?.title,
      topGroundY: _sourceLevelGeometry.mainGround.y,
      leftSegment: segments[0],
      floorSegment: segments[1],
      rightSegment: segments[2],
      exportPrinted: _groundSegmentCalibrationExportPrinted,
    );
  }

  ObstacleCalibrationOverlayInfo? _buildObstacleCalibrationOverlayInfo() {
    final obstacles = _currentSourceObstacleCandidates;
    final candidate = _currentSourceObstacleCandidate;
    if (obstacles == null || obstacles.isEmpty || candidate == null) {
      return null;
    }

    return ObstacleCalibrationOverlayInfo(
      levelId: _sourceLevelGeometry.levelId,
      levelName: currentLevel?.locationName ?? currentLevel?.title,
      groundTopY: _currentSourceGroundTopY,
      candidate: candidate,
      selectedIndex: _selectedObstacleIndex,
      obstacleCount: obstacles.length,
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

  void _printGroundSegmentCalibrationValues() {
    final segments = _currentSourceGroundSegments;
    if (segments == null || segments.isEmpty) {
      return;
    }

    final values = <String, Object>{
      'groundColliders': segments
          .map(
            (segment) => <String, Object>{
              'id': segment.id,
              'x': _jsonNumber(segment.x),
              'y': _jsonNumber(segment.y),
              'width': _jsonNumber(segment.width),
              'height': _jsonNumber(segment.height),
            },
          )
          .toList(growable: false),
      'topGroundY': _jsonNumber(_sourceLevelGeometry.mainGround.y),
      'formula': 'segment.height = world.height - segment.y',
    };
    final json = const JsonEncoder.withIndent('  ').convert(values);
    debugPrint('Ground segment calibration:\n$json');
    _groundSegmentCalibrationExportPrinted = true;
  }

  void _printObstacleCalibrationValues() {
    final obstacles = _currentSourceObstacleCandidates;
    if (obstacles == null || obstacles.isEmpty) {
      return;
    }

    final values = <String, Object>{
      'obstacleColliders': obstacles
          .map(
            (obstacle) => <String, Object>{
              'id': obstacle.id,
              'x': _jsonNumber(obstacle.x),
              'y': _jsonNumber(obstacle.y),
              'width': _jsonNumber(obstacle.width),
              'height': _jsonNumber(obstacle.height),
            },
          )
          .toList(growable: false),
      'groundTopY': _jsonNumber(_currentSourceGroundTopY),
      'formula': 'y = groundTopY - height',
    };
    final json = const JsonEncoder.withIndent('  ').convert(values);
    debugPrint('Obstacle layout calibration:\n$json');
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
      _resolveGroundSegmentCollisions(previousPlayerRect);
      _resolveObstacleCollisions(previousPlayerRect);
    }

    if (!_mentorDialogWasShown && _isPlayerNearMentor) {
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

  bool get _isPlayerNearMentor {
    final playerCenter = player.position + player.size / 2;
    return playerCenter.distanceTo(mentor.interactionPoint) < 92;
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

  void _resolveGroundSegmentCollisions(Rect previousPlayerRect) {
    if (levelGeometry.groundColliders.length < 2) {
      return;
    }

    final resolvedRect = resolveGroundSegmentSideCollision(
      previousPlayerRect: previousPlayerRect,
      futurePlayerRect: _playerRect,
      groundRects: _groundRects,
      minX: 0,
      maxX: size.x - player.size.x,
    );
    if (resolvedRect.left != player.position.x) {
      player.position.x = resolvedRect.left;
    }
  }

  void _updatePlayerActiveGround() {
    final supportObstacle = findObstacleTopSupport(
      playerRect: _playerRect,
      obstacleRects: _obstacleRects,
    );
    if (supportObstacle == null) {
      player.setActiveGroundY(
        findGroundSurfaceY(
          playerRect: _playerRect,
          groundRects: _groundRects,
          fallbackGroundY: levelGeometry.mainGround.y,
        ),
      );
      return;
    }

    player.setActiveGroundY(supportObstacle.top);
  }

  List<Rect> get _groundRects {
    return levelGeometry.groundColliders
        .map(
          (ground) =>
              Rect.fromLTWH(ground.x, ground.y, ground.width, ground.height),
        )
        .toList(growable: false);
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
