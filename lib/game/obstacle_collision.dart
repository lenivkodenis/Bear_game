import 'dart:ui';

const double obstacleTopPassTolerance = 3.0;

Rect resolveObstacleHorizontalCollision({
  required Rect previousPlayerRect,
  required Rect futurePlayerRect,
  required Iterable<Rect> obstacleRects,
  required double minX,
  required double maxX,
  double topPassTolerance = obstacleTopPassTolerance,
}) {
  var resolvedRect = futurePlayerRect;

  for (final obstacleRect in obstacleRects) {
    if (!blocksObstacleHorizontalMovement(
      futurePlayerRect: resolvedRect,
      obstacleRect: obstacleRect,
      topPassTolerance: topPassTolerance,
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

bool blocksObstacleHorizontalMovement({
  required Rect futurePlayerRect,
  required Rect obstacleRect,
  double topPassTolerance = obstacleTopPassTolerance,
}) {
  return futurePlayerRect.overlaps(obstacleRect) &&
      futurePlayerRect.bottom > obstacleRect.top + topPassTolerance;
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
