import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/errand_model.dart';
import '../services/errand_api_service.dart';
import '../services/errand_business_validator.dart';
import '../services/errand_local_storage_service.dart';
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
    ErrandApiService? apiService,
  })  : _localStorageService = localStorageService,
        _apiService = apiService,
        _errands = List<ErrandModel>.from(
          initialErrands ?? MockDataService.getInitialErrands(),
        );

  final ErrandLocalStorageService? _localStorageService;
  final ErrandApiService? _apiService;
  List<ErrandModel> _errands;
  bool _isLoadedFromStorage = false;
  @override
  Future<List<ErrandModel>> getErrands({
    bool simulateError = false,
    bool simulateEmpty = false,
  }) async {
    if (simulateError) {
      throw Exception(
        'Gagal menghubungi server titipan. Periksa koneksi Anda.',
      );
    }
    if (simulateEmpty) {
      return <ErrandModel>[];
    }

    // 1. If remote API service is injected, attempt remote sync
    if (_apiService != null) {
      try {
        final remoteErrands = await _apiService!.fetchErrands();
        _errands = List<ErrandModel>.from(remoteErrands);
        await _localStorageService?.saveErrands(_errands);
        _isLoadedFromStorage = true;
        return List<ErrandModel>.from(_errands);
      } catch (e) {
        // Fallback to local storage on network/connection failure if available
        final storage = _localStorageService;
        if (storage != null) {
          final localCached = await storage.loadErrands();
          if (localCached.isNotEmpty) {
            _errands = List<ErrandModel>.from(localCached);
            _isLoadedFromStorage = true;
            return List<ErrandModel>.from(_errands);
          }
        }
        rethrow;
      }
    }

    // 2. Fallback to local-first / memory storage
    await Future<void>.delayed(const Duration(milliseconds: 10));
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
    // Validate domain business constraints
    ErrandBusinessValidator.validateErrandCreation(errand);

    if (simulateError) {
      throw Exception(
        'Gagal memproses pembuatan titipan baru. Silakan coba lagi.',
      );
    }

    ErrandModel created = errand;
    if (_apiService != null) {
      created = await _apiService!.createErrand(errand);
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    _errands.insert(0, created);
    await _localStorageService?.saveErrands(_errands);
    return created;
  }

  @override
  Future<ErrandModel> acceptErrand(
    String id, {
    String runnerName = 'Runner',
  }) async {
    final index = _errands.indexWhere((element) => element.id == id);
    if (index == -1) {
      throw Exception('Titipan dengan ID $id tidak ditemukan.');
    }

    final current = _errands[index];
    ErrandBusinessValidator.validateAccept(current, runnerName);

    ErrandModel updated = current.copyWith(status: OrderStatus.accepted);
    if (_apiService != null) {
      updated = await _apiService!.acceptErrand(id, runnerName: runnerName);
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    _errands[index] = updated;
    await _localStorageService?.saveErrands(_errands);
    return updated;
  }

  @override
  Future<ErrandModel> completeErrand(String id) async {
    final index = _errands.indexWhere((element) => element.id == id);
    if (index == -1) {
      throw Exception('Titipan dengan ID $id tidak ditemukan.');
    }

    final current = _errands[index];
    ErrandBusinessValidator.validateComplete(current);

    ErrandModel updated = current.copyWith(status: OrderStatus.completed);
    if (_apiService != null) {
      updated = await _apiService!.completeErrand(id);
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    _errands[index] = updated;
    await _localStorageService?.saveErrands(_errands);
    return updated;
  }

  @override
  Future<void> deleteErrand(String id) async {
    final index = _errands.indexWhere((element) => element.id == id);
    if (index == -1) {
      throw Exception('Titipan dengan ID $id tidak ditemukan.');
    }

    final current = _errands[index];
    ErrandBusinessValidator.validateCancellation(current);

    if (_apiService != null) {
      await _apiService!.deleteErrand(id);
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    _errands.removeAt(index);
    await _localStorageService?.saveErrands(_errands);
  }
}

final errandLocalStorageServiceProvider =
    Provider<ErrandLocalStorageService>((ref) {
  return ErrandLocalStorageService();
});
final errandApiServiceProvider = Provider<ErrandApiService>((ref) {
  return ErrandApiService(
    client: http.Client(),
    baseUrl: Uri.parse('https://api.titipjalur.campus/v1'),
  );
});

final errandRepositoryProvider = Provider<ErrandRepository>((ref) {
  final storage = ref.watch(errandLocalStorageServiceProvider);
  return ErrandRepositoryImpl(localStorageService: storage);
});
