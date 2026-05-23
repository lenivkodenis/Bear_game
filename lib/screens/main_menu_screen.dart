import 'package:flutter/material.dart';

import '../services/progress_service.dart';
import '../widgets/menu_button.dart';
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F8FF), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.ac_unit,
                      size: 72,
                      color: Color(0xFF3A8FB7),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Медвежонок и таблица умножения',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF17435A),
                          ),
                    ),
                    const SizedBox(height: 40),
                    MenuButton(
                      label: 'Начать игру',
                      icon: Icons.play_arrow_rounded,
                      onPressed: _startGame,
                    ),
                    const SizedBox(height: 12),
                    MenuButton(
                      label: 'Прогресс',
                      icon: Icons.emoji_events_rounded,
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(ProgressScreen.routeName),
                    ),
                    const SizedBox(height: 12),
                    MenuButton(
                      label: 'Родителям',
                      icon: Icons.family_restroom_rounded,
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(ParentsScreen.routeName),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
