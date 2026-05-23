import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'components/platform_component.dart';
import 'components/player_bear.dart';
import 'components/snowy_background.dart';
import 'components/wise_mentor.dart';

class BearMathGame extends FlameGame with HasKeyboardHandlerComponents {
  BearMathGame();

  static const mentorDialogOverlay = 'mentorDialog';

  late final PlayerBear player;
  late final WiseMentor mentor;

  bool _mentorDialogWasShown = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final groundY = size.y - 88;

    add(SnowyBackground(size: size));
    add(
      PlatformComponent(
        position: Vector2(0, groundY),
        size: Vector2(size.x, 44),
      ),
    );

    player = PlayerBear(
      position: Vector2(72, groundY - PlayerBear.defaultSize.y),
      groundY: groundY,
      levelWidth: size.x,
    );
    mentor = WiseMentor(
      position: Vector2(size.x - 112, groundY - WiseMentor.defaultSize.y),
    );

    add(player);
    add(mentor);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_mentorDialogWasShown && player.distance(mentor) < 92) {
      _mentorDialogWasShown = true;
      player.stopMoving();
      overlays.add(mentorDialogOverlay);
    }
  }

  void startMovingLeft() => player.moveLeft();

  void startMovingRight() => player.moveRight();

  void stopMoving() => player.stopMoving();

  void jump() => player.jump();

  void closeMentorDialog() {
    overlays.remove(mentorDialogOverlay);
  }
}
