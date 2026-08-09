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

  test('enriched stories cover the complete multiplication table', () async {
    final rawLevels = await loadRawLevels();
    expect(rawLevels, hasLength(10));

    final expectedExpressions = <String>{
      for (var left = 1; left <= 10; left += 1)
        for (var right = 1; right <= 10; right += 1) '$left x $right',
    };
    final expressions = <String>{};
    final questionTexts = <String>{};
    var questionCount = 0;

    for (final level in rawLevels) {
      final levelId = level['id']! as int;
      final table = level['table']! as int;
      final questions = (level['questions']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(questions, hasLength(10), reason: 'level $levelId');

      for (final question in questions) {
        questionCount += 1;
        final expression = (question['expression']! as String).replaceAll(
          '×',
          'x',
        );
        final factors = expression
            .split(' x ')
            .map(int.parse)
            .toList(growable: false);
        expect(factors, hasLength(2), reason: expression);
        expect(factors.first, table, reason: expression);

        final correctAnswer = question['correctAnswer']! as int;
        expect(correctAnswer, factors.first * factors.last, reason: expression);
        expect(expressions.add(expression), isTrue, reason: expression);

        final options = (question['options']! as List<Object?>).cast<int>();
        expect(options, hasLength(3), reason: expression);
        expect(options.toSet(), hasLength(options.length), reason: expression);
        expect(options, contains(correctAnswer), reason: expression);

        final questionText = question['questionText']! as String;
        expect(questionText, isNotEmpty, reason: expression);
        expect(questionTexts.add(questionText), isTrue, reason: expression);
        expect(questionText.endsWith('?'), isTrue, reason: expression);
        expect(questionText.length, lessThanOrEqualTo(160), reason: expression);
        expect(
          RegExp(r'\d').hasMatch(questionText),
          isFalse,
          reason: expression,
        );
        final sentences = questionText
            .split(RegExp(r'[.!?]+'))
            .where((sentence) => sentence.trim().isNotEmpty);
        expect(sentences.length, greaterThanOrEqualTo(3), reason: expression);

        final hint = question['hint']! as String;
        expect(hint, isNotEmpty, reason: expression);
        expect(hint.endsWith('.'), isTrue, reason: expression);
        expect(hint.length, lessThanOrEqualTo(140), reason: expression);
        expect(hint, contains(correctAnswer.toString()), reason: expression);
        expect(
          hint,
          contains('${factors.first} × ${factors.last} = $correctAnswer'),
          reason: expression,
        );

        final updatedCopy = '$questionText $hint'.toLowerCase();
        for (final oldFragment in const [
          'медвежонок',
          'льдин',
          'снежин',
          'пингвинён',
          'морж',
        ]) {
          expect(
            updatedCopy.contains(oldFragment),
            isFalse,
            reason: '$expression still contains "$oldFragment"',
          );
        }
      }
    }

    expect(questionCount, 100);
    expect(expressions, expectedExpressions);
    expect(questionTexts, hasLength(100));
  });
}
