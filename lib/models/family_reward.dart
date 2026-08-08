class FamilyReward {
  const FamilyReward({
    required this.id,
    required this.title,
    required this.requiredSnowflakes,
    required this.description,
    required this.isEnabled,
  });

  final String id;
  final String title;
  final int requiredSnowflakes;
  final String description;
  final bool isEnabled;

  int get costSnowflakes => requiredSnowflakes;

  static const defaultDescription =
      'Покажи результат родителям, чтобы получить награду.';

  static const defaultRewards = <FamilyReward>[
    FamilyReward(
      id: 'sticker',
      title: 'Выбрать наклейку / стикер',
      requiredSnowflakes: 10,
      description: defaultDescription,
      isEnabled: true,
    ),
    FamilyReward(
      id: 'bedtime_story',
      title: 'Выбрать сказку перед сном',
      requiredSnowflakes: 20,
      description: defaultDescription,
      isEnabled: true,
    ),
    FamilyReward(
      id: 'console_20_minutes',
      title: '20 минут игры на приставке',
      requiredSnowflakes: 30,
      description: defaultDescription,
      isEnabled: true,
    ),
    FamilyReward(
      id: 'outside_30_minutes',
      title: '30 минут игры на улице',
      requiredSnowflakes: 40,
      description: defaultDescription,
      isEnabled: true,
    ),
    FamilyReward(
      id: 'evening_cartoon',
      title: 'Выбрать мультфильм вечером',
      requiredSnowflakes: 50,
      description: defaultDescription,
      isEnabled: true,
    ),
    FamilyReward(
      id: 'ice_cream_walk',
      title: 'Поход за мороженым',
      requiredSnowflakes: 75,
      description: defaultDescription,
      isEnabled: true,
    ),
    FamilyReward(
      id: 'full_table_reward',
      title: 'Большая семейная награда за всю таблицу',
      requiredSnowflakes: 100,
      description: defaultDescription,
      isEnabled: true,
    ),
  ];

  factory FamilyReward.fromJson(Map<String, Object?> json) {
    final id = json['id'] as String?;
    final title = (json['title'] ?? json['label']) as String?;
    final requiredSnowflakes =
        _readInt(json['requiredSnowflakes']) ??
        _readInt(json['threshold']) ??
        _readInt(json['costSnowflakes']);
    if (id == null || title == null || requiredSnowflakes == null) {
      throw const FormatException('Invalid family reward.');
    }

    return FamilyReward(
      id: id,
      title: title,
      requiredSnowflakes: requiredSnowflakes,
      description:
          (json['description'] as String?) ?? FamilyReward.defaultDescription,
      isEnabled: (json['isEnabled'] as bool?) ?? true,
    ).validated();
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'requiredSnowflakes': requiredSnowflakes,
      'description': description,
      'isEnabled': isEnabled,
    };
  }

  FamilyReward copyWith({
    String? id,
    String? title,
    int? requiredSnowflakes,
    String? description,
    bool? isEnabled,
  }) {
    return FamilyReward(
      id: id ?? this.id,
      title: title ?? this.title,
      requiredSnowflakes: requiredSnowflakes ?? this.requiredSnowflakes,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  FamilyReward validated() {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw const FormatException('Family reward title is empty.');
    }

    final normalizedSnowflakes = requiredSnowflakes.clamp(1, 100).toInt();
    return copyWith(
      title: normalizedTitle,
      requiredSnowflakes: normalizedSnowflakes,
    );
  }

  static int? _readInt(Object? value) {
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
}
