import 'package:bear_game/game/components/player_bear.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bear visual feet align with hitbox bottom', () {
    final hitboxBottom = PlayerBear.defaultSize.y;
    final visualFeetFromOffset =
        PlayerBear.visualOffset.dy +
        PlayerBear.visualSize.height -
        PlayerBear.visualGroundInset;

    expect(PlayerBear.feetToGroundOffset, 0);
    expect(PlayerBear.visualFeetAnchor.dy, hitboxBottom);
    expect(visualFeetFromOffset, hitboxBottom);
  });
}
