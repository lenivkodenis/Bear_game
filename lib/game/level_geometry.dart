import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

const bool kLevelGeometryDebugOverlay = false;

bool get isLevelGeometryDebugOverlayEnabled {
  return kLevelGeometryDebugOverlay ||
      isLevelGeometryDebugOverlayEnabledForUri(Uri.base);
}

bool isLevelGeometryDebugOverlayEnabledForUri(Uri uri) {
  return _hasEnabledDebugGeometryFlag(uri.queryParameters) ||
      _hasEnabledDebugGeometryFlag(_fragmentQueryParameters(uri.fragment));
}

bool _hasEnabledDebugGeometryFlag(Map<String, String> parameters) {
  return parameters['debugGeometry'] == '1';
}

Map<String, String> _fragmentQueryParameters(String fragment) {
  if (fragment.isEmpty) {
    return const <String, String>{};
  }

  final queryStart = fragment.indexOf('?');
  final query = queryStart == -1
      ? fragment
      : fragment.substring(queryStart + 1);
  if (!query.contains('=')) {
    return const <String, String>{};
  }

  try {
    return Uri.splitQueryString(query);
  } on FormatException {
    return const <String, String>{};
  }
}

class LevelGeometryService {
  Future<List<LevelGeometry>> loadGeometries() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/level_geometry.json',
    );
    final decoded = jsonDecode(jsonString);
    final json = _asJsonObject(decoded, context: 'level_geometry.json');
    final world = LevelGeometryWorld.fromJson(
      _requiredObject(json, 'world', context: 'level_geometry.json'),
    );
    final levels = _requiredList(
      json,
      'levels',
      context: 'level_geometry.json',
    );

    return levels
        .map(
          (levelJson) => LevelGeometry.fromJson(
            _asJsonObject(levelJson, context: 'level geometry entry'),
            world: world,
          ),
        )
        .toList(growable: false);
  }

  Future<LevelGeometry> loadLevelGeometry(int levelId) async {
    final geometries = await loadGeometries();

    return geometries.firstWhere(
      (geometry) => geometry.levelId == levelId,
      orElse: () =>
          throw StateError('Missing level geometry for level id $levelId.'),
    );
  }
}

class LevelGeometryWorld {
  const LevelGeometryWorld({required this.width, required this.height});

  factory LevelGeometryWorld.fromJson(Map<String, Object?> json) {
    return LevelGeometryWorld(
      width: _requiredDouble(json, 'width', context: 'world'),
      height: _requiredDouble(json, 'height', context: 'world'),
    );
  }

  final double width;
  final double height;
}

class LevelGeometryPoint {
  const LevelGeometryPoint({required this.x, required this.y});

  factory LevelGeometryPoint.fromJson(
    Map<String, Object?> json, {
    required String context,
  }) {
    return LevelGeometryPoint(
      x: _requiredDouble(json, 'x', context: context),
      y: _requiredDouble(json, 'y', context: context),
    );
  }

  final double x;
  final double y;

  LevelGeometryPoint scaledBy({
    required double scaleX,
    required double scaleY,
  }) {
    return LevelGeometryPoint(x: x * scaleX, y: y * scaleY);
  }

  Vector2 toVector2() => Vector2(x, y);
}

