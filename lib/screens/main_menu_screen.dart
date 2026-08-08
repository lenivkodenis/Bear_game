import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/game_settings_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/effects/snowfall_overlay.dart';
import 'game_screen.dart';
import 'location_map_screen.dart';
import 'parents_screen.dart';
import 'progress_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  static const routeName = '/';

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  static const _backgroundAsset =
      'public/assets/main_screen/main_screen_bear_bg.png';

  final ProgressService _progressService = ProgressService();
  final GameSettingsService _settingsService = GameSettingsService();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.width < 760;
    final panelWidth = (screenSize.width - 32).clamp(320.0, 430.0);

    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                _backgroundAsset,
                fit: BoxFit.cover,
                alignment: isCompact
                    ? const Alignment(-0.08, 0)
                    : Alignment.center,
                filterQuality: FilterQuality.high,
              ),
            ),
            if (isCompact)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Image.asset(
                    _backgroundAsset,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            const Positioned.fill(child: _MenuReadabilityOverlay()),
            const Positioned.fill(
              child: IgnorePointer(
                child: SnowfallOverlay(intensity: SnowfallIntensity.medium),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 16 : 24,
                  isCompact ? 16 : 24,
                  isCompact ? 16 : 56,
                  isCompact ? 132 : 24,
                ),
                child: Align(
                  alignment: isCompact
                      ? Alignment.topCenter
                      : const Alignment(0.12, -0.45),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: panelWidth,
                      child: _MainMenuPanel(
                        onStart: _startGame,
                        onRestart: _restartGame,
                        onMap: () => Navigator.of(
                          context,
                        ).pushNamed(LocationMapScreen.routeName),
                        onProgress: () => Navigator.of(
                          context,
                        ).pushNamed(ProgressScreen.routeName),
                        onParents: () => Navigator.of(
                          context,
                        ).pushNamed(ParentsScreen.routeName),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startGame() async {
    final resetRequired = await _settingsService.isDifficultyResetRequired();
    if (resetRequired) {
      if (!mounted ||
          !await _confirmRestart(
            title: 'Сложность изменилась',
            message:
                'При новой сложности игра начнётся с первого уровня. Весь текущий прогресс и снежинки будут сброшены.',
          )) {
        return;
      }

      await _resetProgressForNewGame();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamed(GameScreen.routeName, arguments: 1);
      return;
    }

    final progress = await _progressService.loadProgress();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamed(
      progress.unlockedLocation > 1
          ? LocationMapScreen.routeName
          : GameScreen.routeName,
    );
  }

  Future<void> _restartGame() async {
    final confirmed = await _confirmRestart(
      title: 'Начать игру заново?',
      message:
          'Все пройденные уровни, решённые примеры и снежинки будут сброшены. Отменить это действие нельзя.',
    );
    if (!confirmed) {
      return;
    }

    await _resetProgressForNewGame();
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamed(GameScreen.routeName, arguments: 1);
  }

  Future<void> _resetProgressForNewGame() async {
    await _progressService.resetProgress();
    await _settingsService.confirmProgressResetForCurrentDifficulty();
  }

  Future<bool> _confirmRestart({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Начать заново'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _MenuReadabilityOverlay extends StatelessWidget {
  const _MenuReadabilityOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFF000814).withValues(alpha: 0.04),
            const Color(0xFF001C38).withValues(alpha: 0.1),
            const Color(0xFF001A35).withValues(alpha: 0.42),
          ],
        ),
      ),
    );
  }
}

class _MainMenuPanel extends StatelessWidget {
  const _MainMenuPanel({
    required this.onStart,
    required this.onRestart,
    required this.onMap,
    required this.onProgress,
    required this.onParents,
  });

