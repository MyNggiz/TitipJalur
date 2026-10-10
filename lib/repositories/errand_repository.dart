import '../services/errand_local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/errand_model.dart';
import '../services/mock_data_service.dart';

abstract class ErrandRepository {
  Future<List<ErrandModel>> getErrands({
    bool simulateError = false,
    bool simulateEmpty = false,
  });

  Future<ErrandModel> createErrand(
    ErrandModel errand, {
    bool simulateError = false,
  });

  Future<ErrandModel> acceptErrand(String id);

  Future<ErrandModel> completeErrand(String id);

  Future<void> deleteErrand(String id);
}

class ErrandRepositoryImpl implements ErrandRepository {
  ErrandRepositoryImpl({
    List<ErrandModel>? initialErrands,
    ErrandLocalStorageService? localStorageService,
  })  : _localStorageService = localStorageService,
        _errands = List<ErrandModel>.from(
          initialErrands ?? MockDataService.getInitialErrands(),
        );

  final ErrandLocalStorageService? _localStorageService;
  List<ErrandModel> _errands;
  bool _isLoadedFromStorage = false;

  @override
  Future<List<ErrandModel>> getErrands({
    bool simulateError = false,
    bool simulateEmpty = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (simulateError) {
      throw Exception(
        'Gagal menghubungi server titipan. Periksa koneksi Anda.',
      );
    }
    if (simulateEmpty) {
      return <ErrandModel>[];
    }

    final storage = _localStorageService;
    if (!_isLoadedFromStorage && storage != null) {
      final loaded = await storage.loadErrands();
      if (loaded.isNotEmpty) {
        _errands = List<ErrandModel>.from(loaded);
      }
      _isLoadedFromStorage = true;
    }

    return List<ErrandModel>.from(_errands);
  }

  @override
  Future<ErrandModel> createErrand(
    ErrandModel errand, {
    bool simulateError = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (simulateError) {
      throw Exception(
        'Gagal memproses pembuatan titipan baru. Silakan coba lagi.',
      );
    }
    _errands.insert(0, errand);
    await _localStorageService?.saveErrands(_errands);
    return errand;
  }

  @override
  Future<ErrandModel> acceptErrand(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _errands.indexWhere((element) => element.id == id);
    if (index == -1) {
      throw Exception('Titipan dengan ID $id tidak ditemukan.');
    }
    final updated = _errands[index].copyWith(status: OrderStatus.accepted);
    _errands[index] = updated;
    await _localStorageService?.saveErrands(_errands);
    return updated;
  }

  @override
  Future<ErrandModel> completeErrand(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _errands.indexWhere((element) => element.id == id);
    if (index == -1) {
      throw Exception('Titipan dengan ID $id tidak ditemukan.');
    }
    final updated = _errands[index].copyWith(status: OrderStatus.completed);
    _errands[index] = updated;
    await _localStorageService?.saveErrands(_errands);
    return updated;
  }

  @override
  Future<void> deleteErrand(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _errands.indexWhere((element) => element.id == id);
    if (index == -1) {
      throw Exception('Titipan dengan ID $id tidak ditemukan.');
    }
    _errands.removeAt(index);
    await _localStorageService?.saveErrands(_errands);
  }
}

final errandLocalStorageServiceProvider =
    Provider<ErrandLocalStorageService>((ref) {
  return ErrandLocalStorageService();
});

final errandRepositoryProvider = Provider<ErrandRepository>((ref) {
  final storage = ref.watch(errandLocalStorageServiceProvider);
  return ErrandRepositoryImpl(localStorageService: storage);
});
