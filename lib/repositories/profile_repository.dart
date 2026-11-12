import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Exception khusus untuk kegagalan komunikasi API profil.
class ProfileUpdateException implements Exception {
  final String message;
  const ProfileUpdateException(this.message);

  @override
  String toString() => message;
}

/// Interface kontrak repository profil mahasiswa (Single Responsibility: Request API & Persistensi).
abstract class ProfileRepository {
  Future<UserModel> getProfile();

  Future<UserModel> updateProfile({
    required String name,
    required String email,
    required String nim,
    required String phoneNumber,
    String? role,
    bool simulateError = false,
  });
}

/// Implementasi resmi [ProfileRepository] yang menangani simulasi request API jaringan,
/// pembaruan model data pengguna, dan sinkronisasi sesi ke penyimpanan lokal permanen.
class ProfileRepositoryImpl implements ProfileRepository {
  final AuthService _authService;

  ProfileRepositoryImpl({AuthService? authService})
      : _authService = authService ?? AuthService.instance;

  @override
  Future<UserModel> getProfile() async {
    // Simulasi latensi jaringan API
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final current = _authService.currentUser;
    if (current != null) {
      return current;
    }
    // Jika belum login, kembalikan user guest default
    return UserModel.guest();
  }

  @override
  Future<UserModel> updateProfile({
    required String name,
    required String email,
    required String nim,
    required String phoneNumber,
    String? role,
    bool simulateError = false,
  }) async {
    // Simulasi panggilan HTTP PUT/POST ke API server kampus
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (simulateError) {
      throw const ProfileUpdateException(
        'Gagal memperbarui profil: Terjadi kendala koneksi ke server kampus. Silakan coba lagi.',
      );
    }

    final current = _authService.currentUser ?? UserModel.guest();
    final updatedUser = current.copyWith(
      name: name.trim(),
      email: email.trim(),
      nim: nim.trim(),
      phoneNumber: phoneNumber.trim(),
      role: role ?? current.role,
    );

    // Sinkronkan ke AuthService dan simpan ke disk lokal
    await _authService.setCurrentUser(updatedUser);
    return updatedUser;
  }
}

/// Provider Riverpod untuk dependency injection [ProfileRepository].
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ProfileRepositoryImpl(authService: authService);
});