  final VoidCallback onStart;
  final VoidCallback onRestart;
  final VoidCallback onMap;
  final VoidCallback onProgress;
  final VoidCallback onParents;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _MainMenuTitle(),
          const SizedBox(height: 20),
          _NorthSignButton(
            label: 'Начать игру',
            icon: _NorthSignIcon.play,
            primary: true,
            onPressed: onStart,
          ),
          const SizedBox(height: 12),
          _NorthSignButton(
            label: 'Начать игру заново',
            icon: _NorthSignIcon.restart,
            onPressed: onRestart,
          ),
          const SizedBox(height: 12),
          _NorthSignButton(
            label: 'Карта',
            icon: _NorthSignIcon.map,
            onPressed: onMap,
          ),
          const SizedBox(height: 12),
          _NorthSignButton(
            label: 'Прогресс',
            icon: _NorthSignIcon.snowflake,
            onPressed: onProgress,
          ),
          const SizedBox(height: 12),
          _NorthSignButton(
            label: 'Родителям',
            icon: _NorthSignIcon.lantern,
            onPressed: onParents,
          ),
        ],
      ),
    );
  }
}

class _MainMenuTitle extends StatelessWidget {
  const _MainMenuTitle();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _TitleSnowDustPainter(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Медвежонок и таблица умножения',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.snowWhite,
                fontWeight: FontWeight.w900,
                height: 1.08,
                shadows: const [
                  Shadow(
                    color: Color(0xC0001026),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Доброе северное путешествие',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.helperStyle.copyWith(
                color: AppTheme.frostBlue,
                fontSize: 15,
                shadows: const [
                  Shadow(
                    color: Color(0x99001026),
                    blurRadius: 8,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _NorthSignIcon { play, restart, map, snowflake, lantern }

class _NorthSignButton extends StatefulWidget {
  const _NorthSignButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final _NorthSignIcon icon;
  final VoidCallback onPressed;
  final bool primary;

  @override
  State<_NorthSignButton> createState() => _NorthSignButtonState();
}

class _NorthSignButtonState extends State<_NorthSignButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }

    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.primary ? 72.0 : 58.0;
    final foreground = widget.primary
        ? const Color(0xFF12384F)
        : const Color(0xFF173F58);
    final iconSize = widget.primary ? 34.0 : 28.0;

    return Semantics(
      button: true,
      label: widget.label,
      onTap: widget.onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          offset: Offset(0, _isPressed ? 0.035 : 0),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOutCubic,
            scale: _isPressed ? 0.985 : 1,
            child: SizedBox(
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _NorthSignPainter(
                      primary: widget.primary,
                      pressed: _isPressed,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      widget.primary ? 22 : 18,
                      widget.primary ? 12 : 9,
                      widget.primary ? 22 : 18,
                      widget.primary ? 8 : 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomPaint(
                          size: Size.square(iconSize),
                          painter: _NorthSignIconPainter(
                            icon: widget.icon,
                            color: foreground,
                            primary: widget.primary,
                          ),
                        ),
                        SizedBox(width: widget.primary ? 13 : 10),
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: foreground,
                              fontSize: widget.primary ? 20 : 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                              shadows: const [
                                Shadow(
                                  color: Color(0x4DFFFFFF),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleSnowDustPainter extends CustomPainter {
  const _TitleSnowDustPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.snowWhite.withValues(alpha: 0.18);
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.28),
      2.4,
      paint,
    );
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.2), 2.8, paint);
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.82),
      1.8,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NorthSignPainter extends CustomPainter {
  const _NorthSignPainter({required this.primary, required this.pressed});

  final bool primary;
  final bool pressed;

  @override
  void paint(Canvas canvas, Size size) {
    final signRect = Rect.fromLTWH(3, 8, size.width - 6, size.height - 12);
    final signRadius = Radius.circular(primary ? 24 : 20);
    final signRRect = RRect.fromRectAndRadius(signRect, signRadius);
    final shadowPaint = Paint()
      ..color = const Color(
        0xFF001426,
      ).withValues(alpha: pressed ? 0.12 : (primary ? 0.26 : 0.18))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, pressed ? 5 : 8);
    canvas.drawRRect(
      signRRect.shift(Offset(0, pressed ? 2.5 : 5)),
      shadowPaint,
    );

    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: primary
            ? const [Color(0xFFFDF9ED), Color(0xFFD7F1FF), Color(0xFF8FCFEC)]
            : const [Color(0xFFF7EBD4), Color(0xFFE6D4B4), Color(0xFFD3E9EF)],
        stops: primary ? const [0, 0.55, 1] : const [0, 0.62, 1],
      ).createShader(signRect);
    canvas.drawRRect(signRRect, basePaint);

    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = primary ? 2.2 : 1.8
      ..color = primary
          ? AppTheme.snowWhite.withValues(alpha: 0.92)
          : const Color(0xFFFFFAF0).withValues(alpha: 0.88);
    canvas.drawRRect(signRRect.deflate(1.1), edgePaint);

    final lowEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF2C6C89).withValues(alpha: 0.18);
    canvas.drawRRect(signRRect.deflate(3.8), lowEdgePaint);

    final snowPath = Path()
      ..moveTo(signRect.left + signRadius.x * 0.55, signRect.top + 1)
      ..lineTo(signRect.right - signRadius.x * 0.55, signRect.top + 1)
      ..quadraticBezierTo(
        signRect.right - 12,
        signRect.top + 8,
        signRect.right - 22,
        signRect.top + 14,
      )
      ..cubicTo(
        signRect.right - 70,
        signRect.top + (primary ? 22 : 18),
        signRect.left + 92,
        signRect.top + (primary ? 9 : 8),
        signRect.left + 54,
        signRect.top + (primary ? 18 : 15),
      )
      ..quadraticBezierTo(
        signRect.left + 20,
        signRect.top + 16,
        signRect.left + signRadius.x * 0.55,
        signRect.top + 1,
      )
      ..close();
    final snowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFE9F8FF)],
      ).createShader(snowPath.getBounds());
    canvas.drawPath(snowPath, snowPaint);

    final snowEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFF8CCBE6).withValues(alpha: 0.35);
    canvas.drawPath(snowPath, snowEdgePaint);

