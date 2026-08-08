import 'dart:math' as math;
import 'dart:ui';

const double groundSegmentTopTolerance = 3.0;

double findGroundSurfaceY({
  required Rect playerRect,
  required Iterable<Rect> groundRects,
  required double fallbackGroundY,
}) {
  final feetX = playerRect.center.dx;
  Rect? bestGround;

  for (final groundRect in groundRects) {
    if (feetX < groundRect.left || feetX > groundRect.right) {
      continue;
    }

    if (bestGround == null || groundRect.top < bestGround.top) {
      bestGround = groundRect;
    }
  }

  return bestGround?.top ?? fallbackGroundY;
}

Rect resolveGroundSegmentSideCollision({
  required Rect previousPlayerRect,
  required Rect futurePlayerRect,
  required Iterable<Rect> groundRects,
  required double minX,
  required double maxX,
  double topTolerance = groundSegmentTopTolerance,
}) {
  final sortedGroundRects = groundRects.toList(growable: false)
    ..sort((left, right) => left.left.compareTo(right.left));
  var resolvedRect = futurePlayerRect;

  for (var index = 0; index < sortedGroundRects.length - 1; index += 1) {
    final leftGround = sortedGroundRects[index];
    final rightGround = sortedGroundRects[index + 1];
    if (!_segmentsTouch(leftGround, rightGround)) {
      continue;
    }

    final boundaryX = leftGround.right;
    if (rightGround.top < leftGround.top &&
        _blocksRightStepUp(
          previousPlayerRect: previousPlayerRect,
          futurePlayerRect: resolvedRect,
          boundaryX: boundaryX,
          upperTopY: rightGround.top,
          lowerTopY: leftGround.top,
          topTolerance: topTolerance,
        )) {
      resolvedRect = _withLeft(
        resolvedRect,
        (boundaryX - resolvedRect.width).clamp(minX, maxX).toDouble(),
      );
      continue;
    }

    if (leftGround.top < rightGround.top &&
        _blocksLeftStepUp(
          previousPlayerRect: previousPlayerRect,
          futurePlayerRect: resolvedRect,
          boundaryX: boundaryX,
          upperTopY: leftGround.top,
          lowerTopY: rightGround.top,
          topTolerance: topTolerance,
        )) {
      resolvedRect = _withLeft(
        resolvedRect,
        boundaryX.clamp(minX, maxX).toDouble(),
      );
    }
  }

  return resolvedRect;
}

bool _segmentsTouch(Rect leftGround, Rect rightGround) {
  return (leftGround.right - rightGround.left).abs() <= 0.01;
}

bool _blocksRightStepUp({
  required Rect previousPlayerRect,
  required Rect futurePlayerRect,
  required double boundaryX,
  required double upperTopY,
  required double lowerTopY,
  required double topTolerance,
}) {
  final movingRight = futurePlayerRect.left > previousPlayerRect.left;
  return movingRight &&
      previousPlayerRect.right <= boundaryX + 0.01 &&
      futurePlayerRect.right > boundaryX &&
      _playerHitsStepWall(
        playerRect: futurePlayerRect,
        upperTopY: upperTopY,
        lowerTopY: lowerTopY,
        topTolerance: topTolerance,
      );
}

bool _blocksLeftStepUp({
  required Rect previousPlayerRect,
  required Rect futurePlayerRect,
  required double boundaryX,
  required double upperTopY,
  required double lowerTopY,
  required double topTolerance,
}) {
  final movingLeft = futurePlayerRect.left < previousPlayerRect.left;
  return movingLeft &&
      previousPlayerRect.left >= boundaryX - 0.01 &&
      futurePlayerRect.left < boundaryX &&
      _playerHitsStepWall(
        playerRect: futurePlayerRect,
        upperTopY: upperTopY,
        lowerTopY: lowerTopY,
        topTolerance: topTolerance,
      );
}

bool _playerHitsStepWall({
  required Rect playerRect,
  required double upperTopY,
  required double lowerTopY,
  required double topTolerance,
}) {
  final wallTop = math.min(upperTopY, lowerTopY);
  final wallBottom = math.max(upperTopY, lowerTopY);
  final overlapsWallHeight =
      playerRect.top < wallBottom && playerRect.bottom > wallTop;

  return overlapsWallHeight && playerRect.bottom > upperTopY + topTolerance;
}

Rect _withLeft(Rect rect, double left) {
  return Rect.fromLTWH(left, rect.top, rect.width, rect.height);
}
