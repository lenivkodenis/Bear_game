import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class SnowyBackground extends PositionComponent {
  SnowyBackground({required Vector2 size}) : super(size: size);

  static const _backgroundAssetPath =
      'locations/snowy_clearing/preview/snowy_clearing_full_preview.png';

  ui.Image? _background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _background = await Flame.images.load(_backgroundAssetPath);
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
