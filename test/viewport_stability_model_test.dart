import 'dart:ui';

import 'package:bear_game/services/viewport_stability_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('viewport settles only after two equal rendered sizes', () {
    final model = ViewportStabilityModel()..beginResize();

    expect(model.sample(const Size(390, 650)), isFalse);
    expect(model.sample(const Size(390, 629)), isFalse);
    expect(model.sample(const Size(390, 629)), isTrue);
    model.complete();

    expect(model.phase, ViewportPhase.stable);
  });

  test('a new size restarts the equal-frame counter', () {
    final model = ViewportStabilityModel()..beginResize();
    model.sample(const Size(844, 300));
    expect(model.sample(const Size(844, 301)), isFalse);
    expect(model.equalSamples, 1);
  });
}
