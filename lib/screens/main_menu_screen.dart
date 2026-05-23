import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/game_card.dart';
import '../widgets/primary_game_button.dart';
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
  final ProgressService _progressService = ProgressService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: AppTheme.snowyGradient,
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _MenuPainter())),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: AppTheme.screenPadding,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        const _BearHero(),
                        const SizedBox(height: 24),
                        Text(
                          'Медвежонок и таблица умножения',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.deepBlue,
                                height: 1.08,
                              ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Доброе северное путешествие по таблице умножения',
                          textAlign: TextAlign.center,
                          style: AppTheme.helperStyle,
                        ),
                        const SizedBox(height: 28),
                        GameCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              PrimaryGameButton(
                                label: 'Начать игру',
                                icon: Icons.play_arrow_rounded,
                                symbol: '▶',
                                onPressed: _startGame,
                              ),
                              const SizedBox(height: 12),
                              PrimaryGameButton(
                                label: 'Карта',
                                icon: Icons.map_rounded,
                                symbol: '⌂',
                                secondary: true,
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushNamed(LocationMapScreen.routeName),
                              ),
                              const SizedBox(height: 12),
                              PrimaryGameButton(
                                label: 'Прогресс',
                                icon: Icons.emoji_events_rounded,
                                symbol: '★',
                                secondary: true,
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushNamed(ProgressScreen.routeName),
                              ),
                              const SizedBox(height: 12),
                              PrimaryGameButton(
                                label: 'Родителям',
                                icon: Icons.family_restroom_rounded,
                                symbol: '♡',
                                secondary: true,
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushNamed(ParentsScreen.routeName),
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
          ],
        ),
      ),
    );
  }

  Future<void> _startGame() async {
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
}

class _BearHero extends StatelessWidget {
  const _BearHero();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 150,
        width: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 8,
              child: Container(
                width: 210,
                height: 54,
                decoration: BoxDecoration(
                  color: AppTheme.snowWhite,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.iceBlue, width: 2),
                ),
              ),
            ),
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: AppTheme.snowWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.iceBlue, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.softShadow,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  const Positioned(left: 15, top: 16, child: _BearEar()),
                  const Positioned(right: 15, top: 16, child: _BearEar()),
                  const Positioned(left: 34, top: 50, child: _BearEye()),
                  const Positioned(right: 34, top: 50, child: _BearEye()),
                  Positioned(
                    left: 50,
                    top: 68,
                    child: Container(
                      width: 18,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.deepBlue,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
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

class _BearEar extends StatelessWidget {
  const _BearEar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8FF),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.iceBlue, width: 2),
      ),
    );
  }
}

class _MenuPainter extends CustomPainter {
  const _MenuPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()..color = AppTheme.iceBlue.withValues(alpha: 0.28);
    final lowerWavePaint = Paint()
      ..color = AppTheme.snowWhite.withValues(alpha: 0.72);
    final snowPaint = Paint()
      ..color = AppTheme.snowWhite.withValues(alpha: 0.8);

    final upperWave = Path()
      ..moveTo(0, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.12,
        size.width * 0.5,
        size.height * 0.18,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.24,
        size.width,
        size.height * 0.16,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(upperWave, wavePaint);

    final lowerWave = Path()
      ..moveTo(0, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.74,
        size.width * 0.58,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.9,
        size.width,
        size.height * 0.8,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(lowerWave, lowerWavePaint);

    for (final flake in _flakes) {
      _drawSnowflake(
        canvas,
        Offset(size.width * flake.x, size.height * flake.y),
        flake.radius,
        snowPaint,
      );
    }
  }

  void _drawSnowflake(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    canvas.drawCircle(center, radius * 0.22, paint);
    for (var i = 0; i < 6; i++) {
      final angle = i * 3.14159 / 3;
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, end, paint..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  static const _flakes = [
    _SnowflakeMark(0.12, 0.18, 10),
    _SnowflakeMark(0.86, 0.22, 8),
    _SnowflakeMark(0.18, 0.62, 7),
    _SnowflakeMark(0.78, 0.7, 11),
  ];
}

class _SnowflakeMark {
  const _SnowflakeMark(this.x, this.y, this.radius);

  final double x;
  final double y;
  final double radius;
}

class _BearEye extends StatelessWidget {
  const _BearEye();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(radius: 4, backgroundColor: AppTheme.deepBlue);
  }
}
