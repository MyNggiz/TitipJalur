import 'package:flutter/material.dart';
import '../models/errand_model.dart';
import '../screens/detail_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/create_errand_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/';
  static const String loginPath = '/login';
  static const String dashboard = '/dashboard';
  static const String home = '/home';
  static const String orders = '/orders';
  static const String accountSettings = '/settings';
  static const String detail = '/detail';
  static const String profile = '/profile';
  static const String createErrand = '/create-errand';

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
          builder: (_) => const MainShellScreen(initialIndex: 1),
          settings: settings,
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => const MainShellScreen(initialIndex: 0),
          settings: settings,
        );
      case orders:
        return MaterialPageRoute(
          builder: (_) => const MainShellScreen(initialIndex: 2),
          settings: settings,
        );
      case accountSettings:
        return MaterialPageRoute(
          builder: (_) => const MainShellScreen(initialIndex: 3),
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
      case createErrand:
        return MaterialPageRoute(
          builder: (_) => const CreateErrandScreen(),
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
