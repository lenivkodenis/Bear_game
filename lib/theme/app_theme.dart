import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const iceBlue = Color(0xFFBFEAFF);
  static const frostBlue = Color(0xFFEAF8FE);
  static const snowWhite = Color(0xFFFFFFFF);
  static const softBlue = Color(0xFF3A8FB7);
  static const softBluePressed = Color(0xFF2B789B);
  static const deepBlue = Color(0xFF17435A);
  static const warmYellow = Color(0xFFF7B733);
  static const paleYellow = Color(0xFFFFF3C8);
  static const gentleGreen = Color(0xFF66C6A4);
  static const gentleGreenPressed = Color(0xFF45AA89);
  static const paleGreen = Color(0xFFE9FBF6);
  static const lockedBlue = Color(0xFF8FA4AE);
  static const lockedPanel = Color(0xFFDDE8ED);
  static const softCoral = Color(0xFFFF8F7E);
  static const paleCoral = Color(0xFFFFEEE9);
  static const palePanel = Color(0xFFF4FBFF);
  static const softShadow = Color(0x1F17435A);

  static const double radius = 22;
  static const double smallRadius = 14;
  static const double buttonRadius = 22;
  static const double spacing = 16;
  static const double smallSpacing = 8;
  static const double largeSpacing = 24;
  static const double minButtonHeight = 56;
  static const double compactButtonHeight = 48;
  static const EdgeInsets screenPadding = EdgeInsets.all(24);
  static const EdgeInsets cardPadding = EdgeInsets.all(24);

  static const TextStyle screenTitleStyle = TextStyle(
    color: deepBlue,
    fontSize: 30,
    fontWeight: FontWeight.w900,
    height: 1.08,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    color: deepBlue,
    fontSize: 22,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle bodyStyle = TextStyle(
    color: deepBlue,
    fontSize: 18,
    height: 1.35,
  );

  static const TextStyle helperStyle = TextStyle(
    color: lockedBlue,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: softBlue,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme.copyWith(
        primary: softBlue,
        onPrimary: snowWhite,
        secondary: gentleGreen,
        tertiary: warmYellow,
        surface: palePanel,
      ),
      scaffoldBackgroundColor: frostBlue,
      fontFamily: 'Roboto',
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: frostBlue,
        foregroundColor: deepBlue,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: deepBlue,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: snowWhite,
        elevation: 4,
        shadowColor: softShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: softBlue,
          foregroundColor: snowWhite,
          minimumSize: const Size.fromHeight(minButtonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
    );
  }

  static const BoxDecoration snowyGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFE3F7FF), Color(0xFFFFFFFF)],
    ),
  );

  static const BoxDecoration nightSnowyGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFCDEFFF), Color(0xFFF9FDFF)],
    ),
  );
}
