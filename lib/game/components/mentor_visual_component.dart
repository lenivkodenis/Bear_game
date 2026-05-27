import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

import '../level_background_assets.dart';

class MentorVisualSpec {
  const MentorVisualSpec({
    required this.assetPath,
    required this.targetHeight,
    this.offsetX = 0,
    this.offsetY = 0,
    this.idleGestureParts = const <MentorIdleGesturePart>[],
  });

  final String assetPath;
  final double targetHeight;
  final double offsetX;
  final double offsetY;
  final List<MentorIdleGesturePart> idleGestureParts;
}

class MentorIdleGesturePart {
  const MentorIdleGesturePart({
    required this.sourceRect,
    required this.pivot,
    this.angleAmplitude = 0.025,
    this.offsetAmplitude = ui.Offset.zero,
    this.speed = 1.5,
    this.phase = 0,
  });

  final ui.Rect sourceRect;
  final ui.Offset pivot;
  final double angleAmplitude;
  final ui.Offset offsetAmplitude;
  final double speed;
  final double phase;
}

const Map<int, MentorVisualSpec>
mentorVisualSpecsByLevelId = <int, MentorVisualSpec>{
  1: MentorVisualSpec(
    assetPath: 'assets/images/characters/mentors/level_01_ice_floe/mentor.png',
    targetHeight: 169,
    offsetX: 48,
    offsetY: 18,
    idleGestureParts: <MentorIdleGesturePart>[
      MentorIdleGesturePart(
        sourceRect: ui.Rect.fromLTWH(0.27, 0.24, 0.21, 0.24),
        pivot: ui.Offset(0.78, 0.58),
        angleAmplitude: 0.035,
        offsetAmplitude: ui.Offset(0.8, -0.6),
        speed: 1.7,
      ),
      MentorIdleGesturePart(
        sourceRect: ui.Rect.fromLTWH(0.55, 0.06, 0.33, 0.80),
        pivot: ui.Offset(0.28, 0.26),
        angleAmplitude: 0.022,
        offsetAmplitude: ui.Offset(1.0, 0),
        speed: 1.45,
        phase: math.pi / 4,
      ),
    ],
  ),
  2: MentorVisualSpec(
    assetPath: 'assets/images/characters/mentors/level_02_icy_river/mentor.png',
    targetHeight: 100,
    offsetX: 18,
  ),
  3: MentorVisualSpec(
    assetPath:
        'assets/images/characters/mentors/level_03_snowy_shore/mentor.png',
    targetHeight: 95,
    offsetX: 16,
  ),
  4: MentorVisualSpec(
    assetPath:
        'assets/images/characters/mentors/level_04_northern_forest/mentor.png',
    targetHeight: 115,
    offsetX: 16,
  ),
  5: MentorVisualSpec(
    assetPath: 'assets/images/characters/mentors/level_05_ice_cave/mentor.png',
    targetHeight: 105,
    offsetX: 18,
  ),
  6: MentorVisualSpec(
    assetPath:
        'assets/images/characters/mentors/level_06_snowy_valley/mentor.png',
    targetHeight: 135,
    offsetX: 14,
  ),
  7: MentorVisualSpec(
    assetPath:
        'assets/images/characters/mentors/level_07_mountain_pass/mentor.png',
    targetHeight: 130,
    offsetX: 12,
  ),
  8: MentorVisualSpec(
    assetPath:
        'assets/images/characters/mentors/level_08_polar_night/mentor.png',
    targetHeight: 125,
    offsetX: 16,
  ),
  9: MentorVisualSpec(
    assetPath:
        'assets/images/characters/mentors/level_09_northern_lights/mentor.png',
    targetHeight: 105,
    offsetX: 18,
  ),
  10: MentorVisualSpec(
    assetPath:
        'assets/images/characters/mentors/level_10_northern_ocean/mentor.png',
    targetHeight: 135,
    offsetX: 14,
  ),
};

