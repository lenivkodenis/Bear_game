import 'dart:ui';

import 'package:bear_game/game/game_viewport_layout.dart';
import 'package:bear_game/game/level_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mobileViewports = <Size>[
    Size(320, 568),
    Size(360, 800),
    Size(375, 667),
    Size(390, 844),
    Size(393, 852),
    Size(412, 915),
    Size(568, 320),
    Size(667, 375),
    Size(844, 390),
    Size(915, 412),
  ];

  test('compact viewport always fills the canvas without letterboxing', () {
    for (final viewport in mobileViewports) {
      final layout = GameViewportLayout.cover(
        canvasSize: viewport,
        playerCenterX: 111,
        gameplayGroundY: 489,
      );

      expect(
        layout.visibleWorldSize.width,
        lessThanOrEqualTo(GameViewportLayout.authoredWorldSize.width + 0.001),
        reason: '$viewport must not expose horizontal letterboxing',
      );
      expect(
        layout.visibleWorldSize.height,
        lessThanOrEqualTo(GameViewportLayout.authoredWorldSize.height + 0.001),
        reason: '$viewport must not expose vertical letterboxing',
      );
      expect(layout.zoom, greaterThan(0));
    }
  });

  test('camera gives the moving player a long view ahead', () {
    final layout = GameViewportLayout.cover(
      canvasSize: const Size(390, 844),
      playerCenterX: 400,
      gameplayGroundY: 489,
    );
    final playerOnScreen = layout.worldToScreen(const Offset(400, 489));

    expect(
      playerOnScreen.dx,
      closeTo(390 * GameViewportLayout.playerScreenFraction, 0.01),
    );
    expect(layout.visibleWorldRect.right - 400, greaterThan(180));
  });

  test('wide mobile landscape shows the full route above browser controls', () {
    final layout = GameViewportLayout.cover(
      canvasSize: const Size(844, 390),
      playerCenterX: 300,
      gameplayGroundY: 489,
    );

    expect(
      layout.visibleWorldSize.width,
      closeTo(GameViewportLayout.authoredWorldSize.width, 0.001),
    );
    expect(layout.visibleWorldRect.left, 0);
    expect(layout.visibleWorldRect.right, closeTo(800, 0.001));
  });

  test('resize and rotation recalculate zoom and camera crop', () {
    final portrait = GameViewportLayout.cover(
      canvasSize: const Size(390, 844),
      playerCenterX: 400,
      gameplayGroundY: 489,
    );
    final landscape = GameViewportLayout.cover(
      canvasSize: const Size(844, 390),
      playerCenterX: 400,
      gameplayGroundY: 489,
    );

    expect(portrait.zoom, isNot(landscape.zoom));
    expect(portrait.visibleWorldSize, isNot(landscape.visibleWorldSize));
    expect(portrait.visibleWorldRect.contains(const Offset(400, 489)), isTrue);
    expect(landscape.visibleWorldRect.contains(const Offset(400, 489)), isTrue);
  });

  test('ground remains visible above the bottom edge on short landscape', () {
    final layout = GameViewportLayout.cover(
      canvasSize: const Size(568, 320),
      playerCenterX: 111,
      gameplayGroundY: 519,
    );
    final groundOnScreen = layout.worldToScreen(const Offset(111, 519));

    expect(groundOnScreen.dy, greaterThan(0));
    expect(groundOnScreen.dy, lessThan(320));
  });

  test('browser-height landscape keeps the bear and mentor fully visible', () {
    final layout = GameViewportLayout.cover(
      canvasSize: const Size(848, 249),
      playerCenterX: 400,
      gameplayGroundY: 489,
    );

    const bearBounds = Rect.fromLTWH(361, 397, 78, 92);
    const mentorBounds = Rect.fromLTWH(650, 359, 100, 130);
    expect(layout.visibleWorldRect.contains(bearBounds.topLeft), isTrue);
    expect(
      layout.visibleWorldRect.contains(
        bearBounds.bottomRight - const Offset(0.001, 0.001),
      ),
      isTrue,
    );
    expect(layout.visibleWorldRect.contains(mentorBounds.topLeft), isTrue);
    expect(
      layout.visibleWorldRect.contains(
        mentorBounds.bottomRight - const Offset(0.001, 0.001),
      ),
      isTrue,
    );
  });

  test('all level obstacles become fully visible before contact', () async {
    final geometries = await LevelGeometryService().loadGeometries();

    for (final geometry in geometries) {
      final gameplayGroundY = geometry.groundColliders
          .map((ground) => ground.y)
          .reduce((left, right) => left > right ? left : right);
      final spawnCenterX = geometry.playerSpawn.x + 39;

      for (final viewport in mobileViewports) {
        for (final obstacle in geometry.obstacleColliders) {
          // The bear is 78 units wide. This position leaves a 20-unit
          // reaction gap between its right edge and the obstacle.
          final playerCenterX = (obstacle.x - 59)
              .clamp(spawnCenterX, GameViewportLayout.authoredWorldSize.width)
              .toDouble();
          final layout = GameViewportLayout.cover(
            canvasSize: viewport,
            playerCenterX: playerCenterX,
            gameplayGroundY: gameplayGroundY,
          );
          final obstacleRect = Rect.fromLTWH(
            obstacle.x,
            obstacle.y,
            obstacle.width,
            obstacle.height,
          );

          expect(
            layout.visibleWorldRect.contains(obstacleRect.topLeft),
            isTrue,
            reason:
                'Level ${geometry.levelId}, $viewport: '
                '${obstacle.id} top-left',
          );
          expect(
            layout.visibleWorldRect.contains(
              obstacleRect.bottomRight - const Offset(0.001, 0.001),
            ),
            isTrue,
            reason:
                'Level ${geometry.levelId}, $viewport: '
                '${obstacle.id} bottom-right',
          );
        }
      }
    }
  });
}
