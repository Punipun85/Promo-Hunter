import 'package:flutter/foundation.dart';

import '../models/profile_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService);

  final AuthService _authService;

  ProfileModel? currentUser;
  bool isLoading = false;

  bool get isLoggedIn => currentUser != null;
  bool get isAdmin => currentUser?.isAdmin ?? false;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      currentUser = await _authService.login(email: email, password: password);
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      currentUser = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    currentUser = null;
    notifyListeners();
  }
}

