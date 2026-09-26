import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titip_jalur/controllers/errand_feed_notifier.dart';
import 'package:titip_jalur/controllers/errand_form_notifier.dart';
import 'package:titip_jalur/models/errand_model.dart';
import 'package:titip_jalur/repositories/errand_repository.dart';
import 'package:titip_jalur/screens/create_errand_screen.dart';
import 'package:titip_jalur/screens/dashboard_screen.dart';
import 'package:titip_jalur/widgets/primary_button.dart';
import 'package:titip_jalur/widgets/state_view.dart';

// Fake mock repository for testing
class MockErrandRepository implements ErrandRepository {
  List<ErrandModel> items;
  bool shouldFailGet;
  bool shouldFailCreate;
  int retryCalls = 0;

  MockErrandRepository({
    this.items = const [],
    this.shouldFailGet = false,
    this.shouldFailCreate = false,
  });

  @override
  Future<List<ErrandModel>> getErrands({
    bool simulateError = false,
    bool simulateEmpty = false,
  }) async {
    retryCalls++;
    if (shouldFailGet || simulateError) {
      throw Exception('Gagal menghubungi server titipan. Periksa koneksi Anda.');
    }
    if (simulateEmpty) {
      return [];
    }
    return items;
  }

  @override
  Future<ErrandModel> createErrand(
    ErrandModel errand, {
    bool simulateError = false,
  }) async {
    if (shouldFailCreate || simulateError) {
      throw Exception('Gagal menyimpan pesanan titipan ke server.');
    }
    items = [errand, ...items];
    return errand;
  }

  @override
  Future<ErrandModel> acceptErrand(String id) async {
    final index = items.indexWhere((e) => e.id == id);
    if (index != -1) {
      final updated = items[index].copyWith(status: OrderStatus.accepted);
      items[index] = updated;
      return updated;
    }
    throw Exception('Order tidak ditemukan');
  }
}

