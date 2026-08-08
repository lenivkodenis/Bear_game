import 'dart:async';

import 'package:bear_game/models/player_progress.dart';
import 'package:bear_game/screens/location_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'map does not show false locked state while progress is loading',
    (tester) async {
      final progressCompleter = Completer<PlayerProgress>();

      await tester.pumpWidget(
        MaterialApp(
          home: LocationMapScreen(
            progressLoader: () => progressCompleter.future,
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('location-map-loading')),
        findsOneWidget,
      );
      expect(_lockedPadlockImages(), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

Finder _lockedPadlockImages() {
  return find.byWidgetPredicate((widget) {
    if (widget is! Image || widget.image is! AssetImage) {
      return false;
    }

    return (widget.image as AssetImage).assetName ==
        'assets/images/map/locked_level_padlock.png';
  });
}
