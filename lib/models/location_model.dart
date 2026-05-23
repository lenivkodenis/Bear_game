class LocationModel {
  const LocationModel({
    required this.id,
    required this.title,
    required this.mentorName,
    required this.multiplicationTable,
  });

  final int id;
  final String title;
  final String mentorName;
  final int multiplicationTable;

  factory LocationModel.fromJson(Map<String, Object?> json) {
    return LocationModel(
      id: json['id'] as int,
      title: json['title'] as String,
      mentorName: json['mentorName'] as String,
      multiplicationTable: json['multiplicationTable'] as int,
    );
  }
}
