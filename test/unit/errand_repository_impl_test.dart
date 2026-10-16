import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titip_jalur/models/errand_model.dart';
import 'package:titip_jalur/repositories/errand_repository.dart';
import 'package:titip_jalur/services/errand_api_service.dart';
import 'package:titip_jalur/services/errand_business_validator.dart';
import 'package:titip_jalur/services/errand_local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('US-01, US-04, US-05 Unit Test: ErrandRepositoryImpl Hybrid Architecture', () {
    late ErrandLocalStorageService localStorageService;
    final testBaseUrl = Uri.parse('https://api.titipjalur.test/v1');

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      localStorageService = ErrandLocalStorageService();
    });

    test('1. getErrands() fetches from remote API service and caches into local storage', () async {
      final mockClient = MockClient((request) async {
        const payload = '''
        [
          {
            "id": "REPO-01",
            "item": "Es Teh Manis Jumbo",
            "pickup": "Kantin Vokasi",
            "dropoff": "Lab Komputer K10",
            "tip": 3000,
            "requester": "Fahrel",
            "status": "open",
            "distanceKm": 0.4,
            "category": "Kantin"
          }
        ]
        ''';
        return http.Response(payload, 200);
      });
      addTearDown(mockClient.close);

      final apiService = ErrandApiService(client: mockClient, baseUrl: testBaseUrl);
      final repository = ErrandRepositoryImpl(
        apiService: apiService,
        localStorageService: localStorageService,
      );

      final errands = await repository.getErrands();

      expect(errands, hasLength(1));
      expect(errands.first.id, equals('REPO-01'));

      // Verify that local storage cached the fetched item
      final cached = await localStorageService.loadErrands();
      expect(cached, hasLength(1));
      expect(cached.first.id, equals('REPO-01'));
    });

    test('2. getErrands() falls back gracefully to local storage cache when remote API fails', () async {
      // 1. Seed local storage with offline cache
      const cachedErrand = ErrandModel(
        id: 'OFFLINE-CACHE-01',
        item: 'Fotokopi Diktat Struktur Data',
        pickup: 'Koperasi Kampus',
        dropoff: 'Ruang Seminar',
        tip: 4000,
        requester: 'Mahasiswa Offline',
        status: OrderStatus.open,
        distanceKm: 0.9,
        category: 'ATK',
      );
      await localStorageService.saveErrands([cachedErrand]);

      // 2. Setup failing remote API client (HTTP 503 Service Unavailable)
      final failingMockClient = MockClient((request) async {
        return http.Response('Service Unavailable', 503);
      });
      addTearDown(failingMockClient.close);

      final apiService = ErrandApiService(client: failingMockClient, baseUrl: testBaseUrl);
      final repository = ErrandRepositoryImpl(
        apiService: apiService,
        localStorageService: localStorageService,
      );

      // 3. Repository should fall back to cached data without crashing
      final errands = await repository.getErrands();

      expect(errands, hasLength(1));
      expect(errands.first.id, equals('OFFLINE-CACHE-01'));
      expect(errands.first.item, equals('Fotokopi Diktat Struktur Data'));
    });

    test('3. getErrands() handles simulateEmpty and simulateError flags', () async {
      final repository = ErrandRepositoryImpl(localStorageService: localStorageService);

      final emptyList = await repository.getErrands(simulateEmpty: true);
      expect(emptyList, isEmpty);

      expect(
        () => repository.getErrands(simulateError: true),
        throwsA(isA<Exception>()),
      );
    });

    test('4. createErrand() validates business rules and propagates to remote and local storage', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        const responseJson = '''
        {
          "id": "SERVER-ID-77",
          "item": "Kopi Susu Dingin",
          "pickup": "Kafe Rimbun",
          "dropoff": "Gedung D4",
          "tip": 3500,
          "requester": "Fahrel",
          "status": "open",
          "distanceKm": 0.7,
          "category": "Kafe"
        }
        ''';
        return http.Response(responseJson, 201);
      });
      addTearDown(mockClient.close);

      final apiService = ErrandApiService(client: mockClient, baseUrl: testBaseUrl);
      final repository = ErrandRepositoryImpl(
        apiService: apiService,
        localStorageService: localStorageService,
      );

      // Attempt invalid errand creation (tip under minimum Rp 2000)
      const invalidErrand = ErrandModel(
        id: 'TEMP-INV',
        item: 'Permen',
        pickup: 'Kantin',
        dropoff: 'Lab',
        tip: 500, // Invalid!
        requester: 'Fahrel',
      );

      expect(
        () => repository.createErrand(invalidErrand),
        throwsA(isA<ErrandValidationException>()),
      );

      // Create valid errand
      const validErrand = ErrandModel(
        id: 'CLIENT-ID-1',
        item: 'Kopi Susu Dingin',
        pickup: 'Kafe Rimbun',
        dropoff: 'Gedung D4',
        tip: 3500,
        requester: 'Fahrel',
        category: 'Kafe',
        distanceKm: 0.7,
      );

      final created = await repository.createErrand(validErrand);

      expect(created.id, equals('SERVER-ID-77'));
      final stored = await localStorageService.loadErrands();
      expect(stored.first.id, equals('SERVER-ID-77'));
    });

    test('5. acceptErrand() updates status to accepted, saves locally, and enforces anti-self-dealing', () async {
      const initialErrand = ErrandModel(
        id: 'CLAIM-TARGET-1',
        item: 'Ayam Geprek',
        pickup: 'Kantin Pusat',
        dropoff: 'Gedung K9',
        tip: 5000,
        requester: 'RequesterUser',
        status: OrderStatus.open,
      );

      final repository = ErrandRepositoryImpl(
        initialErrands: [initialErrand],
        localStorageService: localStorageService,
      );

      // Self-dealing attempt: requester tries to claim own order
      expect(
        () => repository.acceptErrand('CLAIM-TARGET-1', runnerName: 'RequesterUser'),
        throwsA(isA<ErrandBusinessException>()),
      );

      // Valid claim by legitimate runner
      final accepted = await repository.acceptErrand('CLAIM-TARGET-1', runnerName: 'LegitRunner');
      expect(accepted.status, equals(OrderStatus.accepted));

      // Attempting to claim again throws ErrandStateException
      expect(
        () => repository.acceptErrand('CLAIM-TARGET-1', runnerName: 'AnotherRunner'),
        throwsA(isA<ErrandStateException>()),
      );
    });

    test('6. completeErrand() validates transition from accepted to completed', () async {
      const initialOpen = ErrandModel(
        id: 'COMP-TARGET-1',
        item: 'Flashdisk',
        pickup: 'Toko Komputer',
        dropoff: 'Lab Jaringan',
        tip: 4000,
        requester: 'Rudi',
        status: OrderStatus.open,
      );

      final repository = ErrandRepositoryImpl(
        initialErrands: [initialOpen],
        localStorageService: localStorageService,
      );

      // Attempting to complete an unaccepted errand throws ErrandStateException
      expect(
        () => repository.completeErrand('COMP-TARGET-1'),
        throwsA(isA<ErrandStateException>()),
      );

      // Claim first
      await repository.acceptErrand('COMP-TARGET-1', runnerName: 'Andi');

      // Now complete
      final completed = await repository.completeErrand('COMP-TARGET-1');
      expect(completed.status, equals(OrderStatus.completed));
    });

    test('7. deleteErrand() prevents cancellation of accepted errand', () async {
      const initialAccepted = ErrandModel(
        id: 'DEL-TARGET-1',
        item: 'Obat Maag',
        pickup: 'Apotek',
        dropoff: 'Asrama Putra',
        tip: 5000,
        requester: 'Doni',
        status: OrderStatus.accepted,
      );

      final repository = ErrandRepositoryImpl(
        initialErrands: [initialAccepted],
        localStorageService: localStorageService,
      );

      // Cancellation of in-progress errand is blocked
      expect(
        () => repository.deleteErrand('DEL-TARGET-1'),
        throwsA(isA<ErrandStateException>()),
      );
    });
  });
}
