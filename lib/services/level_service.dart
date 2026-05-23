import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/level.dart';

class LevelService {
  Future<Level> loadLevel(int levelId) async {
    final jsonString = await rootBundle.loadString('assets/data/levels.json');
    final levelsJson = jsonDecode(jsonString) as List<Object?>;
    final levelJson = levelsJson.cast<Map<String, Object?>>().firstWhere(
          (level) => level['id'] == levelId,
        );

    return Level.fromJson(levelJson);
  }
}
