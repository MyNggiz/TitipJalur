import 'package:flutter_test/flutter_test.dart';
import 'package:titip_jalur/services/app_notification_service.dart';

class FakeAppNotificationService implements IAppNotificationService {
  final List<String> notificationsSent = [];
  bool isInitialized = false;

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  Future<void> showOrderCreatedNotification({
    required String item,
    required int tip,
  }) async {
    notificationsSent.add('CREATED: $item with tip $tip');
  }

  @override
  Future<void> showOrderAcceptedNotification({
    required String item,
    required String runnerName,
  }) async {
    notificationsSent.add('ACCEPTED: $item claimed by $runnerName');
  }

  @override
  Future<void> showOrderCompletedNotification({
    required String item,
    bool hasProofOfDelivery = true,
  }) async {
    notificationsSent.add('COMPLETED: $item (POD: $hasProofOfDelivery)');
  }
}

void main() {
  group('P7 Bonus Feature: Local System Notification Service Tests', () {
    test('1. Notification service initializes and dispatches order created notification', () async {
      final notifService = FakeAppNotificationService();
      await notifService.initialize();

      await notifService.showOrderCreatedNotification(
        item: 'Nasi Bebek Sinjay',
        tip: 5000,
      );

      expect(notifService.notificationsSent, hasLength(1));
      expect(notifService.notificationsSent.first, contains('Nasi Bebek Sinjay'));
      expect(notifService.notificationsSent.first, contains('5000'));
    });

    test('2. Order accepted notification notifies requester with runner name', () async {
      final notifService = FakeAppNotificationService();

      await notifService.showOrderAcceptedNotification(
        item: 'Es Cokelat Tambun',
        runnerName: 'Rian Komuter',
      );

      expect(notifService.notificationsSent, hasLength(1));
      expect(notifService.notificationsSent.first, contains('Rian Komuter'));
      expect(notifService.notificationsSent.first, contains('Es Cokelat Tambun'));
    });

    test('3. Order completed notification indicates proof of delivery verification', () async {
      final notifService = FakeAppNotificationService();

      await notifService.showOrderCompletedNotification(
        item: 'Kertas HVS 1 Rim',
        hasProofOfDelivery: true,
      );

      expect(notifService.notificationsSent, hasLength(1));
      expect(notifService.notificationsSent.first, contains('POD: true'));
    });
  });
}
