import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show EdgeInsets;

enum GameViewportMode { portrait, landscape, ultraShortLandscape, tablet }

/// Pure camera model for the authored 800×600 world. It intentionally permits
/// letterboxing when a browser toolbar leaves too little height: gameplay must
/// remain visible before decorative edge-to-edge filling.
class GameViewportLayout {
  const GameViewportLayout({
    required this.canvasSize,
    required this.worldSize,
    required this.mode,
    required this.zoom,
    required this.cameraTopLeft,
    required this.safeWorldEnvelope,
  });

  static const Size authoredWorldSize = Size(800, 600);
  static const double portraitVisibleWorldWidth = 560;
  static const double playerScreenFraction = 0.22;
  static const double reversePlayerScreenFraction = 0.78;
  static const double jumpSafetyMargin = 16;
  static const double groundSafetyMargin = 12;

  final Size canvasSize;
  final Size worldSize;
  final GameViewportMode mode;
  final double zoom;
  final Offset cameraTopLeft;
  final Rect safeWorldEnvelope;

  Size get visibleWorldSize =>
      Size(canvasSize.width / zoom, canvasSize.height / zoom);

  Rect get visibleWorldRect => cameraTopLeft & visibleWorldSize;

  Offset worldToScreen(Offset worldPoint) {
    return Offset(
      (worldPoint.dx - cameraTopLeft.dx) * zoom,
      (worldPoint.dy - cameraTopLeft.dy) * zoom,
    );
  }

  static GameViewportMode modeFor(Size canvasSize) {
    if (canvasSize.shortestSide >= 600) return GameViewportMode.tablet;
    if (canvasSize.width > canvasSize.height && canvasSize.height < 300) {
      return GameViewportMode.ultraShortLandscape;
    }
    if (canvasSize.width > canvasSize.height) {
      return GameViewportMode.landscape;
    }
    return GameViewportMode.portrait;
  }

  static GameViewportLayout cover({
    required Size canvasSize,
    required double playerCenterX,
    required double gameplayGroundY,
    Size worldSize = authoredWorldSize,
    EdgeInsets occlusion = EdgeInsets.zero,
    double playerVisualHeight = 96,
    double jumpImpulse = 410,
    double gravity = 820,
    Iterable<Rect> obstacleBounds = const <Rect>[],
    double movementDirection = 1,
  }) {
    final mode = modeFor(canvasSize);
    if (canvasSize.width <= 0 ||
        canvasSize.height <= 0 ||
        worldSize.width <= 0 ||
        worldSize.height <= 0) {
      return GameViewportLayout(
        canvasSize: canvasSize,
        worldSize: worldSize,
        mode: mode,
        zoom: 1,
        cameraTopLeft: Offset.zero,
        safeWorldEnvelope: Rect.zero,
      );
    }

    final jumpRise = jumpImpulse * jumpImpulse / (2 * math.max(1, gravity));
    final obstacleTop = obstacleBounds.fold<double>(
      gameplayGroundY,
      (top, obstacle) => math.min(top, obstacle.top),
    );
    final envelopeTop = math.min(
      gameplayGroundY - playerVisualHeight - jumpRise - jumpSafetyMargin,
      obstacleTop - jumpSafetyMargin,
    );
    final envelopeBottom = gameplayGroundY + groundSafetyMargin;
    final envelope = Rect.fromLTRB(
      0,
      envelopeTop,
      worldSize.width,
      envelopeBottom,
    );

    final usableHeight = math.max(
      1.0,
      canvasSize.height - occlusion.top - occlusion.bottom,
    );
    final verticalFitZoom = usableHeight / math.max(1, envelope.height);
    final preferredZoom = switch (mode) {
      GameViewportMode.portrait => math.max(
        canvasSize.width / math.min(worldSize.width, portraitVisibleWorldWidth),
        canvasSize.height / worldSize.height,
      ),
      GameViewportMode.landscape || GameViewportMode.ultraShortLandscape =>
        canvasSize.width / worldSize.width,
      GameViewportMode.tablet => math.max(
        canvasSize.width / worldSize.width,
        canvasSize.height / worldSize.height,
      ),
    };
    final zoom = math.max(0.1, math.min(preferredZoom, verticalFitZoom));
    final visibleWidth = canvasSize.width / zoom;
    final visibleHeight = canvasSize.height / zoom;

    final playerFraction = movementDirection < 0
        ? reversePlayerScreenFraction
        : playerScreenFraction;
    var desiredLeft = playerCenterX - visibleWidth * playerFraction;
    final nearestAhead = obstacleBounds
        .where(
          (obstacle) => movementDirection < 0
              ? obstacle.right <= playerCenterX
              : obstacle.left >= playerCenterX,
        )
        .fold<Rect?>(null, (nearest, obstacle) {
          if (nearest == null) return obstacle;
          final nearestDistance = (nearest.left - playerCenterX).abs();
          final distance = (obstacle.left - playerCenterX).abs();
          return distance < nearestDistance ? obstacle : nearest;
        });
    if (nearestAhead != null && visibleWidth < worldSize.width) {
      const reactionMargin = 20.0;
      if (movementDirection < 0) {
        desiredLeft = math.min(desiredLeft, nearestAhead.left - reactionMargin);
      } else {
        desiredLeft = math.max(
          desiredLeft,
          nearestAhead.right + reactionMargin - visibleWidth,
        );
      }
    }

    final desiredGroundFraction = switch (mode) {
      GameViewportMode.portrait => 0.72,
      GameViewportMode.landscape => 0.76,
      GameViewportMode.ultraShortLandscape => 0.78,
      GameViewportMode.tablet => 0.76,
    };
    final preferredTop =
        gameplayGroundY - visibleHeight * desiredGroundFraction;
    final minimumTop =
        envelopeBottom - (canvasSize.height - occlusion.bottom) / zoom;
    final maximumTop = envelopeTop - occlusion.top / zoom;
    var desiredTop = minimumTop <= maximumTop
        ? preferredTop.clamp(minimumTop, maximumTop).toDouble()
        : (minimumTop + maximumTop) / 2;

    desiredLeft = _clampCameraAxis(desiredLeft, visibleWidth, worldSize.width);
    desiredTop = _clampCameraAxis(desiredTop, visibleHeight, worldSize.height);

    return GameViewportLayout(
      canvasSize: canvasSize,
      worldSize: worldSize,
      mode: mode,
      zoom: zoom,
      cameraTopLeft: Offset(desiredLeft, desiredTop),
      safeWorldEnvelope: envelope,
    );
  }

  static double _clampCameraAxis(
    double desired,
    double visibleExtent,
    double worldExtent,
  ) {
    if (visibleExtent >= worldExtent) {
      return (worldExtent - visibleExtent) / 2;
    }
    return desired.clamp(0.0, worldExtent - visibleExtent).toDouble();
  }
}
