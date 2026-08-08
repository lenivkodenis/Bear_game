class QuestionStatistics {
  const QuestionStatistics({
    required this.questionId,
    required this.questionNumber,
    required this.expression,
    required this.wrongAnswers,
    required this.correctAnswers,
    required this.elapsedMilliseconds,
  });

  final int questionId;
  final int questionNumber;
  final String expression;
  final int wrongAnswers;
  final int correctAnswers;
  final int elapsedMilliseconds;

  bool get isCompleted => correctAnswers > 0;

  int get attempts => wrongAnswers + correctAnswers;

  QuestionStatistics recordAttempt({
    required bool isCorrect,
    required int elapsedMilliseconds,
  }) {
    return QuestionStatistics(
      questionId: questionId,
      questionNumber: questionNumber,
      expression: expression,
      wrongAnswers: wrongAnswers + (isCorrect ? 0 : 1),
      correctAnswers: correctAnswers + (isCorrect ? 1 : 0),
      elapsedMilliseconds:
          this.elapsedMilliseconds + elapsedMilliseconds.clamp(0, 86400000),
    );
  }

  factory QuestionStatistics.fromJson(Map<String, Object?> json) {
    return QuestionStatistics(
      questionId: _readInt(json['questionId']) ?? 0,
      questionNumber: _readInt(json['questionNumber']) ?? 0,
      expression: json['expression'] as String? ?? '',
      wrongAnswers: (_readInt(json['wrongAnswers']) ?? 0).clamp(0, 100000),
      correctAnswers:
          (_readInt(json['correctAnswers']) ??
                  (json['isCompleted'] == true ? 1 : 0))
              .clamp(0, 100000),
      elapsedMilliseconds: (_readInt(json['elapsedMilliseconds']) ?? 0).clamp(
        0,
        864000000,
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'questionId': questionId,
      'questionNumber': questionNumber,
      'expression': expression,
      'wrongAnswers': wrongAnswers,
      'correctAnswers': correctAnswers,
      'elapsedMilliseconds': elapsedMilliseconds,
    };
  }
}

class LevelStatistics {
  const LevelStatistics({
    required this.levelId,
    required this.locationName,
    required this.questions,
  });

  final int levelId;
  final String locationName;
  final Map<int, QuestionStatistics> questions;

  List<QuestionStatistics> get sortedQuestions {
    final result = questions.values.toList()
      ..sort(
        (left, right) => left.questionNumber.compareTo(right.questionNumber),
      );
    return result;
  }

  int get completedQuestions =>
      questions.values.where((question) => question.isCompleted).length;

  int get totalWrongAnswers => questions.values.fold<int>(
    0,
    (total, question) => total + question.wrongAnswers,
  );

  int get totalAttempts => questions.values.fold<int>(
    0,
    (total, question) => total + question.attempts,
  );

  int get totalCorrectAnswers => questions.values.fold<int>(
    0,
    (total, question) => total + question.correctAnswers,
  );

  int get totalElapsedMilliseconds => questions.values.fold<int>(
    0,
    (total, question) => total + question.elapsedMilliseconds,
  );

  int get averageMillisecondsPerQuestion =>
      questions.isEmpty ? 0 : totalElapsedMilliseconds ~/ questions.length;

  int get accuracyPercent => totalAttempts == 0
      ? 0
      : ((totalCorrectAnswers / totalAttempts) * 100).round();

  LevelStatistics recordAttempt({
    required int questionId,
    required int questionNumber,
    required String expression,
    required bool isCorrect,
    required int elapsedMilliseconds,
  }) {
    final current =
        questions[questionId] ??
        QuestionStatistics(
          questionId: questionId,
          questionNumber: questionNumber,
          expression: expression,
          wrongAnswers: 0,
          correctAnswers: 0,
          elapsedMilliseconds: 0,
        );

    return LevelStatistics(
      levelId: levelId,
      locationName: locationName,
      questions: Map<int, QuestionStatistics>.of(questions)
        ..[questionId] = current.recordAttempt(
          isCorrect: isCorrect,
          elapsedMilliseconds: elapsedMilliseconds,
        ),
    );
  }

  factory LevelStatistics.fromJson(Map<String, Object?> json) {
    final decodedQuestions =
        json['questions'] as Map<String, Object?>? ?? const {};
    return LevelStatistics(
      levelId: _readInt(json['levelId']) ?? 0,
      locationName: json['locationName'] as String? ?? '',
      questions: decodedQuestions.map(
        (questionId, value) => MapEntry(
          int.parse(questionId),
          QuestionStatistics.fromJson(value as Map<String, Object?>),
        ),
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'levelId': levelId,
      'locationName': locationName,
      'questions': questions.map(
        (questionId, statistics) =>
            MapEntry(questionId.toString(), statistics.toJson()),
      ),
    };
  }
}

class LearningStatistics {
  const LearningStatistics({required this.levels});

  final Map<int, LevelStatistics> levels;

  static const empty = LearningStatistics(levels: {});

  List<LevelStatistics> get sortedLevels {
    final result = levels.values.toList()
      ..sort((left, right) => left.levelId.compareTo(right.levelId));
    return result;
  }

  int get completedQuestions => levels.values.fold<int>(
    0,
    (total, level) => total + level.completedQuestions,
  );

  int get totalWrongAnswers => levels.values.fold<int>(
    0,
    (total, level) => total + level.totalWrongAnswers,
  );

  int get totalAttempts =>
      levels.values.fold<int>(0, (total, level) => total + level.totalAttempts);

  int get totalCorrectAnswers => levels.values.fold<int>(
    0,
    (total, level) => total + level.totalCorrectAnswers,
  );

  int get totalElapsedMilliseconds => levels.values.fold<int>(
    0,
    (total, level) => total + level.totalElapsedMilliseconds,
  );

  int get averageMillisecondsPerQuestion =>
      trackedQuestions == 0 ? 0 : totalElapsedMilliseconds ~/ trackedQuestions;

  int get trackedQuestions => levels.values.fold<int>(
    0,
    (total, level) => total + level.questions.length,
  );

  int get accuracyPercent => totalAttempts == 0
      ? 0
      : ((totalCorrectAnswers / totalAttempts) * 100).round();

  LevelStatistics? forLevel(int levelId) => levels[levelId];

  LearningStatistics recordAttempt({
    required int levelId,
    required String locationName,
    required int questionId,
    required int questionNumber,
    required String expression,
    required bool isCorrect,
    required int elapsedMilliseconds,
  }) {
    final level =
        levels[levelId] ??
        LevelStatistics(
          levelId: levelId,
          locationName: locationName,
          questions: const {},
        );

    return LearningStatistics(
      levels: Map<int, LevelStatistics>.of(levels)
        ..[levelId] = level.recordAttempt(
          questionId: questionId,
          questionNumber: questionNumber,
          expression: expression,
          isCorrect: isCorrect,
          elapsedMilliseconds: elapsedMilliseconds,
        ),
    );
  }

  factory LearningStatistics.fromJson(Map<String, Object?> json) {
    final decodedLevels = json['levels'] as Map<String, Object?>? ?? const {};
    return LearningStatistics(
      levels: decodedLevels.map(
        (levelId, value) => MapEntry(
          int.parse(levelId),
          LevelStatistics.fromJson(value as Map<String, Object?>),
        ),
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'levels': levels.map(
        (levelId, statistics) =>
            MapEntry(levelId.toString(), statistics.toJson()),
      ),
    };
  }
}

int? _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}
