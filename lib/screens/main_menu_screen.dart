import 'dart:ui';

import 'package:flutter/material.dart';

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
    required this.onMap,
    required this.onProgress,
    required this.onParents,
  });

  final VoidCallback onStart;
  final VoidCallback onMap;
  final VoidCallback onProgress;
  final VoidCallback onParents;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF071B32).withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppTheme.iceBlue.withValues(alpha: 0.34),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: AppTheme.iceBlue.withValues(alpha: 0.18),
                blurRadius: 24,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Медвежонок и таблица умножения',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.snowWhite,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                    shadows: const [
                      Shadow(
                        color: Color(0xB0001026),
                        blurRadius: 12,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Доброе северное путешествие',
                  textAlign: TextAlign.center,
                  style: AppTheme.helperStyle.copyWith(
                    color: AppTheme.iceBlue.withValues(alpha: 0.92),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 24),
                _FrostedMenuButton(
                  label: 'Начать игру',
                  icon: Icons.play_arrow_rounded,
                  primary: true,
                  onPressed: onStart,
                ),
                const SizedBox(height: 12),
                _FrostedMenuButton(
                  label: 'Карта',
                  icon: Icons.map_rounded,
                  onPressed: onMap,
                ),
                const SizedBox(height: 12),
                _FrostedMenuButton(
                  label: 'Прогресс',
                  icon: Icons.emoji_events_rounded,
                  onPressed: onProgress,
                ),
                const SizedBox(height: 12),
                _FrostedMenuButton(
                  label: 'Родителям',
                  icon: Icons.family_restroom_rounded,
                  onPressed: onParents,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FrostedMenuButton extends StatelessWidget {
  const _FrostedMenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final borderColor = primary
        ? AppTheme.snowWhite.withValues(alpha: 0.78)
        : AppTheme.iceBlue.withValues(alpha: 0.58);
    final gradientColors = primary
        ? const [Color(0xFFEAFBFF), Color(0xFF9FDAF6)]
        : [
            AppTheme.snowWhite.withValues(alpha: 0.24),
            AppTheme.iceBlue.withValues(alpha: 0.16),
          ];
    final foreground = primary ? AppTheme.deepBlue : AppTheme.snowWhite;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onPressed,
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: primary ? 0.24 : 0.16),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              if (primary)
                BoxShadow(
                  color: AppTheme.iceBlue.withValues(alpha: 0.35),
                  blurRadius: 22,
                  spreadRadius: -6,
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 24),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      shadows: primary
                          ? null
                          : const [
                              Shadow(
                                color: Color(0x99001026),
                                blurRadius: 8,
                                offset: Offset(0, 1),
                              ),
                            ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
