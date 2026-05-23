import 'package:bear_game/services/level_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/level_contract.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('levels.json exists and contains 10 complete levels', () async {
    final rawLevels = await loadRawLevels();

    validateLevelsContract(rawLevels);

    final levels = await LevelService().loadLevels();
    expect(levels, hasLength(10));

    for (final level in levels) {
      expect(level.id, inInclusiveRange(1, 10));
      expect(level.title, isNotEmpty);
      expect(level.mentorName, isNotEmpty);
      expect(level.table, isPositive);
      expect(level.introText, isNotEmpty);
      expect(level.questions, hasLength(10));

      for (final question in level.questions) {
        expect(question.questionText, isNotEmpty);
        expect(question.expression, isNotEmpty);
        expect(question.options, hasLength(3));
        expect(question.options, contains(question.correctAnswer));
        expect(question.hint, isNotEmpty);
        expect(question.rewardPoints, isNonNegative);
        expect(question.penaltyPoints, isNonNegative);
      }
    }
  });
}
