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
}

class ErrandRepositoryImpl implements ErrandRepository {
  ErrandRepositoryImpl({List<ErrandModel>? initialErrands})
      : _errands = List<ErrandModel>.from(
          initialErrands ?? MockDataService.getInitialErrands(),
        );

  final List<ErrandModel> _errands;

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
    return updated;
  }
}

final errandRepositoryProvider = Provider<ErrandRepository>((ref) {
  return ErrandRepositoryImpl();
});
