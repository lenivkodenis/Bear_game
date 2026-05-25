import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../level_geometry.dart';
import 'player_bear.dart';

class GroundCalibrationOverlayInfo {
  const GroundCalibrationOverlayInfo({
    required this.levelId,
    required this.baseGroundY,
    required this.calibratedGroundY,
    required this.runtimeGroundY,
    this.levelName,
    this.exportPrinted = false,
  });

  final int levelId;
  final String? levelName;
  final double baseGroundY;
  final double calibratedGroundY;
  final double runtimeGroundY;
  final bool exportPrinted;

  double get delta => calibratedGroundY - baseGroundY;
}

class LevelGeometryDebugOverlay extends PositionComponent {
  LevelGeometryDebugOverlay({
    required LevelGeometry Function() geometry,
    required PlayerBear Function() player,
    GroundCalibrationOverlayInfo? Function()? calibrationInfo,
  }) : _geometryProvider = geometry,
       _playerProvider = player,
       _calibrationInfoProvider = calibrationInfo,
       super(priority: 10000);

  static const _groundFillColor = Color(0x2234C759);
  static const _groundStrokeColor = Color(0xCC34C759);
  static const _groundTopColor = Color(0xFFFFD60A);
  static const _platformColor = Color(0xCC0A84FF);
  static const _obstacleColor = Color(0xFFFF453A);
  static const _candidateFillColor = Color(0x33FF9F0A);
  static const _candidateColor = Color(0xFFFF9F0A);
  static const _spawnColor = Color(0xFFBF5AF2);
  static const _mentorColor = Color(0xFFFF9F0A);
  static const _hitboxColor = Color(0xFFFFFFFF);
  static const _feetColor = Color(0xFFFF2D55);
  static const _visualBoundsColor = Color(0xCC30D158);
  static const _visualFeetColor = Color(0xCCBF5AF2);
  static const _labelBackgroundColor = Color(0xCC111827);
  static const _labelTextColor = Color(0xFFFFFFFF);
  static const _panelBackgroundColor = Color(0xDD111827);
  static const _panelBorderColor = Color(0x99FFFFFF);

  final LevelGeometry Function() _geometryProvider;
  final PlayerBear Function() _playerProvider;
  final GroundCalibrationOverlayInfo? Function()? _calibrationInfoProvider;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final geometry = _geometryProvider();
    final player = _playerProvider();

