import 'dart:ui';

const double obstacleTopTolerance = 3.0;
const double slopedObstacleSnapTolerance = 8.0;
const double slopedObstacleEdgeCapture = 24.0;

class SlopedObstacleSurface {
  const SlopedObstacleSurface({
    required this.bounds,
    required this.surfaceYAtLeft,
    required this.surfaceYAtRight,
    this.edgeCapture = slopedObstacleEdgeCapture,
  });

  final Rect bounds;
  final double surfaceYAtLeft;
  final double surfaceYAtRight;
  final double edgeCapture;

  double surfaceYAt(double x) {
    final normalizedX = ((x - bounds.left) / bounds.width).clamp(0.0, 1.0);
    return surfaceYAtLeft + (surfaceYAtRight - surfaceYAtLeft) * normalizedX;
  }
}

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

double? findSlopedObstacleSurfaceContact({
  required Rect previousPlayerRect,
  required Rect futurePlayerRect,
  required Iterable<SlopedObstacleSurface> slopedSurfaces,
  double topTolerance = obstacleTopTolerance,
  double snapTolerance = slopedObstacleSnapTolerance,
}) {
  for (final surface in slopedSurfaces) {
    if (!feetXNearSlopedSurface(
      futurePlayerRect,
      surface,
      edgeCapture: surface.edgeCapture,
    )) {
      continue;
    }

    final previousSurfaceY = surface.surfaceYAt(previousPlayerRect.center.dx);
    final futureSurfaceY = surface.surfaceYAt(futurePlayerRect.center.dx);
    final wasOnSurface =
        (previousPlayerRect.bottom - previousSurfaceY).abs() <= snapTolerance;
    final wasAboveSurface =
        previousPlayerRect.bottom <= previousSurfaceY + topTolerance;
    final crossedSurface =
        futurePlayerRect.bottom >= futureSurfaceY - topTolerance &&
        futurePlayerRect.top < futureSurfaceY;
    final canSnapToSurface =
        futurePlayerRect.bottom >= futureSurfaceY - topTolerance &&
        futurePlayerRect.bottom <= futureSurfaceY + snapTolerance &&
        futurePlayerRect.top < futureSurfaceY;

    if ((wasOnSurface || wasAboveSurface) &&
        (crossedSurface || canSnapToSurface)) {
      return futureSurfaceY;
    }
  }

  return null;
}

double? findSlopedObstacleTopSupport({
  required Rect playerRect,
  required Iterable<SlopedObstacleSurface> slopedSurfaces,
  double horizontalVelocityX = 0,
  double topTolerance = obstacleTopTolerance,
  double snapTolerance = slopedObstacleSnapTolerance,
}) {
  for (final surface in slopedSurfaces) {
    final feetInside = feetXInsideObstacle(playerRect, surface.bounds);
    final feetNear = feetXNearSlopedSurface(
      playerRect,
      surface,
      edgeCapture: surface.edgeCapture,
    );
    final movingIntoSlopeEdge = _isMovingTowardSlopedObstacle(
      playerRect: playerRect,
      surface: surface,
      horizontalVelocityX: horizontalVelocityX,
    );
    if (!feetInside && (!feetNear || !movingIntoSlopeEdge)) {
      continue;
    }

    final surfaceY = surface.surfaceYAt(playerRect.center.dx);
    final nearSurface =
        playerRect.bottom >= surfaceY - topTolerance &&
        playerRect.bottom <= surfaceY + snapTolerance &&
        playerRect.top < surfaceY;
    if (nearSurface) {
      return surfaceY;
    }
  }

  return null;
}

