import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Abstract contract for local notification operations, enabling isolated unit testing.
abstract class IAppNotificationService {
  Future<void> initialize();

  Future<void> showOrderCreatedNotification({
    required String item,
    required int tip,
  });

  Future<void> showOrderAcceptedNotification({
    required String item,
    required String runnerName,
  });

  Future<void> showOrderCompletedNotification({
    required String item,
    bool hasProofOfDelivery = true,
  });
}

/// Production implementation of local notification service using [FlutterLocalNotificationsPlugin].
class AppNotificationService implements IAppNotificationService {
  AppNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  static const String _channelId = 'titip_jalur_orders_channel';
  static const String _channelName = 'Status TitipJalur';
  static const String _channelDescription = 'Pemberitahuan perubahan status pesanan titipan komuter';

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open');

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    try {
      await _plugin.initialize(settings: initSettings);
      _isInitialized = true;
    } catch (e) {
      debugPrint('[AppNotificationService] Plugin initialization notice: $e');
      _isInitialized = true; // Mark initialized to prevent repeated crashes
    }
  }

  NotificationDetails _buildNotificationDetails({
    required String title,
    required String body,
  }) {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      showWhen: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  @override
  Future<void> showOrderCreatedNotification({
    required String item,
    required int tip,
  }) async {
    await initialize();
    try {
      await _plugin.show(
        id: 101,
        title: 'Titipan Baru Dipublikasikan 🚀',
        body: 'Pesanan "$item" dengan imbalan tip Rp $tip siap diambil oleh komuter searah.',
        notificationDetails: _buildNotificationDetails(
          title: 'Titipan Baru Dipublikasikan',
          body: 'Pesanan "$item" siap diambil komuter.',
        ),
      );
    } catch (e) {
      debugPrint('[AppNotificationService] Notification display fallback: $e');
    }
  }

  @override
  Future<void> showOrderAcceptedNotification({
    required String item,
    required String runnerName,
  }) async {
    await initialize();
    try {
      await _plugin.show(
        id: 102,
        title: 'Titipan Anda Sedang Diantar! 🏃‍♂️',
        body: 'Komuter $runnerName telah mengklaim "$item" dan sedang bergerak menuju lokasi Anda.',
        notificationDetails: _buildNotificationDetails(
          title: 'Titipan Sedang Diantar',
          body: 'Komuter $runnerName sedang mengantar "$item".',
        ),
      );
    } catch (e) {
      debugPrint('[AppNotificationService] Notification display fallback: $e');
    }
  }

  @override
  Future<void> showOrderCompletedNotification({
    required String item,
    bool hasProofOfDelivery = true,
  }) async {
    await initialize();
    final podText = hasProofOfDelivery
        ? 'Bukti foto serah terima (Proof of Delivery) telah terverifikasi.'
        : 'Pesanan berhasil diserahkan.';
    try {
      await _plugin.show(
        id: 103,
        title: 'Titipan Selesai Diantar 🎉',
        body: 'Pesanan "$item" telah sampai. $podText',
        notificationDetails: _buildNotificationDetails(
          title: 'Titipan Selesai',
          body: 'Pesanan "$item" telah sampai di tujuan.',
        ),
      );
    } catch (e) {
      debugPrint('[AppNotificationService] Notification display fallback: $e');
    }
  }
}
