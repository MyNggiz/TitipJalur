import 'dart:developer' as developer;

/// Emits fixed diagnostic events without exception messages or user data.
abstract final class RuntimeLog {
  static void startupStarted() => _event('startup_started');

  static void startupCompleted() => _event('startup_completed');

  static void startupFailed() => _event('startup_failed', level: 1000);

  static void flutterError() => _event('flutter_error', level: 1000);

  static void platformError() => _event('platform_async_error', level: 1000);

  static void _event(String event, {int level = 800}) {
    developer.log('{"event":"$event"}', name: 'titip_jalur.runtime', level: level);
  }
}