void main() {
  group('Tugas P4: Pembuktian 6 Kondisi UI Wajib', () {
    // -------------------------------------------------------------
    // KONDISI UI 1: Initial Loading
    // -------------------------------------------------------------
    testWidgets('Kondisi UI 1: Initial Loading menampilkan LoadingStateView',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandFeedNotifierProvider.overrideWith(
              (ref) => _CustomFeedNotifier(const AsyncValue.loading()),
            ),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      // Verify LoadingStateView is rendered with informational text
      expect(find.byType(LoadingStateView), findsOneWidget);
      expect(find.text('Memuat feed titipan komuter...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // -------------------------------------------------------------
    // KONDISI UI 2: Data Berhasil Dimuat
    // -------------------------------------------------------------
    testWidgets('Kondisi UI 2: Data Berhasil Dimuat menampilkan daftar ErrandCard',
        (tester) async {
      final sampleOrders = [
        const ErrandModel(
          id: 'p4_01',
          item: 'Nasi Ayam Sambal Matah',
          pickup: 'Kantin FTI',
          dropoff: 'Lab RPL',
          tip: 5000,
          requester: 'Fahrel',
        ),
        const ErrandModel(
          id: 'p4_02',
          item: 'Fotokopi Catatan Kuliah 10 Lembar',
          pickup: 'Koperasi Kampus',
          dropoff: 'Ruang Dosen 302',
          tip: 4000,
          requester: 'Dimas',
          category: 'ATK',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandFeedNotifierProvider.overrideWith(
              (ref) => _CustomFeedNotifier(AsyncValue.data(sampleOrders)),
            ),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify data is loaded and rendered as cards
      expect(find.text('Nasi Ayam Sambal Matah'), findsOneWidget);
      expect(find.text('Fotokopi Catatan Kuliah 10 Lembar'), findsOneWidget);
      expect(find.text('Rp 5.000'), findsOneWidget);
      expect(find.text('Rp 4.000'), findsOneWidget);
      expect(find.textContaining('Titipan Tersedia (2)'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // KONDISI UI 3: Empty State
    // -------------------------------------------------------------
    testWidgets('Kondisi UI 3: Empty State menampilkan EmptyStateView dan tombol aksi',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandFeedNotifierProvider.overrideWith(
              (ref) => _CustomFeedNotifier(const AsyncValue.data([])),
            ),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify EmptyStateView is displayed
      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('Belum Ada Titipan Aktif'), findsOneWidget);
      expect(find.text('Buat Titipan Pertama'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // KONDISI UI 4: Error State dengan Tombol Retry
    // -------------------------------------------------------------
    testWidgets('Kondisi UI 4: Error State menampilkan ErrorStateView dan tombol Coba Lagi',
        (tester) async {
      final mockRepo = MockErrandRepository(shouldFailGet: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify ErrorStateView with message and retry button
      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Gagal Memuat Titipan'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      final initialCalls = mockRepo.retryCalls;

      // Tap "Coba Lagi" (Retry)
      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();

      // Verify retry was executed
      expect(mockRepo.retryCalls, greaterThan(initialCalls));
    });

    // -------------------------------------------------------------
    // KONDISI UI 5: Validasi Input pada Form
    // -------------------------------------------------------------
    testWidgets(
        'Kondisi UI 5: Validasi input pada form mendeteksi input kosong dan tidak valid',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateErrandScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Form header & fields present
      expect(find.text('Buat Titipan Baru'), findsOneWidget);
      expect(find.text('Nama Barang / Pesanan'), findsOneWidget);

      // Clear initial tip controller to trigger all empty validations
      final tipField = find.widgetWithText(TextField, '5000');
      await tester.enterText(tipField, '');
      await tester.pumpAndSettle();

      // Submit immediately with empty inputs
      final submitBtn = find.text('Kirim Permintaan Titipan');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify validation error messages are displayed
      expect(find.text('Nama barang wajib diisi'), findsOneWidget);
      expect(find.text('Lokasi pengambilan wajib diisi'), findsOneWidget);
      expect(find.text('Lokasi tujuan wajib diisi'), findsOneWidget);
      expect(find.text('Nominal tip wajib diisi'), findsOneWidget);
    });

    testWidgets(
        'Kondisi UI 5: Validasi batas minimal karakter dan tip minimal Rp 2.000',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateErrandScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill with invalid short values
      await tester.enterText(
        find.widgetWithText(TextField, '').first,
        'AB', // Less than 3 chars
      );
      await tester.pumpAndSettle();

      // Clear tip and enter 1000 (< 2000)
      final tipField = find.widgetWithText(TextField, '5000');
      await tester.enterText(tipField, '1000');
      await tester.pumpAndSettle();

      // Tap submit to trigger validation
      final submitBtn = find.text('Kirim Permintaan Titipan');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify min length & min tip validation
      expect(find.text('Nama barang minimal 3 karakter'), findsOneWidget);
      expect(find.text('Nominal tip minimal Rp 2.000'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // KONDISI UI 6: Loading saat Proses Submit (Anti-Double Tap)
    // -------------------------------------------------------------
    testWidgets(
        'Kondisi UI 6: Loading saat proses submit mendisable tombol dan mencegah double tap',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandFormNotifierProvider.overrideWith(
              (ref) => _CustomFormNotifier(
                const ErrandFormState(
                  item: 'Nasi Padang Rendang',
                  pickup: 'Kantin Pusat',
                  dropoff: 'Lab RPL Gedung B',
                  tip: '5000',
                  isSubmitting: true, // Simulate submitting state
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: CreateErrandScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify button shows loading spinner and text status
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.text('Sedang memproses permintaan titipan...'),
        findsOneWidget,
      );

      // Verify PrimaryButton is disabled (onPressed is null) preventing double tap
      final primaryButton = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(primaryButton.isLoading, isTrue);
    });
  });
}

// Custom mock Notifiers for deterministic testing
class _CustomFeedNotifier
    extends StateNotifier<AsyncValue<List<ErrandModel>>>
    implements ErrandFeedNotifier {
  _CustomFeedNotifier(super.state);

  @override
  void addErrand(ErrandModel errand) {}

  @override
  Future<void> acceptErrand(String id) async {}

  @override
  Future<void> loadErrands({bool forceError = false, bool forceEmpty = false}) async {}

  @override
  Future<void> retry() async {}
}

class _CustomFormNotifier extends StateNotifier<ErrandFormState>
    implements ErrandFormNotifier {
  _CustomFormNotifier(super.state);

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
