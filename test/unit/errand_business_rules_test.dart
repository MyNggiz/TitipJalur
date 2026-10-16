import 'package:flutter_test/flutter_test.dart';
import 'package:titip_jalur/models/errand_model.dart';
import 'package:titip_jalur/services/errand_business_validator.dart';

void main() {
  group('US-03, US-04, US-05 Unit Test: Domain Business Rules & Marketplace Integrity', () {
    const validBaseErrand = ErrandModel(
      id: 'BIZ-01',
      item: 'Buku Binder A5 Joyko',
      pickup: 'Toko Buku Togamas',
      dropoff: 'Gedung Rektorat Lt 2',
      tip: 3000,
      requester: 'Fahrel',
      status: OrderStatus.open,
      distanceKm: 1.4,
      category: 'ATK',
    );

    group('1. Creation Rules (US-03: Minimum Tip, Item Length, Distinct Route)', () {
      test('1.1 Valid errand request satisfies all business validation constraints', () {
        expect(
          () => ErrandBusinessValidator.validateErrandCreation(validBaseErrand),
          returnsNormally,
        );
      });

      test('1.2 Tip under minimum threshold (Rp 2.000) throws ErrandValidationException', () {
        final lowTipErrand = validBaseErrand.copyWith(tip: 1500);

        expect(
          () => ErrandBusinessValidator.validateErrandCreation(lowTipErrand),
          throwsA(
            isA<ErrandValidationException>().having(
              (e) => e.message,
              'message',
              contains('2.000'),
            ),
          ),
        );
      });

      test('1.3 Item title shorter than 3 characters throws ErrandValidationException', () {
        final shortItemErrand = validBaseErrand.copyWith(item: 'Ab');

        expect(
          () => ErrandBusinessValidator.validateErrandCreation(shortItemErrand),
          throwsA(
            isA<ErrandValidationException>().having(
              (e) => e.message,
              'message',
              contains('3 karakter'),
            ),
          ),
        );
      });

      test('1.4 Identical pickup and dropoff locations are rejected', () {
        final sameRouteErrand = validBaseErrand.copyWith(
          pickup: 'Kantin Vokasi',
          dropoff: 'kantin vokasi', // case-insensitive identical route
        );

        expect(
          () => ErrandBusinessValidator.validateErrandCreation(sameRouteErrand),
          throwsA(
            isA<ErrandValidationException>().having(
              (e) => e.message,
              'message',
              contains('tidak boleh sama'),
            ),
          ),
        );
      });

      test('1.5 Empty pickup, dropoff, or requester throws ErrandValidationException', () {
        expect(
          () => ErrandBusinessValidator.validateErrandCreation(
            validBaseErrand.copyWith(pickup: '   '),
          ),
          throwsA(isA<ErrandValidationException>()),
        );

        expect(
          () => ErrandBusinessValidator.validateErrandCreation(
            validBaseErrand.copyWith(dropoff: ''),
          ),
          throwsA(isA<ErrandValidationException>()),
        );

        expect(
          () => ErrandBusinessValidator.validateErrandCreation(
            validBaseErrand.copyWith(requester: '  '),
          ),
          throwsA(isA<ErrandValidationException>()),
        );
      });
    });

    group('2. Errand Claim & Anti-Self-Dealing Rules (US-04: Runner Claim Constraints)', () {
      test('2.1 Legitimate commuter runner can claim an open errand', () {
        expect(
          () => ErrandBusinessValidator.validateAccept(validBaseErrand, 'Rian Runner'),
          returnsNormally,
        );
      });

      test('2.2 Anti-Self-Dealing: Requester cannot claim their own errand', () {
        // Requester is 'Fahrel', runner is 'fahrel' (case-insensitive)
        expect(
          () => ErrandBusinessValidator.validateAccept(validBaseErrand, 'fahrel'),
          throwsA(
            isA<ErrandBusinessException>().having(
              (e) => e.message,
              'message',
              contains('Anti-Self-Dealing'),
            ),
          ),
        );
      });

      test('2.3 Runner name cannot be blank when claiming', () {
        expect(
          () => ErrandBusinessValidator.validateAccept(validBaseErrand, '   '),
          throwsA(isA<ErrandValidationException>()),
        );
      });

      test('2.4 Claiming an errand that is already accepted throws ErrandStateException', () {
        final acceptedErrand = validBaseErrand.copyWith(status: OrderStatus.accepted);

        expect(
          () => ErrandBusinessValidator.validateAccept(acceptedErrand, 'Dimas'),
          throwsA(
            isA<ErrandStateException>().having(
              (e) => e.message,
              'message',
              contains('sudah diambil'),
            ),
          ),
        );
      });

      test('2.5 Claiming an errand that is already completed throws ErrandStateException', () {
        final completedErrand = validBaseErrand.copyWith(status: OrderStatus.completed);

        expect(
          () => ErrandBusinessValidator.validateAccept(completedErrand, 'Dimas'),
          throwsA(
            isA<ErrandStateException>().having(
              (e) => e.message,
              'message',
              contains('sudah selesai'),
            ),
          ),
        );
      });
    });

    group('3. Errand Completion & Cancellation Rules (US-05: State Transition Integrity)', () {
      test('3.1 Completing an accepted errand is permitted', () {
        final acceptedErrand = validBaseErrand.copyWith(status: OrderStatus.accepted);

        expect(
          () => ErrandBusinessValidator.validateComplete(acceptedErrand),
          returnsNormally,
        );
      });

      test('3.2 Completing an unaccepted (open) errand is strictly rejected', () {
        expect(
          () => ErrandBusinessValidator.validateComplete(validBaseErrand),
          throwsA(
            isA<ErrandStateException>().having(
              (e) => e.message,
              'message',
              contains('Terbuka (Open)'),
            ),
          ),
        );
      });

      test('3.3 Re-completing an already completed errand throws ErrandStateException', () {
        final completedErrand = validBaseErrand.copyWith(status: OrderStatus.completed);

        expect(
          () => ErrandBusinessValidator.validateComplete(completedErrand),
          throwsA(isA<ErrandStateException>()),
        );
      });

      test('3.4 Cancelling an open errand before it is claimed is permitted', () {
        expect(
          () => ErrandBusinessValidator.validateCancellation(validBaseErrand),
          returnsNormally,
        );
      });

      test('3.5 Cancelling an in-progress accepted errand by requester throws ErrandStateException', () {
        final acceptedErrand = validBaseErrand.copyWith(status: OrderStatus.accepted);

        expect(
          () => ErrandBusinessValidator.validateCancellation(acceptedErrand),
          throwsA(
            isA<ErrandStateException>().having(
              (e) => e.message,
              'message',
              contains('tidak dapat dibatalkan secara sepihak'),
            ),
          ),
        );
      });
    });
  });
}
