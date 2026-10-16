import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:titip_jalur/models/errand_model.dart';
import 'package:titip_jalur/services/errand_api_service.dart';

void main() {
  final testBaseUrl = Uri.parse('https://api.titipjalur.test/v1');

  group('US-01 & US-03 Unit Test: ErrandApiService Remote HTTP Client with MockClient', () {
    test('1. fetchErrands() returns parsed List<ErrandModel> on HTTP 200 OK', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.path, equals('/v1/errands'));

        const responsePayload = '''
        [
          {
            "id": "API-01",
            "item": "Nasi Padang Rendang",
            "pickup": "Kantin Utama",
            "dropoff": "Lab Jaringan",
            "tip": 7000,
            "requester": "Fahrel",
            "status": "open",
            "distanceKm": 1.2,
            "category": "Kantin"
          },
          {
            "id": "API-02",
            "item": "Kertas Folio Bergaris 1 Rim",
            "pickup": "Fotokopi Barokah",
            "dropoff": "Ruang Hima",
            "tip": 5000,
            "requester": "Ahmad",
            "status": "open",
            "distanceKm": 0.6,
            "category": "ATK"
          }
        ]
        ''';
        return http.Response(responsePayload, 200, headers: {'content-type': 'application/json'});
      });
      addTearDown(mockClient.close);

      final service = ErrandApiService(client: mockClient, baseUrl: testBaseUrl);
      final errands = await service.fetchErrands();

      expect(errands, hasLength(2));
      expect(errands.first.id, equals('API-01'));
      expect(errands.first.item, equals('Nasi Padang Rendang'));
      expect(errands.first.tip, equals(7000));
      expect(errands.last.id, equals('API-02'));
    });

    test('2. fetchErrands() returns empty list on HTTP 200 with empty JSON array []', () async {
      final mockClient = MockClient((request) async {
        return http.Response('[]', 200, headers: {'content-type': 'application/json'});
      });
      addTearDown(mockClient.close);

      final service = ErrandApiService(client: mockClient, baseUrl: testBaseUrl);
      final errands = await service.fetchErrands();

      expect(errands, isEmpty);
    });

    test('3. fetchErrands() throws ApiException on HTTP 404 or 500', () async {
      final mockClient500 = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });
      addTearDown(mockClient500.close);

      final service500 = ErrandApiService(client: mockClient500, baseUrl: testBaseUrl);
      expect(
        () => service500.fetchErrands(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', equals(500))
              .having((e) => e.message, 'message', contains('500')),
        ),
      );

      final mockClient404 = MockClient((request) async {
        return http.Response('Not Found', 404);
      });
      addTearDown(mockClient404.close);

      final service404 = ErrandApiService(client: mockClient404, baseUrl: testBaseUrl);
      expect(
        () => service404.fetchErrands(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', equals(404)),
        ),
      );
    });

    test('4. fetchErrands() throws FormatException on non-array or malformed JSON', () async {
      final mockClientNonArray = MockClient((request) async {
        return http.Response('{"error": "Forbidden"}', 200);
      });
      addTearDown(mockClientNonArray.close);

      final serviceNonArray = ErrandApiService(client: mockClientNonArray, baseUrl: testBaseUrl);
      expect(
        () => serviceNonArray.fetchErrands(),
        throwsA(isA<FormatException>()),
      );

      final mockClientBroken = MockClient((request) async {
        return http.Response('<<<not json>>>', 200);
      });
      addTearDown(mockClientBroken.close);

      final serviceBroken = ErrandApiService(client: mockClientBroken, baseUrl: testBaseUrl);
      expect(
        () => serviceBroken.fetchErrands(),
        throwsA(isA<FormatException>()),
      );
    });

    test('5. createErrand() sends HTTP POST and returns newly created ErrandModel', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/v1/errands'));
        expect(request.headers['Content-Type'], contains('application/json'));
        expect(request.body, contains('Kopi Latte Dingin'));

        const responseJson = '''
        {
          "id": "API-POST-99",
          "item": "Kopi Latte Dingin",
          "pickup": "Kafe Danau",
          "dropoff": "Gazebo Gedung B",
          "tip": 4500,
          "requester": "Fahrel",
          "status": "open",
          "distanceKm": 0.5,
          "category": "Kafe"
        }
        ''';
        return http.Response(responseJson, 201);
      });
      addTearDown(mockClient.close);

      final service = ErrandApiService(client: mockClient, baseUrl: testBaseUrl);
      const newErrand = ErrandModel(
        id: 'TEMP-1',
        item: 'Kopi Latte Dingin',
        pickup: 'Kafe Danau',
        dropoff: 'Gazebo Gedung B',
        tip: 4500,
        requester: 'Fahrel',
        category: 'Kafe',
        distanceKm: 0.5,
      );

      final created = await service.createErrand(newErrand);

      expect(created.id, equals('API-POST-99'));
      expect(created.item, equals('Kopi Latte Dingin'));
      expect(created.status, equals(OrderStatus.open));
      expect(created.tip, equals(4500));
    });

    test('6. acceptErrand() sends PATCH and returns updated ErrandModel with status accepted', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('PATCH'));
        expect(request.url.path, equals('/v1/errands/API-01/accept'));
        expect(request.body, contains('Runner Andi'));

        const responseJson = '''
        {
          "id": "API-01",
          "item": "Nasi Padang Rendang",
          "pickup": "Kantin Utama",
          "dropoff": "Lab Jaringan",
          "tip": 7000,
          "requester": "Fahrel",
          "status": "accepted",
          "distanceKm": 1.2,
          "category": "Kantin"
        }
        ''';
        return http.Response(responseJson, 200);
      });
      addTearDown(mockClient.close);

      final service = ErrandApiService(client: mockClient, baseUrl: testBaseUrl);
      final accepted = await service.acceptErrand('API-01', runnerName: 'Runner Andi');

      expect(accepted.id, equals('API-01'));
      expect(accepted.status, equals(OrderStatus.accepted));
    });

    test('7. completeErrand() sends PATCH and returns updated ErrandModel with status completed', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('PATCH'));
        expect(request.url.path, equals('/v1/errands/API-01/complete'));

        const responseJson = '''
        {
          "id": "API-01",
          "item": "Nasi Padang Rendang",
          "pickup": "Kantin Utama",
          "dropoff": "Lab Jaringan",
          "tip": 7000,
          "requester": "Fahrel",
          "status": "completed",
          "distanceKm": 1.2,
          "category": "Kantin"
        }
        ''';
        return http.Response(responseJson, 200);
      });
      addTearDown(mockClient.close);

      final service = ErrandApiService(client: mockClient, baseUrl: testBaseUrl);
      final completed = await service.completeErrand('API-01');

      expect(completed.id, equals('API-01'));
      expect(completed.status, equals(OrderStatus.completed));
    });

    test('8. deleteErrand() sends DELETE and completes successfully on HTTP 200 / 204', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('DELETE'));
        expect(request.url.path, equals('/v1/errands/API-01'));
        return http.Response('', 204);
      });
      addTearDown(mockClient.close);

      final service = ErrandApiService(client: mockClient, baseUrl: testBaseUrl);
      await expectLater(service.deleteErrand('API-01'), completes);
    });

    test('9. Network timeout triggers TimeoutException as specified in P6 slides', () async {
      final slowMockClient = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response('[]', 200);
      });
      addTearDown(slowMockClient.close);

      final timeoutService = ErrandApiService(
        client: slowMockClient,
        baseUrl: testBaseUrl,
        timeoutDuration: const Duration(milliseconds: 10),
      );

      await expectLater(
        timeoutService.fetchErrands(),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}
