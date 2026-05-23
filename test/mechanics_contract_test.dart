import 'package:flutter_test/flutter_test.dart';

import 'helpers/level_contract.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('contract accepts the current levels.json', () async {
    final levels = await loadRawLevels();

    expect(() => validateLevelsContract(levels), returnsNormally);
  });

  test('contract rejects a level without questions', () async {
    final levels = deepCopyLevels(await loadRawLevels());
    levels.first['questions'] = <Object?>[];

    expect(
      () => validateLevelsContract(levels),
      throwsA(isA<FormatException>()),
    );
  });

  test('contract rejects a question without 3 answer options', () async {
    final levels = deepCopyLevels(await loadRawLevels());
    final questions = levels.first['questions']! as List<Object?>;
    final question = questions.first! as Map<String, Object?>;
    question['options'] = <Object?>[1, 2];

    expect(
      () => validateLevelsContract(levels),
      throwsA(isA<FormatException>()),
    );
  });

  test('contract rejects correctAnswer missing from options', () async {
    final levels = deepCopyLevels(await loadRawLevels());
    final questions = levels.first['questions']! as List<Object?>;
    final question = questions.first! as Map<String, Object?>;
    question['correctAnswer'] = 999;

    expect(
      () => validateLevelsContract(levels),
      throwsA(isA<FormatException>()),
    );
  });
}
