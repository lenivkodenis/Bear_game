import 'package:flutter/material.dart';

import '../game/bear_math_game.dart';

class ViewportDebugOverlay extends StatelessWidget {
  const ViewportDebugOverlay({required this.game, super.key});

  final BearMathGame game;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final worldRect = game.debugVisibleWorldRect;
          final canvas = game.canvasSize;
          return Align(
            alignment: Alignment.topRight,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(4, 70, 4, 4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xD9041826),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 5,
                  ),
                  child: Text(
                    'Flutter ${media.size.width.toStringAsFixed(1)}×'
                    '${media.size.height.toStringAsFixed(1)} '
                    'dpr=${media.devicePixelRatio.toStringAsFixed(2)}\n'
                    'render ${constraints.maxWidth.toStringAsFixed(1)}×'
                    '${constraints.maxHeight.toStringAsFixed(1)} '
                    'canvas ${canvas.x.toStringAsFixed(1)}×'
                    '${canvas.y.toStringAsFixed(1)}\n'
                    'safe ${media.padding.left.toStringAsFixed(0)},'
                    '${media.padding.top.toStringAsFixed(0)},'
                    '${media.padding.right.toStringAsFixed(0)},'
                    '${media.padding.bottom.toStringAsFixed(0)} '
                    'zoom=${game.debugCameraZoom.toStringAsFixed(3)}\n'
                    'world ${worldRect == null ? 'loading' : '${worldRect.left.toStringAsFixed(1)},${worldRect.top.toStringAsFixed(1)} ${worldRect.width.toStringAsFixed(1)}×${worldRect.height.toStringAsFixed(1)}'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      height: 1.25,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
