import 'dart:math' as math;
import 'dart:ui';

/// Pure layout model that maps the authored 800x600 game world to a compact
/// browser viewport without changing world coordinates or collision physics.
class GameViewportLayout {
  const GameViewportLayout({
    required this.canvasSize,
    required this.worldSize,
    required this.zoom,
    required this.cameraTopLeft,
  });

  static const Size authoredWorldSize = Size(800, 600);
  static const double maxVisibleWorldWidth = 560;
  static const double playerScreenFraction = 0.20;
  static const double groundScreenFraction = 0.74;

  final Size canvasSize;
  final Size worldSize;
  final double zoom;
  final Offset cameraTopLeft;

  Size get visibleWorldSize =>
      Size(canvasSize.width / zoom, canvasSize.height / zoom);

  Rect get visibleWorldRect => cameraTopLeft & visibleWorldSize;

  Offset worldToScreen(Offset worldPoint) {
    return Offset(
      (worldPoint.dx - cameraTopLeft.dx) * zoom,
      (worldPoint.dy - cameraTopLeft.dy) * zoom,
    );
  }

  static GameViewportLayout cover({
    required Size canvasSize,
    required double playerCenterX,
    required double gameplayGroundY,
    Size worldSize = authoredWorldSize,
  }) {
    if (canvasSize.width <= 0 ||
        canvasSize.height <= 0 ||
        worldSize.width <= 0 ||
        worldSize.height <= 0) {
      return GameViewportLayout(
        canvasSize: canvasSize,
        worldSize: worldSize,
        zoom: 1,
        cameraTopLeft: Offset.zero,
      );
    }

    final coverZoom = math.max(
      canvasSize.width / worldSize.width,
      canvasSize.height / worldSize.height,
    );
    // A portrait phone needs the cover crop to keep the bear and obstacles
    // readable. In landscape the browser chrome leaves very little height;
    // applying the same horizontal tracking zoom there reduces the game to a
    // narrow strip. Showing the full authored width keeps the whole route,
    // bear and mentor usable without changing world coordinates or physics.
    final isLandscape = canvasSize.width > canvasSize.height;
    final trackingZoom =
        canvasSize.width / math.min(worldSize.width, maxVisibleWorldWidth);
    final zoom = isLandscape ? coverZoom : math.max(coverZoom, trackingZoom);
    final visibleWidth = canvasSize.width / zoom;
    final visibleHeight = canvasSize.height / zoom;
    final maxLeft = math.max(0.0, worldSize.width - visibleWidth);
    final maxTop = math.max(0.0, worldSize.height - visibleHeight);
    final desiredLeft = playerCenterX - visibleWidth * playerScreenFraction;
    final desiredTop = gameplayGroundY - visibleHeight * groundScreenFraction;

    return GameViewportLayout(
      canvasSize: canvasSize,
      worldSize: worldSize,
      zoom: zoom,
      cameraTopLeft: Offset(
        desiredLeft.clamp(0.0, maxLeft).toDouble(),
        desiredTop.clamp(0.0, maxTop).toDouble(),
      ),
    );
  }
}
