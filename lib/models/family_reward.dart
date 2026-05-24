class FamilyReward {
  const FamilyReward({
    required this.id,
    required this.title,
    required this.costSnowflakes,
    required this.description,
    required this.isEnabled,
  });

  final String id;
  final String title;
  final int costSnowflakes;
  final String description;
  final bool isEnabled;

  static const defaultDescription =
      'Покажи результат родителям, чтобы получить награду.';

  static const defaultRewards = <FamilyReward>[
    FamilyReward(
      id: 'console_30_minutes',
      title: '30 минут игры на приставке',
      costSnowflakes: 50,
      description: defaultDescription,
      isEnabled: true,
    ),
    FamilyReward(
      id: 'outside_30_minutes',
      title: '30 минут игры на улице',
      costSnowflakes: 50,
      description: defaultDescription,
      isEnabled: true,
    ),
    FamilyReward(
      id: 'evening_cartoon',
      title: 'Выбрать мультик вечером',
      costSnowflakes: 50,
      description: defaultDescription,
      isEnabled: true,
    ),
    FamilyReward(
      id: 'family_movie',
      title: 'Семейный фильм',
      costSnowflakes: 100,
      description: defaultDescription,
      isEnabled: true,
    ),
    FamilyReward(
      id: 'ice_cream_walk',
      title: 'Поход за мороженым',
      costSnowflakes: 150,
      description: defaultDescription,
      isEnabled: true,
    ),
    FamilyReward(
      id: 'full_game_reward',
      title: 'Большая награда за прохождение всей игры',
      costSnowflakes: 500,
      description: defaultDescription,
      isEnabled: true,
    ),
  ];

  factory FamilyReward.fromJson(Map<String, Object?> json) {
    return FamilyReward(
      id: json['id'] as String,
      title: json['title'] as String,
      costSnowflakes: json['costSnowflakes'] as int,
      description: json['description'] as String,
      isEnabled: json['isEnabled'] as bool,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'costSnowflakes': costSnowflakes,
      'description': description,
      'isEnabled': isEnabled,
    };
  }

  FamilyReward copyWith({
    String? id,
    String? title,
    int? costSnowflakes,
    String? description,
    bool? isEnabled,
  }) {
    return FamilyReward(
      id: id ?? this.id,
      title: title ?? this.title,
      costSnowflakes: costSnowflakes ?? this.costSnowflakes,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