    _drawColliders(
      canvas,
      geometry.groundColliders,
      fillColor: _groundFillColor,
      strokeColor: _groundStrokeColor,
      labelPrefix: 'ground',
      drawTopLine: true,
    );
    _drawColliders(
      canvas,
      geometry.platformColliders,
      fillColor: Colors.transparent,
      strokeColor: _platformColor,
      labelPrefix: 'platform',
    );
    _drawColliders(
      canvas,
      geometry.obstacleColliders,
      fillColor: Colors.transparent,
      strokeColor: _obstacleColor,
      labelPrefix: 'obstacle',
    );
    _drawColliders(
      canvas,
      geometry.calibrationObstacles,
      fillColor: _candidateFillColor,
      strokeColor: _candidateColor,
      labelPrefix: 'candidate',
      drawTopLine: true,
      drawBottomLine: true,
    );
    _drawPoint(
      canvas,
      geometry.playerSpawn.toVector2(),
      _spawnColor,
      'playerSpawn',
    );
    _drawPoint(
      canvas,
      geometry.mentorPosition.toVector2(),
      _mentorColor,
      'mentor',
    );
    _drawPlayerHitbox(canvas, player);
    _drawCalibrationInfo(canvas, _calibrationInfoProvider?.call());
  }

  void _drawColliders(
    Canvas canvas,
    List<LevelGeometryCollider> colliders, {
    required Color fillColor,
    required Color strokeColor,
    required String labelPrefix,
    bool drawTopLine = false,
    bool drawBottomLine = false,
  }) {
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final topLinePaint = Paint()
      ..color = _groundTopColor
      ..strokeWidth = 2.5;

    for (final collider in colliders) {
      final rect = Rect.fromLTWH(
        collider.x,
        collider.y,
        collider.width,
        collider.height,
      );
      if (fillColor != Colors.transparent) {
        canvas.drawRect(rect, fillPaint);
      }
      canvas.drawRect(rect, strokePaint);
      if (drawTopLine) {
        canvas.drawLine(rect.topLeft, rect.topRight, topLinePaint);
      }
      if (drawBottomLine) {
        canvas.drawLine(rect.bottomLeft, rect.bottomRight, topLinePaint);
      }
      _drawLabel(
        canvas,
        '$labelPrefix:${collider.id}',
        Offset(rect.left + 4, rect.top + 4),
        strokeColor,
      );
    }
  }

  void _drawPlayerHitbox(Canvas canvas, PlayerBear player) {
    final hitbox = Rect.fromLTWH(
      player.position.x,
      player.position.y,
      player.size.x,
      player.size.y,
    );
    final hitboxPaint = Paint()
      ..color = _hitboxColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final feetPaint = Paint()
      ..color = _feetColor
      ..strokeWidth = 2.5;
    final visualBoundsPaint = Paint()
      ..color = _visualBoundsColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final visualFeetPaint = Paint()
      ..color = _visualFeetColor
      ..strokeWidth = 2.5;
    final visualBounds = player.visualBounds;
    final visualFeetY = player.visualFeetY;

    canvas.drawRect(visualBounds, visualBoundsPaint);
    canvas.drawLine(
      Offset(visualBounds.left, visualFeetY),
      Offset(visualBounds.right, visualFeetY),
      visualFeetPaint,
    );
    canvas.drawRect(hitbox, hitboxPaint);
    canvas.drawLine(hitbox.bottomLeft, hitbox.bottomRight, feetPaint);
    _drawLabel(
      canvas,
      'visual bounds',
      visualBounds.topLeft + const Offset(4, 4),
      _visualBoundsColor,
    );
    _drawLabel(
      canvas,
      'visual feet',
      Offset(visualBounds.left + 4, visualFeetY - 24),
      _visualFeetColor,
    );
    _drawLabel(
      canvas,
      'player hitbox',
      hitbox.topLeft + const Offset(4, 4),
      _hitboxColor,
    );
    _drawLabel(
      canvas,
      'feet/bottom',
      hitbox.bottomLeft + const Offset(4, -24),
      _feetColor,
    );
  }

  void _drawCalibrationInfo(Canvas canvas, GroundCalibrationOverlayInfo? info) {
    if (info == null) {
      return;
    }

    final levelName = info.levelName?.trim();
    final lines = <String>[
      'Ground calibration',
      'levelId: ${info.levelId}',
      if (levelName != null && levelName.isNotEmpty) 'level: $levelName',
      'json main_ground.y: ${_formatNumber(info.baseGroundY)}',
      'temporary groundY: ${_formatNumber(info.calibratedGroundY)}',
      'delta: ${_formatSignedNumber(info.delta)}',
      'runtime line y: ${_formatNumber(info.runtimeGroundY)}',
      'ArrowUp/ArrowDown: 5 px',
      'Shift+Arrow: 1 px',
      'C: print JSON',
      'R: reset',
      if (info.exportPrinted) 'last export printed to console',
    ];

    _drawTextPanel(canvas, lines, const Offset(12, 64));
  }

  void _drawTextPanel(Canvas canvas, List<String> lines, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: lines.join('\n'),
        style: const TextStyle(
          color: _labelTextColor,
          fontSize: 11,
          height: 1.25,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 280);
    final background = Rect.fromLTWH(
      position.dx - 8,
      position.dy - 6,
      textPainter.width + 16,
      textPainter.height + 12,
    );
    final backgroundPaint = Paint()..color = _panelBackgroundColor;
    final borderPaint = Paint()
      ..color = _panelBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(background, backgroundPaint);
    canvas.drawRect(background, borderPaint);
    textPainter.paint(canvas, position);
  }

  void _drawPoint(Canvas canvas, Vector2 point, Color color, String label) {
    final center = Offset(point.x, point.y);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    canvas.drawCircle(center, 4, paint);
    canvas.drawLine(
      center + const Offset(-8, 0),
      center + const Offset(8, 0),
      paint,
    );
    canvas.drawLine(
      center + const Offset(0, -8),
      center + const Offset(0, 8),
      paint,
    );
    _drawLabel(canvas, label, center + const Offset(8, -22), color);
  }

  void _drawLabel(Canvas canvas, String label, Offset position, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: _labelTextColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final background = Rect.fromLTWH(
      position.dx - 3,
      position.dy - 2,
      textPainter.width + 6,
      textPainter.height + 4,
    );
    final backgroundPaint = Paint()..color = _labelBackgroundColor;
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(background, backgroundPaint);
    canvas.drawRect(background, borderPaint);
    textPainter.paint(canvas, position);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(2);
  }

  String _formatSignedNumber(double value) {
    final sign = value > 0 ? '+' : '';

    return '$sign${_formatNumber(value)}';
  }
}
