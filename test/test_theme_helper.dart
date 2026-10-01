import 'package:flutter/material.dart';

ThemeData getTitipJalurTheme() {
  const primaryEmerald = Color(0xFF059669);
  const scaffoldBg = Color(0xFFF8FAFC);

  final baseTextTheme = Typography.material2021(platform: TargetPlatform.android).black.apply(
    fontFamily: 'Roboto',
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryEmerald,
      primary: primaryEmerald,
      surface: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: scaffoldBg,
    textTheme: baseTextTheme,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryEmerald,
      foregroundColor: Colors.white,
      extendedTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
      thickness: 1,
    ),
  );
}
