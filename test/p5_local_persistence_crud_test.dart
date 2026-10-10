import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titip_jalur/controllers/errand_feed_notifier.dart';
import 'package:titip_jalur/models/errand_model.dart';
import 'package:titip_jalur/repositories/errand_repository.dart';
import 'package:titip_jalur/services/errand_local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ErrandLocalStorageService storageService;
  late ErrandRepositoryImpl repository;

  setUp(() async {
    // Reset SharedPreferences mock sebelum setiap tes
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = ErrandLocalStorageService(prefs: prefs);
    repository = ErrandRepositoryImpl(localStorageService: storageService);
  });

  group('Tugas P5 MVP Fitur 1: Sistem Persistensi Lokal & CRUD Titipan', () {
    test('1. Read Initial: Memuat seed data awal dan menyimpannya secara otomatis ke local storage',
        () async {
      final errands = await repository.getErrands();

      // Memastikan data awal dimuat
      expect(errands.isNotEmpty, isTrue);
      expect(errands.length, greaterThanOrEqualTo(3));

      // Verifikasi bahwa data tersimpan di SharedPreferences
      final storedData = await storageService.loadErrands();
      expect(storedData.length, equals(errands.length));
      expect(storedData.first.item, equals(errands.first.item));
    });

    test('2. Create (C): Menambahkan pesanan baru dan memverifikasi persistensi ke local storage',
        () async {
      const newErrand = ErrandModel(
        id: 'p5_mvp_create_01',
        item: 'Nasi Kuning Komplit + Es Jeruk',
        pickup: 'Kantin Asrama Putra',
        dropoff: 'Gedung Perpustakaan Pusat Lt. 3',
        tip: 7000,
        requester: 'Naufal',
        status: OrderStatus.open,
        distanceKm: 0.6,
        category: 'Kantin',
      );

      final created = await repository.createErrand(newErrand);
      expect(created.id, equals('p5_mvp_create_01'));

      // Verifikasi di repository memory
      final currentList = await repository.getErrands();
      expect(currentList.first.id, equals('p5_mvp_create_01'));

      // Verifikasi di SharedPreferences (Data Persisten)
      final storedList = await storageService.loadErrands();
      expect(storedList.any((e) => e.id == 'p5_mvp_create_01'), isTrue);
      expect(storedList.first.item, equals('Nasi Kuning Komplit + Es Jeruk'));
    });

    test('3. Read (R) Persisten: Instansiasi repository baru tetap membaca data yang telah disimpan sebelumnya',
        () async {
      const persistedErrand = ErrandModel(
        id: 'p5_persist_check',
        item: 'Buku Catatan Algoritma & Pulpen Gel',
        pickup: 'Koperasi Mahasiswa',
        dropoff: 'Lab Robotika Gedung C',
        tip: 5000,
        requester: 'Dimas',
        status: OrderStatus.open,
      );

      // Simpan menggunakan repository pertama
      await repository.createErrand(persistedErrand);

      // Simulasikan app restart: buat repository baru dengan storage yang sama
      final reloadedRepo = ErrandRepositoryImpl(localStorageService: storageService);
      final reloadedErrands = await reloadedRepo.getErrands();

      // Bukti data tidak hilang saat restart (Data Persisten)
      expect(reloadedErrands.any((e) => e.id == 'p5_persist_check'), isTrue);
      final found = reloadedErrands.firstWhere((e) => e.id == 'p5_persist_check');
      expect(found.item, equals('Buku Catatan Algoritma & Pulpen Gel'));
      expect(found.tip, equals(5000));
    });

    test('4. Update (U): Mengubah status menjadi accepted dan completed secara persisten',
        () async {
      final initial = await repository.getErrands();
      final targetId = initial.first.id;

      // Update 1: Terima titipan (Accepted)
      final accepted = await repository.acceptErrand(targetId);
      expect(accepted.status, equals(OrderStatus.accepted));

      // Verifikasi perubahan di local storage
      var stored = await storageService.loadErrands();
      var storedItem = stored.firstWhere((e) => e.id == targetId);
      expect(storedItem.status, equals(OrderStatus.accepted));

      // Update 2: Selesaikan titipan (Completed)
      final completed = await repository.completeErrand(targetId);
      expect(completed.status, equals(OrderStatus.completed));

      // Verifikasi perubahan selesai di local storage
      stored = await storageService.loadErrands();
      storedItem = stored.firstWhere((e) => e.id == targetId);
      expect(storedItem.status, equals(OrderStatus.completed));
    });

    test('5. Delete (D): Menghapus/membatalkan titipan dan memverifikasi data terhapus dari local storage',
        () async {
      const deleteCandidate = ErrandModel(
        id: 'p5_to_delete_id',
        item: 'Kopi Kenangan Mantan Dingin',
        pickup: 'Kafe Dekanat',
        dropoff: 'Gazebo FTI',
        tip: 3000,
        requester: 'Naufal',
      );

      await repository.createErrand(deleteCandidate);

      // Pastikan ada sebelum dihapus
      var list = await repository.getErrands();
      expect(list.any((e) => e.id == 'p5_to_delete_id'), isTrue);

      // Eksekusi Delete
      await repository.deleteErrand('p5_to_delete_id');

      // Verifikasi di repository
      list = await repository.getErrands();
      expect(list.any((e) => e.id == 'p5_to_delete_id'), isFalse);

      // Verifikasi di local storage
      final stored = await storageService.loadErrands();
      expect(stored.any((e) => e.id == 'p5_to_delete_id'), isFalse);
    });

    test('6. ErrandFeedNotifier Reaktif: Memverifikasi integrasi StateNotifier dengan operasi CRUD persisten',
        () async {
      final notifier = ErrandFeedNotifier(repository);
      await Future<void>.delayed(const Duration(milliseconds: 350));

      // Initial state is data
      expect(notifier.state.hasValue, isTrue);

      // Create via notifier
      const notifierItem = ErrandModel(
        id: 'notifier_item_01',
        item: 'Roti Bakar Coklat Keju',
        pickup: 'Kantin FTI',
        dropoff: 'Ruang BEM',
        tip: 4000,
        requester: 'Fahrel',
      );
      await repository.createErrand(notifierItem);
      notifier.addErrand(notifierItem);

      expect(notifier.state.value!.first.id, equals('notifier_item_01'));

      // Accept via notifier
      await notifier.acceptErrand('notifier_item_01');
      expect(notifier.state.value!.first.status, equals(OrderStatus.accepted));

      // Complete via notifier
      await notifier.completeErrand('notifier_item_01');
      expect(notifier.state.value!.first.status, equals(OrderStatus.completed));

      // Delete via notifier
      await notifier.deleteErrand('notifier_item_01');
      expect(notifier.state.value!.any((e) => e.id == 'notifier_item_01'), isFalse);
    });
  });
}