MentorVisualSpec mentorVisualSpecForLevel(int levelId) {
  final spec = mentorVisualSpecsByLevelId[levelId];
  if (spec == null) {
    throw StateError('Missing mentor visual spec for level id $levelId.');
  }

  return spec;
}

class MentorVisualComponent extends SpriteComponent {
  MentorVisualComponent({required int levelId, required Vector2 groundPosition})
    : spec = mentorVisualSpecForLevel(levelId),
      super(
        position: _positionFor(levelId, groundPosition),
        size: _initialSizeFor(levelId),
        anchor: Anchor.bottomCenter,
        priority: 10,
      );

  final MentorVisualSpec spec;
  ui.Image? _image;
  double _gestureTime = 0;
  bool _isWaitingForPlayer = true;

  Vector2 get interactionPoint {
    return position - Vector2(0, size.y * 0.5);
  }

  void setWaitingForPlayer(bool value) {
    _isWaitingForPlayer = value;
    if (!value) {
      _gestureTime = 0;
    }
  }

  void moveToGroundPosition(Vector2 groundPosition) {
    position = _positionForSpec(spec, groundPosition);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final image = await Flame.images.load(
      LevelBackgroundAssets.flameImageKey(spec.assetPath),
    );
    _image = image;
    sprite = Sprite(image);
    size = Vector2(
      spec.targetHeight * image.width / image.height,
      spec.targetHeight,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isWaitingForPlayer && spec.idleGestureParts.isNotEmpty) {
      _gestureTime += dt;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    final image = _image;
    if (image == null ||
        !_isWaitingForPlayer ||
        spec.idleGestureParts.isEmpty) {
      return;
    }

    final paint = ui.Paint()..filterQuality = ui.FilterQuality.high;
    for (final part in spec.idleGestureParts) {
      _renderIdleGesturePart(canvas, image, part, paint);
    }
  }

  static Vector2 _positionFor(int levelId, Vector2 groundPosition) {
    final spec = mentorVisualSpecForLevel(levelId);
    return _positionForSpec(spec, groundPosition);
  }

  static Vector2 _initialSizeFor(int levelId) {
    final spec = mentorVisualSpecForLevel(levelId);
    return Vector2(spec.targetHeight, spec.targetHeight);
  }

  static Vector2 _positionForSpec(
    MentorVisualSpec spec,
    Vector2 groundPosition,
  ) {
    return groundPosition + Vector2(spec.offsetX, spec.offsetY);
  }

  void _renderIdleGesturePart(
    ui.Canvas canvas,
    ui.Image image,
    MentorIdleGesturePart part,
    ui.Paint paint,
  ) {
    final sourceRect = _sourceRectFor(image, part.sourceRect);
    final destinationRect = _destinationRectFor(image, sourceRect);
    final wave = math.sin(_gestureTime * part.speed + part.phase);
    final pivot = ui.Offset(
      destinationRect.left + destinationRect.width * part.pivot.dx,
      destinationRect.top + destinationRect.height * part.pivot.dy,
    );
    final offset = part.offsetAmplitude * wave;

    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(part.angleAmplitude * wave);
    canvas.translate(offset.dx, offset.dy);
    canvas.translate(-pivot.dx, -pivot.dy);
    canvas.drawImageRect(image, sourceRect, destinationRect, paint);
    canvas.restore();
  }

  ui.Rect _sourceRectFor(ui.Image image, ui.Rect normalizedRect) {
    return ui.Rect.fromLTWH(
      normalizedRect.left * image.width,
      normalizedRect.top * image.height,
      normalizedRect.width * image.width,
      normalizedRect.height * image.height,
    );
  }

  ui.Rect _destinationRectFor(ui.Image image, ui.Rect sourceRect) {
    final scaleX = size.x / image.width;
    final scaleY = size.y / image.height;

    return ui.Rect.fromLTWH(
      sourceRect.left * scaleX,
      sourceRect.top * scaleY,
      sourceRect.width * scaleX,
      sourceRect.height * scaleY,
    );
  }
}
