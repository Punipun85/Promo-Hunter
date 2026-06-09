import 'package:flutter/foundation.dart';

import '../models/profile_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService);

  final AuthService _authService;

  ProfileModel? currentUser;
  bool isLoading = false;
  String? errorMessage;
  bool registerNeedsVerification = false;

  bool get isLoggedIn => currentUser != null;
  bool get isAdmin => currentUser?.isAdmin ?? false;

  Future<void> bootstrap() async {
    currentUser = await _authService.restoreSession();
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    currentUser = await _authService.refreshCurrentUserProfile();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    registerNeedsVerification = false;
    notifyListeners();
    try {
      currentUser = await _authService.login(email: email, password: password);
      currentUser = await _authService.refreshCurrentUserProfile();
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    isLoading = true;
    errorMessage = null;
    registerNeedsVerification = false;
    notifyListeners();
    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      currentUser = null;
      registerNeedsVerification = _authService.registerNeedsVerification;
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    currentUser = null;
    errorMessage = null;
    registerNeedsVerification = false;
    notifyListeners();
  }
}
