import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titip_jalur/controllers/errand_feed_notifier.dart';
import 'package:titip_jalur/models/errand_model.dart';
import 'package:titip_jalur/repositories/errand_repository.dart';

class FakeErrandRepository implements ErrandRepository {
  FakeErrandRepository({
    List<ErrandModel>? seedErrands,
    this.shouldThrowError = false,
  }) : errands = List<ErrandModel>.from(seedErrands ?? []);

  final List<ErrandModel> errands;
  bool shouldThrowError;

  @override
  Future<List<ErrandModel>> getErrands({
    bool simulateError = false,
    bool simulateEmpty = false,
  }) async {
    if (shouldThrowError || simulateError) {
      throw Exception('Server Error Simulasi');
    }
    if (simulateEmpty) {
      return <ErrandModel>[];
    }
    return List<ErrandModel>.from(errands);
  }

  @override
  Future<ErrandModel> createErrand(
    ErrandModel errand, {
    bool simulateError = false,
  }) async {
    if (shouldThrowError || simulateError) {
      throw Exception('Gagal membuat titipan');
    }
    errands.insert(0, errand);
    return errand;
  }

  @override
  Future<ErrandModel> acceptErrand(String id) async {
    if (shouldThrowError) {
      throw Exception('Gagal klaim');
    }
    final index = errands.indexWhere((e) => e.id == id);
    if (index == -1) throw Exception('Not found');
    final updated = errands[index].copyWith(status: OrderStatus.accepted);
    errands[index] = updated;
    return updated;
  }

  @override
  Future<ErrandModel> completeErrand(String id) async {
    if (shouldThrowError) {
      throw Exception('Gagal menyelesaikan');
    }
    final index = errands.indexWhere((e) => e.id == id);
    if (index == -1) throw Exception('Not found');
    final updated = errands[index].copyWith(status: OrderStatus.completed);
    errands[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteErrand(String id) async {
    if (shouldThrowError) {
      throw Exception('Gagal menghapus');
    }
    errands.removeWhere((e) => e.id == id);
  }
}

void main() {
  group('US-01, US-04, US-05 Unit Test: ErrandFeedNotifier Riverpod State Management & 4 UI States', () {
    const sampleErrand1 = ErrandModel(
      id: 'FEED-1',
      item: 'Nasi Kuning Komplit',
      pickup: 'Kantin Asrama',
      dropoff: 'Lab Robotika Gedung E',
      tip: 3000,
      requester: 'Naufal',
      status: OrderStatus.open,
    );

    const sampleErrand2 = ErrandModel(
      id: 'FEED-2',
      item: 'Kopi Cold Brew',
      pickup: 'Kafe Kampus',
      dropoff: 'Ruang Dosen K10',
      tip: 4000,
      requester: 'Fahrel',
      status: OrderStatus.open,
    );

    test('1. Initial State transitions from Loading to Data with populated list', () async {
      final fakeRepo = FakeErrandRepository(seedErrands: [sampleErrand1, sampleErrand2]);
      final notifier = ErrandFeedNotifier(fakeRepo);

      // Await initialization
      await pumpEventQueue();

      expect(notifier.state, isA<AsyncData<List<ErrandModel>>>());
      expect(notifier.state.value, hasLength(2));
      expect(notifier.state.value!.first.id, equals('FEED-1'));
    });

    test('2. Repository error transitions notifier to AsyncError (Error State)', () async {
      final failingRepo = FakeErrandRepository(shouldThrowError: true);
      final notifier = ErrandFeedNotifier(failingRepo);

      await pumpEventQueue();

      expect(notifier.state, isA<AsyncError<List<ErrandModel>>>());
      expect(notifier.state.hasError, isTrue);
    });

    test('3. retry() recovers notifier from Error state back to Data state', () async {
      final repo = FakeErrandRepository(
        seedErrands: [sampleErrand1],
        shouldThrowError: true,
      );
      final notifier = ErrandFeedNotifier(repo);
      await pumpEventQueue();

      expect(notifier.state, isA<AsyncError<List<ErrandModel>>>());

      // Fix repo and retry
      repo.shouldThrowError = false;
      await notifier.retry();

      expect(notifier.state, isA<AsyncData<List<ErrandModel>>>());
      expect(notifier.state.value, hasLength(1));
      expect(notifier.state.value!.first.id, equals('FEED-1'));
    });

    test('4. Empty repository response sets AsyncData with empty list [] (Empty State)', () async {
      final emptyRepo = FakeErrandRepository(seedErrands: []);
      final notifier = ErrandFeedNotifier(emptyRepo);
      await pumpEventQueue();

      expect(notifier.state, isA<AsyncData<List<ErrandModel>>>());
      expect(notifier.state.value, isEmpty);
    });

    test('5. addErrand() prepends new errand to active feed state', () async {
      final repo = FakeErrandRepository(seedErrands: [sampleErrand1]);
      final notifier = ErrandFeedNotifier(repo);
      await pumpEventQueue();

      expect(notifier.state.value, hasLength(1));

      notifier.addErrand(sampleErrand2);

      expect(notifier.state.value, hasLength(2));
      expect(notifier.state.value!.first.id, equals('FEED-2'));
    });

    test('6. acceptErrand() re-emits updated state with status OrderStatus.accepted', () async {
      final repo = FakeErrandRepository(seedErrands: [sampleErrand1]);
      final notifier = ErrandFeedNotifier(repo);
      await pumpEventQueue();

      expect(notifier.state.value!.first.status, equals(OrderStatus.open));

      await notifier.acceptErrand('FEED-1');

      expect(notifier.state.value!.first.status, equals(OrderStatus.accepted));
    });

    test('7. completeErrand() re-emits updated state with status OrderStatus.completed', () async {
      final repo = FakeErrandRepository(
        seedErrands: [sampleErrand1.copyWith(status: OrderStatus.accepted)],
      );
      final notifier = ErrandFeedNotifier(repo);
      await pumpEventQueue();

      await notifier.completeErrand('FEED-1');

      expect(notifier.state.value!.first.status, equals(OrderStatus.completed));
    });

    test('8. deleteErrand() removes targeted errand from state without full reload', () async {
      final repo = FakeErrandRepository(seedErrands: [sampleErrand1, sampleErrand2]);
      final notifier = ErrandFeedNotifier(repo);
      await pumpEventQueue();

      expect(notifier.state.value, hasLength(2));

      await notifier.deleteErrand('FEED-1');

      expect(notifier.state.value, hasLength(1));
      expect(notifier.state.value!.first.id, equals('FEED-2'));
    });

    test('9. acceptErrand failure rethrows error while maintaining current feed state', () async {
      final repo = FakeErrandRepository(seedErrands: [sampleErrand1]);
      final notifier = ErrandFeedNotifier(repo);
      await pumpEventQueue();

      repo.shouldThrowError = true;

      expect(
        () => notifier.acceptErrand('FEED-1'),
        throwsA(isA<Exception>()),
      );

      // State is retained
      expect(notifier.state.value, hasLength(1));
      expect(notifier.state.value!.first.status, equals(OrderStatus.open));
    });
  });
}
