import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titip_jalur/app.dart';
import 'package:titip_jalur/models/errand_model.dart';
import 'package:titip_jalur/routes/app_routes.dart';
import 'package:titip_jalur/screens/detail_screen.dart';
import 'package:titip_jalur/screens/profile_screen.dart';
import 'package:titip_jalur/widgets/app_text_field.dart';
import 'package:titip_jalur/widgets/errand_card.dart';
import 'package:titip_jalur/widgets/primary_button.dart';
import 'package:titip_jalur/widgets/state_view.dart';

void main() {
  group('Tugas P3: Prototype, Routing, and Reusable Widgets Tests', () {
    testWidgets('Renders LoginScreen on startup with logo, fields, and login buttons',
        (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TitipJalurApp()));
      await tester.pumpAndSettle();

      // Check branding
      expect(find.text('TitipJalur'), findsOneWidget);
      expect(find.textContaining('P2P Micro-Errand & Commuter Delivery'), findsOneWidget);

      // Check fields
      expect(find.text('Email Kampus'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);

      // Check action buttons
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Masuk sebagai Tamu Kampus (Demo P3)'), findsOneWidget);
    });

    testWidgets('Navigation from LoginScreen to DashboardScreen via guest button',
        (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TitipJalurApp()));
      await tester.pumpAndSettle();

      final guestBtn = find.text('Masuk sebagai Tamu Kampus (Demo P3)');
      await tester.ensureVisible(guestBtn);
      await tester.tap(guestBtn);
      await tester.pumpAndSettle();

      // Should arrive at Dashboard
      expect(find.textContaining('Halo,'), findsOneWidget);
      expect(find.textContaining('Radius Pengantaran:'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Kantin'), findsWidgets);
    });

    testWidgets('Navigation from DashboardScreen to DetailScreen with ErrandModel argument',
        (tester) async {
      final sampleErrand = ErrandModel(
        id: 'test_01',
        item: 'Ayam Geprek Sambal Matah',
        pickup: 'Kantin FTI',
        dropoff: 'Lab RPL Gedung B',
        tip: 6000,
        requester: 'Naufal',
        status: OrderStatus.open,
        distanceKm: 0.5,
        category: 'Kantin',
      );

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DetailScreen(errand: sampleErrand),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detail Permintaan Titipan'), findsOneWidget);
      expect(find.text('Ayam Geprek Sambal Matah'), findsOneWidget);
      expect(find.text('Kantin FTI'), findsOneWidget);
      expect(find.text('Lab RPL Gedung B'), findsOneWidget);
      expect(find.text('Rp 6.000'), findsOneWidget);
      expect(find.text('Bantu Teman (Ambil Titipan Ini)'), findsOneWidget);
    });

    testWidgets('Navigation to ProfileScreen displays user info and stats',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profil Komuter'), findsOneWidget);
      expect(find.text('Titipan Selesai'), findsOneWidget);
      expect(find.text('Tip Terkumpul'), findsOneWidget);
      expect(find.text('Keluar dari Akun'), findsOneWidget);
    });

    testWidgets('Reusable widgets: PrimaryButton, AppTextField, ErrandCard, and StateView',
        (tester) async {
      bool buttonPressed = false;
      final sampleErrand = ErrandModel(
        id: 'c1',
        item: 'Kopi Susu Dingin',
        pickup: 'Kantin Utama',
        dropoff: 'Perpustakaan Lt. 2',
        tip: 4000,
        requester: 'Fahrel',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Test Button',
                    onPressed: () => buttonPressed = true,
                  ),
                  const AppTextField(
                    label: 'Test Input',
                    hint: 'Enter text here',
                  ),
                  ErrandCard(
                    errand: sampleErrand,
                  ),
                  const EmptyStateView(
                    title: 'Kosong',
                    message: 'Tidak ada data',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Button'), findsOneWidget);
      await tester.tap(find.text('Test Button'));
      expect(buttonPressed, isTrue);

      expect(find.text('Test Input'), findsOneWidget);
      expect(find.text('Kopi Susu Dingin'), findsOneWidget);
      expect(find.text('Kosong'), findsOneWidget);
    });
  });
}
