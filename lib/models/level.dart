import 'question.dart';

class Level {
  const Level({
    required this.id,
    required this.title,
    required this.locationName,
    required this.mentorName,
    required this.table,
    required this.introText,
    required this.questions,
  });

  final int id;
  final String title;
  final String locationName;
  final String mentorName;
  final int table;
  final String introText;
  final List<Question> questions;

  factory Level.fromJson(Map<String, Object?> json) {
    return Level(
      id: json['id'] as int,
      title: json['title'] as String,
      locationName: json['locationName'] as String,
      mentorName: json['mentorName'] as String,
      table: json['table'] as int,
      introText: json['introText'] as String,
      questions: (json['questions'] as List<Object?>)
          .map((item) => Question.fromJson(item as Map<String, Object?>))
          .toList(),
    );
  }
}
