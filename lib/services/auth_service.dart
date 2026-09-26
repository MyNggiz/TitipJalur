import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();
  factory AuthService() => instance;

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<UserModel> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final rawName = email.contains('@') ? email.split('@').first : email;
    final displayName = rawName.isNotEmpty
        ? '${rawName[0].toUpperCase()}${rawName.substring(1)}'
        : 'Pengguna';

    _currentUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: displayName,
      email: email,
      role: 'Mahasiswa',
    );
    notifyListeners();
    return _currentUser!;
  }

  Future<UserModel> loginAsGuest() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _currentUser = UserModel.guest();
    notifyListeners();
    return _currentUser!;
  }

  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _currentUser = null;
    notifyListeners();
  }
}
