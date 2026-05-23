import 'question.dart';

class Level {
  const Level({
    required this.id,
    required this.title,
    required this.locationName,
    required this.mentorName,
    required this.table,
    required this.rewardPoints,
    required this.penaltyPoints,
    required this.introText,
    required this.completionText,
    required this.questions,
  });

  final int id;
  final String title;
  final String locationName;
  final String mentorName;
  final int table;
  final int rewardPoints;
  final int penaltyPoints;
  final String introText;
  final String completionText;
  final List<Question> questions;

  factory Level.fromJson(Map<String, Object?> json) {
    return Level(
      id: json['id'] as int,
      title: json['title'] as String,
      locationName: json['locationName'] as String,
      mentorName: json['mentorName'] as String,
      table: json['table'] as int,
      rewardPoints: json['rewardPoints'] as int,
      penaltyPoints: json['penaltyPoints'] as int,
      introText: json['introText'] as String,
      completionText: json['completionText'] as String,
      questions: (json['questions'] as List<Object?>)
          .map((item) => Question.fromJson(item as Map<String, Object?>))
          .toList(),
    );
  }
}
