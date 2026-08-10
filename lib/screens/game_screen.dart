import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/bear_math_game.dart';
import '../models/level_completion_summary.dart';
import '../services/mobile_display_service.dart';
import '../services/viewport_stability_model.dart';
import '../theme/app_theme.dart';
import '../widgets/game_controls.dart';
import '../widgets/mentor_dialog.dart';
import '../widgets/score_hud.dart';
import '../widgets/viewport_debug_overlay.dart';
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

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  BearMathGame? _game;
  bool _gameWasCreated = false;
  final GameControlsController _controlsController = GameControlsController();
  final ViewportStabilityModel _viewportStability = ViewportStabilityModel();
  final MobileDisplayService _displayService = MobileDisplayService.instance;
  Timer? _settleTimer;
  bool _isResizing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_gameWasCreated) {
      return;
    }

    _game?.stopMoving();
    final routeLevelId = ModalRoute.of(context)?.settings.arguments as int?;
    final levelId = routeLevelId ?? _levelIdFromUri(Uri.base) ?? 1;
    _game = BearMathGame(
      levelId: levelId,
      useResponsiveCamera: true,
    );
    _gameWasCreated = true;
  }

  @override
  void didChangeMetrics() {
    _beginViewportTransition();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _beginViewportTransition();
      return;
    }
    _interruptGameplay();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settleTimer?.cancel();
    _controlsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = _game!;
    final viewportSize = MediaQuery.sizeOf(context);
    final useCenteredLandscapeHud =
        viewportSize.width > viewportSize.height && viewportSize.height < 420;
    final debugViewport = _debugViewportEnabled(Uri.base);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _isResizing,
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
                    );
                  },
                },
              ),
            ),
          ),
          Positioned.fill(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                game.sceneReadyNotifier,
                game.mentorDialogOpenNotifier,
              ]),
              builder: (context, _) {
                if (!game.sceneReadyNotifier.value || _isResizing) {
                  if (_isResizing && game.sceneReadyNotifier.value) {
                    return const _ViewportSettlingOverlay();
                  }
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
                        child: Row(
                          children: [
                            IconButton.filledTonal(
                              onPressed: _leaveLevel,
                              icon: const Icon(Icons.arrow_back_rounded),
                              tooltip: 'Назад',
                            ),
                            if (_displayService.fullscreenSupported &&
                                !_displayService.isStandalone) ...[
                              const SizedBox(width: 4),
                              IconButton.filledTonal(
                                onPressed: () {
                                  unawaited(
                                    _displayService.requestImmersive(
                                      lockLandscape:
                                          viewportSize.width >
                                          viewportSize.height,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.fullscreen_rounded),
                                tooltip: 'На весь экран',
                              ),
                            ],
                          ],
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
                          controller: _controlsController,
                          enabled: !_isResizing,
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
          if (debugViewport)
            Positioned.fill(child: ViewportDebugOverlay(game: game)),
        ],
      ),
    );
  }

  void _beginViewportTransition() {
    if (!mounted) return;
    _settleTimer?.cancel();
    _viewportStability.beginResize();
    _interruptGameplay();
    if (!_isResizing) {
      setState(() => _isResizing = true);
    }
    if (_debugViewportEnabled(Uri.base)) {
      final view = View.of(context);
      debugPrint(
        '[BearMath Flutter viewport] resizing '
        '${view.physicalSize.width / view.devicePixelRatio}×'
        '${view.physicalSize.height / view.devicePixelRatio} '
        'dpr=${view.devicePixelRatio}',
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _sampleViewport());
  }

  void _sampleViewport() {
    if (!mounted || !_isResizing) return;
    final view = View.of(context);
    final size = view.physicalSize / view.devicePixelRatio;
    if (!_viewportStability.sample(size)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sampleViewport());
      return;
    }
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: 280), () {
      if (!mounted || !_isResizing) return;
      final currentView = View.of(context);
      final currentSize =
          currentView.physicalSize / currentView.devicePixelRatio;
      if (!_viewportStability.sample(currentSize)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _sampleViewport());
        return;
      }
      _viewportStability.complete();
      _game?.resumeEngine();
      if (_debugViewportEnabled(Uri.base)) {
        debugPrint(
          '[BearMath Flutter viewport] stable '
          '${currentSize.width}×${currentSize.height}',
        );
      }
      setState(() => _isResizing = false);
    });
  }

  void _interruptGameplay() {
    _controlsController.interrupt();
    _game?.stopMoving();
    if (_isResizing || _viewportStability.phase == ViewportPhase.resizing) {
      _game?.pauseEngine();
    }
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

  bool _debugViewportEnabled(Uri uri) {
    return uri.queryParameters['debugViewport'] == '1' ||
        _fragmentQueryParameters(uri.fragment)['debugViewport'] == '1';
  }
}

class _ViewportSettlingOverlay extends StatelessWidget {
  const _ViewportSettlingOverlay();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: ColoredBox(
        color: Color(0x33001C38),
        child: Center(
          child: SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      ),
    );
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
