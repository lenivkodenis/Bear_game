import 'dart:async';

import 'package:bear_game/models/player_progress.dart';
import 'package:bear_game/screens/location_map_screen.dart';
import 'package:bear_game/services/progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets('double click rewinds progress to the selected level', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'score': 61,
      'solved_examples': 80,
      'unlocked_location': 9,
      'current_question_indexes':
          '{"1":10,"2":10,"3":10,"4":10,"5":10,"6":10,"7":10,"8":10}',
      'completed_level_ids': ['1', '2', '3', '4', '5', '6', '7', '8'],
    });

    await tester.pumpWidget(
      MaterialApp(home: LocationMapScreen(imagePreloader: (_) async {})),
    );
    await tester.pump();
    for (var frame = 0; frame < 10; frame += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final levelEight = find.byKey(const ValueKey<String>('map-location-8'));
    expect(levelEight, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('location-map-interactive-viewer')),
      findsOneWidget,
    );
    expect(find.byType(SingleChildScrollView), findsNothing);

    await tester.tap(levelEight);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(levelEight);
    await tester.pump(const Duration(milliseconds: 500));

    final progress = await ProgressService().loadProgress();
    expect(progress.unlockedLocation, 8);
    expect(progress.isLevelCompleted(8), isFalse);
    expect(progress.questionIndexForLevel(8), 0);
    expect(progress.score, 61);
    expect(progress.solvedExamples, 80);
  });

  testWidgets('hotspots wait until the map image is ready', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final imageCompleter = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: LocationMapScreen(imagePreloader: (_) => imageCompleter.future),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('location-map-loading')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('map-location-1')), findsNothing);

    imageCompleter.complete();
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('map-location-1')),
      findsOneWidget,
    );
  });

  testWidgets('map recenters and refits when rotating to landscape', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(home: LocationMapScreen(imagePreloader: (_) async {})),
    );
    await tester.pump();
    for (var frame = 0; frame < 5; frame += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.binding.setSurfaceSize(const Size(844, 390));
    await tester.pump();
    await tester.pump();

    final mapRect = tester.getRect(_progressionMapImage());
    expect(mapRect.center.dx, closeTo(422, 1));
    expect(mapRect.left, greaterThanOrEqualTo(0));
    expect(mapRect.right, lessThanOrEqualTo(844));
  });
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

Finder _progressionMapImage() {
  return find.byWidgetPredicate((widget) {
    if (widget is! Image || widget.image is! AssetImage) {
      return false;
    }

    return (widget.image as AssetImage).assetName ==
        'assets/images/map/progression_map.png';
  });
}
