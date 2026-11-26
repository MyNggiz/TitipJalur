import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'services/auth_service.dart';

class TitipJalurApp extends StatelessWidget {
  const TitipJalurApp({super.key});

  static String resolveInitialRoute() {
    return AuthService.instance.isAuthenticated
        ? AppRoutes.home
        : AppRoutes.login;
  }

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = Color(0xFF059669);
    const scaffoldBg = Color(0xFFF8FAFC);

    return MaterialApp(
      title: 'TitipJalur',
      debugShowCheckedModeBanner: false,
      initialRoute: resolveInitialRoute(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryEmerald,
          primary: primaryEmerald,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: scaffoldBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
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
      ),
    );
  }
}
