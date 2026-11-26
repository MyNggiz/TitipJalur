import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/errand_model.dart';
import 'mock_data_service.dart';

/// Exception thrown when persistent local storage is unavailable or fails to write.
class LocalStorageException implements Exception {
  final String message;
  const LocalStorageException(this.message);

  @override
  String toString() => 'LocalStorageException: $message';
}

/// Service untuk menangani penyimpanan lokal persisten data titipan
/// menggunakan [SharedPreferences] dengan serialisasi JSON.
class ErrandLocalStorageService {
  static const String storageKey = 'titipjalur_errands_v1';

  final SharedPreferences? _prefs;
  final Future<SharedPreferences?> Function()? _prefsProvider;

  ErrandLocalStorageService({
    SharedPreferences? prefs,
    Future<SharedPreferences?> Function()? prefsProvider,
  })  : _prefs = prefs,
        _prefsProvider = prefsProvider;

  Future<SharedPreferences?> _getPrefs() async {
    if (_prefs != null) return _prefs;
    if (_prefsProvider != null) {
      return await _prefsProvider!();
    }
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
  /// Melempar [LocalStorageException] jika penyimpanan lokal tidak tersedia atau gagal menulis.
  Future<void> saveErrands(List<ErrandModel> errands) async {
    final SharedPreferences? prefs;
    try {
      prefs = await _getPrefs();
    } catch (e) {
      throw LocalStorageException('Penyimpanan lokal tidak tersedia: $e');
    }

    if (prefs == null) {
      throw const LocalStorageException(
        'Penyimpanan lokal tidak tersedia untuk menyimpan data titipan.',
      );
    }

    try {
      final jsonList = errands.map((e) => e.toMap()).toList();
      final jsonString = jsonEncode(jsonList);
      final saved = await prefs.setString(storageKey, jsonString);
      if (!saved) {
        throw const LocalStorageException(
          'Gagal menulis data titipan ke penyimpanan lokal.',
        );
      }
    } on LocalStorageException {
      rethrow;
    } catch (e) {
      throw LocalStorageException(
        'Gagal menyimpan data titipan ke penyimpanan lokal: $e',
      );
    }
  }

  /// Menghapus seluruh data titipan dari penyimpanan lokal (reset).
  Future<void> clear() async {
    final SharedPreferences? prefs;
    try {
      prefs = await _getPrefs();
    } catch (e) {
      throw LocalStorageException('Penyimpanan lokal tidak tersedia: $e');
    }

    if (prefs == null) {
      throw const LocalStorageException(
        'Penyimpanan lokal tidak tersedia untuk menghapus data titipan.',
      );
    }

    try {
      final removed = await prefs.remove(storageKey);
      if (!removed) {
        throw const LocalStorageException(
          'Gagal menghapus data titipan dari penyimpanan lokal.',
        );
      }
    } on LocalStorageException {
      rethrow;
    } catch (e) {
      throw LocalStorageException(
        'Gagal menghapus data titipan dari penyimpanan lokal: $e',
      );
    }
  }
}
