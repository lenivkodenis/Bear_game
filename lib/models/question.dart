class Question {
  const Question({
    required this.id,
    required this.level,
    required this.table,
    required this.questionText,
    required this.expression,
    required this.options,
    required this.correctAnswer,
    required this.hint,
    required this.rewardPoints,
    required this.penaltyPoints,
  });

  final int id;
  final int level;
  final int table;
  final String questionText;
  final String expression;
  final List<int> options;
  final int correctAnswer;
  final String hint;
  final int rewardPoints;
  final int penaltyPoints;

  factory Question.fromJson(Map<String, Object?> json) {
    return Question(
      id: json['id'] as int,
      level: json['level'] as int,
      table: json['table'] as int,
      questionText: json['questionText'] as String,
      expression: json['expression'] as String,
      options: (json['options'] as List<Object?>).cast<int>(),
      correctAnswer: json['correctAnswer'] as int,
      hint: json['hint'] as String,
      rewardPoints: json['rewardPoints'] as int,
      penaltyPoints: json['penaltyPoints'] as int,
    );
  }
}
