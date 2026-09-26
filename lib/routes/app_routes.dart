import 'package:flutter/material.dart';
import '../models/errand_model.dart';
import '../screens/dashboard_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/';
  static const String loginPath = '/login';
  static const String dashboard = '/dashboard';
  static const String detail = '/detail';
  static const String profile = '/profile';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
      case loginPath:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
      case detail:
        ErrandModel? errand;
        if (settings.arguments is ErrandModel) {
          errand = settings.arguments as ErrandModel;
        } else if (settings.arguments is Map<String, dynamic>) {
          errand = ErrandModel.fromMap(settings.arguments as Map<String, dynamic>);
        }
        return MaterialPageRoute(
          builder: (_) => DetailScreen(errand: errand),
          settings: settings,
        );
      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
    }
  }
}
