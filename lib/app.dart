import 'package:flutter/material.dart';

import 'screens/final_screen.dart';
import 'screens/game_screen.dart';
import 'screens/level_complete_screen.dart';
import 'screens/location_map_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/parents_screen.dart';
import 'screens/progress_screen.dart';
import 'theme/app_theme.dart';
import 'visual_test/visual_test_config.dart';
import 'visual_test/visual_test_dom_bridge.dart';
import 'visual_test/visual_test_fixtures.dart';

class BearGameApp extends StatelessWidget {
  const BearGameApp({
    super.key,
    this.visualTestConfig = const VisualTestConfig.disabled(),
  });

  final VisualTestConfig visualTestConfig;

  @override
  Widget build(BuildContext context) {
    final namedRoutes = <String, WidgetBuilder>{
      GameScreen.routeName: (_) =>
          GameScreen(visualTestConfig: visualTestConfig),
      FinalScreen.routeName: (_) => const FinalScreen(),
      LevelCompleteScreen.routeName: (_) => const LevelCompleteScreen(),
      LocationMapScreen.routeName: (_) => visualTestConfig.enabled
          ? const _VisualTestAppReadyReporter(
              child: LocationMapScreen(progressLoader: visualTestMapProgress),
            )
          : const LocationMapScreen(),
      ProgressScreen.routeName: (_) => const ProgressScreen(),
      ParentsScreen.routeName: (_) => const ParentsScreen(),
    };
    if (!visualTestConfig.enabled) {
      namedRoutes[MainMenuScreen.routeName] = (_) => const MainMenuScreen();
    }

    return MaterialApp(
      title: 'BearMath — игра для изучения таблицы умножения',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routes: namedRoutes,
      home: visualTestConfig.enabled ? _visualTestHome(visualTestConfig) : null,
      initialRoute: MainMenuScreen.routeName,
    );
  }
}

Widget _visualTestHome(VisualTestConfig config) {
  return switch (config.routePath) {
    GameScreen.routeName || LocationMapScreen.routeName => _VisualTestLauncher(
      routeName: config.routePath,
    ),
    _ => _VisualTestAppReadyReporter(
      child: MainMenuScreen(visualTestConfig: config),
    ),
  };
}

class _VisualTestLauncher extends StatefulWidget {
  const _VisualTestLauncher({required this.routeName});

  final String routeName;

  @override
  State<_VisualTestLauncher> createState() => _VisualTestLauncherState();
}

class _VisualTestLauncherState extends State<_VisualTestLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(widget.routeName);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class _VisualTestAppReadyReporter extends StatefulWidget {
  const _VisualTestAppReadyReporter({required this.child});

  final Widget child;

  @override
  State<_VisualTestAppReadyReporter> createState() =>
      _VisualTestAppReadyReporterState();
}

class _VisualTestAppReadyReporterState
    extends State<_VisualTestAppReadyReporter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        markVisualTestAppReady();
      });
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
