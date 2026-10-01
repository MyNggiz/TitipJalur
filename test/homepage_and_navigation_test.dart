import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titip_jalur/app.dart';
import 'package:titip_jalur/screens/account_settings_screen.dart';
import 'package:titip_jalur/screens/errand_orders_page.dart';
import 'package:titip_jalur/screens/homepage_screen.dart';
import 'package:titip_jalur/screens/main_shell_screen.dart';
import 'package:titip_jalur/widgets/interactive_bottom_nav.dart';

void main() {
  group('Homepage & Interactive Bottom Nav Multi-Page Tests', () {
    testWidgets('Guest login lands on HomepageScreen with tutorial and live stats',
        (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TitipJalurApp()));
      await tester.pumpAndSettle();

      // Tap guest login
      final guestBtn = find.text('Masuk sebagai Tamu Kampus (Demo P3)');
      await tester.ensureVisible(guestBtn);
      await tester.tap(guestBtn);
      await tester.pumpAndSettle();

      // Verify we are on Homepage
      expect(find.byType(HomepageScreen), findsOneWidget);
      expect(find.textContaining('Nol Emisi, Hemat Waktu'), findsOneWidget);
      expect(find.text('Cara Kerja TitipJalur'), findsOneWidget);
      expect(find.text('Ketik Pesanan Anda'), findsOneWidget);
      expect(find.text('Ringkasan Ekosistem Kampus'), findsOneWidget);
      expect(find.byType(InteractiveBottomNav), findsOneWidget);
    });

    testWidgets('InteractiveBottomNav switches between Home, Feed, Titipan, and Akun',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainShellScreen(initialIndex: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial tab: Home
      expect(find.byType(HomepageScreen), findsOneWidget);

      // Switch to Tab 1: Feed Rute
      await tester.tap(find.text('Feed Rute'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Radius Pengantaran:'), findsOneWidget);

      // Switch to Tab 2: Titipan
      await tester.tap(find.text('Titipan'));
      await tester.pumpAndSettle();
      expect(find.byType(ErrandOrdersPage), findsOneWidget);
      expect(find.text('Permintaan Saya'), findsOneWidget);
      expect(find.text('Tugas Belanja / Antar'), findsOneWidget);

      // Switch to Tab 3: Akun
      await tester.tap(find.text('Akun'));
      await tester.pumpAndSettle();
      expect(find.byType(AccountSettingsScreen), findsOneWidget);
      expect(find.text('Dompet Komuter Kampus'), findsOneWidget);
      expect(find.text('Preferensi Perjalanan & Layanan'), findsOneWidget);
      expect(find.text('Tarik Saldo'), findsOneWidget);
    });

    testWidgets('InteractiveBottomNav animations and button interaction',
        (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: InteractiveBottomNav(
              currentIndex: selected,
              onTap: (idx) => selected = idx,
              items: const [
                NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
                NavItem(icon: Icons.list_outlined, activeIcon: Icons.list, label: 'Feed'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveBottomNav), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Feed'), findsOneWidget);

      // Tap second item
      await tester.tap(find.text('Feed'));
      await tester.pumpAndSettle();
      expect(selected, equals(1));
    });
  });
}
