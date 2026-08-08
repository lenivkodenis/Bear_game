import 'package:bear_game/widgets/north_sign_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('snow sign variants render and preserve button behavior', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < SnowCapVariant.values.length;
                  index++
                )
                  NorthSignButton(
                    label: 'Кнопка ${index + 1}',
                    icon: Icons.ac_unit_rounded,
                    snowCap: SnowCapVariant.values[index],
                    tone: NorthSignTone
                        .values[index % NorthSignTone.values.length],
                    onPressed: index == 0 ? () => taps += 1 : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Кнопка 1'));
    await tester.pump();
    expect(taps, 1);

    await tester.tap(find.text('Кнопка 2'));
    await tester.pump();
    expect(taps, 1);
  });
}
