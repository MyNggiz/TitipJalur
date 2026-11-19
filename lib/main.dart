import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/runtime_log.dart';

void main() {
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
