import 'package:flame/components.dart';
import 'package:flame/flame.dart';

import '../level_background_assets.dart';

class MentorVisualSpec {
  const MentorVisualSpec({
    required this.assetPath,
    required this.targetHeight,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  final String assetPath;
  final double targetHeight;
  final double offsetX;
  final double offsetY;
}

const Map<int, MentorVisualSpec>
mentorVisualSpecsByLevelId = <int, MentorVisualSpec>{
  1: MentorVisualSpec(
    assetPath: 'assets/images/characters/mentors/level_01_ice_floe/mentor.png',
    targetHeight: 130,
    offsetX: 12,
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

  Vector2 get interactionPoint {
    return position - Vector2(0, size.y * 0.5);
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
    sprite = Sprite(image);
    size = Vector2(
      spec.targetHeight * image.width / image.height,
      spec.targetHeight,
    );
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
}
