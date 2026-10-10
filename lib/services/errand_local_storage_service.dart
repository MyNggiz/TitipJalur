import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/errand_model.dart';
import 'mock_data_service.dart';

/// Service untuk menangani penyimpanan lokal persisten data titipan
/// menggunakan [SharedPreferences] dengan serialisasi JSON.
class ErrandLocalStorageService {
  static const String storageKey = 'titipjalur_errands_v1';

  final SharedPreferences? _prefs;
  ErrandLocalStorageService({SharedPreferences? prefs}) : _prefs = prefs;


  Future<SharedPreferences?> _getPrefs() async {
    if (_prefs != null) return _prefs;
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  /// Memuat daftar pesanan titipan dari penyimpanan lokal.
  /// Jika belum ada data tersimpan, memuat data awal dari [MockDataService]
  /// dan menyimpannya secara otomatis ke penyimpanan lokal.
  Future<List<ErrandModel>> loadErrands() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) {
        return MockDataService.getInitialErrands();
      }
      final jsonString = prefs.getString(storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        final seedData = MockDataService.getInitialErrands();
        await saveErrands(seedData);
        return List<ErrandModel>.from(seedData);
      }

      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is List) {
        final list = decoded
            .map<ErrandModel>(
              (dynamic item) =>
                  ErrandModel.fromMap(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
        return list;
      }
      return MockDataService.getInitialErrands();
    } catch (_) {
      // Fallback aman jika terjadi error parsing
      return MockDataService.getInitialErrands();
    }
  }

  /// Menyimpan daftar pesanan titipan ke penyimpanan lokal secara persisten.
  Future<void> saveErrands(List<ErrandModel> errands) async {
    final prefs = await _getPrefs();
    if (prefs == null) return;
    final jsonList = errands.map((e) => e.toMap()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(storageKey, jsonString);
  }

  /// Menghapus seluruh data titipan dari penyimpanan lokal (reset).
  Future<void> clear() async {
    final prefs = await _getPrefs();
    if (prefs == null) return;
    await prefs.remove(storageKey);
  }
}
