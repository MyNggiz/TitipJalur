import 'package:flutter_test/flutter_test.dart';
import 'package:titip_jalur/models/errand_model.dart';

void main() {
  group('US-02 Unit Test: ErrandModel API Contract & Serialization', () {
    test('1. Valid JSON payload with all fields parses correctly into ErrandModel', () {
      final validJson = {
        'id': 'TJ-101',
        'item': 'Nasi Ayam Geprek Level 3',
        'pickup': 'Kantin Vokasi UNESA',
        'dropoff': 'Lab Pemrograman Komputer Gedung K10',
        'tip': 5000,
        'requester': 'Naufal Fahrel',
        'status': 'open',
        'distanceKm': 0.8,
        'category': 'Kantin',
      };

      final errand = ErrandModel.fromJson(validJson);

      expect(errand.id, equals('TJ-101'));
      expect(errand.item, equals('Nasi Ayam Geprek Level 3'));
      expect(errand.pickup, equals('Kantin Vokasi UNESA'));
      expect(errand.dropoff, equals('Lab Pemrograman Komputer Gedung K10'));
      expect(errand.tip, equals(5000));
      expect(errand.requester, equals('Naufal Fahrel'));
      expect(errand.status, equals(OrderStatus.open));
      expect(errand.distanceKm, equals(0.8));
      expect(errand.category, equals('Kantin'));
      expect(errand.formattedTip, equals('Rp 5.000'));
    });

    test('2. Numeric integer ID in JSON is converted safely to String', () {
      final jsonWithIntId = {
        'id': 9921,
        'item': 'Buku Catatan Grid A5',
        'pickup': 'Koperasi Mahasiswa',
        'dropoff': 'Perpustakaan Pusat Lantai 2',
        'tip': 3000,
        'requester': 'Rizky Pratama',
      };

      final errand = ErrandModel.fromJson(jsonWithIntId);

      expect(errand.id, equals('9921'));
      expect(errand.distanceKm, equals(1.0)); // Default fallback
      expect(errand.category, equals('Kantin')); // Default fallback
      expect(errand.status, equals(OrderStatus.open));
    });

    test('3. toJson() generates strict Map matching API contract specifications', () {
      const errand = ErrandModel(
        id: 'TJ-88',
        item: 'Kopi Susu Gula Aren Dingin',
        pickup: 'Kafe Rimbun Kampus',
        dropoff: 'Gedung Rektorat Lt 3',
        tip: 4000,
        requester: 'Fahrel',
        status: OrderStatus.accepted,
        distanceKm: 1.5,
        category: 'Kafe',
      );

      final json = errand.toJson();

      expect(json['id'], equals('TJ-88'));
      expect(json['item'], equals('Kopi Susu Gula Aren Dingin'));
      expect(json['pickup'], equals('Kafe Rimbun Kampus'));
      expect(json['dropoff'], equals('Gedung Rektorat Lt 3'));
      expect(json['tip'], equals(4000));
      expect(json['requester'], equals('Fahrel'));
      expect(json['status'], equals('accepted'));
      expect(json['distanceKm'], equals(1.5));
      expect(json['category'], equals('Kafe'));
    });

    test('4. Missing mandatory fields throw FormatException with descriptive message', () {
      // Missing 'id'
      expect(
        () => ErrandModel.fromJson({
          'item': 'Flashdisk 32GB',
          'pickup': 'Toko Komputer',
          'dropoff': 'Ruang Dosen',
          'tip': 5000,
          'requester': 'Budi',
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('id'),
          ),
        ),
      );

      // Missing 'item'
      expect(
        () => ErrandModel.fromJson({
          'id': 'TJ-1',
          'pickup': 'Kantin',
          'dropoff': 'Lab',
          'tip': 5000,
          'requester': 'Budi',
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('item'),
          ),
        ),
      );

      // Missing 'pickup'
      expect(
        () => ErrandModel.fromJson({
          'id': 'TJ-1',
          'item': 'Buku',
          'dropoff': 'Lab',
          'tip': 5000,
          'requester': 'Budi',
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('pickup'),
          ),
        ),
      );

      // Missing 'dropoff'
      expect(
        () => ErrandModel.fromJson({
          'id': 'TJ-1',
          'item': 'Buku',
          'pickup': 'Kantin',
          'tip': 5000,
          'requester': 'Budi',
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('dropoff'),
          ),
        ),
      );

      // Missing 'tip'
      expect(
        () => ErrandModel.fromJson({
          'id': 'TJ-1',
          'item': 'Buku',
          'pickup': 'Kantin',
          'dropoff': 'Lab',
          'requester': 'Budi',
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('tip'),
          ),
        ),
      );

      // Missing 'requester'
      expect(
        () => ErrandModel.fromJson({
          'id': 'TJ-1',
          'item': 'Buku',
          'pickup': 'Kantin',
          'dropoff': 'Lab',
          'tip': 5000,
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('requester'),
          ),
        ),
      );
    });

    test('5. Non-numeric or negative tip produces FormatException', () {
      expect(
        () => ErrandModel.fromJson({
          'id': 'TJ-01',
          'item': 'Air Mineral',
          'pickup': 'Minimarket',
          'dropoff': 'Asrama',
          'tip': 'Lima Ribu', // String instead of num
          'requester': 'Citra',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => ErrandModel.fromJson({
          'id': 'TJ-02',
          'item': 'Air Mineral',
          'pickup': 'Minimarket',
          'dropoff': 'Asrama',
          'tip': -500, // Negative tip
          'requester': 'Citra',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('6. copyWith modifies target fields while preserving untouched fields', () {
      const original = ErrandModel(
        id: 'TJ-ORIG',
        item: 'Donat Cokelat',
        pickup: 'Kantin Utama',
        dropoff: 'Gedung D3',
        tip: 2500,
        requester: 'Dina',
        status: OrderStatus.open,
        distanceKm: 0.5,
        category: 'Kantin',
      );

      final updated = original.copyWith(
        status: OrderStatus.accepted,
        tip: 3500,
      );

      expect(updated.id, equals('TJ-ORIG'));
      expect(updated.item, equals('Donat Cokelat'));
      expect(updated.status, equals(OrderStatus.accepted));
      expect(updated.tip, equals(3500));
      expect(updated.formattedTip, equals('Rp 3.500'));
      expect(updated.pickup, equals('Kantin Utama'));
    });
  });
}
