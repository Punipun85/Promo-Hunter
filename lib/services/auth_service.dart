import '../models/profile_model.dart';

class AuthService {
  ProfileModel? _currentUser;

  Future<ProfileModel> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _currentUser = ProfileModel(
      id: 'demo-user',
      name: email.contains('admin') ? 'Admin PromoHunter' : 'Demo User',
      email: email,
      role: email.contains('admin') ? 'admin' : 'user',
    );
    return _currentUser!;
  }

  Future<ProfileModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _currentUser = ProfileModel(
      id: 'demo-user',
      name: name,
      email: email,
      role: 'user',
    );
    return _currentUser!;
  }

  Future<void> logout() async {
    _currentUser = null;
  }

  ProfileModel? getCurrentUser() => _currentUser;
}

