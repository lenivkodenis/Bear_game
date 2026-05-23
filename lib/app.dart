import 'package:flutter/material.dart';

import 'screens/final_screen.dart';
import 'screens/game_screen.dart';
import 'screens/level_complete_screen.dart';
import 'screens/location_map_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/parents_screen.dart';
import 'screens/progress_screen.dart';

class BearGameApp extends StatelessWidget {
  const BearGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Медвежонок и таблица умножения',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3A8FB7),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      routes: {
        MainMenuScreen.routeName: (_) => const MainMenuScreen(),
        GameScreen.routeName: (_) => const GameScreen(),
        FinalScreen.routeName: (_) => const FinalScreen(),
        LevelCompleteScreen.routeName: (_) => const LevelCompleteScreen(),
        LocationMapScreen.routeName: (_) => const LocationMapScreen(),
        ProgressScreen.routeName: (_) => const ProgressScreen(),
        ParentsScreen.routeName: (_) => const ParentsScreen(),
      },
      initialRoute: MainMenuScreen.routeName,
    );
  }
}
