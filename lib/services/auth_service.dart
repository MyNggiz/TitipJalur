import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Advanced Authentication and Role Management Service for TitipJalur.
/// Supports session persistence (SharedPreferences), role-based actions, and reactive state updates.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();
  factory AuthService() => instance;

  static const String _userStorageKey = 'titip_jalur_active_user_session';

  UserModel? _currentUser;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isRunner => _currentUser?.role.toLowerCase() == 'runner' || _currentUser?.role.toLowerCase() == 'komuter';
  bool get isRequester => !isRunner;

  /// Restores saved authentication session from local disk on app startup.
  Future<UserModel?> restoreSession() async {
    if (_isInitialized) return _currentUser;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_userStorageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _currentUser = UserModel.fromMap(map);
      }
    } catch (e) {
      debugPrint('[AuthService] Gagal memulihkan sesi login: $e');
    }
    _isInitialized = true;
    notifyListeners();
    return _currentUser;
  }

  Future<UserModel> login(String email, String password, {String role = 'Mahasiswa'}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final rawName = email.contains('@') ? email.split('@').first : email;
    final displayName = rawName.isNotEmpty
        ? '${rawName[0].toUpperCase()}${rawName.substring(1)}'
        : 'Pengguna';

    _currentUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: displayName,
      email: email,
      role: role,
    );

    await _saveSessionToDisk();
    notifyListeners();
    return _currentUser!;
  }

  Future<UserModel> loginAsGuest({String role = 'Mahasiswa'}) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _currentUser = UserModel.guest().copyWith(role: role);
    await _saveSessionToDisk();
    notifyListeners();
    return _currentUser!;
  }

  /// Toggles or sets user role (e.g. switching between Requester and Runner).
  Future<UserModel?> switchRole(String newRole) async {
    if (_currentUser == null) return null;
    _currentUser = _currentUser!.copyWith(role: newRole);
    await _saveSessionToDisk();
    notifyListeners();
    return _currentUser;
  }

  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userStorageKey);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _saveSessionToDisk() async {
    if (_currentUser == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userStorageKey, jsonEncode(_currentUser!.toMap()));
    } catch (e) {
      debugPrint('[AuthService] Gagal menyimpan sesi ke disk: $e');
    }
  }
}

final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) {
  return AuthService.instance;
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});
