import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/auth_service.dart';
import 'services/runtime_log.dart';

Future<void> main() async {
  final previousFlutterError = FlutterError.onError;
  FlutterError.onError = (details) {
    RuntimeLog.flutterError();
    previousFlutterError?.call(details);
  };

  final previousPlatformError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    RuntimeLog.platformError();
    return previousPlatformError?.call(error, stack) ?? false;
  };

  RuntimeLog.startupStarted();
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await AuthService.instance.restoreSession();
    runApp(
      const ProviderScope(
        child: TitipJalurApp(),
      ),
    );
    RuntimeLog.startupCompleted();
  } catch (_) {
    RuntimeLog.startupFailed();
    rethrow;
  }
}
