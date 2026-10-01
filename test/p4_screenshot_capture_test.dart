import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titip_jalur/controllers/errand_feed_notifier.dart';
import 'package:titip_jalur/controllers/errand_form_notifier.dart';
import 'package:titip_jalur/models/errand_model.dart';
import 'package:titip_jalur/repositories/errand_repository.dart';
import 'package:titip_jalur/screens/create_errand_screen.dart';
import 'package:titip_jalur/screens/dashboard_screen.dart';
import 'font_loader_helper.dart';

class _MockFeedNotifier extends StateNotifier<AsyncValue<List<ErrandModel>>>
    implements ErrandFeedNotifier {
  _MockFeedNotifier(super.state);

  @override
  void addErrand(ErrandModel errand) {}

  @override
  Future<void> acceptErrand(String id) async {}

  @override
  Future<void> loadErrands(
      {bool forceError = false, bool forceEmpty = false}) async {}

  @override
  Future<void> retry() async {}
}

class _MockFormNotifier extends StateNotifier<ErrandFormState>
    implements ErrandFormNotifier {
  _MockFormNotifier(super.state);

  @override
  void setCategory(String val) {}

  @override
  void setDropoff(String val) {}

  @override
  void setItem(String val) {}

  @override
  void setPickup(String val) {}

  @override
  void setTip(String val) {}

  @override
  void reset() {}

  @override
  bool validate() => true;

  @override
  Future<bool> submit(
    ErrandRepository repository, {
    required String requesterName,
    bool simulateError = false,
  }) async =>
      true;
}

void main() {
  setUpAll(() async {
    await loadRealFonts();
  });
  group('P4 Widget Test Screenshot Capture', () {
    testWidgets('State 1: Initial Loading', (tester) async {
      tester.view.physicalSize = const Size(412, 915); // Standard modern phone size
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandFeedNotifierProvider.overrideWith(
              (ref) => _MockFeedNotifier(const AsyncValue.loading()),
            ),
          ],
          child: const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pump(); // Pump frame without pumpAndSettle due to spinner

      await expectLater(
        find.byType(DashboardScreen),
        matchesGoldenFile('../P4/screenshots/01_initial_loading.png'),
      );
    });

    testWidgets('State 2: Data Loaded', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final orders = [
        const ErrandModel(
          id: 'p4_01',
          item: 'Nasi Ayam Sambal Matah & Es Teh Manis',
          pickup: 'Kantin Pusat FTI Lt. 1',
          dropoff: 'Lab Riset Software Engineering R.302',
          tip: 6000,
          requester: 'Fahrel (FTI)',
          distanceKm: 0.5,
          category: 'Kantin',
        ),
        const ErrandModel(
          id: 'p4_02',
          item: 'Print Makalah 15 Lembar + Map Hijau',
          pickup: 'Fotokopi Gerbang Depan',
          dropoff: 'Gedung Dekanat Lt. 2',
          tip: 5000,
          requester: 'Dimas (FEB)',
          distanceKm: 0.8,
          category: 'ATK',
        ),
        const ErrandModel(
          id: 'p4_03',
          item: 'Kopi Susu Gula Aren Hangat',
          pickup: 'Kafe Pojok Perpus',
          dropoff: 'Ruang Baca Lt. 3',
          tip: 4000,
          requester: 'Sarah (Fasilkom)',
          distanceKm: 0.3,
          category: 'Kafe',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandFeedNotifierProvider.overrideWith(
              (ref) => _MockFeedNotifier(AsyncValue.data(orders)),
            ),
          ],
          child: const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(DashboardScreen),
        matchesGoldenFile('../P4/screenshots/02_data_loaded.png'),
      );
    });

    testWidgets('State 3: Empty State', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandFeedNotifierProvider.overrideWith(
              (ref) => _MockFeedNotifier(const AsyncValue.data([])),
            ),
          ],
          child: const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(DashboardScreen),
        matchesGoldenFile('../P4/screenshots/03_empty_state.png'),
      );
    });

    testWidgets('State 4: Error State with Retry Button', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandFeedNotifierProvider.overrideWith(
              (ref) => _MockFeedNotifier(
                AsyncValue.error(
                  Exception('Gagal menghubungi server titipan. Periksa koneksi internet Anda.'),
                  StackTrace.empty,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(DashboardScreen),
        matchesGoldenFile('../P4/screenshots/04_error_state_with_retry.png'),
      );
    });

    testWidgets('State 5: Form Input Validation Error', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandFormNotifierProvider.overrideWith(
              (ref) => _MockFormNotifier(
                const ErrandFormState(
                  item: 'AB',
                  pickup: '',
                  dropoff: '',
                  tip: '1000',
                  itemError: 'Nama barang minimal 3 karakter',
                  pickupError: 'Lokasi pengambilan wajib diisi',
                  dropoffError: 'Lokasi tujuan wajib diisi',
                  tipError: 'Nominal tip minimal Rp 2.000',
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: CreateErrandScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CreateErrandScreen),
        matchesGoldenFile('../P4/screenshots/05_form_input_validation.png'),
      );
    });

    testWidgets('State 6: Submit Loading (Anti-Double Tap)', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandFormNotifierProvider.overrideWith(
              (ref) => _MockFormNotifier(
                const ErrandFormState(
                  item: 'Nasi Padang Rendang + Es Jeruk',
                  pickup: 'Kantin Utama FMIPA',
                  dropoff: 'Lab RPL Gedung B R.204',
                  tip: '7000',
                  category: 'Kantin',
                  isSubmitting: true,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: CreateErrandScreen(),
          ),
        ),
      );
      await tester.pump(); // Pump single frame due to loading spinner

      await expectLater(
        find.byType(CreateErrandScreen),
        matchesGoldenFile('../P4/screenshots/06_submit_loading_antidoubletap.png'),
      );
    });
  });
}
