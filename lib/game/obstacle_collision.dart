import 'dart:ui';

const double obstacleTopTolerance = 3.0;

Rect resolveObstacleSideCollision({
  required Rect previousPlayerRect,
  required Rect futurePlayerRect,
  required Iterable<Rect> obstacleRects,
  required double minX,
  required double maxX,
  double topTolerance = obstacleTopTolerance,
}) {
  var resolvedRect = futurePlayerRect;

  for (final obstacleRect in obstacleRects) {
    if (_isLeavingTopSurface(
      previousPlayerRect: previousPlayerRect,
      futurePlayerRect: resolvedRect,
      obstacleRect: obstacleRect,
      topTolerance: topTolerance,
    )) {
      continue;
    }

    if (!blocksObstacleSideMovement(
      futurePlayerRect: resolvedRect,
      obstacleRect: obstacleRect,
      topTolerance: topTolerance,
    )) {
      continue;
    }

    final resolveOnLeft = _shouldResolveOnLeft(
      previousPlayerRect: previousPlayerRect,
      futurePlayerRect: resolvedRect,
      obstacleRect: obstacleRect,
    );
    final resolvedLeft = resolveOnLeft
        ? obstacleRect.left - resolvedRect.width
        : obstacleRect.right;
    final clampedLeft = resolvedLeft.clamp(minX, maxX).toDouble();
    resolvedRect = Rect.fromLTWH(
      clampedLeft,
      resolvedRect.top,
      resolvedRect.width,
      resolvedRect.height,
    );
  }

  return resolvedRect;
}

Rect? findObstacleTopLanding({
  required Rect previousPlayerRect,
  required Rect futurePlayerRect,
  required Iterable<Rect> obstacleRects,
  double topTolerance = obstacleTopTolerance,
}) {
  for (final obstacleRect in obstacleRects) {
    if (!feetXInsideObstacle(futurePlayerRect, obstacleRect)) {
      continue;
    }

    final wasAboveTop =
        previousPlayerRect.bottom <= obstacleRect.top + topTolerance;
    final crossedTop =
        futurePlayerRect.bottom >= obstacleRect.top &&
        futurePlayerRect.top < obstacleRect.top;
    final movingDown = futurePlayerRect.bottom >= previousPlayerRect.bottom;
    if (wasAboveTop && crossedTop && movingDown) {
      return obstacleRect;
    }
  }

  return null;
}

Rect? findObstacleTopSupport({
  required Rect playerRect,
  required Iterable<Rect> obstacleRects,
  double topTolerance = obstacleTopTolerance,
}) {
  for (final obstacleRect in obstacleRects) {
    final feetOnTop =
        (playerRect.bottom - obstacleRect.top).abs() <= topTolerance;
    if (feetOnTop && feetXInsideObstacle(playerRect, obstacleRect)) {
      return obstacleRect;
    }
  }

  return null;
}

bool blocksObstacleSideMovement({
  required Rect futurePlayerRect,
  required Rect obstacleRect,
  double topTolerance = obstacleTopTolerance,
}) {
  return rectsOverlapHorizontally(futurePlayerRect, obstacleRect) &&
      futurePlayerRect.overlaps(obstacleRect) &&
      !isPlayerAboveObstacleTop(
        playerRect: futurePlayerRect,
        obstacleRect: obstacleRect,
        topTolerance: topTolerance,
      );
}

bool isPlayerAboveObstacleTop({
  required Rect playerRect,
  required Rect obstacleRect,
  double topTolerance = obstacleTopTolerance,
}) {
  return playerRect.bottom <= obstacleRect.top + topTolerance;
}

bool feetXInsideObstacle(Rect playerRect, Rect obstacleRect) {
  final feetX = playerRect.center.dx;
  return feetX >= obstacleRect.left && feetX <= obstacleRect.right;
}

bool rectsOverlapHorizontally(Rect a, Rect b) {
  return a.left < b.right && a.right > b.left;
}

bool _isLeavingTopSurface({
  required Rect previousPlayerRect,
  required Rect futurePlayerRect,
  required Rect obstacleRect,
  required double topTolerance,
}) {
  if (feetXInsideObstacle(futurePlayerRect, obstacleRect)) {
    return false;
  }

  final horizontalDelta = futurePlayerRect.left - previousPlayerRect.left;
  final feetPastRightEdge = futurePlayerRect.center.dx > obstacleRect.right;
  final feetPastLeftEdge = futurePlayerRect.center.dx < obstacleRect.left;
  final movingIntoObstacle =
      (feetPastRightEdge && horizontalDelta < 0) ||
      (feetPastLeftEdge && horizontalDelta > 0);
  if (movingIntoObstacle) {
    return false;
  }

  final justLeftTop =
      previousPlayerRect.bottom <= obstacleRect.top + topTolerance &&
      futurePlayerRect.bottom > obstacleRect.top;
  final stillDroppingBesideObstacle =
      previousPlayerRect.bottom < obstacleRect.bottom &&
      futurePlayerRect.top < obstacleRect.top;

  return justLeftTop || stillDroppingBesideObstacle;
}

bool _shouldResolveOnLeft({
  required Rect previousPlayerRect,
  required Rect futurePlayerRect,
  required Rect obstacleRect,
}) {
  final horizontalDelta = futurePlayerRect.left - previousPlayerRect.left;
  if (horizontalDelta > 0) {
    return true;
  }
  if (horizontalDelta < 0) {
    return false;
  }

  final leftPenetration = futurePlayerRect.right - obstacleRect.left;
  final rightPenetration = obstacleRect.right - futurePlayerRect.left;
  return leftPenetration <= rightPenetration;
}