Rect resolveSlopedObstacleSideCollision({
  required Rect previousPlayerRect,
  required Rect futurePlayerRect,
  required Iterable<SlopedObstacleSurface> slopedSurfaces,
  required double minX,
  required double maxX,
  double topTolerance = obstacleTopTolerance,
  double snapTolerance = slopedObstacleSnapTolerance,
}) {
  var resolvedRect = futurePlayerRect;

  for (final surface in slopedSurfaces) {
    final obstacleRect = surface.bounds;
    if (!rectsOverlapHorizontally(resolvedRect, obstacleRect) ||
        !resolvedRect.overlaps(obstacleRect)) {
      continue;
    }
    if (_isAboveOrNearSlopedSurface(
      playerRect: resolvedRect,
      surface: surface,
      snapTolerance: snapTolerance,
    )) {
      continue;
    }
    if (_isMovingAwayFromSlopedObstacle(
      previousPlayerRect: previousPlayerRect,
      futurePlayerRect: resolvedRect,
      surface: surface,
    )) {
      continue;
    }
    if (_isRisingFromSlopedSurface(
      previousPlayerRect: previousPlayerRect,
      futurePlayerRect: resolvedRect,
      surface: surface,
      snapTolerance: snapTolerance,
    )) {
      continue;
    }
    if (_isApproachingSlopedTopFromSide(
      previousPlayerRect: previousPlayerRect,
      futurePlayerRect: resolvedRect,
      surface: surface,
      snapTolerance: snapTolerance,
    )) {
      continue;
    }

    final surfaceY = surface.surfaceYAt(resolvedRect.center.dx);
    final isNearTopSurface =
        feetXInsideObstacle(resolvedRect, obstacleRect) &&
        resolvedRect.bottom >= surfaceY - topTolerance &&
        resolvedRect.bottom <= surfaceY + snapTolerance &&
        resolvedRect.top < surfaceY;
    if (isNearTopSurface) {
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

bool _isAboveOrNearSlopedSurface({
  required Rect playerRect,
  required SlopedObstacleSurface surface,
  required double snapTolerance,
}) {
  final surfaceY = surface.surfaceYAt(playerRect.center.dx);
  return playerRect.bottom <= surfaceY + snapTolerance &&
      playerRect.top < surfaceY;
}

bool _isMovingAwayFromSlopedObstacle({
  required Rect previousPlayerRect,
  required Rect futurePlayerRect,
  required SlopedObstacleSurface surface,
}) {
  if (feetXInsideObstacle(futurePlayerRect, surface.bounds)) {
    return false;
  }

  final horizontalDelta = futurePlayerRect.left - previousPlayerRect.left;
  final feetPastRightEdge = futurePlayerRect.center.dx > surface.bounds.right;
  final feetPastLeftEdge = futurePlayerRect.center.dx < surface.bounds.left;

  return (feetPastRightEdge && horizontalDelta > 0) ||
      (feetPastLeftEdge && horizontalDelta < 0);
}

bool _isMovingTowardSlopedObstacle({
  required Rect playerRect,
  required SlopedObstacleSurface surface,
  required double horizontalVelocityX,
}) {
  final feetPastRightEdge = playerRect.center.dx > surface.bounds.right;
  final feetPastLeftEdge = playerRect.center.dx < surface.bounds.left;

  return (feetPastRightEdge && horizontalVelocityX < 0) ||
      (feetPastLeftEdge && horizontalVelocityX > 0);
}

bool _isRisingFromSlopedSurface({
  required Rect previousPlayerRect,
  required Rect futurePlayerRect,
  required SlopedObstacleSurface surface,
  required double snapTolerance,
}) {
  if (futurePlayerRect.bottom >= previousPlayerRect.bottom) {
    return false;
  }
  if (!feetXNearSlopedSurface(
    previousPlayerRect,
    surface,
    edgeCapture: surface.edgeCapture,
  )) {
    return false;
  }

  final previousSurfaceY = surface.surfaceYAt(previousPlayerRect.center.dx);
  final wasOnSurface =
      (previousPlayerRect.bottom - previousSurfaceY).abs() <= snapTolerance;

  return wasOnSurface && futurePlayerRect.top < previousSurfaceY;
}

bool _isApproachingSlopedTopFromSide({
  required Rect previousPlayerRect,
  required Rect futurePlayerRect,
  required SlopedObstacleSurface surface,
  required double snapTolerance,
}) {
  if (feetXInsideObstacle(futurePlayerRect, surface.bounds)) {
    return false;
  }

  final horizontalDelta = futurePlayerRect.left - previousPlayerRect.left;
  final feetPastRightEdge = futurePlayerRect.center.dx > surface.bounds.right;
  final feetPastLeftEdge = futurePlayerRect.center.dx < surface.bounds.left;
  final movingTowardFromRight = feetPastRightEdge && horizontalDelta < 0;
  final movingTowardFromLeft = feetPastLeftEdge && horizontalDelta > 0;
  if (!movingTowardFromRight && !movingTowardFromLeft) {
    return false;
  }

  final edgeX = movingTowardFromRight
      ? surface.bounds.right
      : surface.bounds.left;
  final edgeSurfaceY = surface.surfaceYAt(edgeX);
  final isNearTopApproach =
      futurePlayerRect.bottom <= edgeSurfaceY + snapTolerance &&
      futurePlayerRect.top < edgeSurfaceY;

  return isNearTopApproach;
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

bool feetXNearSlopedSurface(
  Rect playerRect,
  SlopedObstacleSurface surface, {
  required double edgeCapture,
}) {
  final feetX = playerRect.center.dx;
  return feetX >= surface.bounds.left - edgeCapture &&
      feetX <= surface.bounds.right + edgeCapture &&
      rectsOverlapHorizontally(playerRect, surface.bounds);
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