    if (primary) {
      final glowPaint = Paint()
        ..color = AppTheme.iceBlue.withValues(alpha: 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawRRect(signRRect.deflate(7), glowPaint);
      canvas.drawRRect(signRRect, basePaint);
      canvas.drawPath(snowPath, snowPaint);
      canvas.drawPath(snowPath, snowEdgePaint);
      canvas.drawRRect(signRRect.deflate(1.1), edgePaint);
    }

    final grainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..color = const Color(
        0xFF7B6B50,
      ).withValues(alpha: primary ? 0.12 : 0.16);
    final grainY = signRect.top + size.height * 0.62;
    canvas.drawLine(
      Offset(signRect.left + 22, grainY),
      Offset(signRect.left + size.width * 0.34, grainY - 2),
      grainPaint,
    );
    canvas.drawLine(
      Offset(signRect.right - size.width * 0.34, grainY + 2),
      Offset(signRect.right - 24, grainY),
      grainPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _NorthSignPainter oldDelegate) {
    return oldDelegate.primary != primary || oldDelegate.pressed != pressed;
  }
}

class _NorthSignIconPainter extends CustomPainter {
  const _NorthSignIconPainter({
    required this.icon,
    required this.color,
    required this.primary,
  });

  final _NorthSignIcon icon;
  final Color color;
  final bool primary;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = primary ? 3.1 : 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    switch (icon) {
      case _NorthSignIcon.play:
        _paintPlay(canvas, size, stroke, fill);
      case _NorthSignIcon.restart:
        _paintRestart(canvas, size, stroke);
      case _NorthSignIcon.map:
        _paintMap(canvas, size, stroke, fill);
      case _NorthSignIcon.snowflake:
        _paintSnowflake(canvas, size, stroke);
      case _NorthSignIcon.lantern:
        _paintLantern(canvas, size, stroke, fill);
    }
  }

