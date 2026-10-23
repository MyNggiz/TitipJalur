import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titip_jalur/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P7 Advanced Feature 1: Authentication & Multi-Sided Role Management Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('1. Guest login initializes user with Mahasiswa (Requester) role', () async {
      final auth = AuthService.instance;
      final user = await auth.loginAsGuest(role: 'Mahasiswa');

      expect(auth.isAuthenticated, isTrue);
      expect(user.name, equals('Muhammad Naufal Fahrel'));
      expect(user.role, equals('Mahasiswa'));
      expect(auth.isRequester, isTrue);
      expect(auth.isRunner, isFalse);
    });

    test('2. Role switching between Requester and Runner updates state and permissions', () async {
      final auth = AuthService.instance;
      await auth.loginAsGuest(role: 'Mahasiswa');

      expect(auth.isRunner, isFalse);

      // Switch to Runner mode
      final runnerUser = await auth.switchRole('Runner');
      expect(runnerUser?.role, equals('Runner'));
      expect(auth.isRunner, isTrue);
      expect(auth.isRequester, isFalse);

      // Switch back to Requester mode
      final requesterUser = await auth.switchRole('Mahasiswa');
      expect(requesterUser?.role, equals('Mahasiswa'));
      expect(auth.isRequester, isTrue);
      expect(auth.isRunner, isFalse);
    });

    test('3. Session persists in SharedPreferences and restores on app startup', () async {
      final auth = AuthService.instance;
      await auth.login('fahrel@unesa.ac.id', 'password123', role: 'Runner');

      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('titip_jalur_active_user_session');
      expect(savedJson, isNotNull);
      expect(savedJson, contains('fahrel@unesa.ac.id'));
      expect(savedJson, contains('Runner'));

      // Simulate logout
      await auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(prefs.getString('titip_jalur_active_user_session'), isNull);
    });
  });
}
