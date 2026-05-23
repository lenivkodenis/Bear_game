import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/level.dart';

class LevelService {
  Future<List<Level>> loadLevels() async {
    final jsonString = await rootBundle.loadString('assets/data/levels.json');
    final levelsJson = jsonDecode(jsonString) as List<Object?>;

    return levelsJson.cast<Map<String, Object?>>().map(Level.fromJson).toList();
  }

  Future<Level> loadLevel(int levelId) async {
    final levels = await loadLevels();

    return levels.firstWhere((level) => level.id == levelId);
  }

  Future<bool> hasLevel(int levelId) async {
    final levels = await loadLevels();

    return levels.any((level) => level.id == levelId);
  }
}