  void _paintPlay(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.29, h * 0.2)
      ..lineTo(w * 0.76, h * 0.5)
      ..lineTo(w * 0.29, h * 0.8)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    canvas.drawLine(
      Offset(w * 0.18, h * 0.86),
      Offset(w * 0.82, h * 0.86),
      stroke,
    );
  }

  void _paintMap(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.14, h * 0.24)
      ..quadraticBezierTo(w * 0.28, h * 0.14, w * 0.42, h * 0.23)
      ..quadraticBezierTo(w * 0.57, h * 0.32, w * 0.72, h * 0.22)
      ..quadraticBezierTo(w * 0.82, h * 0.16, w * 0.88, h * 0.25)
      ..lineTo(w * 0.84, h * 0.76)
      ..quadraticBezierTo(w * 0.67, h * 0.86, w * 0.51, h * 0.75)
      ..quadraticBezierTo(w * 0.36, h * 0.64, w * 0.16, h * 0.78)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    canvas.drawLine(
      Offset(w * 0.4, h * 0.24),
      Offset(w * 0.37, h * 0.72),
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.66, h * 0.26),
      Offset(w * 0.63, h * 0.76),
      stroke,
    );
    canvas.drawCircle(
      Offset(w * 0.53, h * 0.5),
      w * 0.045,
      Paint()..color = color,
    );
  }

  void _paintRestart(Canvas canvas, Size size, Paint stroke) {
    final w = size.width;
    final h = size.height;
    canvas.drawArc(
      Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.64, h * 0.64),
      -math.pi * 0.7,
      math.pi * 1.55,
      false,
      stroke,
    );
    final arrow = Path()
      ..moveTo(w * 0.12, h * 0.2)
      ..lineTo(w * 0.39, h * 0.2)
      ..lineTo(w * 0.2, h * 0.42)
      ..close();
    canvas.drawPath(arrow, Paint()..color = color);
  }

  void _paintSnowflake(Canvas canvas, Size size, Paint stroke) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = size.shortestSide * 0.36;
    for (var i = 0; i < 6; i++) {
      final angle = i * 1.0471975512;
      final end =
          center + Offset(radius * math.cos(angle), radius * math.sin(angle));
      canvas.drawLine(center, end, stroke);
      final branch = radius * 0.23;
      final branchCenter =
          center +
          Offset(
            radius * 0.66 * math.cos(angle),
            radius * 0.66 * math.sin(angle),
          );
      canvas.drawLine(
        branchCenter,
        branchCenter +
            Offset(
              branch * math.cos(angle + 0.75),
              branch * math.sin(angle + 0.75),
            ),
        stroke,
      );
      canvas.drawLine(
        branchCenter,
        branchCenter +
            Offset(
              branch * math.cos(angle - 0.75),
              branch * math.sin(angle - 0.75),
            ),
        stroke,
      );
    }
    canvas.drawCircle(center, size.shortestSide * 0.07, Paint()..color = color);
  }

  void _paintLantern(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final w = size.width;
    final h = size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.28, h * 0.32, w * 0.44, h * 0.45),
      Radius.circular(w * 0.09),
    );
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, stroke);
    canvas.drawArc(
      Rect.fromLTWH(w * 0.32, h * 0.13, w * 0.36, h * 0.28),
      3.14159,
      3.14159,
      false,
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.22, h * 0.82),
      Offset(w * 0.78, h * 0.82),
      stroke,
    );
    final flame = Path()
      ..moveTo(w * 0.5, h * 0.43)
      ..cubicTo(w * 0.39, h * 0.53, w * 0.45, h * 0.65, w * 0.5, h * 0.68)
      ..cubicTo(w * 0.58, h * 0.61, w * 0.62, h * 0.52, w * 0.5, h * 0.43);
    canvas.drawPath(flame, Paint()..color = color.withValues(alpha: 0.32));
  }

  @override
  bool shouldRepaint(covariant _NorthSignIconPainter oldDelegate) {
    return oldDelegate.icon != icon ||
        oldDelegate.color != color ||
        oldDelegate.primary != primary;
  }
}
