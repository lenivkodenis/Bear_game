import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

const levelsAssetPath = 'assets/data/levels.json';

Future<List<Map<String, Object?>>> loadRawLevels() async {
  final jsonFile = File(levelsAssetPath);
  if (!jsonFile.existsSync()) {
    throw const FormatException('levels.json asset file is missing.');
  }

  final jsonString = await rootBundle.loadString(levelsAssetPath);
  final decoded = jsonDecode(jsonString);
  if (decoded is! List) {
    throw const FormatException('levels.json must contain a list of levels.');
  }

  return decoded.map(_asJsonObject).toList();
}

List<Map<String, Object?>> deepCopyLevels(List<Map<String, Object?>> levels) {
  final copied = jsonDecode(jsonEncode(levels)) as List<Object?>;

  return copied.map(_asJsonObject).toList();
}

void validateLevelsContract(List<Map<String, Object?>> levels) {
  if (levels.length != 10) {
    throw FormatException(
      'Expected exactly 10 levels, found ${levels.length}.',
    );
  }

  final ids = <int>{};
  for (final level in levels) {
    final levelId = _requiredInt(level, 'id', context: 'level');
    if (!ids.add(levelId)) {
      throw FormatException('Duplicate level id: $levelId.');
    }

    _requiredString(level, 'title', context: 'level $levelId');
    _requiredString(level, 'mentorName', context: 'level $levelId');
    _requiredInt(level, 'table', context: 'level $levelId');
    _requiredString(level, 'introText', context: 'level $levelId');

    final questions = _requiredList(
      level,
      'questions',
      context: 'level $levelId',
    ).map(_asJsonObject).toList();
    if (questions.length != 10) {
      throw FormatException(
        'Level $levelId must contain 10 questions, found ${questions.length}.',
      );
    }

    for (final question in questions) {
      final questionId = _requiredInt(
        question,
        'id',
        context: 'level $levelId question',
      );
      final questionContext = 'level $levelId question $questionId';

      _requiredString(question, 'questionText', context: questionContext);
      _requiredString(question, 'expression', context: questionContext);
      _requiredString(question, 'hint', context: questionContext);
      _requiredInt(question, 'rewardPoints', context: questionContext);
      _requiredInt(question, 'penaltyPoints', context: questionContext);

      final options = _requiredList(
        question,
        'options',
        context: questionContext,
      );
      if (options.length != 3) {
        throw FormatException(
          '$questionContext must contain exactly 3 answer options.',
        );
      }
      if (options.any((option) => option is! int)) {
        throw FormatException('$questionContext options must all be integers.');
      }

      final correctAnswer = _requiredInt(
        question,
        'correctAnswer',
        context: questionContext,
      );
      if (!options.contains(correctAnswer)) {
        throw FormatException(
          '$questionContext correctAnswer must be present in options.',
        );
      }
    }
  }
}

Map<String, Object?> _asJsonObject(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, Object?>();
  }

  throw const FormatException('Expected a JSON object.');
}

int _requiredInt(
  Map<String, Object?> json,
  String key, {
  required String context,
}) {
  final value = json[key];
  if (value is int) {
    return value;
  }

  throw FormatException('$context must contain integer "$key".');
}

String _requiredString(
  Map<String, Object?> json,
  String key, {
  required String context,
}) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }

  throw FormatException('$context must contain non-empty string "$key".');
}

List<Object?> _requiredList(
  Map<String, Object?> json,
  String key, {
  required String context,
}) {
  final value = json[key];
  if (value is List<Object?>) {
    return value;
  }
  if (value is List) {
    return value.cast<Object?>();
  }

  throw FormatException('$context must contain list "$key".');
}
