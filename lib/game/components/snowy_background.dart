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
  ui.Image? _backLayer;
  ui.Image? _foregroundOverlay;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _background = await _loadBackground(assetPath);

    final layeredAssets = LevelBackgroundAssets.layersForBackground(assetPath);
    if (layeredAssets == null) {
      return;
    }

    try {
      _backLayer = await _loadRequiredImage(layeredAssets.backLayerAssetPath);
      _foregroundOverlay = await _loadRequiredImage(
        layeredAssets.foregroundOverlayAssetPath,
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to load layered background for "$assetPath": $error');
      debugPrintStack(stackTrace: stackTrace);
      _backLayer = null;
      _foregroundOverlay = null;
    }
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

  Future<ui.Image> _loadRequiredImage(String path) {
    return Flame.images.load(LevelBackgroundAssets.flameImageKey(path));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final backLayer = _backLayer;
    final foregroundOverlay = _foregroundOverlay;
    if (backLayer != null && foregroundOverlay != null) {
      _paintImage(canvas, backLayer);
      _paintImage(canvas, foregroundOverlay);
      return;
    }

    final background = _background;
    if (background == null) {
      return;
    }

    _paintImage(canvas, background);
  }

  void _paintImage(Canvas canvas, ui.Image image) {
    paintImage(
      canvas: canvas,
      rect: size.toRect(),
      image: image,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
    );
  }
}
