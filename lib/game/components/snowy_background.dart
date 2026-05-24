import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class SnowyBackground extends PositionComponent {
  SnowyBackground({required Vector2 size}) : super(size: size);

  static const _layerAssetPaths = [
    'locations/snowy_clearing/01_sky.png',
    'locations/snowy_clearing/02_far_hills.png',
    'locations/snowy_clearing/03_mid_forest.png',
    'locations/snowy_clearing/04_ground_platform.png',
  ];

  final List<ui.Image> _layers = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _layers.addAll(await Future.wait(_layerAssetPaths.map(Flame.images.load)));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final destination = size.toRect();
    for (final layer in _layers) {
      paintImage(
        canvas: canvas,
        rect: destination,
        image: layer,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      );
    }
  }
}
