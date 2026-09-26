import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/errand_model.dart';
import '../repositories/errand_repository.dart';

class ErrandFeedNotifier extends StateNotifier<AsyncValue<List<ErrandModel>>> {
  ErrandFeedNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadErrands();
  }

  final ErrandRepository _repository;

  Future<void> loadErrands({
    bool forceError = false,
    bool forceEmpty = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getErrands(
        simulateError: forceError,
        simulateEmpty: forceEmpty,
      );
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> retry() => loadErrands();

  void addErrand(ErrandModel errand) {
    final current = state.valueOrNull ?? <ErrandModel>[];
    state = AsyncValue.data(<ErrandModel>[errand, ...current]);
  }

  Future<void> acceptErrand(String id) async {
    try {
      final updated = await _repository.acceptErrand(id);
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncValue.data(
          current.map((item) => item.id == id ? updated : item).toList(),
        );
      }
    } catch (e) {
      // Keep existing list on failure, or report error
      rethrow;
    }
  }
}

final errandFeedNotifierProvider =
    StateNotifierProvider<ErrandFeedNotifier, AsyncValue<List<ErrandModel>>>((ref) {
  final repo = ref.watch(errandRepositoryProvider);
  return ErrandFeedNotifier(repo);
});
