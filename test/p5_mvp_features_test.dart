import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titip_jalur/controllers/errand_feed_notifier.dart';
import 'package:titip_jalur/models/errand_model.dart';
import 'package:titip_jalur/repositories/errand_repository.dart';
import 'package:titip_jalur/screens/dashboard_screen.dart';
import 'package:titip_jalur/screens/detail_screen.dart';
import 'package:titip_jalur/screens/errand_orders_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleErrands = [
    const ErrandModel(
      id: 'errand_near_01',
      item: 'Ayam Geprek Sambal Bawang',
      pickup: 'Kantin FTI',
      dropoff: 'Lab RPL Gedung B',
      tip: 5000,
      requester: 'Naufal',
      status: OrderStatus.open,
      distanceKm: 0.4,
      category: 'Kantin',
    ),
    const ErrandModel(
      id: 'errand_mid_02',
      item: 'Print Makalah 15 Lembar + Jilid',
      pickup: 'Fotokopi Gerbang Depan',
      dropoff: 'Gedung Dekanat Lt. 1',
      tip: 6000,
      requester: 'Dimas',
      status: OrderStatus.open,
      distanceKm: 1.5,
      category: 'ATK',
    ),
    const ErrandModel(
      id: 'errand_far_03',
      item: 'Paket Vitamin & Obat Flu',
      pickup: 'Apotek Simpang Kampus',
      dropoff: 'Asrama Mahasiswa Putri',
      tip: 10000,
      requester: 'Fahrel',
      status: OrderStatus.open,
      distanceKm: 3.8,
      category: 'Obat',
    ),
  ];

  group('Tugas P5 MVP Fitur 2: Hyperlocal Radius Filter & Alur Transaksi Dua-Sisi', () {
    testWidgets('1. Radius Filter: Menampilkan hanya pesanan dalam radius jarak yang dipilih',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repository = ErrandRepositoryImpl(initialErrands: sampleErrands);
      final feedNotifier = ErrandFeedNotifier(repository);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandRepositoryProvider.overrideWithValue(repository),
            errandFeedNotifierProvider.overrideWith((ref) => feedNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardScreen(isEmbedded: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Secara default radius adalah 2.0 km -> errand_near (0.4 km) & errand_mid (1.5 km) terlihat
      expect(find.text('Ayam Geprek Sambal Bawang'), findsOneWidget);
      expect(find.text('Print Makalah 15 Lembar + Jilid'), findsOneWidget);
      // errand_far (3.8 km) tidak terlihat di radius default 2.0 km
      expect(find.text('Paket Vitamin & Obat Flu'), findsNothing);

      // Slider radius hadir di UI
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);
      expect(find.textContaining('Radius Pengantaran:'), findsOneWidget);
    });

    testWidgets('2. Category Filter: Memfilter titipan berdasarkan kategori Kantin dan ATK',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repository = ErrandRepositoryImpl(initialErrands: sampleErrands);
      final feedNotifier = ErrandFeedNotifier(repository);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandRepositoryProvider.overrideWithValue(repository),
            errandFeedNotifierProvider.overrideWith((ref) => feedNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardScreen(isEmbedded: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap filter chip "ATK"
      final atkChip = find.widgetWithText(FilterChip, 'ATK');
      expect(atkChip, findsOneWidget);
      await tester.tap(atkChip);
      await tester.pumpAndSettle();

      // Hanya ATK yang tampil
      expect(find.text('Print Makalah 15 Lembar + Jilid'), findsOneWidget);
      expect(find.text('Ayam Geprek Sambal Bawang'), findsNothing);
    });

    testWidgets('3. Two-Sided Workflow: Runner mengklaim order di DetailScreen dan status ter-update',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repository = ErrandRepositoryImpl(initialErrands: sampleErrands);
      final feedNotifier = ErrandFeedNotifier(repository);
      final targetErrand = sampleErrands.first;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandRepositoryProvider.overrideWithValue(repository),
            errandFeedNotifierProvider.overrideWith((ref) => feedNotifier),
          ],
          child: MaterialApp(
            home: DetailScreen(errand: targetErrand),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Awalnya status open -> tombol "Bantu Teman (Ambil Titipan Ini)" ada
      final claimBtn = find.text('Bantu Teman (Ambil Titipan Ini)');
      expect(claimBtn, findsOneWidget);

      // Scroll hingga terlihat lalu tekan
      await tester.ensureVisible(claimBtn);
      await tester.tap(claimBtn);
      await tester.pumpAndSettle();

      // SnackBar berhasil muncul
      expect(find.textContaining('Berhasil! Anda bersedia membantu'), findsOneWidget);

      // Tombol berubah menjadi "Titipan Sedang Berjalan (Anda Ambil)"
      expect(find.text('Titipan Sedang Berjalan (Anda Ambil)'), findsOneWidget);

      // Verifikasi di state bahwa status telah accepted
      final updatedInState = feedNotifier.state.value!.firstWhere((e) => e.id == targetErrand.id);
      expect(updatedInState.status, equals(OrderStatus.accepted));
    });

    testWidgets('4. Two-Sided Workflow: Runner menyelesaikan order di ErrandOrdersPage',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      const acceptedErrand = ErrandModel(
        id: 'task_accepted_01',
        item: 'Buku Komik One Piece & Pulpen',
        pickup: 'Koperasi FMIPA',
        dropoff: 'Gedung Rektorat Lt. 2',
        tip: 7000,
        requester: 'Dimas',
        status: OrderStatus.accepted,
      );

      final repository = ErrandRepositoryImpl(initialErrands: [acceptedErrand]);
      final feedNotifier = ErrandFeedNotifier(repository);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandRepositoryProvider.overrideWithValue(repository),
            errandFeedNotifierProvider.overrideWith((ref) => feedNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ErrandOrdersPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pindah ke tab Tugas Belanja / Antar
      final runnerTab = find.text('Tugas Belanja / Antar');
      expect(runnerTab, findsOneWidget);
      await tester.tap(runnerTab);
      await tester.pumpAndSettle();

      // Tombol "Selesaikan Tugas" terlihat
      final completeBtn = find.text('Selesaikan Tugas');
      expect(completeBtn, findsOneWidget);
      await tester.tap(completeBtn);
      await tester.pumpAndSettle();

      // Dialog konfirmasi penyelesaian tugas muncul
      expect(find.text('Selesaikan Tugas?'), findsOneWidget);
      await tester.tap(find.text('Ya, Selesaikan'));
      await tester.pumpAndSettle();

      // Verifikasi tugas berhasil diselesaikan
      expect(find.textContaining('berhasil diselesaikan!'), findsOneWidget);
      // Verifikasi di state bahwa status telah completed
      final updatedInState = feedNotifier.state.value!.firstWhere((e) => e.id == 'task_accepted_01');
      expect(updatedInState.status, equals(OrderStatus.completed));
    });

    testWidgets('5. Requester Workflow: Membatalkan pesanan titipan yang berstatus open di ErrandOrdersPage',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      const cancellableErrand = ErrandModel(
        id: 'cancel_me_01',
        item: 'Kopi Susu Dingin Gula Aren',
        pickup: 'Kafe Pojok FMIPA',
        dropoff: 'Lab RPL',
        tip: 4000,
        requester: 'Muhammad Naufal Fahrel',
        status: OrderStatus.open,
      );

      final repository = ErrandRepositoryImpl(initialErrands: [cancellableErrand]);
      final feedNotifier = ErrandFeedNotifier(repository);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandRepositoryProvider.overrideWithValue(repository),
            errandFeedNotifierProvider.overrideWith((ref) => feedNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ErrandOrdersPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Di tab Permintaan Saya, tombol batalkan terlihat untuk order open
      final cancelBtn = find.text('Batalkan Titipan Ini');
      expect(cancelBtn, findsOneWidget);
      await tester.ensureVisible(cancelBtn);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Dialog konfirmasi pembatalan muncul
      expect(find.text('Batalkan Pesanan Titipan?'), findsOneWidget);
      await tester.tap(find.text('Batalkan Titipan'));
      await tester.pumpAndSettle();

      // Pesanan terhapus
      expect(find.textContaining('berhasil dibatalkan.'), findsOneWidget);
      // Verifikasi di state bahwa titipan telah terhapus
      expect(feedNotifier.state.value!.any((e) => e.id == 'cancel_me_01'), isFalse);
    });
  });
}
