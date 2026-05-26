import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:bear_game/game/ground_segment_collision.dart';

void main() {
  const playerWidth = 78.0;
  const playerHeight = 92.0;
  final groundSegments = <Rect>[
    const Rect.fromLTWH(0, 460, 388.62, 140),
    const Rect.fromLTWH(388.62, 500, 230.63, 100),
    const Rect.fromLTWH(619.25, 460, 180.75, 140),
  ];

  Rect playerRect({required double left, required double bottom}) {
    return Rect.fromLTWH(
      left,
      bottom - playerHeight,
      playerWidth,
      playerHeight,
    );
  }

  test('ground segment collision uses the surface below the player feet', () {
    expect(
      findGroundSurfaceY(
        playerRect: playerRect(left: 120, bottom: 460),
        groundRects: groundSegments,
        fallbackGroundY: 460,
      ),
      460,
    );
    expect(
      findGroundSurfaceY(
        playerRect: playerRect(left: 430, bottom: 460),
        groundRects: groundSegments,
        fallbackGroundY: 460,
      ),
      500,
    );
  });

  test(
    'ground segment collision blocks walking from low floor into right wall',
    () {
      final previousRect = playerRect(left: 535, bottom: 500);
      final futureRect = playerRect(left: 555, bottom: 500);

      final resolved = resolveGroundSegmentSideCollision(
        previousPlayerRect: previousRect,
        futurePlayerRect: futureRect,
        groundRects: groundSegments,
        minX: 0,
        maxX: 800 - playerWidth,
      );

      expect(resolved.left, 619.25 - playerWidth);
    },
  );

  test(
    'ground segment collision blocks walking from low floor into left wall',
    () {
      final previousRect = playerRect(left: 395, bottom: 500);
      final futureRect = playerRect(left: 365, bottom: 500);

      final resolved = resolveGroundSegmentSideCollision(
        previousPlayerRect: previousRect,
        futurePlayerRect: futureRect,
        groundRects: groundSegments,
        minX: 0,
        maxX: 800 - playerWidth,
      );

      expect(resolved.left, 388.62);
    },
  );

  test(
    'ground segment collision lets the player walk off high ground into the dip',
    () {
      final previousRect = playerRect(left: 300, bottom: 460);
      final futureRect = playerRect(left: 355, bottom: 460);

      final resolved = resolveGroundSegmentSideCollision(
        previousPlayerRect: previousRect,
        futurePlayerRect: futureRect,
        groundRects: groundSegments,
        minX: 0,
        maxX: 800 - playerWidth,
      );

      expect(resolved.left, futureRect.left);
    },
  );

  test(
    'ground segment collision lets a high enough jump clear the step up',
    () {
      final previousRect = playerRect(left: 540, bottom: 455);
      final futureRect = playerRect(left: 555, bottom: 455);

      final resolved = resolveGroundSegmentSideCollision(
        previousPlayerRect: previousRect,
        futurePlayerRect: futureRect,
        groundRects: groundSegments,
        minX: 0,
        maxX: 800 - playerWidth,
      );

      expect(resolved.left, futureRect.left);
    },
  );
}
