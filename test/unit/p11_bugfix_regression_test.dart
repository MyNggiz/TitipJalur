import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titip_jalur/app.dart';
import 'package:titip_jalur/models/errand_model.dart';
import 'package:titip_jalur/models/user_model.dart';
import 'package:titip_jalur/repositories/errand_repository.dart';
import 'package:titip_jalur/routes/app_routes.dart';
import 'package:titip_jalur/screens/errand_orders_page.dart';
import 'package:titip_jalur/services/auth_service.dart';
import 'package:titip_jalur/services/errand_local_storage_service.dart';
import 'package:titip_jalur/providers/errand_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P11 Bug #1 Regression: Session Restoration on Startup', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AuthService.instance.logout();
    });

    test('1.1 restoreSession() returns null when no session is saved', () async {
      final user = await AuthService.instance.restoreSession(force: true);
      expect(user, isNull);
      expect(AuthService.instance.isAuthenticated, isFalse);
    });

    test('1.2 loginAsGuest() persists session and restoreSession(force: true) recovers it', () async {
      await AuthService.instance.loginAsGuest(role: 'Mahasiswa');
      AuthService.instance.resetForTest();
      expect(AuthService.instance.currentUser, isNull);

      final restored = await AuthService.instance.restoreSession(force: true);
      expect(restored, isNotNull);
      expect(restored!.isGuest, isTrue);
      expect(restored.role, equals('Mahasiswa'));
      expect(AuthService.instance.isAuthenticated, isTrue);
    });

    test('1.3 login() persists user email and role across simulated restart', () async {
      await AuthService.instance.login('budi@kampus.ac.id', 'secret123', role: 'Runner');
      AuthService.instance.resetForTest();

      final restored = await AuthService.instance.restoreSession(force: true);
      expect(restored, isNotNull);
      expect(restored!.email, equals('budi@kampus.ac.id'));
      expect(restored.role, equals('Runner'));
      expect(AuthService.instance.isRunner, isTrue);
    });

    test('1.4 switchRole() persists updated role across simulated restart', () async {
      await AuthService.instance.loginAsGuest(role: 'Mahasiswa');
      await AuthService.instance.switchRole('Runner');
      AuthService.instance.resetForTest();

      final restored = await AuthService.instance.restoreSession(force: true);
      expect(restored, isNotNull);
      expect(restored!.role, equals('Runner'));
    });

    test('1.5 logout() removes persisted session so restoreSession returns null', () async {
      await AuthService.instance.loginAsGuest();
      await AuthService.instance.logout();
      AuthService.instance.resetForTest();

      final restored = await AuthService.instance.restoreSession(force: true);
      expect(restored, isNull);
      expect(AuthService.instance.isAuthenticated, isFalse);
    });

    test('1.6 restoreSession() handles corrupted JSON gracefully without throwing', () async {
      SharedPreferences.setMockInitialValues({
        'titip_jalur_active_user_session': '{corrupted-json',
      });
      AuthService.instance.resetForTest();

      final restored = await AuthService.instance.restoreSession(force: true);
      expect(restored, isNull);
      expect(AuthService.instance.isAuthenticated, isFalse);
    });

    test('1.7 restoreSession() handles empty string session gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'titip_jalur_active_user_session': '',
      });
      AuthService.instance.resetForTest();

      final restored = await AuthService.instance.restoreSession(force: true);
      expect(restored, isNull);
    });

    test('1.8 TitipJalurApp resolves initialRoute to login when unauthenticated', () async {
      await AuthService.instance.logout();
      expect(TitipJalurApp.resolveInitialRoute(), equals(AppRoutes.login));
    });

    test('1.9 TitipJalurApp resolves initialRoute to home when session is restored', () async {
      await AuthService.instance.loginAsGuest();
      expect(TitipJalurApp.resolveInitialRoute(), equals(AppRoutes.home));
    });

    test('1.10 setCurrentUser() persists custom UserModel across restart', () async {
      const customUser = UserModel(
        id: 'usr_custom_99',
        name: 'Siti Aminah',
        email: 'siti@kampus.ac.id',
        role: 'Mahasiswa',
      );
      await AuthService.instance.setCurrentUser(customUser);
      AuthService.instance.resetForTest();

      final restored = await AuthService.instance.restoreSession(force: true);
      expect(restored?.id, equals('usr_custom_99'));
      expect(restored?.name, equals('Siti Aminah'));
    });

    test('1.11 isRequester is true when restored role is Mahasiswa', () async {
      await AuthService.instance.loginAsGuest(role: 'Mahasiswa');
      AuthService.instance.resetForTest();
      await AuthService.instance.restoreSession(force: true);
      expect(AuthService.instance.isRequester, isTrue);
      expect(AuthService.instance.isRunner, isFalse);
    });

    test('1.12 isRunner is true when restored role is Komuter', () async {
      await AuthService.instance.loginAsGuest(role: 'Komuter');
      AuthService.instance.resetForTest();
      await AuthService.instance.restoreSession(force: true);
      expect(AuthService.instance.isRunner, isTrue);
      expect(AuthService.instance.isRequester, isFalse);
    });
  });

  group('P11 Bug #2 Regression: Empty Errand List Persistence Across Restarts', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('2.1 Saving empty list and reloading via new ErrandRepositoryImpl keeps list empty', () async {
      final storage1 = ErrandLocalStorageService();
      await storage1.saveErrands([]);

      final repoAfterRestart = ErrandRepositoryImpl(localStorageService: ErrandLocalStorageService());
      final loaded = await repoAfterRestart.getErrands();

      expect(loaded, isEmpty);
    });

    test('2.2 Deleting all errands persists empty state across repository restart', () async {
      const onlyOrder = ErrandModel(
        id: 'err_only_1',
        item: 'Teh Botol',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 2000,
        requester: 'Rina',
      );
      final storage = ErrandLocalStorageService();
      await storage.saveErrands([onlyOrder]);

      final repo1 = ErrandRepositoryImpl(localStorageService: storage);
      final initial = await repo1.getErrands();
      expect(initial, hasLength(1));

      await repo1.deleteErrand('err_only_1');

      final repo2 = ErrandRepositoryImpl(localStorageService: ErrandLocalStorageService());
      final afterRestart = await repo2.getErrands();
      expect(afterRestart, isEmpty);
    });

    test('2.3 loadErrands() returns empty list when storage explicitly holds "[]"', () async {
      SharedPreferences.setMockInitialValues({
        ErrandLocalStorageService.storageKey: '[]',
      });
      final storage = ErrandLocalStorageService();
      final loaded = await storage.loadErrands();
      expect(loaded, isEmpty);
    });

    test('2.4 loadErrands() seeds initial errands only when storage key is absent', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = ErrandLocalStorageService();
      final loaded = await storage.loadErrands();
      expect(loaded, isNotEmpty);
    });

    test('2.5 Second getErrands() call on same repository does not re-seed mock data', () async {
      final storage = ErrandLocalStorageService();
      await storage.saveErrands([]);

      final repo = ErrandRepositoryImpl(localStorageService: storage);
      expect(await repo.getErrands(), isEmpty);
      expect(await repo.getErrands(), isEmpty);
    });

    test('2.6 Creating an errand after empty state persists only that errand across restart', () async {
      final storage = ErrandLocalStorageService();
      await storage.saveErrands([]);

      final repo1 = ErrandRepositoryImpl(localStorageService: storage);
      expect(await repo1.getErrands(), isEmpty);

      await repo1.createErrand(
        const ErrandModel(
          id: 'err_new_1',
          item: 'Roti Bakar',
          pickup: 'Kantin',
          dropoff: 'Perpus',
          tip: 3000,
          requester: 'Andi',
        ),
      );

      final repo2 = ErrandRepositoryImpl(localStorageService: ErrandLocalStorageService());
      final reloaded = await repo2.getErrands();
      expect(reloaded, hasLength(1));
      expect(reloaded.first.id, equals('err_new_1'));
    });

    test('2.7 ErrandRepositoryImpl with simulateEmpty returns empty without overwriting storage', () async {
      const order = ErrandModel(
        id: 'err_keep_1',
        item: 'Air Mineral',
        pickup: 'Kantin',
        dropoff: 'Kelas',
        tip: 2000,
        requester: 'Dina',
      );
      final storage = ErrandLocalStorageService();
      await storage.saveErrands([order]);

      final repo = ErrandRepositoryImpl(localStorageService: storage);
      expect(await repo.getErrands(simulateEmpty: true), isEmpty);
      expect(await repo.getErrands(), hasLength(1));
    });

    test('2.8 Deleting non-existent ID does not alter persisted empty list', () async {
      final storage = ErrandLocalStorageService();
      await storage.saveErrands([]);
      final repo = ErrandRepositoryImpl(localStorageService: storage);
      await repo.getErrands();
      await repo.deleteErrand('non_existent');
      expect(await repo.getErrands(), isEmpty);
    });

    test('2.9 Repository initialized with empty initialErrands respects empty local storage', () async {
      final storage = ErrandLocalStorageService();
      await storage.saveErrands([]);
      final repo = ErrandRepositoryImpl(initialErrands: [], localStorageService: storage);
      expect(await repo.getErrands(), isEmpty);
    });

    test('2.10 Repository initialized without initialErrands still respects empty local storage', () async {
      SharedPreferences.setMockInitialValues({
        ErrandLocalStorageService.storageKey: '[]',
      });
      final repo = ErrandRepositoryImpl(localStorageService: ErrandLocalStorageService());
      expect(await repo.getErrands(), isEmpty);
    });

    test('2.11 saveErrands([]) followed by loadErrands() does not return mock data', () async {
      final storage = ErrandLocalStorageService();
      await storage.saveErrands([]);
      final loaded = await storage.loadErrands();
      expect(loaded, isEmpty);
    });

    test('2.12 clear() resets storage key so subsequent loadErrands() re-seeds defaults', () async {
      final storage = ErrandLocalStorageService();
      await storage.saveErrands([]);
      expect(await storage.loadErrands(), isEmpty);
      await storage.clear();
      expect(await storage.loadErrands(), isNotEmpty);
    });
  });

  group('P11 Bug #3 Regression: Local Storage Failure Propagation', () {
    test('3.1 saveErrands() throws LocalStorageException when SharedPreferences is unavailable', () async {
      final failingStorage = ErrandLocalStorageService(
        prefsProvider: () async => null,
      );

      await expectLater(
        failingStorage.saveErrands([]),
        throwsA(isA<LocalStorageException>()),
      );
    });

    test('3.2 saveErrands() throws LocalStorageException when prefsProvider throws', () async {
      final failingStorage = ErrandLocalStorageService(
        prefsProvider: () async => throw Exception('Disk full'),
      );

      await expectLater(
        failingStorage.saveErrands([]),
        throwsA(isA<LocalStorageException>()),
      );
    });

    test('3.3 clear() throws LocalStorageException when SharedPreferences is unavailable', () async {
      final failingStorage = ErrandLocalStorageService(
        prefsProvider: () async => null,
      );

      await expectLater(
        failingStorage.clear(),
        throwsA(isA<LocalStorageException>()),
      );
    });

    test('3.4 ErrandRepositoryImpl.createErrand() surfaces LocalStorageException on save failure', () async {
      final failingStorage = ErrandLocalStorageService(
        prefsProvider: () async => null,
      );
      final repo = ErrandRepositoryImpl(localStorageService: failingStorage);

      const order = ErrandModel(
        id: 'err_fail_save_1',
        item: 'Nasi Goreng',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 5000,
        requester: 'Budi',
      );

      await expectLater(
        repo.createErrand(order),
        throwsA(isA<LocalStorageException>()),
      );
    });

    test('3.5 ErrandRepositoryImpl.acceptErrand() surfaces LocalStorageException on save failure', () async {
      final failingStorage = ErrandLocalStorageService(
        prefsProvider: () async => null,
      );
      const order = ErrandModel(
        id: 'err_fail_accept_1',
        item: 'Es Jeruk',
        pickup: 'Kantin',
        dropoff: 'Perpus',
        tip: 3000,
        requester: 'Ani',
      );
      final repo = ErrandRepositoryImpl(
        initialErrands: [order],
        localStorageService: failingStorage,
      );

      await expectLater(
        repo.acceptErrand('err_fail_accept_1', runnerName: 'Budi'),
        throwsA(isA<LocalStorageException>()),
      );
    });

    test('3.6 ErrandRepositoryImpl.completeErrand() surfaces LocalStorageException on save failure', () async {
      final failingStorage = ErrandLocalStorageService(
        prefsProvider: () async => null,
      );
      const order = ErrandModel(
        id: 'err_fail_complete_1',
        item: 'Kopi Hitam',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 3000,
        requester: 'Ani',
        status: OrderStatus.accepted,
      );
      final repo = ErrandRepositoryImpl(
        initialErrands: [order],
        localStorageService: failingStorage,
      );

      await expectLater(
        repo.completeErrand('err_fail_complete_1'),
        throwsA(isA<LocalStorageException>()),
      );
    });

    test('3.7 ErrandRepositoryImpl.deleteErrand() surfaces LocalStorageException on save failure', () async {
      final failingStorage = ErrandLocalStorageService(
        prefsProvider: () async => null,
      );
      const order = ErrandModel(
        id: 'err_fail_del_1',
        item: 'Bakso',
        pickup: 'Kantin',
        dropoff: 'Kelas',
        tip: 4000,
        requester: 'Ani',
      );
      final repo = ErrandRepositoryImpl(
        initialErrands: [order],
        localStorageService: failingStorage,
      );

      await expectLater(
        repo.deleteErrand('err_fail_del_1'),
        throwsA(isA<LocalStorageException>()),
      );
    });

    test('3.8 LocalStorageException has descriptive Indonesian message', () {
      const ex = LocalStorageException('Penyimpanan lokal tidak tersedia');
      expect(ex.toString(), contains('Penyimpanan lokal tidak tersedia'));
    });

    test('3.9 createErrand() rolls back in-memory list if saveErrands() throws', () async {
      final failingStorage = ErrandLocalStorageService(
        prefsProvider: () async => null,
      );
      final repo = ErrandRepositoryImpl(
        initialErrands: [],
        localStorageService: failingStorage,
      );

      const order = ErrandModel(
        id: 'err_rollback_1',
        item: 'Mie Ayam',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 4000,
        requester: 'Budi',
      );

      await expectLater(repo.createErrand(order), throwsA(isA<LocalStorageException>()));
      final items = await repo.getErrands();
      expect(items.any((e) => e.id == 'err_rollback_1'), isFalse);
    });

    test('3.10 acceptErrand() rolls back in-memory status if saveErrands() throws', () async {
      final failingStorage = ErrandLocalStorageService(
        prefsProvider: () async => null,
      );
      const order = ErrandModel(
        id: 'err_rollback_accept_1',
        item: 'Sate',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 5000,
        requester: 'Ani',
      );
      final repo = ErrandRepositoryImpl(
        initialErrands: [order],
        localStorageService: failingStorage,
      );

      await expectLater(
        repo.acceptErrand('err_rollback_accept_1', runnerName: 'Budi'),
        throwsA(isA<LocalStorageException>()),
      );
      final items = await repo.getErrands();
      expect(items.first.status, equals(OrderStatus.open));
    });

    test('3.11 saveErrands() succeeds normally when SharedPreferences is available', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = ErrandLocalStorageService();
      await expectLater(storage.saveErrands([]), completes);
    });

    test('3.12 LocalStorageException implements Exception', () {
      const ex = LocalStorageException('error');
      expect(ex, isA<Exception>());
    });
  });

  group('P11 Bug #4 Regression: Permintaan Saya Strict Ownership Filter', () {
    test('4.1 Excludes another user order whose ID ends with "1"', () {
      const otherOrderEnding1 = ErrandModel(
        id: 'order_001',
        item: 'Milik Orang Lain 1',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 3000,
        requester: 'Siti',
      );
      final result = ErrandOrdersPage.filterMyRequests(
        [otherOrderEnding1],
        currentUserName: 'Budi',
      );
      expect(result, isEmpty);
    });

    test('4.2 Excludes another user order whose ID ends with "3"', () {
      const otherOrderEnding3 = ErrandModel(
        id: 'order_003',
        item: 'Milik Orang Lain 3',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 3000,
        requester: 'Dewi',
      );
      final result = ErrandOrdersPage.filterMyRequests(
        [otherOrderEnding3],
        currentUserName: 'Budi',
      );
      expect(result, isEmpty);
    });

    test('4.3 Excludes another user whose name contains "naufal" when active user is Budi', () {
      const otherNaufal = ErrandModel(
        id: 'order_naufal',
        item: 'Kopi Naufal',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 3000,
        requester: 'Naufal Pratama',
      );
      final result = ErrandOrdersPage.filterMyRequests(
        [otherNaufal],
        currentUserName: 'Budi',
      );
      expect(result, isEmpty);
    });

    test('4.4 Excludes another user whose name contains "saya" (e.g. "Sayangku")', () {
      const otherSaya = ErrandModel(
        id: 'order_saya',
        item: 'Snack',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 3000,
        requester: 'Sayangku',
      );
      final result = ErrandOrdersPage.filterMyRequests(
        [otherSaya],
        currentUserName: 'Budi',
      );
      expect(result, isEmpty);
    });

    test('4.5 Includes order with exact case-insensitive requester name match', () {
      const myOrder = ErrandModel(
        id: 'order_budi_9',
        item: 'Air Putih',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 2000,
        requester: '  budi  ',
      );
      final result = ErrandOrdersPage.filterMyRequests(
        [myOrder],
        currentUserName: 'Budi',
      );
      expect(result, hasLength(1));
    });

    test('4.6 Matches by requesterId when both requesterId and currentUserId are provided', () {
      const myOrder = ErrandModel(
        id: 'order_id_match',
        item: 'Pulpen',
        pickup: 'Koperasi',
        dropoff: 'Kelas',
        tip: 2000,
        requester: 'Budi A',
        requesterId: 'usr_123',
      );
      const sameNameOtherUser = ErrandModel(
        id: 'order_id_mismatch',
        item: 'Pensil',
        pickup: 'Koperasi',
        dropoff: 'Kelas',
        tip: 2000,
        requester: 'Budi',
        requesterId: 'usr_999',
      );
      final result = ErrandOrdersPage.filterMyRequests(
        [myOrder, sameNameOtherUser],
        currentUserName: 'Budi',
        currentUserId: 'usr_123',
      );
      expect(result, hasLength(1));
      expect(result.first.id, equals('order_id_match'));
    });

    test('4.7 Excludes empty requester name when currentUserName is non-empty', () {
      const emptyReq = ErrandModel(
        id: 'order_empty_req',
        item: 'Item',
        pickup: 'A',
        dropoff: 'B',
        tip: 2000,
        requester: '',
      );
      final result = ErrandOrdersPage.filterMyRequests(
        [emptyReq],
        currentUserName: 'Budi',
      );
      expect(result, isEmpty);
    });

    test('4.8 Preserves all statuses (open, accepted, completed) for own orders', () {
      const orders = [
        ErrandModel(id: '1', item: 'A', pickup: 'P', dropoff: 'D', tip: 2000, requester: 'Budi', status: OrderStatus.open),
        ErrandModel(id: '2', item: 'B', pickup: 'P', dropoff: 'D', tip: 2000, requester: 'Budi', status: OrderStatus.accepted),
        ErrandModel(id: '3', item: 'C', pickup: 'P', dropoff: 'D', tip: 2000, requester: 'Budi', status: OrderStatus.completed),
      ];
      final result = ErrandOrdersPage.filterMyRequests(orders, currentUserName: 'Budi');
      expect(result, hasLength(3));
    });

    test('4.9 Does not match partial substring of currentUserName', () {
      const partial = ErrandModel(
        id: 'order_partial',
        item: 'Item',
        pickup: 'P',
        dropoff: 'D',
        tip: 2000,
        requester: 'Budiman',
      );
      final result = ErrandOrdersPage.filterMyRequests([partial], currentUserName: 'Budi');
      expect(result, isEmpty);
    });

    test('4.10 Handles empty allErrands list safely', () {
      final result = ErrandOrdersPage.filterMyRequests([], currentUserName: 'Budi');
      expect(result, isEmpty);
    });

    test('4.11 ErrandModel serializes and deserializes requesterId cleanly', () {
      const model = ErrandModel(
        id: 'm1',
        item: 'Kopi',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 3000,
        requester: 'Budi',
        requesterId: 'usr_budi',
      );
      final decoded = ErrandModel.fromMap(model.toMap());
      expect(decoded.requesterId, equals('usr_budi'));
    });

    test('4.12 ErrandModel.fromMap handles legacy map without requesterId', () {
      final decoded = ErrandModel.fromMap({
        'id': 'legacy_1',
        'item': 'Teh',
        'pickup': 'Kantin',
        'dropoff': 'Lab',
        'tip': 2000,
        'requester': 'Siti',
        'status': 'open',
      });
      expect(decoded.requesterId, isNull);
    });

    test('4.13 copyWith updates requesterId properly', () {
      const model = ErrandModel(
        id: 'm2',
        item: 'Teh',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 2000,
        requester: 'Budi',
      );
      final updated = model.copyWith(requesterId: 'usr_77');
      expect(updated.requesterId, equals('usr_77'));
    });

    testWidgets('4.14 Widget Permintaan Saya hides other user order ending with 1', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await AuthService.instance.login('budi@kampus.ac.id', 'pass123');

      const otherOrder = ErrandModel(
        id: 'other_order_1',
        item: 'Pesanan Rahasia Siti',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 5000,
        requester: 'Siti',
        status: OrderStatus.open,
      );
      final repo = ErrandRepositoryImpl(initialErrands: [otherOrder]);
      final notifier = ErrandFeedNotifier(repo);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandRepositoryProvider.overrideWithValue(repo),
            errandFeedNotifierProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(home: Scaffold(body: ErrandOrdersPage())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pesanan Rahasia Siti'), findsNothing);
      expect(find.text('Belum Ada Permintaan'), findsOneWidget);
      await AuthService.instance.logout();
    });
  });

  group('P11 Bug #5 Regression: Tugas Belanja / Antar Runner Claim Filter', () {
    test('5.1 Excludes unclaimed open orders from other requesters', () {
      const openOther = ErrandModel(
        id: 'open_other_1',
        item: 'Belum Diklaim',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 4000,
        requester: 'Siti',
        status: OrderStatus.open,
      );
      final result = ErrandOrdersPage.filterRunnerTasks(
        [openOther],
        currentUserName: 'Budi',
      );
      expect(result, isEmpty);
    });

    test('5.2 Excludes unclaimed open orders from active user himself', () {
      const openMine = ErrandModel(
        id: 'open_mine_1',
        item: 'Order Sendiri',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 4000,
        requester: 'Budi',
        status: OrderStatus.open,
      );
      final result = ErrandOrdersPage.filterRunnerTasks(
        [openMine],
        currentUserName: 'Budi',
      );
      expect(result, isEmpty);
    });

    test('5.3 Excludes accepted order claimed by a DIFFERENT runner', () {
      const claimedByOther = ErrandModel(
        id: 'claimed_other_1',
        item: 'Diklaim Runner Lain',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 4000,
        requester: 'Siti',
        status: OrderStatus.accepted,
        runnerName: 'Andi',
        runnerId: 'usr_andi',
      );
      final result = ErrandOrdersPage.filterRunnerTasks(
        [claimedByOther],
        currentUserName: 'Budi',
        currentUserId: 'usr_budi',
      );
      expect(result, isEmpty);
    });

    test('5.4 Includes accepted order claimed by active runner (by runnerId)', () {
      const claimedByMe = ErrandModel(
        id: 'claimed_me_1',
        item: 'Tugas Saya',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 4000,
        requester: 'Siti',
        status: OrderStatus.accepted,
        runnerName: 'Budi',
        runnerId: 'usr_budi',
      );
      final result = ErrandOrdersPage.filterRunnerTasks(
        [claimedByMe],
        currentUserName: 'Budi',
        currentUserId: 'usr_budi',
      );
      expect(result, hasLength(1));
      expect(result.first.id, equals('claimed_me_1'));
    });

    test('5.5 Includes completed order claimed by active runner (by runnerName)', () {
      const completedByMe = ErrandModel(
        id: 'completed_me_1',
        item: 'Sudah Selesai Saya Antar',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 4000,
        requester: 'Siti',
        status: OrderStatus.completed,
        runnerName: 'Budi',
      );
      final result = ErrandOrdersPage.filterRunnerTasks(
        [completedByMe],
        currentUserName: 'Budi',
      );
      expect(result, hasLength(1));
    });

    test('5.6 ErrandRepositoryImpl.acceptErrand() records runnerName on ErrandModel', () async {
      SharedPreferences.setMockInitialValues({});
      const openOrder = ErrandModel(
        id: 'acc_1',
        item: 'Bakmie',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 5000,
        requester: 'Siti',
      );
      final repo = ErrandRepositoryImpl(initialErrands: [openOrder]);
      final accepted = await repo.acceptErrand('acc_1', runnerName: 'Budi');
      expect(accepted.status, equals(OrderStatus.accepted));
      expect(accepted.runnerName, equals('Budi'));
    });

    test('5.7 ErrandRepositoryImpl.acceptErrand() records runnerId when provided', () async {
      SharedPreferences.setMockInitialValues({});
      const openOrder = ErrandModel(
        id: 'acc_2',
        item: 'Bakmie',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 5000,
        requester: 'Siti',
      );
      final repo = ErrandRepositoryImpl(initialErrands: [openOrder]);
      final accepted = await repo.acceptErrand('acc_2', runnerName: 'Budi', runnerId: 'usr_budi');
      expect(accepted.runnerId, equals('usr_budi'));
    });

    test('5.8 ErrandModel serializes and deserializes runnerName and runnerId', () {
      const model = ErrandModel(
        id: 'ser_1',
        item: 'Kopi',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 3000,
        requester: 'Siti',
        status: OrderStatus.accepted,
        runnerName: 'Budi',
        runnerId: 'usr_budi',
      );
      final decoded = ErrandModel.fromMap(model.toMap());
      expect(decoded.runnerName, equals('Budi'));
      expect(decoded.runnerId, equals('usr_budi'));
    });

    test('5.9 ErrandModel.fromMap handles legacy map without runnerName/runnerId', () {
      final decoded = ErrandModel.fromMap({
        'id': 'legacy_2',
        'item': 'Teh',
        'pickup': 'Kantin',
        'dropoff': 'Lab',
        'tip': 2000,
        'requester': 'Siti',
        'status': 'accepted',
      });
      expect(decoded.runnerName, isNull);
      expect(decoded.runnerId, isNull);
    });

    test('5.10 copyWith updates runnerName and runnerId properly', () {
      const model = ErrandModel(
        id: 'cw_1',
        item: 'Teh',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 2000,
        requester: 'Siti',
      );
      final updated = model.copyWith(runnerName: 'Budi', runnerId: 'usr_budi');
      expect(updated.runnerName, equals('Budi'));
      expect(updated.runnerId, equals('usr_budi'));
    });

    test('5.11 Legacy accepted order without runnerName still shows for non-requester runner', () {
      const legacyAccepted = ErrandModel(
        id: 'legacy_acc_1',
        item: 'Komik',
        pickup: 'Koperasi',
        dropoff: 'Rektorat',
        tip: 5000,
        requester: 'Dimas',
        status: OrderStatus.accepted,
      );
      final result = ErrandOrdersPage.filterRunnerTasks(
        [legacyAccepted],
        currentUserName: 'Budi',
      );
      expect(result, hasLength(1));
    });

    test('5.12 Legacy accepted order requested by active user does not show in Runner Tasks', () {
      const myAcceptedOrder = ErrandModel(
        id: 'my_acc_1',
        item: 'Komik',
        pickup: 'Koperasi',
        dropoff: 'Rektorat',
        tip: 5000,
        requester: 'Budi',
        status: OrderStatus.accepted,
      );
      final result = ErrandOrdersPage.filterRunnerTasks(
        [myAcceptedOrder],
        currentUserName: 'Budi',
      );
      expect(result, isEmpty);
    });

    test('5.13 Excludes completed order claimed by another runner', () {
      const otherCompleted = ErrandModel(
        id: 'comp_other_1',
        item: 'Nasi Uduk',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 4000,
        requester: 'Siti',
        status: OrderStatus.completed,
        runnerName: 'Andi',
      );
      final result = ErrandOrdersPage.filterRunnerTasks(
        [otherCompleted],
        currentUserName: 'Budi',
      );
      expect(result, isEmpty);
    });

    test('5.14 Handles empty list safely', () {
      final result = ErrandOrdersPage.filterRunnerTasks([], currentUserName: 'Budi');
      expect(result, isEmpty);
    });

    testWidgets('5.15 Widget Tugas Belanja / Antar hides unclaimed open order from another user', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await AuthService.instance.login('budi@kampus.ac.id', 'pass123');

      const openOther = ErrandModel(
        id: 'open_other_widget_1',
        item: 'Order Belum Diklaim',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 5000,
        requester: 'Siti',
        status: OrderStatus.open,
      );
      final repo = ErrandRepositoryImpl(initialErrands: [openOther]);
      final notifier = ErrandFeedNotifier(repo);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandRepositoryProvider.overrideWithValue(repo),
            errandFeedNotifierProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(home: Scaffold(body: ErrandOrdersPage())),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tugas Belanja / Antar'));
      await tester.pumpAndSettle();

      expect(find.text('Order Belum Diklaim'), findsNothing);
      expect(find.text('Belum Ada Tugas Belanja'), findsOneWidget);
      await AuthService.instance.logout();
    });
  });
}