class LevelGeometryCollider {
  const LevelGeometryCollider({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory LevelGeometryCollider.fromJson(
    Map<String, Object?> json, {
    required String context,
  }) {
    return LevelGeometryCollider(
      id: _requiredString(json, 'id', context: context),
      x: _requiredDouble(json, 'x', context: context),
      y: _requiredDouble(json, 'y', context: context),
      width: _requiredDouble(json, 'width', context: context),
      height: _requiredDouble(json, 'height', context: context),
    );
  }

  final String id;
  final double x;
  final double y;
  final double width;
  final double height;

  Vector2 get position => Vector2(x, y);
  Vector2 get size => Vector2(width, height);

  LevelGeometryCollider scaledBy({
    required double scaleX,
    required double scaleY,
  }) {
    return LevelGeometryCollider(
      id: id,
      x: x * scaleX,
      y: y * scaleY,
      width: width * scaleX,
      height: height * scaleY,
    );
  }
}

class LevelGeometry {
  const LevelGeometry({
    required this.levelId,
    required this.world,
    required this.backgroundAsset,
    required this.playerSpawn,
    required this.mentorPosition,
    required this.groundColliders,
    required this.platformColliders,
    required this.obstacleColliders,
    required this.notes,
  });

  factory LevelGeometry.fromJson(
    Map<String, Object?> json, {
    required LevelGeometryWorld world,
  }) {
    final levelId = _requiredInt(json, 'levelId', context: 'level geometry');

    return LevelGeometry(
      levelId: levelId,
      world: world,
      backgroundAsset: _requiredString(
        json,
        'backgroundAsset',
        context: 'level geometry $levelId',
      ),
      playerSpawn: LevelGeometryPoint.fromJson(
        _requiredObject(
          json,
          'playerSpawn',
          context: 'level geometry $levelId',
        ),
        context: 'level geometry $levelId playerSpawn',
      ),
      mentorPosition: LevelGeometryPoint.fromJson(
        _requiredObject(
          json,
          'mentorPosition',
          context: 'level geometry $levelId',
        ),
        context: 'level geometry $levelId mentorPosition',
      ),
      groundColliders: _readColliders(
        json,
        'groundColliders',
        context: 'level geometry $levelId',
      ),
      platformColliders: _readColliders(
        json,
        'platformColliders',
        context: 'level geometry $levelId',
      ),
      obstacleColliders: _readColliders(
        json,
        'obstacleColliders',
        context: 'level geometry $levelId',
      ),
      notes: _requiredString(json, 'notes', context: 'level geometry $levelId'),
    );
  }

  final int levelId;
  final LevelGeometryWorld world;
  final String backgroundAsset;
  final LevelGeometryPoint playerSpawn;
  final LevelGeometryPoint mentorPosition;
  final List<LevelGeometryCollider> groundColliders;
  final List<LevelGeometryCollider> platformColliders;
  final List<LevelGeometryCollider> obstacleColliders;
  final String notes;

  LevelGeometryCollider get mainGround => groundColliders.first;

  LevelGeometry scaledTo(Vector2 targetSize) {
    final scaleX = targetSize.x / world.width;
    final scaleY = targetSize.y / world.height;

    return LevelGeometry(
      levelId: levelId,
      world: LevelGeometryWorld(width: targetSize.x, height: targetSize.y),
      backgroundAsset: backgroundAsset,
      playerSpawn: playerSpawn.scaledBy(scaleX: scaleX, scaleY: scaleY),
      mentorPosition: mentorPosition.scaledBy(scaleX: scaleX, scaleY: scaleY),
      groundColliders: _scaleColliders(
        groundColliders,
        scaleX: scaleX,
        scaleY: scaleY,
      ),
      platformColliders: _scaleColliders(
        platformColliders,
        scaleX: scaleX,
        scaleY: scaleY,
      ),
      obstacleColliders: _scaleColliders(
        obstacleColliders,
        scaleX: scaleX,
        scaleY: scaleY,
      ),
      notes: notes,
    );
  }
}

List<LevelGeometryCollider> _readColliders(
  Map<String, Object?> json,
  String key, {
  required String context,
}) {
  final colliders = _requiredList(json, key, context: context);

  return colliders
      .map(
        (colliderJson) => LevelGeometryCollider.fromJson(
          _asJsonObject(colliderJson, context: '$context $key entry'),
          context: '$context $key',
        ),
      )
      .toList(growable: false);
}

List<LevelGeometryCollider> _scaleColliders(
  List<LevelGeometryCollider> colliders, {
  required double scaleX,
  required double scaleY,
}) {
  return colliders
      .map((collider) => collider.scaledBy(scaleX: scaleX, scaleY: scaleY))
      .toList(growable: false);
}

Map<String, Object?> _requiredObject(
  Map<String, Object?> json,
  String key, {
  required String context,
}) {
  return _asJsonObject(json[key], context: '$context $key');
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

Map<String, Object?> _asJsonObject(Object? value, {required String context}) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, Object?>();
  }

  throw FormatException('$context must be a JSON object.');
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

double _requiredDouble(
  Map<String, Object?> json,
  String key, {
  required String context,
}) {
  final value = json[key];
  if (value is int) {
    return value.toDouble();
  }
  if (value is double) {
    return value;
  }

  throw FormatException('$context must contain number "$key".');
}
