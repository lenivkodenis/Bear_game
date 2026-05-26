import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../level_background_assets.dart';

class SnowyBackground extends PositionComponent {
  SnowyBackground({required Vector2 size, required this.assetPath})
    : super(size: size, priority: -1000);

  final String assetPath;
  ui.Image? _background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _background = await _loadBackground(assetPath);
  }

  Future<ui.Image> _loadBackground(String path) async {
    try {
      return await Flame.images.load(LevelBackgroundAssets.flameImageKey(path));
    } catch (error, stackTrace) {
      debugPrint('Unable to load level background "$path": $error');
      debugPrintStack(stackTrace: stackTrace);

      if (path == LevelBackgroundAssets.fallbackAssetPath) {
        rethrow;
      }

      return Flame.images.load(
        LevelBackgroundAssets.flameImageKey(
          LevelBackgroundAssets.fallbackAssetPath,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final background = _background;
    if (background == null) {
      return;
    }

    paintImage(
      canvas: canvas,
      rect: size.toRect(),
      image: background,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
    );
  }
}
