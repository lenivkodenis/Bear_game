import 'package:bear_game/app.dart';
import 'package:bear_game/game/bear_math_game.dart';
import 'package:bear_game/game/game_viewport_layout.dart';
import 'package:bear_game/screens/game_screen.dart';
import 'package:bear_game/widgets/game_controls.dart';
import 'package:bear_game/widgets/north_confirmation_dialog.dart';
import 'package:bear_game/widgets/primary_game_button.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('main menu shows primary actions', (tester) async {
    await tester.pumpWidget(const BearGameApp());

    expect(find.text('Медвежонок и таблица умножения'), findsOneWidget);
    expect(find.text('Начать игру'), findsOneWidget);
    expect(find.text('Начать игру заново'), findsOneWidget);
    expect(find.text('Карта'), findsOneWidget);
    expect(find.text('Прогресс'), findsOneWidget);
    expect(find.text('Родителям'), findsOneWidget);
  });

  testWidgets('difficulty change warns before starting a new game', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'game_difficulty': 'expert',
      'progress_difficulty': 'beginner',
      'difficulty_progress_reset_required': true,
      'unlocked_location': 8,
    });
    await tester.pumpWidget(const BearGameApp());

    await tester.tap(find.text('Начать игру'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Сложность изменилась'), findsOneWidget);
    expect(find.textContaining('текущий прогресс'), findsOneWidget);

    await tester.tap(find.text('Отмена'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('restart button asks for confirmation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BearGameApp());

    await tester.tap(find.text('Начать игру заново'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Начать игру заново?'), findsOneWidget);
    expect(find.textContaining('Отменить это действие'), findsOneWidget);
    expect(find.byType(NorthConfirmationDialog), findsOneWidget);
    expect(find.byType(PrimaryGameButton), findsNWidgets(2));
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    final dialogTextStyle = tester.widget<DefaultTextStyle>(
      find.byKey(const Key('north_confirmation_dialog_text_style')),
    );
    expect(dialogTextStyle.style.decoration, TextDecoration.none);

    await tester.tap(find.text('Отмена'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('branded restart dialog fits a compact mobile viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BearGameApp());

    await tester.tap(find.text('Начать игру заново'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(NorthConfirmationDialog), findsOneWidget);
    expect(find.text('Начать заново'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Отмена'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('game movement controls react on pointer down', (tester) async {
    var rightStartCount = 0;
    var moveEndCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameControls(
            onMoveLeftStart: () {},
            onMoveRightStart: () {
              rightStartCount += 1;
            },
            onMoveEnd: () {
              moveEndCount += 1;
            },
            onJump: () {},
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.text('›')));
    await tester.pump();

    expect(rightStartCount, 1);
    expect(moveEndCount, 0);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 121));

    expect(moveEndCount, 1);
  });

  test('compact portrait and landscape use the responsive game camera', () {
    expect(usesCompactGameViewport(const Size(390, 844)), isTrue);
    expect(usesCompactGameViewport(const Size(844, 390)), isTrue);
    expect(usesCompactGameViewport(const Size(1024, 768)), isFalse);
  });

  test('responsive game camera uses the full canvas viewport', () {
    final game = BearMathGame(levelId: 1, useResponsiveCamera: true);

    expect(game.camera.viewfinder.anchor, Anchor.topLeft);
  });

  test('game can close an overlay before the scene finishes loading', () {
    final game = BearMathGame(levelId: 1, useResponsiveCamera: true);

    expect(game.closeMentorDialog, returnsNormally);
  });

  test(
    'portrait viewport keeps the player left and first obstacle visible',
    () {
      final layout = GameViewportLayout.cover(
        canvasSize: const Size(390, 844),
        playerCenterX: 111,
        gameplayGroundY: 489,
      );

      expect(layout.visibleWorldRect.contains(const Offset(111, 489)), isTrue);
      expect(
        layout.visibleWorldRect.contains(const Offset(197.47, 446.25)),
        isTrue,
      );
      expect(layout.worldToScreen(const Offset(111, 489)).dx, lessThan(195));
      expect(layout.worldToScreen(const Offset(111, 489)).dy, lessThan(844));
    },
  );

  testWidgets('mobile controls remain inside a short landscape viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(667, 375));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: GameControls(
              onMoveLeftStart: () {},
              onMoveRightStart: () {},
              onMoveEnd: () {},
              onJump: () {},
            ),
          ),
        ),
      ),
    );

    final screenRect = const Offset(0, 0) & const Size(667, 375);
    for (final symbol in ['‹', '›', '↑']) {
      expect(screenRect.contains(tester.getCenter(find.text(symbol))), isTrue);
    }
    for (final key in <String>[
      'game-control-left',
      'game-control-right',
      'game-control-jump',
    ]) {
      expect(
        tester.getSize(find.byKey(ValueKey<String>(key))),
        const Size(56, 56),
      );
    }
    expect(tester.takeException(), isNull);
  });
}
